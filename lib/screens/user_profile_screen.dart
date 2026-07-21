import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  const UserProfileScreen({super.key, required this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _sifreDegistir() async {
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifre en az 6 karakter olmalıdır."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifreler uyuşmuyor."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.currentUser
          ?.updatePassword(_passwordController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifreniz başarıyla güncellendi!"),
          backgroundColor: Colors.green,
        ),
      );
      _passwordController.clear();
      _passwordConfirmController.clear();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Güvenlik nedeniyle şifre değiştirmek için çıkış yapıp tekrar giriş yapmanız gerekmektedir.",
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bilinmeyen Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getIconStyleForAction(String type) {
    switch (type) {
      case 'eq_assign':
        return {'icon': Icons.assignment_ind_rounded, 'color': Colors.teal};
      case 'eq_return':
        return {
          'icon': Icons.assignment_returned_rounded,
          'color': Colors.purple,
        };
      default:
        return {'icon': Icons.history_rounded, 'color': Colors.blueGrey};
    }
  }

  @override
  Widget build(BuildContext context) {
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Bilinmiyor';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        appBar: AppBar(
          title: const Text(
            "Profilim",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey.shade900,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.tealAccent,
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: "Profil Bilgileri"),
              Tab(icon: Icon(Icons.history_rounded), text: "İşlem Geçmişim"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Profil ve Şifre
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userEmail)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        String displayFullName = widget.userName;
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var uData = userSnapshot.data!.data() as Map<String, dynamic>;
                          String n = uData['name'] ?? '';
                          String s = uData['surname'] ?? uData['soyad'] ?? '';
                          displayFullName = "$n $s".trim();
                          if (displayFullName.isEmpty) displayFullName = widget.userName;
                        }

                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blueGrey.shade700,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayFullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Personel (Staff)",
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Şifre Değiştir",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Yeni Şifre",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordConfirmController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Yeni Şifre (Tekrar)",
                            prefixIcon: const Icon(Icons.lock_reset),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _sifreDegistir,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Şifreyi Güncelle",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // TAB 2: İşlem Geçmişim
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userEmail)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String searchName = widget.userName.toLowerCase();
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  var uData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String n = uData['name'] ?? '';
                  String s = uData['surname'] ?? uData['soyad'] ?? '';
                  searchName = "$n $s".trim().toLowerCase();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('logs')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Geçmiş işlem bulunamadı.",
                          style: TextStyle(color: Colors.blueGrey.shade400),
                        ),
                      );
                    }

                    // Kullanıcının adına göre logları filtrele
                    var logs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String detail = (data['detail'] ?? '').toString().toLowerCase();
                      
                      if (searchName == 'kullanıcı' || searchName.isEmpty) return false;
                      
                      // İsmin log detayı içinde tam olarak geçip geçmediğini kontrol et.
                      return detail.contains(searchName);
                    }).toList();

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      "Size ait herhangi bir işlem bulunmuyor.",
                      style: TextStyle(color: Colors.blueGrey.shade400),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var data = logs[index].data() as Map<String, dynamic>;

                    String title = data['title'] ?? 'Bilinmeyen İşlem';
                    String detail = data['detail'] ?? 'Detay yok.';
                    String type = data['type'] ?? 'unknown';
                    String actionBy = data['action_by'] ?? 'Bilinmeyen Yönetici';

                    var style = _getIconStyleForAction(type);
                    Color iconColor = style['color'];
                    IconData iconData = style['icon'];

                    String timeString = "";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      timeString =
                          "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: iconColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, thickness: 1),
                            ),
                            Text(
                              detail,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.blueGrey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      "İşlemi Yapan: $actionBy",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (timeString.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 14, color: Colors.blueGrey.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
