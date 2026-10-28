import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../sync/application/sync_service.dart';
import '../application/account_controller.dart';
import '../data/auth_repository.dart';
import 'google_button.dart';

/// Account and sync (spec 4.6, 9): the app's own sign-in screens over
/// Firebase Auth, with email/password and Google. Everything else works
/// without an account; this screen never pretends sign-in works when the
/// backend is not configured.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final user = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: !auth.isConfigured
          ? const _NotConfigured()
          : user.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (u) => u == null ? const _SignInForm() : _Profile(user: u),
            ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      children: [
        const Center(child: AppLogo(size: 72)),
        const SizedBox(height: 20),
        Text(
          'Accounts are not set up in this build.',
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You are using AS Media as a guest. Your library, playlists, '
          'favourites and settings are saved on this phone and work offline. '
          'Sign-in and sync become available once the app is connected to '
          'its account service.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _Mode { signIn, register }

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _googleBusy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await _run(
      (auth) => _mode == _Mode.signIn
          ? auth.signIn(_email.text, _password.text)
          : auth.register(_email.text, _password.text),
      setBusy: (v) => _busy = v,
    );
  }

  Future<void> _google() =>
      _run((auth) => auth.signInWithGoogle(), setBusy: (v) => _googleBusy = v);

  /// Signs in, then offers sync. Signing in replaces this form with the
  /// profile, so the follow-up captures what it needs while still mounted.
  Future<void> _run(
    Future<AppUser> Function(AuthRepository auth) signIn, {
    required void Function(bool) setBusy,
  }) async {
    setState(() {
      setBusy(true);
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final sync = ref.read(syncServiceProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final navigator = Navigator.of(context);
    try {
      await signIn(auth);
      await _offerSync(sync, controller, navigator);
    } on AuthFailure catch (e) {
      // Closing Google's account picker is not an error.
      if (mounted && !e.isCancelled) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => setBusy(false));
    }
  }

  /// Asks before attaching guest playlists to the account (spec 9.2).
  static Future<void> _offerSync(
    SyncService? sync,
    SyncController controller,
    NavigatorState navigator,
  ) async {
    if (sync == null) return;
    final local = await sync.unattachedPlaylistCount();
    var attach = false;
    if (local > 0 && navigator.mounted) {
      attach =
          await showDialog<bool>(
            context: navigator.context,
            builder: (context) => AlertDialog(
              title: const Text('Sync playlists from this device?'),
              content: Text(
                'Add your $local playlist(s) on this device to this account? '
                'Only playlist names and anonymous file fingerprints are '
                'synced. Your media files are never uploaded.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep on this device'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add to account'),
                ),
              ],
            ),
          ) ??
          false;
    }
    await controller.enableAndSync(attachLocalPlaylists: attach);
  }

  Future<void> _resetPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    if (AuthValidation.email(_email.text) != null) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link is on its way.',
          ),
        ),
      );
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signIn = _mode == _Mode.signIn;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final anyBusy = _busy || _googleBusy;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Center(child: AppLogo(size: 72)),
          const SizedBox(height: 16),
          Center(
            child: GradientText(
              signIn ? 'Welcome back' : 'Create your account',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sync playlists, favourites and settings across your devices.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Mode>(
                  segments: const [
                    ButtonSegment(value: _Mode.signIn, label: Text('Sign in')),
                    ButtonSegment(
                      value: _Mode.register,
                      label: Text('Create account'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.single;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: AuthValidation.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  autofillHints: [
                    signIn ? AutofillHints.password : AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  validator: AuthValidation.password,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: scheme.error)),
                  ),
                ],
                const SizedBox(height: 18),
                _busy
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        label: signIn ? 'Sign in' : 'Create account',
                        icon: signIn
                            ? Icons.login_rounded
                            : Icons.person_add_rounded,
                        onPressed: anyBusy ? null : _submit,
                      ),
                if (signIn)
                  TextButton(
                    onPressed: anyBusy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  busy: _googleBusy,
                  onPressed: anyBusy ? null : _google,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'An account is optional. Your media files always stay on your '
            'phone.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final meta = ref.watch(syncMetadataProvider).value;
    final enabled = ref.watch(syncEnabledProvider).value ?? false;
    final last = meta?.lastSyncAt;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = user.displayName ?? user.email?.split('@').first ?? 'You';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _Avatar(user: user, name: name),
              const SizedBox(height: 12),
              Text(name, style: text.titleLarge),
              if (user.email != null)
                Text(
                  user.email!,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 10),
              Chip(
                avatar: user.usesGoogle
                    ? const GoogleLogo(size: 16)
                    : const Icon(Icons.mail_rounded, size: 16),
                label: Text(
                  user.usesGoogle
                      ? 'Signed in with Google'
                      : 'Signed in with email',
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Sync', padding: EdgeInsets.fromLTRB(4, 20, 4, 8)),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                leading: IconBadge(
                  icon: enabled
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  colors: enabled ? AppColors.accents[3] : AppColors.accents[4],
                ),
                title: Text(
                  enabled ? 'Sync is on' : 'Sync is off on this device',
                ),
                subtitle: Text(
                  sync.status == SyncStatus.syncing
                      ? 'Syncing…'
                      : sync.message ??
                            (meta?.lastError != null
                                ? 'Last sync failed. Your data on this device is unchanged.'
                                : last != null
                                ? 'Last synced ${MaterialLocalizations.of(context).formatShortDate(last)} '
                                      '${TimeOfDay.fromDateTime(last).format(context)}'
                                : 'Not synced yet'),
                ),
                trailing: enabled
                    ? TextButton(
                        onPressed: sync.status == SyncStatus.syncing
                            ? null
                            : () => ref
                                  .read(syncControllerProvider.notifier)
                                  .syncNow(),
                        child: const Text('Sync now'),
                      )
                    : TextButton(
                        onPressed: () => ref
                            .read(syncControllerProvider.notifier)
                            .enableAndSync(attachLocalPlaylists: false),
                        child: const Text('Turn on'),
                      ),
              ),
              const Divider(indent: 68),
              const ListTile(
                dense: true,
                title: Text(
                  'Synced: playlists added to this account, favourites and app '
                  'settings. Never synced: media files, file names, paths, '
                  'thumbnails or listening history.',
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          'Account',
          padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
        ),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                leading: IconBadge(
                  icon: Icons.logout_rounded,
                  colors: AppColors.accents[1],
                ),
                title: const Text('Sign out'),
                onTap: () => _signOut(context, ref),
              ),
              const Divider(indent: 68),
              ListTile(
                leading: IconBadge(
                  icon: Icons.delete_forever_rounded,
                  colors: AppColors.accents[4],
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: const Text(
                  'Deletes the account and its synced data. Files on this phone '
                  'are not affected.',
                ),
                onTap: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your playlists and favourites stay on this phone by default. You '
          'can also remove this account\'s playlists from this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out and remove'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (remove == null) return;
    await ref
        .read(syncControllerProvider.notifier)
        .signOut(removeAccountData: remove);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final password = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final askPassword = user.usesPassword && !user.usesGoogle;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This permanently deletes your account and the playlists, '
              'favourites and settings synced to it. '
              '${askPassword ? 'Enter your password to confirm.' : 'You will confirm with Google.'}',
            ),
            if (askPassword)
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final text = password.text;
    password.dispose();
    if (ok != true) return;
    try {
      await ref
          .read(syncControllerProvider.notifier)
          .deleteAccount(password: askPassword ? text : null);
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
    } on AuthFailure catch (e) {
      if (!e.isCancelled) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.name});

  final AppUser user;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final fallback = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brand,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return SizedBox.square(
      dimension: 84,
      child: ClipOval(
        child: user.photoUrl == null
            ? fallback
            : Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                semanticLabel: 'Profile photo',
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
