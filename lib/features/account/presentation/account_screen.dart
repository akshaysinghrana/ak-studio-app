import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../application/account_controller.dart';
import '../../sync/application/sync_service.dart';
import '../data/auth_repository.dart';

/// Account and sync (spec 4.6, 9). Everything else in the app works without
/// an account; this screen never pretends sign-in works when it does not.
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
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppTokens.spaceL),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_off_outlined, size: 48),
        SizedBox(height: AppTokens.spaceM),
        Text(
          'Accounts are not set up in this build.',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: AppTokens.spaceS),
        Text(
          'You are using the app as a guest. Your library, playlists, '
          'favourites and settings are saved on this device and work '
          'offline. Sign-in and sync become available once the app is '
          'connected to an account service.',
        ),
      ],
    ),
  );
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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    // Signing in replaces this form with the profile, so capture what the
    // follow-up needs while still mounted.
    final sync = ref.read(syncServiceProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final navigator = Navigator.of(context);
    try {
      if (_mode == _Mode.signIn) {
        await auth.signIn(_email.text, _password.text);
      } else {
        await auth.register(_email.text, _password.text);
      }
      await _offerSync(sync, controller, navigator);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.spaceL),
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
          const SizedBox(height: AppTokens.spaceL),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: AuthValidation.email,
          ),
          const SizedBox(height: AppTokens.spaceM),
          TextFormField(
            controller: _password,
            obscureText: true,
            autofillHints: [
              signIn ? AutofillHints.password : AutofillHints.newPassword,
            ],
            decoration: const InputDecoration(labelText: 'Password'),
            validator: AuthValidation.password,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.spaceM),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceL),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(signIn ? 'Sign in' : 'Create account'),
          ),
          if (signIn)
            TextButton(
              onPressed: _busy ? null : _resetPassword,
              child: const Text('Forgot password?'),
            ),
          const SizedBox(height: AppTokens.spaceM),
          const Text(
            'An account is optional. It syncs playlists, favourites and '
            'settings. Media files always stay on your device.',
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
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user.email ?? 'Signed in'),
          subtitle: const Text('Signed in'),
        ),
        const Divider(),
        ListTile(
          leading: Icon(enabled ? Icons.cloud_done_outlined : Icons.cloud_off),
          title: Text(enabled ? 'Sync is on' : 'Sync is off on this device'),
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
                      : () =>
                            ref.read(syncControllerProvider.notifier).syncNow(),
                  child: const Text('Sync now'),
                )
              : TextButton(
                  onPressed: () => ref
                      .read(syncControllerProvider.notifier)
                      .enableAndSync(attachLocalPlaylists: false),
                  child: const Text('Turn on'),
                ),
        ),
        const ListTile(
          dense: true,
          title: Text(
            'Synced: playlists added to this account, favourites and app '
            'settings. Not synced: media files, file names, paths, '
            'thumbnails or listening history.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => _signOut(context, ref),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('Delete account'),
          subtitle: const Text(
            'Deletes the account and its synced data. Files on this device '
            'are not affected.',
          ),
          onTap: () => _delete(context, ref),
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
          'Your playlists and favourites stay on this device by default. '
          'You can also remove this account\'s playlists from this device.',
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your account and the playlists, '
              'favourites and settings synced to it. Enter your password '
              'to confirm.',
            ),
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
      await ref.read(syncControllerProvider.notifier).deleteAccount(text);
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
