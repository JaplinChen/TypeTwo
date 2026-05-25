part of 'glossary_tab.dart';

class _GlossarySyncPanel extends StatelessWidget {
  const _GlossarySyncPanel({
    required this.s,
    required this.syncUrlCtrl,
    required this.syncEmailCtrl,
    required this.syncPasswordCtrl,
    required this.isSyncing,
    required this.isLoggingIn,
    required this.isLoggedIn,
    required this.role,
    required this.canReview,
    required this.canManageUsers,
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.onUrlChanged,
    required this.onEmailChanged,
    required this.onLogin,
    required this.onLogout,
    required this.onSync,
    required this.onReview,
    required this.onManageUsers,
  });

  final AppStrings s;
  final TextEditingController syncUrlCtrl;
  final TextEditingController syncEmailCtrl;
  final TextEditingController syncPasswordCtrl;
  final bool isSyncing;
  final bool isLoggingIn;
  final bool isLoggedIn;
  final String role;
  final bool canReview;
  final bool canManageUsers;
  final String? lastSyncedAt;
  final int pendingCount;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onSync;
  final VoidCallback onReview;
  final VoidCallback onManageUsers;

  @override
  Widget build(BuildContext context) {
    final baseStatus = lastSyncedAt == null
        ? s.glossaryNeverSynced
        : s.glossaryLastSynced(lastSyncedAt!);
    final status = pendingCount > 0
        ? '$baseStatus · ${s.glossaryPendingCount(pendingCount)}'
        : baseStatus;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Row(
        children: [
          const Icon(Icons.cloud_sync_outlined, size: 18),
          const SizedBox(width: 8),
          Text(s.glossaryCloudSync),
          const SizedBox(width: 8),
          Icon(
            isLoggedIn ? Icons.verified_user_outlined : Icons.lock_outline,
            size: 16,
            color: isLoggedIn ? Colors.green : Colors.grey,
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(s.glossaryPendingCount(pendingCount)),
            ),
          ],
          if (isLoggedIn && role.isNotEmpty) ...[
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(s.glossaryRole(role)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 820;
            final urlField = TextField(
              key: const ValueKey('glossarySyncUrlField'),
              controller: syncUrlCtrl,
              decoration: InputDecoration(
                labelText: s.glossarySyncUrl,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onUrlChanged,
            );
            final emailField = TextField(
              key: const ValueKey('glossarySyncEmailField'),
              controller: syncEmailCtrl,
              decoration: InputDecoration(
                labelText: s.glossarySyncEmail,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onEmailChanged,
            );
            final passwordField = TextField(
              key: const ValueKey('glossarySyncPasswordField'),
              controller: syncPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: s.glossarySyncPassword,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onLogin(),
            );
            final loginButton = OutlinedButton.icon(
              onPressed: isLoggingIn ? null : (isLoggedIn ? onLogout : onLogin),
              icon: isLoggingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isLoggedIn ? Icons.logout : Icons.login, size: 16),
              label: Text(isLoggedIn ? s.glossaryLogout : s.glossaryLogin),
            );
            final syncButton = FilledButton.icon(
              onPressed: isSyncing ? null : onSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(s.glossarySync),
            );
            final reviewButton = OutlinedButton.icon(
              onPressed: canReview ? onReview : null,
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: Text(s.glossaryReviewPending),
            );
            final usersButton = OutlinedButton.icon(
              onPressed: canManageUsers ? onManageUsers : null,
              icon: const Icon(Icons.group_outlined, size: 16),
              label: Text(s.glossaryManageUsers),
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  urlField,
                  const SizedBox(height: 8),
                  emailField,
                  const SizedBox(height: 8),
                  passwordField,
                  const SizedBox(height: 8),
                  Row(children: [
                    loginButton,
                    const SizedBox(width: 8),
                    syncButton,
                    if (canReview) ...[
                      const SizedBox(width: 8),
                      reviewButton,
                    ],
                    if (canManageUsers) ...[
                      const SizedBox(width: 8),
                      usersButton,
                    ],
                  ]),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 2, child: urlField),
                const SizedBox(width: 8),
                Expanded(child: emailField),
                const SizedBox(width: 8),
                Expanded(child: passwordField),
                const SizedBox(width: 8),
                loginButton,
                const SizedBox(width: 8),
                syncButton,
                if (canReview) ...[
                  const SizedBox(width: 8),
                  reviewButton,
                ],
                if (canManageUsers) ...[
                  const SizedBox(width: 8),
                  usersButton,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
