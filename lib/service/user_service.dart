import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(uid).get();
    return documentSnapshot.data() as Map<String, dynamic>;
  }

  Future<void> updateProfilePicture(String uid, File imageFile) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('profile_pictures').child(uid);
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'profilePictureUrl': downloadUrl,
      });
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  Future<void> updateUserProfile(String? name, String username) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'username': username,
        });
      } catch (e) {
        print('Update Profile Error: $e');
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> searchUserExactMatch(String username) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error searching for user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchUserPartialMatch(
      String partialUsername) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("users")
          .where("username", isGreaterThanOrEqualTo: partialUsername)
          .where("username", isLessThanOrEqualTo: '$partialUsername\uf8ff')
          .get();

      // Convert the results to a list of maps
      List<Map<String, dynamic>> userList = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return userList;
    } catch (e) {
      print('Error searching for user data: $e');
      // Handle the error, possibly rethrow or return an empty list
      return [];
    }
  }

  Future<String?> getUserIdByUsername(String username) async {
    try {
      // Query Firestore for users with the specified username
      QuerySnapshot querySnapshot = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .limit(1) // Limit the result to one document
          .get();

      // Check if any document exists
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        // Return the user ID
        return documentSnapshot.id;
      } else {
        // Username not found
        print('User with username "$username" not found.');
        return null;
      }
    } catch (e) {
      print('Error getting user ID by username: $e');
      // Handle error
      return null;
    }
  }
}
