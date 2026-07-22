import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart';
import 'equipment_detail_screen.dart'; // YENİ EKLENDİ

class EquipmentManagementScreen extends StatefulWidget {
  const EquipmentManagementScreen({super.key});

  @override
  State<EquipmentManagementScreen> createState() =>
      _EquipmentManagementScreenState();
}

class _EquipmentManagementScreenState extends State<EquipmentManagementScreen> {
  String searchQuery = "";

  // Controllers for Adding Equipment
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Bilgisayar / Laptop',
    'Telefon / Tablet',
    'Kamera / Fotoğraf',
    'Yazıcı / Tarayıcı',
    'Ağ ve Güvenlik',
    'Diğer Donanımlar',
  ];

  void _resetForm() {
    _idController.clear();
    _typeController.clear();
    _brandController.clear();
    _modelController.clear();
    _selectedCategory = null;
  }

  Future<void> _cihazKaydet(StateSetter setModalState) async {
    if (_idController.text.trim().isEmpty ||
        _typeController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
          content: const Text(
            "Lütfen tüm alanları eksiksiz doldurun!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setModalState(() {
      _isLoading = true;
    });

    try {
      String ekipmanId = _idController.text.trim().toUpperCase();

      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(ekipmanId)
          .set({
        'type': _typeController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'category': _selectedCategory,
        'status': 'Müsait',
        'assignedTo': '',
        'assignedToId': '',
        'addedDate': FieldValue.serverTimestamp(),
      });

      await LoggerService.logAction(
        title: "Yeni Ekipman Eklendi",
        detail:
            "Admin, '$ekipmanId' seri numaralı ${_typeController.text.trim()} cihazını sisteme kaydetti.",
        type: 'eq_add',
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close bottom sheet
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          content: const Text(
            "Cihaz başarıyla eklendi!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text(
            "Hata oluştu: $e",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      setModalState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddBottomSheet() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _resetForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blueGrey.shade600 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 28,
                            color: Colors.teal.shade500,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Yeni Ekipman Ekle",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.blueGrey.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDialogTextField(_idController, "Cihaz ID (Örn: EQ-001)", isDark, icon: Icons.qr_code_scanner),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("QR Okuyucu kamera modülü yakında eklenecek."),
                                  backgroundColor: Colors.blueGrey,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56, // Match standard text field height roughly
                              width: 56,
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.teal.shade500,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(Icons.camera_alt_rounded, color: Colors.teal.shade600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Kategori Seçin",
                        value: _selectedCategory,
                        items: _categories,
                        isDark: isDark,
                        onChanged: (String? newValue) {
                          setModalState(() {
                            _selectedCategory = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(_typeController, "Cihaz Türü (Örn: Laptop)", isDark, icon: Icons.devices),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogTextField(_brandController, "Marka", isDark, icon: Icons.branding_watermark),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDialogTextField(_modelController, "Model", isDark, icon: Icons.model_training),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _isLoading ? null : () => _cihazKaydet(setModalState),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Sisteme Kaydet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, bool isDark, {IconData? icon}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600),
        prefixIcon: icon != null ? Icon(icon, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.blueGrey.shade50.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600),
        prefixIcon: Icon(Icons.category_rounded, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.blueGrey.shade50.withValues(alpha: 0.5),
      ),
      items: items
          .map(
            (String category) => DropdownMenuItem(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBottomSheet,
        backgroundColor: Colors.teal.shade500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Yeni Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Compact Header with Emblem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
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
                          "Ekipman Yönetimi",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.blueGrey.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Envanter Kayıtları",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Emblem / Logo Area
                  Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Cihaz ID veya Marka Ara...",
                    hintStyle: TextStyle(color: isDark ? Colors.blueGrey.shade400 : Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.blueGrey.shade300 : Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toUpperCase();
                    });
                  },
                ),
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Kayıtlı ekipman bulunamadı.",
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String docId = doc.id.toUpperCase();
                    String brand = (data['brand'] ?? "").toString().toUpperCase();
                    return docId.contains(searchQuery) || brand.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80), // Padding bottom for FAB
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.blueGrey.shade700.withValues(alpha: 0.3) : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EquipmentDetailScreen(
                                    equipmentId: doc.id,
                                    isAdmin: true,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark 
                                            ? [Colors.teal.shade600, Colors.teal.shade800]
                                            : [Colors.teal.shade300, Colors.teal.shade500],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.devices_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                      doc.id,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${data['brand']} ${data['model']}",
                                      style: TextStyle(
                                        color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: data['status'] == 'Mevcut'
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        data['status'] ?? 'Bilinmiyor',
                                        style: TextStyle(
                                          color: data['status'] == 'Mevcut'
                                              ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                              : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.chevron_right_rounded, color: isDark ? Colors.blueGrey.shade600 : Colors.blueGrey.shade300),
                                ],
                              ),
                            ],
                          ),
                        ),
                       ), // Close InkWell
                      ), // Close Material
                    ); // Close Container
                  },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
