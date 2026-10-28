#!/usr/bin/env python3
"""Host-driven Phase 1 device checks (docs/testing/phase1-device-checklist.md).

Drives a physical Android device over adb: real screen lock/unlock, Home,
media keys, notification-shade media controls, PiP, battery saver and task
removal. Measures the system media session (`dumpsys media_session`), active
audio players (`dumpsys audio`) and on-screen/captured video frames (decoded
from the synthetic test pattern, see scripts/gen_test_media.sh).

Prerequisites: a debug build installed with
  --dart-define=UMP_DEBUG_AUTOLOAD=<dir>/ump_long.mp4;<dir>/ump_tone.mp3;<dir>/ump_portrait.mp4
and test media pushed via scripts/device_test_media.sh. Requires ffmpeg.
The device must unlock without a PIN while connected (else unlock steps fail).

Usage: python3 -I scripts/device_lifecycle_checks.py <device-id> [check ...]
"""

import os
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

PKG = "com.akshayrana.video_music_app"
ALBUM = "Media Player Screenshots"
DEV = sys.argv[1]
RESULTS = []


def adb(*args, text=True):
    return subprocess.run(
        ["adb", "-s", DEV, *args], capture_output=True, text=text
    ).stdout


def sh(cmd):
    return adb("shell", cmd)


def record(name, ok, evidence):
    status = "PASS" if ok is True else ("FAIL" if ok is False else ok)
    RESULTS.append((name, status, evidence))
    print(f"[{status}] {name}: {evidence}", flush=True)


# --------------------------------------------------------------------------
# Observations


def session():
    out = sh("dumpsys media_session")
    start = out.find(f"media-session {PKG}")
    if start < 0:
        return {"state": "NONE", "pos": 0.0, "title": None}
    block = out[start : start + 3000]
    m = re.search(
        r"state=PlaybackState \{state=(\w+)\(\d+\), position=(-?\d+),"
        r".*?speed=([\d.]+), updated=(\d+)",
        block,
    )
    title = re.search(r"metadata: size=\d+, description=([^,\n]*)", block)
    if not m:
        return {"state": "NONE", "pos": 0.0, "title": None}
    state, pos, speed, updated = m.group(1), int(m.group(2)), float(m.group(3)), int(m.group(4))
    if state == "PLAYING":
        now = float(sh("cat /proc/uptime").split()[0]) * 1000
        pos += (now - updated) * speed
    return {"state": state, "pos": pos / 1000, "title": title.group(1) if title else None}


APP_UID = None


def started_players():
    out = sh("dumpsys audio")
    section = out[out.find("  players:") :]
    section = section[: section.find("\n\n")] if "\n\n" in section else section
    return sum(
        1
        for line in section.splitlines()
        if f"u/pid:{APP_UID}/" in line and "state:started" in line
    )


def ui_nodes():
    sh("uiautomator dump /sdcard/ump_ui.xml")
    xml = sh("cat /sdcard/ump_ui.xml")
    try:
        root = ET.fromstring(xml[xml.find("<?xml") :])
    except ET.ParseError:
        return []
    nodes = []
    for n in root.iter("node"):
        b = re.findall(r"\d+", n.get("bounds", "0,0,0,0"))
        nodes.append(
            {
                "desc": n.get("content-desc", "") or n.get("text", ""),
                "pkg": n.get("package", ""),
                "checked": n.get("checked") == "true",
                "bounds": tuple(map(int, b)),
            }
        )
    return nodes


def find(prefix, pkg=PKG, nodes=None):
    for n in nodes or ui_nodes():
        if n["pkg"] == pkg and n["desc"].startswith(prefix):
            return n
    return None


def tap(node):
    x1, y1, x2, y2 = node["bounds"]
    sh(f"input tap {(x1 + x2) // 2} {(y1 + y2) // 2}")


def screen_grey(x, y):
    """Grey level at (x, y) of a fresh screenshot."""
    png = adb("exec-out", "screencap -p", text=False)
    return grey_from_png(png, x, y)


def grey_from_png(png, x, y):
    with tempfile.NamedTemporaryFile(suffix=".png") as f:
        f.write(png)
        f.flush()
        raw = subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-i", f.name, "-vf",
             f"crop=4:4:{x - 2}:{y - 2},format=gray", "-f", "rawvideo", "-"],
            capture_output=True,
        ).stdout
    return sum(raw) / len(raw) if raw else -1


