import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String userEmail,
    required String title,
    required String message,
    String type = 'info', // info, success, warning
  }) async {
    if (userEmail.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'user_email': userEmail.trim().toLowerCase(),
        'title': title,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });
    } catch (e) {
      print("Bildirim gönderilirken hata: $e");
    }
  }

  static Future<void> markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
        'is_read': true,
      });
    } catch (e) {
      print("Bildirim okunuldu işaretlenirken hata: $e");
    }
  }

  static Future<void> clearAllNotifications(String userEmail) async {
    if (userEmail.isEmpty) return;
    
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_email', isEqualTo: userEmail.trim().toLowerCase())
          .get();
          
      // Batch delete for efficiency
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Bildirimler temizlenirken hata: $e");
    }
  }
}
