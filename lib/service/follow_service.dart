import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/follow.dart';

class FollowService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser(String followingId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final follow = Follow(
        followerId: user.uid,
        followingId: followingId,
        timestamp: Timestamp.now(),
      );

      await _firestore.collection('follows').add(follow.toMap());

      await _updateFollowCount(user.uid, followingId, increment: true);
    }
  }

  Future<void> unfollowUser(String followingId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final followQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: user.uid)
          .where('followingId', isEqualTo: followingId)
          .get();

      for (var doc in followQuery.docs) {
        await doc.reference.delete();
      }

      await _updateFollowCount(user.uid, followingId, increment: false);
    }
  }

  Future<bool> isFollowing(String userId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final followQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: user.uid)
          .where('followingId', isEqualTo: userId)
          .get();

      return followQuery.docs.isNotEmpty;
    }
    return false;
  }

  Future<List<String>> getFollowingList(String userId, bool me) async {
    if (me) {
      return [];
    }

    final followingQuery = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .get();

    final followingList = followingQuery.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toList();

    return followingList;
  }

  Future<void> _updateFollowCount(String followerId, String followingId,
      {required bool increment}) async {
    // Windows에서 프로세스가 왜 죽음?
    /*final followerRef = _firestore.collection('users').doc(followerId);
    final followingRef = _firestore.collection('users').doc(followingId);

    await _firestore.runTransaction((transaction) async {
      final followerDoc = await transaction.get(followerRef);
      final followingDoc = await transaction.get(followingRef);

      if (followerDoc.exists && followingDoc.exists) {
        final followerData = followerDoc.data()!;
        final followingData = followingDoc.data()!;

        final newFollowingCount = increment
            ? (followerData['followingCount'] as int) + 1
            : (followerData['followingCount'] as int) - 1;

        final newFollowerCount = increment
            ? (followingData['followerCount'] as int) + 1
            : (followingData['followerCount'] as int) - 1;

        transaction.update(followerRef, {'followingCount': newFollowingCount});
        transaction.update(followingRef, {'followerCount': newFollowerCount});
      }
    });*/

    final followerRef = _firestore.collection('users').doc(followerId);
    final followingRef = _firestore.collection('users').doc(followingId);

    final incrementValue = increment ? 1 : -1;

    await followerRef.update({
      'followingCount': FieldValue.increment(incrementValue),
    });

    await followingRef.update({
      'followerCount': FieldValue.increment(incrementValue),
    });
  }
}
