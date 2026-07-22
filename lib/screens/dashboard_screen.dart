import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipment_management_screen.dart';
import 'equipments_screen.dart';
import 'user_management_screen.dart';
import 'history_screen.dart';
import 'user_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _name = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _kullaniciBilgileriniGetir();
  }

  Future<void> _kullaniciBilgileriniGetir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        setState(() {
          var data = userDoc.data() as Map<String, dynamic>;
          String n = data['name'] ?? '';
          String s = data['surname'] ?? data['soyad'] ?? '';
          _name = "$n $s".trim();
          if (_name.isEmpty) _name = 'Admin';
          _isLoading = false;
        });
      } else {
        setState(() {
          _name = 'Admin';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Removed glowing orbs to keep background clean
                // Ana İçerik
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 32),
                        _buildMainModulesSection(context),
                        const SizedBox(height: 32),
                        _buildRecentLogsSection(context),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showLogDetails(
    BuildContext context,
    String title,
    String detail,
    String actionBy,
    String timeString,
    IconData iconData,
    Color iconColor,
    Color bgColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.blueGrey.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.calendar_today_rounded, "Tarih ve Saat", timeString),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.person_outline_rounded, "İşlemi Yapan", actionBy),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.info_outline_rounded, "Detay", detail),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.teal.shade700 : Colors.blueGrey.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Kapat", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo tamamen serbest
              Image.asset(
                'assets/images/logo.png',
                height: 56, // Logoyu belirgin şekilde büyüttük
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  "KİMDE?",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black87),
                ),
              ),
              // Profil İkonu (Yuvarlak)
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.person_outline_rounded, color: Colors.blueGrey.shade800, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                "Genel Durum",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.blueGrey.shade900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
                builder: (context, equipmentSnapshot) {
                  int totalUsers = 0;
                  int totalEquipments = 0;
                  int assignedEquipments = 0;
                  int availableEquipments = 0;

                  if (userSnapshot.hasData) {
                    totalUsers = userSnapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['role'] == 'staff';
                    }).length;
                  }

                  if (equipmentSnapshot.hasData) {
                    var equipments = equipmentSnapshot.data!.docs;
                    totalEquipments = equipments.length;
                    for (var doc in equipments) {
                      var data = doc.data() as Map<String, dynamic>;
                      if (data['status'] == 'Zimmetli') {
                        assignedEquipments++;
                      } else {
                        availableEquipments++;
                      }
                    }
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Personel",
                              count: totalUsers,
                              icon: Icons.people_alt_rounded,
                              baseColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              title: "Envanter",
                              count: totalEquipments,
                              icon: Icons.inventory_2_rounded,
                              baseColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Kartlar arası dikey boşluk
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Zimmetler",
                              count: assignedEquipments,
                              icon: Icons.assignment_ind_rounded,
                              baseColor: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildStatCard(
                              title: "Depoda",
                              count: availableEquipments,
                              icon: Icons.devices_other_rounded,
                              baseColor: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required MaterialColor baseColor,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : baseColor.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? baseColor.shade700.withValues(alpha: 0.3) : baseColor.shade200.withValues(alpha: 0.6), 
          width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : baseColor.shade100.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? baseColor.shade900.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: baseColor.shade100.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(icon, color: isDark ? baseColor.shade300 : baseColor.shade600, size: 24),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainModulesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Ana Modüller" yazısı kaldırıldı.

          // Büyük (Hero) Kart - Ekipman Yönetimi
          _buildHeroCard(
            context: context,
            title: "Ekipman Yönetimi",
            subtitle: "Sisteme yeni cihaz ekleyin veya mevcut envanteri yönetin.",
            buttonText: "Cihaz Ekle",
            icon: Icons.add_to_photos_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFE76F51), Color(0xFFF4A261)], // Daha pastel/mute edilmiş şık bir turuncu/şeftali
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EquipmentManagementScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          // İki Küçük Kart Yan Yana - Zimmet & Kullanıcı Yönetimi
          Row(
            children: [
              Expanded(
                child: _buildSmallActionCard(
                  title: "Zimmet\nYönetimi",
                  icon: Icons.assignment_turned_in_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade700, Colors.indigo.shade400],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EquipmentsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallActionCard(
                  title: "Kullanıcı\nYönetimi",
                  icon: Icons.manage_accounts_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 175, // Yükseklik artırıldı ki taşma (overflow) olmasın
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Sağ alttaki büyük transparan ikon (Estetik detay)
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    icon,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spacer yerine bunu kullanıyoruz, taşmayı önler
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.70, // Daha geniş alan
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14, // Çok ufak küçülttüm ki sığsın
                              fontWeight: FontWeight.w500, // Biraz daha kalın
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Butonu sağ alta almak için Align kullanıyoruz
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: gradient.colors.first,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: gradient.colors.first, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        height: 140,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Transparan arka plan ikonu
              Positioned(
                right: -15,
                bottom: -15,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    icon,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLogsSection(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Son İşlemler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Text(
                        "Tümünü Gör",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.orange.shade700),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('logs')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.blueGrey.shade200),
                      const SizedBox(height: 12),
                      Text(
                        "Henüz bir işlem kaydedilmedi.",
                        style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = data['title'] ?? 'İşlem';
                  String detail = data['detail'] ?? '';
                  String type = data['type'] ?? 'unknown';
                  String actionBy = data['action_by'] ?? 'Bilinmeyen Yönetici';

                  String timeString = "";
                  if (data['timestamp'] != null) {
                    DateTime date = (data['timestamp'] as Timestamp).toDate();
                    timeString = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  IconData iconData = Icons.info_outline_rounded;
                  Color iconColor = Colors.blueGrey.shade600;
                  Color bgColor = Colors.blueGrey.shade50;

                  String lowerTitle = title.toLowerCase();

                  // Zıt işlemler için özel renkler ve ikonlar
                  if (type == 'eq_add' || (lowerTitle.contains('ekipman') && lowerTitle.contains('eklendi'))) {
                    iconData = Icons.add_to_queue_rounded; // Ekipman eklendi
                    iconColor = Colors.green.shade600;
                    bgColor = Colors.green.shade50;
                  } else if (type == 'eq_delete' || (lowerTitle.contains('ekipman') && lowerTitle.contains('silindi'))) {
                    iconData = Icons.delete_sweep_rounded; // Ekipman silindi
                    iconColor = Colors.red.shade600;
                    bgColor = Colors.red.shade50;
                  } else if (type == 'eq_assign' || lowerTitle.contains('teslim edildi') || lowerTitle.contains('zimmetlendi')) {
                    iconData = Icons.upload_rounded; // Dışarı (Personele) gidiş
                    iconColor = Colors.orange.shade600;
                    bgColor = Colors.orange.shade50;
                  } else if (type == 'eq_return' || lowerTitle.contains('teslim alındı') || lowerTitle.contains('iade')) {
                    iconData = Icons.download_rounded; // Depoya geri geliş
                    iconColor = Colors.teal.shade600;
                    bgColor = Colors.teal.shade50;
                  } else if (type == 'user_add' || lowerTitle.contains('kullanıcı eklendi') || lowerTitle.contains('personel eklendi')) {
                    iconData = Icons.person_add_rounded; // Kullanıcı eklendi
                    iconColor = Colors.purple.shade500;
                    bgColor = Colors.purple.shade50;
                  } else if (type == 'user_delete' || lowerTitle.contains('kullanıcı silindi') || lowerTitle.contains('personel silindi')) {
                    iconData = Icons.person_remove_rounded; // Kullanıcı silindi
                    iconColor = Colors.redAccent.shade700;
                    bgColor = Colors.red.shade50;
                  } else if (type == 'user_update' || lowerTitle.contains('güncellendi')) {
                    iconData = Icons.edit_note_rounded; // Güncelleme
                    iconColor = Colors.blue.shade600;
                    bgColor = Colors.blue.shade50;
                  } else {
                    iconData = Icons.history_edu_rounded; // Genel işlem
                    iconColor = Colors.blueGrey.shade500;
                    bgColor = Colors.blueGrey.shade50;
                  }

                  return InkWell(
                    onTap: () => _showLogDetails(
                      context, title, detail, actionBy, timeString, iconData, iconColor, bgColor
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(iconData, color: iconColor, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey.shade500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.shade300),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
