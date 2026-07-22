import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class LoggerService {
  static Future<void> logAction({
    required String title,
    required String detail,
    required String type,
  }) async {
    String islemYapan = "Sistem Yöneticisi";

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        String queryEmail = user.email!.trim().toLowerCase();

        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(queryEmail)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          String name = userDoc['name'] ?? '';
          String surname = userDoc['surname'] ?? '';

          if (name.isNotEmpty || surname.isNotEmpty) {
            islemYapan = "$name $surname".trim();
          }
        } else {
          var query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: queryEmail)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            var data = query.docs.first.data();
            String name = data['name'] ?? '';
            String surname = data['surname'] ?? '';
            if (name.isNotEmpty || surname.isNotEmpty) {
              islemYapan = "$name $surname".trim();
            }
          }
        }
      }
    } catch (e) {
      log("İşlemi yapan kişi çekilemedi: $e");
    }

    String temizDetail = detail
        .replaceFirst("Admin, ", "")
        .replaceFirst("Admin ", "");

    if (temizDetail.isNotEmpty && !temizDetail.startsWith("'")) {
      temizDetail = temizDetail[0].toUpperCase() + temizDetail.substring(1);
    }

    await FirebaseFirestore.instance.collection('logs').add({
      'title': title,
      'detail': temizDetail,
      'action_by': islemYapan,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
