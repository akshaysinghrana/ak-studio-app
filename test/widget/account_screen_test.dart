import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/app/providers.dart';
import 'package:video_music_app/app/theme/brand_widgets.dart';
import 'package:video_music_app/features/account/data/auth_repository.dart';
import 'package:video_music_app/features/account/presentation/account_screen.dart';
import 'package:video_music_app/features/account/presentation/google_button.dart';
import 'package:video_music_app/features/playlists/data/playlist_repository.dart';
import 'package:video_music_app/features/sync/data/remote_store.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../support/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  Future<void> pump(
    WidgetTester tester,
    AuthRepository auth, {
    RemoteStore? remote,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(auth),
          remoteStoreProvider.overrideWithValue(remote),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('unconfigured build says so and offers no sign-in', (t) async {
    await pump(t, const UnconfiguredAuthRepository());
    expect(find.text('Accounts are not set up in this build.'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    await unmount(t);
  });

  testWidgets('validates input and shows friendly errors', (t) async {
    await pump(t, FakeAuthRepository(), remote: InMemoryRemoteStore());
    await t.tap(find.widgetWithText(GradientButton, 'Sign in'));
    await t.pump();
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.co');
    await t.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong12',
    );
    await t.tap(find.widgetWithText(GradientButton, 'Sign in'));
    await settle(t);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('asks before attaching guest playlists, then shows profile', (
    t,
  ) async {
    await t.runAsync(() => PlaylistRepository(db).create('Guest list'));
    final remote = InMemoryRemoteStore();
    await pump(t, FakeAuthRepository(), remote: remote);
    await t.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.co');
    await t.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await t.tap(find.widgetWithText(GradientButton, 'Sign in'));
    await settle(t);

    expect(find.text('Sync playlists from this device?'), findsOneWidget);
    await t.tap(find.text('Keep on this device'));
    await settle(t);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Sync is on'), findsOneWidget);
    // Declined: the guest playlist was not uploaded.
    expect(remote.data['uid-1']?['playlists'] ?? const {}, isEmpty);
    await unmount(t);
  });

  testWidgets('Google sign-in offers sync, then shows the Google profile', (
    t,
  ) async {
    await t.runAsync(() => PlaylistRepository(db).create('Guest list'));
    final remote = InMemoryRemoteStore();
    await pump(t, FakeAuthRepository(), remote: remote);
    await t.ensureVisible(find.byType(GoogleSignInButton));
    await t.pump();
    await t.tap(find.byType(GoogleSignInButton));
    await settle(t);

    expect(find.text('Sync playlists from this device?'), findsOneWidget);
    await t.tap(find.text('Add to account'));
    await settle(t);
    expect(find.text('Google User'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(remote.data['uid-g']?['playlists'], isNotEmpty);
    await unmount(t);
  });

  testWidgets('closing the Google picker is not shown as an error', (t) async {
    await pump(
      t,
      FakeAuthRepository(googleCancels: true),
      remote: InMemoryRemoteStore(),
    );
    await t.ensureVisible(find.byType(GoogleSignInButton));
    await t.pump();
    await t.tap(find.byType(GoogleSignInButton));
    await settle(t);
    expect(find.text('Google sign-in was cancelled.'), findsNothing);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    await unmount(t);
  });
}
