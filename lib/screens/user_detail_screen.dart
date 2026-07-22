import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String docId;
  final String fullName;
  final String email;

  const UserDetailScreen({
    super.key,
    required this.docId,
    required this.fullName,
    required this.email,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  void _toggleAdminRole(String fullName, bool currentAdminStatus) {
    String title = currentAdminStatus ? "Yetkiyi Al" : "Admin Yap";
    String content = currentAdminStatus
        ? "$fullName adlı kullanıcının Admin yetkisini almak istediğinize emin misiniz?"
        : "$fullName adlı kullanıcıya Admin yetkisi vermek istediğinize emin misiniz?";

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentAdminStatus ? Colors.orange : Colors.green,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.docId)
                  .update({'role': currentAdminStatus ? 'staff' : 'admin'});

              await LoggerService.logAction(
                title: currentAdminStatus ? "Yetki Alındı" : "Admin Yetkisi Verildi",
                detail: currentAdminStatus
                    ? "Admin, '$fullName' adlı kullanıcının admin yetkisini aldı."
                    : "Admin, '$fullName' adlı kullanıcıya admin yetkisi verdi.",
                type: 'user_role',
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentAdminStatus
                        ? "$fullName artık standart kullanıcı."
                        : "$fullName artık Admin!",
                  ),
                ),
              );
            },
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveUser(String fullName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: Text(
          "$fullName adlı kullanıcıyı sistemden kalıcı olarak çıkarmak istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.docId)
                  .delete();

              await LoggerService.logAction(
                title: "Kullanıcı Silindi",
                detail: "Admin, '$fullName' adlı kullanıcıyı sistemden çıkardı.",
                type: 'user_remove',
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kullanıcı sistemden çıkarıldı.")),
              );
              Navigator.pop(context); // Go back to management screen
            },
            child: const Text("Evet, Çıkar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.blueGrey.shade800 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: isDark ? Colors.blueGrey.shade300 : Colors.blue.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.blueGrey.shade900),
        title: Text(
          "Kullanıcı Detayları",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.blueGrey.shade900,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.docId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Kullanıcı bulunamadı.",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool isAdmin = data['role'] == 'admin';
          String phone = data['phone'] ?? "Telefon yok";
          
          Timestamp? createdAt = data['created_at'];
          String createdDate = "Bilinmiyor";
          if (createdAt != null) {
            DateTime dt = createdAt.toDate();
            createdDate = "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'avatar_${widget.docId}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAdmin ? Colors.orange : Colors.blue).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: isAdmin ? Colors.orange.shade500 : Colors.blue.shade500,
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.fullName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.orange.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAdmin ? "Yönetici" : "Personel",
                    style: TextStyle(
                      color: isAdmin ? Colors.orange.shade600 : Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.email_rounded, "E-posta Adresi", widget.email, isDark),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                      _buildDetailRow(Icons.phone_rounded, "Telefon Numarası", phone, isDark),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                      _buildDetailRow(Icons.calendar_today_rounded, "Kayıt Tarihi", createdDate, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdmin ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      foregroundColor: isAdmin ? Colors.orange.shade600 : Colors.blue.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _toggleAdminRole(widget.fullName, isAdmin),
                    icon: Icon(isAdmin ? Icons.person_remove_alt_1_rounded : Icons.admin_panel_settings_rounded),
                    label: Text(
                      isAdmin ? "Yetkiyi Al (Personel Yap)" : "Yönetici Yap",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _confirmRemoveUser(widget.fullName),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text(
                      "Kullanıcıyı Sistemden Sil",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