def grey_to_second(grey):
    limited = 16 + grey * 219 / 255
    return round((limited - 16) / 7)


def png_size(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
         "stream=width,height", "-of", "csv=p=0", path],
        capture_output=True, text=True,
    ).stdout.strip()
    return tuple(map(int, out.split(","))) if out else None


# --------------------------------------------------------------------------
# Actions


def key(code):
    sh(f"input keyevent {code}")


def media(cmd):
    """Media key routed by MediaSessionService (headset/Bluetooth path)."""
    sh(f"cmd media_session dispatch {cmd}")


def ensure(state):
    """Reach PLAYING/PAUSED with the play-pause key. Until the app's session
    has been active once (e.g. right after a reinstall), the system routes
    keys to a stale receiver, so fall back to the in-app Play/Pause button."""
    for attempt in range(4):
        if session()["state"] == state:
            return True
        if attempt < 2:
            media("play-pause")
        else:
            button = find("Play" if state == "PLAYING" else "Pause")
            if button:
                tap(button)
        time.sleep(1.5)
    return session()["state"] == state


def lock():
    key("KEYCODE_SLEEP")


def unlock():
    key("KEYCODE_WAKEUP")
    time.sleep(0.5)
    sh("wm dismiss-keyguard")
    time.sleep(1.5)


def open_app():
    sh(f"am start -n {PKG}/.MainActivity")
    time.sleep(2)


def keyguard_showing():
    return "isKeyguardShowing=true" in sh("dumpsys window | grep isKeyguardShowing")


def background_setting():
    """Current value from the app's debug log (uiautomator's checked state can
    be stale after a tap). Defaults to off, the app default."""
    pid = sh(f"pidof {PKG}").strip()
    if not pid:
        return False
    hits = re.findall(r"continueVideoAudioInBackground=(true|false)",
                      adb("logcat", "-d", f"--pid={pid}", "-s", "flutter"))
    return hits[-1] == "true" if hits else False


def set_background_setting(on):
    """Toggles the in-app switch. uiautomator cannot dump while media plays
    (the seek bar's semantics never go idle), so pause briefly, then restore."""
    if background_setting() == on:
        return True
    was_playing = session()["state"] == "PLAYING"
    if was_playing:
        ensure("PAUSED")
    try:
        return _tap_setting(on)
    finally:
        if was_playing:
            ensure("PLAYING")


def _tap_setting(on):
    scroll_to_top()
    node = find("Continue video audio in background")
    if node is None:
        sh("input swipe 600 2400 600 1600 400")
        time.sleep(1.2)
        node = find("Continue video audio in background")
    if node is None:
        return False
    tap(node)
    time.sleep(1)
    return background_setting() == on


def select(title):
    for _ in range(6):
        s = session()
        if s["title"] == title:
            return True
        order = ["ump_long", "ump_tone", "ump_portrait"]
        cur = s["title"]
        if cur in order and order.index(cur) > order.index(title):
            media("previous")
            time.sleep(0.3)
            media("previous")
        else:
            media("next")
        time.sleep(2)
    return session()["title"] == title


def play_from(title, seconds=0.0):
    select(title)
    ensure("PLAYING")
    # Seek via +/-10 s keys is coarse; use rewind to the start when asked.
    if seconds == 0.0:
        for _ in range(15):
            if session()["pos"] < 1.5:
                break
            media("rewind")
            time.sleep(0.4)
    time.sleep(1)
    return session()


def scroll_to_top():
    """Swipes on the lower half (not the video, whose InteractiveViewer owns
    drags) until the top buttons are visible, then lets the scroll settle."""
    for _ in range(4):
        top = find("Choose files")
        if top and top["bounds"][1] < 500:
            break
        sh("input swipe 600 2250 600 2650 300")  # below the seek bar
        time.sleep(1.2)


