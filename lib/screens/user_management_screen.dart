import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_nameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    String phone = _phoneController.text.trim();
    if (phone.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir telefon numarası girin!")),
      );
      return;
    }

    String userEmail = _emailController.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    try {
      String tempPassword = phone.substring(phone.length - 4);

      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'search_name': _nameController.text.trim().toLowerCase(),
        'email': userEmail,
        'phone': phone,
        'password': tempPassword,
        'role': 'staff',
        'created_at': FieldValue.serverTimestamp(),
      });

      await LoggerService.logAction(
        title: "Kullanıcı Eklendi",
        detail:
            "Admin, '${_nameController.text.trim()} ${_surnameController.text.trim()}' kişisini sisteme ekledi.",
        type: 'user_add',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Text("Kullanıcı eklendi! Geçici Şifre: $tempPassword"),
          ),
        );
        _nameController.clear();
        _surnameController.clear();
        _emailController.clear();
        _phoneController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAdminRole(
    String docId,
    String fullName,
    bool currentAdminStatus,
  ) {
    String title = currentAdminStatus ? "Yetkiyi Al" : "Admin Yap";
    String content = currentAdminStatus
        ? "$fullName adlı kullanıcının Admin yetkisini almak istediğinize emin misiniz?"
        : "$fullName adlı kullanıcıya Admin yetkisi vermek istediğinize emin misiniz?";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentAdminStatus
                  ? Colors.orange
                  : Colors.green,
            ),
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .update({'role': currentAdminStatus ? 'staff' : 'admin'});

              // --- LOG EKLEME KISMI ---
              await LoggerService.logAction(
                title: currentAdminStatus
                    ? "Yetki Alındı"
                    : "Admin Yetkisi Verildi",
                detail: currentAdminStatus
                    ? "Admin, '$fullName' adlı kullanıcının admin yetkisini aldı."
                    : "Admin, '$fullName' adlı kullanıcıya admin yetkisi verdi.",
                type: 'user_role',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentAdminStatus
                          ? "$fullName artık standart kullanıcı."
                          : "$fullName artık Admin!",
                    ),
                  ),
                );
              }
            },
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveUser(String docId, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: Text(
          "$fullName adlı kullanıcıyı sistemden kalıcı olarak çıkarmak istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .delete();

              // --- LOG EKLEME KISMI ---
              await LoggerService.logAction(
                title: "Kullanıcı Silindi",
                detail:
                    "Admin, '$fullName' adlı kullanıcıyı sistemden çıkardı.",
                type: 'user_remove',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kullanıcı sistemden çıkarıldı."),
                  ),
                );
              }
            },
            child: const Text(
              "Evet, Çıkar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Yeni Kullanıcı Ekle",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "İsim",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _surnameController,
                  decoration: const InputDecoration(
                    labelText: "Soyisim",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-posta Adresi",
                    prefixIcon: Icon(Icons.email_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefon Numarası",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _saveUser,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sisteme Kaydet"),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Kullanıcılar"),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "İsim ile kullanıcı ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Sistemde kayıtlı kullanıcı yok."),
                  );
                }

                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String searchName = data['search_name'] ?? "";
                  return searchName.contains(_searchText);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin
                              ? Colors.amber
                              : Colors.blueGrey,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("$email\n${data['phone'] ?? ''}"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.admin_panel_settings,
                                color: isAdmin
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade400,
                              ),
                              tooltip: isAdmin
                                  ? "Admin Yetkisini Al"
                                  : "Admin Yap",
                              onPressed: () =>
                                  _toggleAdminRole(docId, fullName, isAdmin),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: "Sistemden Çıkar",
                              onPressed: () =>
                                  _confirmRemoveUser(docId, fullName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserSheet,
        backgroundColor: Colors.blueGrey.shade800,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Kullanıcı Ekle",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
