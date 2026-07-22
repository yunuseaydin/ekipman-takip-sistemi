// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_screen.dart';
import 'add_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  int _selectedTab = 1; // 1: Onaylılar, 2: Onay Bekleyenler

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Admin role toggle and remove user logic moved to UserDetailScreen
  // Add user logic moved to AddUserScreen

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String count,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? gradientColors
                  : [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.blueGrey.shade600),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blueGrey.shade900),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            
            int approvedUsers = 0;
            int pendingUsers = 0;
            
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data['status'] == 'onay_bekliyor') {
                  pendingUsers++;
                } else {
                  approvedUsers++;
                }
              }
            }

            return Column(
              children: [
                // Premium Compact Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.blueGrey.shade800, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kullanıcılar",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Personel Yönetimi",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildDashboardCard(
                            context: context,
                            title: "ONAYLILAR",
                            count: approvedUsers.toString(),
                            icon: Icons.verified_user_rounded,
                            gradientColors: [Colors.green.shade400, Colors.teal.shade700],
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                          _buildDashboardCard(
                            context: context,
                            title: "BEKLEYENLER",
                            count: pendingUsers.toString(),
                            icon: Icons.pending_actions_rounded,
                            gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                            isSelected: _selectedTab == 2,
                            onTap: () => setState(() => _selectedTab = 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.toLowerCase();
                      });
                    },
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "İsim ile kullanıcı ara...",
                      hintStyle: TextStyle(color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade400),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),

                // List Area
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "Sistemde kayıtlı kullanıcı yok",
                                style: TextStyle(
                                  color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      var users = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String searchName = data['search_name'] ?? "";
                        String status = data['status'] ?? "onayli"; // default
                        
                        bool matchesSearch = searchName.contains(_searchText);
                        bool matchesTab = false;
                        
                        if (_selectedTab == 0) {
                          matchesTab = true; // Tüm
                        } else if (_selectedTab == 1) {
                          matchesTab = status == 'onayli' || status != 'onay_bekliyor'; // Onaylılar
                        } else if (_selectedTab == 2) {
                          matchesTab = status == 'onay_bekliyor'; // Bekleyenler
                        }

                        return matchesSearch && matchesTab;
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var data = users[index].data() as Map<String, dynamic>;
                          String docId = users[index].id;

                          String name = data['name'] ?? "";
                          String surname = data['surname'] ?? "";
                          String fullName = "$name $surname".trim();
                          if (fullName.isEmpty) fullName = "İsimsiz Kullanıcı";

                          bool isAdmin = data['role'] == 'admin';
                          String email = data['email'] ?? "E-posta yok";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(
                                    docId: docId,
                                    fullName: fullName,
                                    email: email,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isAdmin ? Colors.orange.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                                      child: Icon(
                                        isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                        color: isAdmin ? Colors.orange.shade600 : Colors.blue.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isAdmin ? "Yönetici" : "Personel",
                                            style: TextStyle(
                                              color: isAdmin ? Colors.orange.shade400 : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade500),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black26),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserScreen())),
        backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade700,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          "Yeni Kullanıcı",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
