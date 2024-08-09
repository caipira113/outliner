import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Map<String, dynamic>>> uploadMedia(List<File> mediaFiles) async {
    List<Map<String, dynamic>> mediaInfo = [];
    if (mediaFiles.isNotEmpty) {
      final storageRef = _storage.ref().child('post_media');
      for (var file in mediaFiles) {
        final fileRef = storageRef.child(
            '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
        await fileRef.putFile(file);
        final downloadUrl = await fileRef.getDownloadURL();
        final metaData = await fileRef.getMetadata();
        final mimeType = metaData.contentType;

        mediaInfo.add({
          'url': downloadUrl,
          'type': mimeType,
        });
      }
    }
    return mediaInfo;
  }

  Future<void> createPost({
    required String content,
    required List<File> mediaFiles,
    String? cw,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final mediaInfo = await uploadMedia(mediaFiles);

    final post = {
      'userId': user.uid,
      'cw': cw,
      'content': content,
      'mediaInfo': mediaInfo,
      'timestamp': Timestamp.now(),
    };

    await _firestore.collection('posts').add(post);
  }
}
