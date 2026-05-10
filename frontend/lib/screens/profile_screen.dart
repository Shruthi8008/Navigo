import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/map/application/profile_controller.dart';
import '../features/map/data/map_community_service.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return SafeArea(
      child: authState.when(
        data: (session) {
          if (session == null) {
            return _SignedOutProfile(
              onLoginTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AuthScreen(initialMode: AuthMode.login),
                  ),
                );
              },
              onSignupTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AuthScreen(initialMode: AuthMode.signup),
                  ),
                );
              },
            );
          }

          return _SignedInProfile(
            session: session,
            onLogout: () => ref.read(authProvider.notifier).logout(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile({
    required this.onLoginTap,
    required this.onSignupTap,
  });

  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 34,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "You haven't logged in",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to view your profile, or create an account to save your safety experience.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onLoginTap,
              child: const Text('Login'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onSignupTap,
              child: const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.session, required this.onLogout});

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = session.user;

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 160,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _initialsFor(user.fullName),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            user.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: const Text('My Comments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _MyCommentsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favorite Places'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _MyFavoritesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Log Out'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MyCommentsScreen extends ConsumerWidget {
  const _MyCommentsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(myCommentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Comments'),
      ),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load comments',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(myCommentsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (comments) {
          if (comments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your safety comments will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myCommentsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                comment.targetType == 'place' ? 'Place' : 'Route',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(comment.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        if (comment.placeName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            comment.placeName!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (comment.address != null)
                            Text(
                              comment.address!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                        const SizedBox(height: 8),
                        Text(comment.comment),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MyFavoritesScreen extends ConsumerWidget {
  const _MyFavoritesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(myFavoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Places'),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load favorites',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(myFavoritesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save places to find them quickly later',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myFavoritesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.place,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      favorite['placeName'] as String? ?? 'Unknown Place',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      favorite['address'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () async {
                        final session = ref.read(authProvider).valueOrNull;
                        if (session == null) return;

                        final id = favorite['id'] as int;
                        await ref.read(mapCommunityServiceProvider).removeFavoriteById(
                          session: session,
                          id: id,
                        );
                        ref.invalidate(myFavoritesProvider);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}