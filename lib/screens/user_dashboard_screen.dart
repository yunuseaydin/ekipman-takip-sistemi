import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import 'my_equipments_screen.dart';
import 'user_equipments_screen.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _name = '';
  late final String _email;
  bool _isLoading = true;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot>? _pendingEquipmentSubscription;

  @override
  void initState() {
    super.initState();
    _email = currentUser?.email ?? '';
    _kullaniciBilgileriniGetir();
    _baslatOnayDinleyici();
  }

  void _baslatOnayDinleyici() {
    if (currentUser?.email == null) return;
    
    _pendingEquipmentSubscription = FirebaseFirestore.instance
        .collection('equipment')
        .where('assigned_email', isEqualTo: currentUser!.email)
        .where('status', isEqualTo: 'onay_bekliyor')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _showOnayPopup(change.doc);
        }
      }
    });
  }

  @override
  void dispose() {
    _pendingEquipmentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _kullaniciBilgileriniGetir() async {
    if (currentUser != null && currentUser!.email != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser!.email)
            .limit(1)
            .get();

        if (!mounted) return;

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            var data = querySnapshot.docs.first.data();
            String n = data['name'] ?? '';
            String s = data['surname'] ?? data['soyad'] ?? '';
            _name = "$n $s".trim();
            if (_name.isEmpty) _name = 'Kullanıcı';
            _isLoading = false;
          });
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();
              
          if (!mounted) return;
          
          if (userDoc.exists) {
            setState(() {
              var data = userDoc.data() as Map<String, dynamic>;
              String n = data['name'] ?? '';
              String s = data['surname'] ?? data['soyad'] ?? '';
              _name = "$n $s".trim();
              if (_name.isEmpty) _name = 'Kullanıcı';
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }



  void _showOnayPopup(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String docId = doc.id;
    String brand = data['brand'] ?? 'Bilinmeyen';
    String model = data['model'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(
                color: Colors.orange.shade700.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Animation Area
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, double val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.touch_app_rounded,
                          size: 64,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  "YENİ CİHAZ ATAMASI",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                    ),
                    children: [
                      const TextSpan(text: "Yönetici tarafından size "),
                      TextSpan(
                        text: "$brand $model",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                        ),
                      ),
                      const TextSpan(text: " cihazı atandı. Cihazı teslim aldığınızı onaylıyor musunuz?"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: isDark ? Colors.red.shade400 : Colors.red.shade600),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('equipment').doc(docId).update({
                            'status': 'Mevcut',
                            'assigned_to': null,
                            'assigned_email': null,
                            'assigned_date': null,
                          });
                          await LoggerService.logAction(
                            title: "Zimmet Reddedildi",
                            detail: "Personel $_name, '$brand $model' cihaz atamasını reddetti.",
                            type: 'eq_reject',
                          );
                          await NotificationService.sendNotification(
                            userEmail: currentUser!.email!,
                            title: "Zimmet Reddedildi",
                            message: "'$brand $model' cihaz atamasını reddettiniz.",
                            type: "info",
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Reddet",
                          style: TextStyle(
                            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                          shadowColor: Colors.orange.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('equipment').doc(docId).update({
                            'status': 'Zimmetli',
                            'assigned_date': FieldValue.serverTimestamp(),
                          });
                          await LoggerService.logAction(
                            title: "Zimmet Onaylandı",
                            detail: "Personel $_name, '$brand $model' cihazını teslim aldığını onayladı.",
                            type: 'eq_accept',
                          );
                          await NotificationService.sendNotification(
                            userEmail: currentUser!.email!,
                            title: "Zimmet Onaylandı",
                            message: "'$brand $model' cihazını başarıyla teslim aldınız.",
                            type: "success",
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green.shade600,
                              content: const Text("Cihaz başarıyla üzerinize zimmetlendi!"),
                            ),
                          );
                        },
                        child: const Text(
                          "Onayla",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _buildDashboardView(isDark),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(
              "PERSONEL",
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 24, 
                color: isDark ? Colors.white : Colors.blueGrey.shade900
              ),
            ),
          ),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('user_email', isEqualTo: _email)
                    .where('is_read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }
                  
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade200, 
                          width: 2
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded, 
                            color: isDark ? Colors.white : Colors.blueGrey.shade800, 
                            size: 24
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 9 ? "9+" : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userName: _name),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade200, 
                      width: 2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.person_outline_rounded, 
                    color: isDark ? Colors.white : Colors.blueGrey.shade800, 
                    size: 24
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(bool isDark) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildHeader(context, isDark),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              // İki Kart: Üzerimdeki Ekipmanlar ve Tüm Ekipman Durumları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallActionCard(
                        title: "Üzerime\nZimmetli",
                        icon: Icons.inventory_rounded,
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade700, Colors.orange.shade400],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyEquipmentsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSmallActionCard(
                        title: "Ekipman\nDurumları",
                        icon: Icons.manage_search_rounded,
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.teal.shade400],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserEquipmentsScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Son Bildirimler Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Son Etkinlikler",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.blueGrey.shade100 : Colors.blueGrey.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                      child: const Text("Tümünü Gör", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
              // Son Bildirimler Listesi
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('user_email', isEqualTo: _email)
                      .orderBy('timestamp', descending: true)
                      .limit(5)
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
                            Icon(Icons.notifications_none_rounded, size: 48, color: Colors.blueGrey.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text("Yeni bildirim yok.", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          elevation: isRead ? 0 : 1,
                          color: isRead 
                              ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isRead ? Colors.transparent : iconColor.withValues(alpha: 0.3),
                            )
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 20),
                            ),
                            title: Text(
                              title, 
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600, fontSize: 12, height: 1.2)),
                                const SizedBox(height: 4),
                                Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400)),
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
              ),
            ],
          );
  }

  Widget _buildSmallActionCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
