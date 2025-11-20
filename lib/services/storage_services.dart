import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageServices {
  // Imagine this as your library's security gate.
  // It checks who's entering, identifies them,
  // and only lets valid visitors roam the halls.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This is your master key to the shelves.
  // The databaseURL is the location of your “branch.”
  // The ref() at the end acts like saying:
  // "Bring me to the root hallway where all the shelves begin."
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://attendance-app-1631a-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  //upload photo to firebase reealtime databaase Base64 (String)
  Future<String> uploadAttendancePhoto(
    String localPath,
    String photoType,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authentificated');

      final file = File(localPath);

      //function untuk compressing photo
      final compressBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 70,
      );

      if (compressBytes == null) {
        throw Exception('Failed to compress Image');
      }

      // convert to Base64
      final base64Image = base64Encode(compressBytes);

      // create unique ID for each pic
      final photoKey = '${DateTime.now().millisecondsSinceEpoch}_$photoType';

      //function to save to database
      await _database
          .child('attendance_photos')
          .child(user.uid)
          .child(photoKey)
          .set({
            'data': base64Image,
            'timestamp': ServerValue.timestamp,
            'type': photoType,
          });

      //return the key as refference
      return photoKey;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // get photo from firebase realtime database
  Future<String?> getPhotoBase64(String photoKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final snapshot = await _database
          .child('attendance_photos')
          .child(user.uid)
          .child(photoKey)
          .child('data')
          .get();

      if (snapshot.exists) {
        return snapshot.value as String;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  //delete photo from firebase realtime database
  Future<void> deletePhoto(String photoKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      await _database
          .child('attendance_photos')
          .child(user.uid)
          .child(photoKey)
          .remove();
    } catch (e) {}
  }
}
