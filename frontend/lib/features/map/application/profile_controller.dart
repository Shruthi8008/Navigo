import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_community_service.dart';
import '../domain/community_comment.dart';
import '../../../providers/auth_provider.dart';

final myCommentsProvider = FutureProvider.autoDispose<List<CommunityComment>>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    return [];
  }

  final service = ref.read(mapCommunityServiceProvider);
  final comments = await service.getMyComments(session: session);
  return comments;
});

final myFavoritesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    return [];
  }

  final service = ref.read(mapCommunityServiceProvider);
  return await service.getMyFavorites(session: session);
});

class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  Future<void> removeFavorite(int id) async {
    final session = _ref.read(authProvider).valueOrNull;
    if (session == null) return;

    final service = _ref.read(mapCommunityServiceProvider);
    await service.removeFavoriteById(session: session, id: id);
    _ref.invalidate(myFavoritesProvider);
  }

  Future<void> deleteComment(int commentId) async {
    final session = _ref.read(authProvider).valueOrNull;
    if (session == null) return;

    final service = _ref.read(mapCommunityServiceProvider);
    await service.deleteComment(session: session, commentId: commentId);
    _ref.invalidate(myCommentsProvider);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});