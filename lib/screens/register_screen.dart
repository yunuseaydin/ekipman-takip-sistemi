import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _kayitOl() async {
    if (_nameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String userEmail = _emailController.text.trim().toLowerCase();
      String password = _passwordController.text.trim();

      // 1. Firebase Auth Kullanıcı Oluşturma
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: userEmail,
        password: password,
      );

      // 2. Doğrulama Maili Gönder
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
      }

      // 3. Firestore'a Kaydet (emailVerified: false ile)
      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'search_name': _nameController.text.trim().toLowerCase(),
        'email': userEmail,
        'phone': _phoneController.text.trim(),
        'password': password,
        'role': 'staff',
        'emailVerified': false, // Admin paneli için onay bekleniyor statüsü
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Çıkış yap (kullanıcı önce e-postasını onaylamalı)
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 5. Başarı Mesajı ve Yönlendirme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade700, // Turuncu kurumsal kimlik
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kayıt Başarılı!\nOnay linki e-postanıza gönderildi. Lütfen e-postanızı kontrol edin.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Login ekranına geri dön
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMsg = "Kayıt olurken bir hata oluştu.";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Bu e-posta adresi zaten kullanımda!";
      } else if (e.code == 'weak-password') {
        errorMsg = "Şifre çok zayıf. En az 6 karakter girin.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(errorMsg),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.blueGrey.withValues(alpha: 0.15) : Colors.blueGrey.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.blueGrey.withValues(alpha: 0.15) : Colors.blueGrey.withValues(alpha: 0.2),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.15),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blueGrey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.blueGrey.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset('assets/images/logo.png', height: 60),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Aramıza Katıl",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.blueGrey.shade900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ekipmanlarını takip etmek için kayıt ol",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                  hintText: "Ad",
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _surnameController,
                                  icon: Icons.badge_outlined,
                                  hintText: "Soyad",
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            icon: Icons.alternate_email_rounded,
                            hintText: "Kurumsal E-posta",
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            hintText: "Telefon Numarası",
                            keyboardType: TextInputType.phone,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline_rounded,
                            hintText: "Şifre Belirle",
                            isPassword: true,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 40),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _kayitOl,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800), // Kurumsal Turuncu
                                foregroundColor: Colors.white,
                                elevation: 10,
                                shadowColor: const Color(0xFFFF9800).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Kayıt Ol",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Zaten hesabın var mı? ",
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Giriş Yap",
                                    style: TextStyle(
                                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.blueGrey.shade900),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade400),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade400,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.blueGrey.shade500 : Colors.blueGrey.shade300),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}
