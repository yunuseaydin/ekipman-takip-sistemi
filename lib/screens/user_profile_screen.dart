import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // To access themeNotifier
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  const UserProfileScreen({super.key, required this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _sifreDegistirBottomSheet() {
    _oldPasswordController.clear();
    _passwordController.clear();
    _passwordConfirmController.clear();
    _isPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Şifre Değiştir",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Lütfen güvenliğiniz için mevcut şifrenizi doğrulayın.",
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400),
                  ),
                  const SizedBox(height: 24),
                  
                  // Old Password
                  _buildPasswordFieldModal(
                    controller: _oldPasswordController,
                    label: "Mevcut Şifre",
                    icon: Icons.lock_clock_rounded,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setModalState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // New Password
                  _buildPasswordFieldModal(
                    controller: _passwordController,
                    label: "Yeni Şifre",
                    icon: Icons.lock_outline_rounded,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setModalState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password
                  _buildPasswordFieldModal(
                    controller: _passwordConfirmController,
                    label: "Yeni Şifre (Tekrar)",
                    icon: Icons.lock_reset_rounded,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setModalState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    isConfirm: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : () => _performPasswordChange(setModalState),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Şifreyi Güncelle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _performPasswordChange(StateSetter setModalState) async {
    String oldPass = _oldPasswordController.text.trim();
    String newPass = _passwordController.text.trim();
    String newPassConf = _passwordConfirmController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      _showSnack("Lütfen tüm alanları doldurun.", Colors.red);
      return;
    }
    if (newPass.length < 6) {
      _showSnack("Yeni şifre en az 6 karakter olmalıdır.", Colors.red);
      return;
    }
    if (newPass != newPassConf) {
      _showSnack("Yeni şifreler uyuşmuyor.", Colors.red);
      return;
    }

    setModalState(() => _isLoading = true);
    
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPass,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);
        
        // Şifreyi açık metin olarak Firestore'a kaydet (Admin görebilsin diye)
        await FirebaseFirestore.instance.collection('users').doc(user.email).update({
          'password': newPass,
        });
        
        if (!mounted) return;
        Navigator.pop(context); // Close modal
        _showSnack("Şifreniz başarıyla güncellendi!", Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Bir hata oluştu.";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = "Mevcut şifrenizi yanlış girdiniz.";
      } else {
        msg = e.message ?? msg;
      }
      _showSnack(msg, Colors.red);
    } catch (e) {
      _showSnack("Hata: $e", Colors.red);
    } finally {
      if (mounted) {
        setModalState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?", style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFieldModal({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    bool isConfirm = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.blueGrey.shade300),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isConfirm
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: Colors.blueGrey.shade300,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Bilinmiyor';
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Profil",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userEmail)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String displayFullName = widget.userName;
                  String role = "Personel"; 
                  String p = "";
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    var uData = userSnapshot.data!.data() as Map<String, dynamic>;
                    String n = uData['name'] ?? '';
                    String s = uData['surname'] ?? uData['soyad'] ?? '';
                    p = uData['phone'] ?? uData['telefon'] ?? '';
                    displayFullName = "$n $s".trim();
                    if (displayFullName.isEmpty) displayFullName = widget.userName;
                    
                    if (uData.containsKey('role')) {
                      role = uData['role'] == 'admin' ? 'Yönetici' : 'Personel';
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode 
                          ? [Colors.blueGrey.shade900.withValues(alpha: 0.7), Colors.blueGrey.shade800.withValues(alpha: 0.5)]
                          : [Colors.blueGrey.shade900, Colors.blueGrey.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        if (!isDarkMode)
                          BoxShadow(
                            color: Colors.blueGrey.shade900.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              displayFullName.isNotEmpty ? displayFullName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          displayFullName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blueGrey.shade200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (p.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_rounded, color: Colors.blueGrey.shade300, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                p,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueGrey.shade200,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: role == 'Yönetici' 
                                ? Colors.orange.shade500.withValues(alpha: 0.2)
                                : Colors.teal.shade500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: role == 'Yönetici' 
                                  ? Colors.orange.shade500.withValues(alpha: 0.5)
                                  : Colors.teal.shade500.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                role == 'Yönetici' ? Icons.admin_panel_settings_rounded : Icons.badge_rounded,
                                color: role == 'Yönetici' ? Colors.orange.shade300 : Colors.teal.shade300,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                role,
                                style: TextStyle(
                                  color: role == 'Yönetici' ? Colors.orange.shade100 : Colors.teal.shade100,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
              
              const SizedBox(height: 40),
              
              // Settings Section
              Text(
                "Ayarlar",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings List
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                  boxShadow: [
                    if (!isDarkMode)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    // Dark Mode Toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.dark_mode_rounded, color: Colors.indigo.shade400),
                      ),
                      title: Text(
                        "Karanlık Tema",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.blueGrey.shade900,
                        ),
                      ),
                      trailing: Switch(
                        value: isDarkMode,
                        activeThumbColor: Colors.indigo.shade400,
                        onChanged: (val) {
                          themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                          setState(() {});
                        },
                      ),
                    ),
                    Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.grey.shade100, indent: 24, endIndent: 24),
                    
                    // Change Password
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.lock_outline_rounded, color: Colors.orange.shade600),
                      ),
                      title: Text(
                        "Şifre Değiştir",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.blueGrey.shade900,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.shade300),
                      onTap: _sifreDegistirBottomSheet,
                    ),
                    Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.grey.shade100, indent: 24, endIndent: 24),
                    
                    // Logout
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                      ),
                      title: Text(
                        "Çıkış Yap",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