def video_probe_point():
    nodes = ui_nodes()
    top = find("Add to queue", nodes=nodes)
    bottom = find("Reset zoom", nodes=nodes)
    if not top or not bottom:
        return None
    width = int(sh("wm size").split()[-1].split("x")[0])
    return (width * 3 // 4, (top["bounds"][3] + bottom["bounds"][1]) // 2)


# --------------------------------------------------------------------------
# Checks


def check_lock_setting_off():
    unlock(); open_app()
    set_background_setting(False)
    play_from("ump_long")
    time.sleep(3)
    before = session()
    lock(); time.sleep(4)
    kg = keyguard_showing()
    locked = session()
    players = started_players()
    unlock(); time.sleep(3)
    after = session()
    record(
        "6 setting off + lock -> pause, stays paused after unlock",
        before["state"] == "PLAYING" and locked["state"] == "PAUSED"
        and players == 0 and after["state"] == "PAUSED"
        and abs(after["pos"] - locked["pos"]) < 0.5,
        f"before={before['state']}@{before['pos']:.1f}s locked={locked['state']}@{locked['pos']:.1f}s "
        f"keyguard={kg} startedPlayers={players} afterUnlock={after['state']}@{after['pos']:.1f}s",
    )


def check_home_setting_off():
    open_app()
    ensure("PLAYING"); time.sleep(3)
    before = session()
    key("KEYCODE_HOME"); time.sleep(3)
    bg = session()
    open_app(); time.sleep(2)
    back = session()
    record(
        "7 setting off + Home -> pause, no auto-resume on return",
        before["state"] == "PLAYING" and bg["state"] == "PAUSED" and back["state"] == "PAUSED",
        f"before={before['state']} background={bg['state']}@{bg['pos']:.1f}s returned={back['state']}",
    )


def check_lock_setting_on_and_controls():
    unlock(); open_app()
    ok_setting = set_background_setting(True)
    select("ump_long")
    ensure("PAUSED")
    scroll_to_top()
    point = video_probe_point()  # read while paused; reused after unlock
    play_from("ump_long")
    start = session()
    lock(); t0 = time.time()
    time.sleep(5)
    kg = keyguard_showing()
    time.sleep(85)
    mid = session()
    elapsed = time.time() - t0
    players = started_players()
    advanced = mid["pos"] - start["pos"]
    record(
        "8 setting on + lock 90 s -> MP4 audio continues",
        ok_setting and mid["state"] == "PLAYING" and abs(advanced - elapsed) < 4 and players == 1,
        f"settingOn={ok_setting} keyguard={kg} state={mid['state']} advanced={advanced:.1f}s "
        f"over {elapsed:.1f}s startedPlayers={players}",
    )

    # 9: system media controls while locked (MediaSessionService key routing).
    steps = []
    media("play-pause"); time.sleep(1.5); s = session(); steps.append(("pause", s["state"] == "PAUSED", s["state"]))
    media("play-pause"); time.sleep(1.5); s = session(); steps.append(("play", s["state"] == "PLAYING", s["state"]))
    p = session()["pos"]; media("fast-forward"); time.sleep(1); q = session()["pos"]
    steps.append(("+10s", 9 < q - p < 12, f"{p:.1f}->{q:.1f}"))
    p = session()["pos"]; media("rewind"); time.sleep(1); q = session()["pos"]
    steps.append(("-10s", -11 < q - p < -8, f"{p:.1f}->{q:.1f}"))
    media("next"); time.sleep(3); s = session()
    steps.append(("next", s["title"] not in (None, "ump_long") and s["state"] == "PLAYING", f"{s['title']} {s['state']}"))
    media("previous"); time.sleep(3); s = session()
    steps.append(("previous", s["title"] == "ump_long" and s["state"] == "PLAYING", f"{s['title']} {s['state']}"))
    players = started_players()
    record(
        "9 lock-screen/system media controls change real playback",
        all(ok for _, ok, _ in steps) and players == 1,
        "; ".join(f"{n}:{'ok' if ok else 'BAD'}({e})" for n, ok, e in steps) + f"; startedPlayers={players}",
    )

    # 9c: the real lock-screen media card (SystemUI TransportControls). Needs
    # UMP_LOCKSCREEN_BUTTONS="play=1075,1843;next=852,2021;previous=96,2021",
    # measured from a screenshot of this device's lock screen.
    pts = os.environ.get("UMP_LOCKSCREEN_BUTTONS")
    if pts:
        pts = {k: tuple(map(int, v.split(","))) for k, v in
               (item.split("=") for item in pts.split(";"))}
        key("KEYCODE_WAKEUP"); time.sleep(2)
        on_keyguard = keyguard_showing()
        steps = []
        def tap_pt(name, wait=2.5):
            sh("input tap %d %d" % pts[name]); time.sleep(wait)
            return session()
        s1 = tap_pt("play"); steps.append(("pause", s1["state"] == "PAUSED", s1["state"]))
        s1 = tap_pt("play"); steps.append(("play", s1["state"] == "PLAYING", s1["state"]))
        s1 = tap_pt("next"); steps.append(("next", s1["title"] == "ump_tone", s1["title"]))
        # Spec 7.1: previous goes back within 3 s of the start, else restarts.
        before = session()
        s1 = tap_pt("previous")
        if before["pos"] < 3:
            ok = s1["title"] == "ump_long"
        else:
            ok = s1["title"] == before["title"] and s1["pos"] < 3
        steps.append(("previous", ok, f"from {before['title']}@{before['pos']:.1f}s -> "
                                      f"{s1['title']}@{s1['pos']:.1f}s"))
        record(
            "9c lock-screen media card controls change real playback",
            on_keyguard and all(ok for _, ok, _ in steps),
            f"keyguardShowing={on_keyguard}; "
            + "; ".join(f"{n}:{'ok' if ok else 'BAD'}({e})" for n, ok, e in steps),
        )
    # Leave room before ump_long (120 s) ends while waiting for the user.
    for _ in range(8):
        media("rewind"); time.sleep(0.3)

    # 10: unlock -> picture back, in sync, single audio stream. A secure lock
    # cannot be dismissed over adb, so wait for the user to unlock.
    unlock()
    if keyguard_showing() or "deviceLocked=1" in sh("dumpsys trust"):
        print(">>> Please unlock the phone now (waiting up to 3 minutes)...", flush=True)
        deadline = time.time() + 180
        while time.time() < deadline and keyguard_showing():
            time.sleep(1)
        time.sleep(2)
    if keyguard_showing():
        record("10 unlock -> video at current position, A/V in sync, no double audio",
               "NOT RUN", "phone was not unlocked within 3 minutes")
        return
    players = started_players()
    if point is None:
        record("10 unlock -> video at current position, A/V in sync, no double audio", False,
               "video area not found on screen")
        return
    s = session()
    png = adb("exec-out", "screencap -p", text=False)
    s2 = session()
    # The probe must sit on the flat grey half of the test pattern.
    spread = max(grey_from_png(png, point[0] + dx, point[1] + dy)
                 for dx, dy in ((-40, 0), (40, 0), (0, -40), (0, 40))) - \
        min(grey_from_png(png, point[0] + dx, point[1] + dy)
            for dx, dy in ((-40, 0), (40, 0), (0, -40), (0, 40)))
    shown = grey_to_second(grey_from_png(png, *point))
    # The frame must lie between the session positions read around the capture.
    window = [int(t) % 30 for t in range(int(s["pos"]), int(s2["pos"]) + 1)]
    expected = f"{window[0]}..{window[-1]}"
    diff = min(min((shown - w) % 30, (w - shown) % 30) for w in window)
    record(
        "10 unlock -> video at current position, A/V in sync, no double audio",
        s["state"] == "PLAYING" and players == 1 and spread < 6 and diff <= 1,
        f"state={s['state']} session={s['pos']:.1f}-{s2['pos']:.1f}s screenFrameSecond(mod30)={shown} "
        f"expected~{expected} probeSpread={spread:.0f} startedPlayers={players}",
    )


def _sync_after_return(name, send_to_background, bring_back, away_s):
    """Video audio continues while the surface is torn down, then the picture
    returns at the current position with a single audio player."""
    unlock(); open_app()
    set_background_setting(True)
    select("ump_long")
    ensure("PAUSED")
    scroll_to_top()
    point = video_probe_point()
    ensure("PLAYING")
    for _ in range(9):  # start near 0 so the item cannot finish meanwhile
        media("rewind"); time.sleep(0.3)
    send_to_background(); time.sleep(away_s)
    bg = session()
    bg_players = started_players()
    bring_back(); time.sleep(2.5)
    if point is None:
        record(name, False, "video area not found")
        return
    s = session()
    png = adb("exec-out", "screencap -p", text=False)
    s2 = session()
    players = started_players()
    probes = [grey_from_png(png, point[0] + dx, point[1] + dy)
              for dx, dy in ((-40, 0), (40, 0), (0, -40), (0, 40))]
    spread = max(probes) - min(probes)
    shown = grey_to_second(grey_from_png(png, *point))
    window = [int(t) % 30 for t in range(int(s["pos"]), int(s2["pos"]) + 1)]
    diff = min(min((shown - w) % 30, (w - shown) % 30) for w in window)
    record(
        name,
        bg["state"] == "PLAYING" and bg_players == 1 and s["state"] == "PLAYING"
        and players == 1 and spread < 6 and diff <= 1,
        f"background={bg['state']}@{bg['pos']:.1f}s players={bg_players}; returned={s['state']} "
        f"session={s['pos']:.1f}-{s2['pos']:.1f}s screenFrameSecond(mod30)={shown} "
        f"expected={window[0]}..{window[-1]} probeSpread={spread:.0f} startedPlayers={players}",
    )
    set_background_setting(False)


def check_screen_off_sync():
    def off():
        lock()
    def on():
        unlock()
        if keyguard_showing():
            raise RuntimeError("secure keyguard engaged; unlock needed")
    # Short enough that this device's secure keyguard has not engaged yet; the
    # activity is stopped and the video surface destroyed all the same.
    _sync_after_return("10a screen off 6 s (setting on) -> wake: picture in sync, one player",
                       off, on, 6)


def check_home_sync():
    _sync_after_return("10b Home 20 s (setting on) -> reopen: picture in sync, one player",
                       lambda: key("KEYCODE_HOME"), open_app, 20)


def check_notification_controls():
    """Taps the SystemUI media controls in the notification shade (the same
    TransportControls path the lock screen uses). The shade only reaches an
    idle state for uiautomator while paused, so button bounds are read once."""
    unlock(); open_app()
    ensure("PAUSED"); time.sleep(1)
    # uiautomator needs an idle UI; animations are disabled briefly and the
    # user's original scales are restored right after the dump.
    scales = {k: sh(f"settings get global {k}").strip() for k in
              ("animator_duration_scale", "transition_animation_scale", "window_animation_scale")}
    nodes = []
    try:
        for k in scales:
            sh(f"settings put global {k} 0")
        sh("cmd statusbar expand-notifications"); time.sleep(2.5)
        for _ in range(3):
            nodes = [n for n in ui_nodes() if n["pkg"] == "com.android.systemui"]
            if nodes:
                break
            time.sleep(1)
    finally:
        for k, v in scales.items():
            sh(f"settings put global {k} {v if v not in ('', 'null') else 1.0}")
    play = next((n for n in nodes if n["desc"] in ("Play", "Play media")), None)
    nxt = next((n for n in nodes if n["desc"] in ("Next", "Next track", "Skip to next")), None)
    # Fallback when another app's live notification keeps the shade from ever
    # being idle: UMP_SHADE_BUTTONS="play=1060,789;next=837,970" measured from a
    # screenshot of this device's expanded shade.
    override = os.environ.get("UMP_SHADE_BUTTONS")
    if (play is None or nxt is None) and override:
        pts = dict(item.split("=") for item in override.split(";"))
        def pt(name):
            x, y = map(int, pts[name].split(","))
            return {"bounds": (x, y, x, y)}
        play, nxt = pt("play"), pt("next")
        sh("cmd statusbar expand-notifications"); time.sleep(2)
    steps = []
    if play is None or nxt is None:
        # Short labels only: other apps' notification text is personal data.
        labels = sorted({n["desc"] for n in nodes
                         if n["desc"] and len(n["desc"]) <= 20 and "\n" not in n["desc"]})[:25]
        record("9b notification media controls change real playback", False,
               f"buttons not found; shade labels={labels}")
        sh("cmd statusbar collapse")
        return
    tap(play); time.sleep(2)
    s = session(); steps.append(("Play", s["state"] == "PLAYING", s["state"]))
    tap(play); time.sleep(2)  # same slot now shows Pause
    s = session(); steps.append(("Pause", s["state"] == "PAUSED", s["state"]))
    before = session()["title"]
    tap(nxt); time.sleep(3)
    s = session(); steps.append(("Next", s["title"] != before, f"{before}->{s['title']}"))
    notif = f"pkg={PKG}" in sh("dumpsys notification --noredact")
    sh("cmd statusbar collapse")
    record(
        "9b notification media controls change real playback",
        all(ok for _, ok, _ in steps) and notif,
        "; ".join(f"{l}:{'ok' if ok else 'BAD'}({e})" for l, ok, e in steps) + f"; notificationPosted={notif}",
    )


def check_toggle_off_then_background():
    unlock(); open_app()
    set_background_setting(True)
    play_from("ump_long")
    key("KEYCODE_HOME"); time.sleep(3)
    bg_on = session()
    open_app()
    off = set_background_setting(False)
    still = session()
    key("KEYCODE_HOME"); time.sleep(3)
    bg_off = session()
    open_app()
    record(
        "11 setting on keeps playing in background; turned off -> background pauses",
        bg_on["state"] == "PLAYING" and off and bg_off["state"] == "PAUSED",
        f"backgroundWithSettingOn={bg_on['state']} settingOff={off} foreground={still['state']} "
        f"backgroundWithSettingOff={bg_off['state']}",
    )


def check_mp3_lock():
    unlock(); open_app()
    set_background_setting(False)
    ok_sel = select("ump_tone")
    ensure("PLAYING"); time.sleep(2)
    start = session()
    lock(); t0 = time.time(); time.sleep(150)
    s = session(); elapsed = time.time() - t0
    players = started_players()
    unlock()
    record(
        "12 MP3 (setting off) keeps playing while locked 150 s",
        ok_sel and s["state"] == "PLAYING" and abs((s["pos"] - start["pos"]) - elapsed) < 4 and players == 1,
        f"title={s['title']} state={s['state']} advanced={s['pos'] - start['pos']:.1f}s over {elapsed:.1f}s "
        f"startedPlayers={players}",
    )


def check_headset_button():
    unlock(); open_app()
    ensure("PLAYING"); time.sleep(2)
    a = session()["state"]
    key("KEYCODE_HEADSETHOOK"); time.sleep(2)
    b = session()["state"]
    key("KEYCODE_HEADSETHOOK"); time.sleep(2)
    c = session()["state"]
    key("KEYCODE_MEDIA_PLAY_PAUSE"); time.sleep(2)
    d = session()["state"]
    record(
        "15 headset hook / play-pause key toggles playback",
        (a, b, c, d) == ("PLAYING", "PAUSED", "PLAYING", "PAUSED"),
        f"start={a} hook->{b} hook->{c} playPause->{d}",
    )


def check_focus_loss():
    """Another app takes permanent audio focus; we must pause and stay paused."""
    unlock(); open_app()
    ensure("PLAYING"); time.sleep(2)
    before = session()["state"]
    sh("mkdir -p /sdcard/Music && run-as %s cat files/test_media/ump_short_tone.mp3 "
       "> /sdcard/Music/ump_focus_test.mp3" % PKG)
    sh("cmd media scan /sdcard/Music/ump_focus_test.mp3 2>/dev/null; "
       "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Music/ump_focus_test.mp3")
    time.sleep(3)
    row = sh("content query --uri content://media/external/audio/media --projection _id "
             "--where \"_display_name='ump_focus_test.mp3'\"")
    m = re.search(r"_id=(\d+)", row)
    handler = None
    if m:
        uri = f"content://media/external/audio/media/{m.group(1)}"
        target = "com.google.android.apps.nbu.files/.gateway.preview.PreviewActivity"
        if "gateway.preview.PreviewActivity" not in sh(
            "cmd package query-activities --brief -a android.intent.action.VIEW -t audio/mpeg "
            f"-d {uri}"
        ):
            target = None
        out = sh(f"am start -W -a android.intent.action.VIEW -d {uri} -t audio/mpeg -f 1"
                 + (f" -n {target}" if target else ""))
        handler = re.search(r"Activity: ([\w.]+)/", out)
        time.sleep(6)
    taken = session()["state"]
    focus = sh("dumpsys audio | sed -n '/Audio Focus stack entries/,/^$/p'")
    other = handler.group(1) if handler else None
    if other == "com.google.android.permissioncontroller":
        key("KEYCODE_BACK")
        other = None
    if other:
        sh(f"am force-stop {other}")
    time.sleep(5)
    after = session()["state"]
    if m:
        sh(f"content delete --uri content://media/external/audio/media/{m.group(1)}")
    sh("rm -f /sdcard/Music/ump_focus_test.mp3")
    open_app()
    if not other:
        record("13 audio focus loss pauses, no auto-resume", "NOT RUN",
               "no system app handled the audio VIEW intent")
        return
    record(
        "13 audio focus loss pauses, no auto-resume",
        before == "PLAYING" and taken == "PAUSED" and after == "PAUSED",
        f"before={before} afterOtherAppPlayed={taken} afterOtherAppStopped={after} other={other} "
        f"focusTop={' '.join(focus.split()[:12])}",
    )


def check_capture_frame():
    unlock(); open_app()
    select("ump_long")
    ensure("PLAYING"); time.sleep(4)
    for _ in range(4):
        media("fast-forward"); time.sleep(0.3)
    time.sleep(1.5)
    ensure("PAUSED")
    pos = session()["pos"]
    scroll_to_top()
    n = find("Capture frame")
    before = set(sh(f"ls '/sdcard/Pictures/{ALBUM}' 2>/dev/null").split())
    if n is None:
        record("5 capture frame saves the decoded frame", False, "button not found")
        return
    tap(n); time.sleep(4)
    after = set(sh(f"ls '/sdcard/Pictures/{ALBUM}' 2>/dev/null").split())
    new = sorted(after - before)
    if not new:
        record("5 capture frame saves the decoded frame", False, "no new file in gallery album")
        return
    with tempfile.TemporaryDirectory() as d:
        local = f"{d}/{new[-1]}"
        adb("pull", f"/sdcard/Pictures/{ALBUM}/{new[-1]}", local)
        size = png_size(local)
        with open(local, "rb") as f:
            grey = grey_from_png(f.read(), size[0] * 3 // 4, size[1] // 2)
    shown = grey_to_second(grey)
    record(
        "5 capture frame saves the decoded frame (source resolution, no UI)",
        size == (1280, 720) and shown == int(pos) % 30,
        f"file=Pictures/{ALBUM}/{new[-1]} size={size} frameSecond(mod30)={shown} "
        f"playerPosition={pos:.2f}s",
    )
    sh(f"content delete --uri content://media/external/images/media "
       f"--where \"relative_path LIKE 'Pictures/{ALBUM}%'\"")
    sh(f"rm -rf '/sdcard/Pictures/{ALBUM}'")


def row_profile(png, y, x0, x1, n=16):
    return [grey_from_png(png, x0 + (x1 - x0) * i // n, y) for i in range(1, n)]


def profile_diff(a, b):
    return sum(abs(p - q) for p, q in zip(a, b)) / len(a)


def check_double_tap_zoom():
    unlock(); open_app()
    select("ump_long")
    ensure("PAUSED"); time.sleep(1)
    point = video_probe_point()
    if point is None:
        record("4 double-tap zoom on the real video surface", False, "video area not found")
        return
    width = int(sh("wm size").split()[-1].split("x")[0])
    y = point[1] - 120  # through the testsrc pattern, not the flat grey half
    cx = width // 4
    png_a = adb("exec-out", "screencap -p", text=False)
    pos_a = session()["pos"]
    sh(f"input tap {cx} {y} & sleep 0.08; input tap {cx} {y}")
    time.sleep(1.5)
    png_b = adb("exec-out", "screencap -p", text=False)
    pos_b = session()["pos"]
    reset = find("Reset zoom")
    if reset:
        tap(reset); time.sleep(1)
    png_c = adb("exec-out", "screencap -p", text=False)
    a, b, c = (row_profile(p, y, 0, width) for p in (png_a, png_b, png_c))
    zoomed, restored = profile_diff(a, b), profile_diff(a, c)
    record(
        "4 double-tap zoom / reset on the real video surface (no seek side effect)",
        zoomed > 25 and restored < 5 and abs(pos_a - pos_b) < 0.2,
        f"meanRowDiff zoomed={zoomed:.1f} afterReset={restored:.1f} "
        f"position {pos_a:.2f}->{pos_b:.2f}s (paused)",
    )


def check_explicit_keys():
    """Bluetooth AVRCP / cars send explicit PLAY and PAUSE keys. A PAUSE while
    already paused must not start playback (spec 4.2: no unwanted resume)."""
    unlock(); open_app()
    ensure("PAUSED")
    media("pause"); time.sleep(2)
    after_pause = session()["state"]
    ensure("PLAYING")
    media("play"); time.sleep(2)
    after_play = session()["state"]
    ensure("PAUSED")
    record(
        "explicit PAUSE/PLAY media keys are idempotent",
        after_pause == "PAUSED" and after_play == "PLAYING",
        f"PAUSE while paused -> {after_pause}; PLAY while playing -> {after_play}",
    )


def check_pip():
    unlock(); open_app()
    select("ump_long")
    ensure("PAUSED")
    scroll_to_top()
    n = find("Picture-in-picture")
    ensure("PLAYING"); time.sleep(2)
    if n is None:
        record("PiP: enter, keep playing, expand back", False, "button not found")
        return
    tap(n); time.sleep(3)
    pinned = "mode=pinned" in sh(f"dumpsys activity activities | grep -A3 {PKG}") or \
        "pinned" in sh("dumpsys window | grep -i 'pinned' | head -3").lower()
    s = session()
    players = started_players()
    open_app(); time.sleep(2)
    back = session()
    full = find("Choose files") is not None
    record(
        "PiP: enter, keep playing, expand back to full UI",
        pinned and s["state"] == "PLAYING" and players == 1 and back["state"] == "PLAYING" and full,
        f"pinned={pinned} inPip={s['state']} startedPlayers={players} expanded={back['state']} fullUi={full}",
    )


def check_battery_saver():
    unlock(); open_app()
    original = sh("settings get global low_power").strip()
    sh("cmd power set-mode 1"); time.sleep(2)
    set_background_setting(True)
    play_from("ump_long")
    start = session()
    lock(); t0 = time.time(); time.sleep(60)
    s = session(); elapsed = time.time() - t0
    unlock()
    sh(f"cmd power set-mode {1 if original == '1' else 0}")
    open_app()
    set_background_setting(False)
    record(
        "18 battery saver + setting on + lock 60 s -> MP4 audio continues",
        s["state"] == "PLAYING" and abs((s["pos"] - start["pos"]) - elapsed) < 4,
        f"state={s['state']} advanced={s['pos'] - start['pos']:.1f}s over {elapsed:.1f}s "
        f"(battery saver restored to {original})",
    )


def check_task_removed():
    unlock(); open_app()
    ensure("PLAYING"); time.sleep(2)
    before = session()["state"]
    stacks = sh("am stack list")
    m = re.search(r"RootTask id=(\d+)[^\n]*\n(?:[^\n]*\n){0,3}?[^\n]*" + re.escape(PKG), stacks)
    if not m:
        m = re.search(r"taskId=(\d+): " + re.escape(PKG), stacks)
    if not m:
        record("19 swipe away from recents stops playback", "NOT RUN", "task id not found")
        return
    sh(f"am stack remove {m.group(1)}"); time.sleep(4)
    s = session()
    players = started_players()
    notif = f"pkg={PKG}" in sh("dumpsys notification --noredact")
    record(
        "19 task removed -> playback stops, notification removed",
        before == "PLAYING" and s["state"] in ("STOPPED", "NONE") and players == 0 and not notif,
        f"before={before} after={s['state']} startedPlayers={players} notificationPresent={notif}",
    )


CHECKS = {
    "lock_off": check_lock_setting_off,
    "home_off": check_home_setting_off,
    "lock_on": check_lock_setting_on_and_controls,
    "notification": check_notification_controls,
    "screen_off_sync": check_screen_off_sync,
    "home_sync": check_home_sync,
    "toggle": check_toggle_off_then_background,
    "mp3_lock": check_mp3_lock,
    "headset": check_headset_button,
    "focus": check_focus_loss,
    "capture": check_capture_frame,
    "zoom": check_double_tap_zoom,
    "pip": check_pip,
    "explicit_keys": check_explicit_keys,
    "battery": check_battery_saver,
    "task_removed": check_task_removed,
}


def main():
    global APP_UID
    APP_UID = re.search(r"appId=(\d+)", sh(f"dumpsys package {PKG}")).group(1)
    model = sh("getprop ro.product.model").strip()
    release = sh("getprop ro.build.version.release").strip()
    print(f"Device: {model}, Android {release}, app uid {APP_UID}", flush=True)
    names = sys.argv[2:] or list(CHECKS)
    for name in names:
        try:
            CHECKS[name]()
        except Exception as e:  # keep going; record the failure
            record(name, False, f"exception: {e!r}")
    print("\nSUMMARY")
    for name, status, _ in RESULTS:
        print(f"  {status:8} {name}")


if __name__ == "__main__":
    main()
