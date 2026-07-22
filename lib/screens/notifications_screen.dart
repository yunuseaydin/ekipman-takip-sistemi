import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser?.email == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Bildirimler")),
        body: const Center(child: Text("Hata: Kullanıcı bilgisi bulunamadı.")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Bildirimler",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await NotificationService.clearAllNotifications(currentUser!.email!);
            },
            icon: const Icon(Icons.clear_all_rounded, color: Colors.redAccent),
            label: const Text("Tümünü Temizle", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_email', isEqualTo: currentUser!.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text("Henüz bir bildiriminiz yok.", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String title = data['title'] ?? '';
              String message = data['message'] ?? '';
              String type = data['type'] ?? 'info';
              bool isRead = data['is_read'] ?? false;
              Timestamp? ts = data['timestamp'];
              
              String timeStr = "";
              if (ts != null) {
                DateTime d = ts.toDate();
                timeStr = "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
              }
              
              Color iconColor = Colors.blue;
              IconData icon = Icons.info_outline_rounded;
              if (type == 'success') {
                iconColor = Colors.green;
                icon = Icons.check_circle_outline_rounded;
              } else if (type == 'warning') {
                iconColor = Colors.orange;
                icon = Icons.warning_amber_rounded;
              }

              return Card(
                elevation: isRead ? 0 : 2,
                color: isRead 
                    ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isRead ? Colors.transparent : iconColor.withValues(alpha: 0.3),
                  )
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(
                    title, 
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    )
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(message, style: TextStyle(color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600, height: 1.3)),
                      const SizedBox(height: 8),
                      Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      NotificationService.markAsRead(doc.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
