import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart';

class EquipmentManagementScreen extends StatelessWidget {
  const EquipmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        appBar: AppBar(
          title: const Text(
            "Ekipman Yönetimi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey.shade900,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            indicatorWeight: 3,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_box_rounded), text: "Yeni Ekle"),
              Tab(
                icon: Icon(Icons.manage_search_rounded),
                text: "Sil & Düzenle",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AddEquipmentTab(), ManageEquipmentTab()],
        ),
      ),
    );
  }
}

class AddEquipmentTab extends StatefulWidget {
  const AddEquipmentTab({super.key});

  @override
  State<AddEquipmentTab> createState() => _AddEquipmentTabState();
}

class _AddEquipmentTabState extends State<AddEquipmentTab> {
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

  Future<void> _cihazKaydet() async {
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

    setState(() {
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
            'status': 'Mevcut',
            'assigned_to': null,
            'created_at': FieldValue.serverTimestamp(),
          });

      await LoggerService.logAction(
        title: "Yeni Ekipman Eklendi",
        detail:
            "Admin, '${_brandController.text.trim()} ${_modelController.text.trim()}' cihazını sisteme ekledi.",
        type: 'eq_add',
      );

      if (!mounted) return;

      _idController.clear();
      _typeController.clear();
      _brandController.clear();
      _modelController.clear();
      setState(() {
        _selectedCategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          content: const Text(
            "Cihaz başarıyla depoya eklendi!",
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
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "QR ve Kategori",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: "Cihaz ID / QR Kodu (Örn: EQ-001)",
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blueGrey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Kategori Seçin",
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blueGrey.shade50,
              ),
              items: _categories
                  .map(
                    (String category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(),
            ),
            Text(
              "Donanım Detayları",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: "Cihaz Türü (Örn: Laptop, Monitör)",
                prefixIcon: const Icon(Icons.devices_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: "Marka",
                      hintText: "Örn: Apple",
                      prefixIcon: const Icon(Icons.branding_watermark_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: "Model",
                      hintText: "Örn: M2 Pro",
                      prefixIcon: const Icon(Icons.memory_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _cihazKaydet,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Sisteme Kaydet",
                            style: TextStyle(
                              fontSize: 18,
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
    );
  }
}

class ManageEquipmentTab extends StatefulWidget {
  const ManageEquipmentTab({super.key});

  @override
  State<ManageEquipmentTab> createState() => _ManageEquipmentTabState();
}

class _ManageEquipmentTabState extends State<ManageEquipmentTab> {
  String searchQuery = "";

  // SİLME İŞLEMİ
  Future<void> _confirmDelete(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Ekipmanı Sil'),
          content: const Text(
            'Bu ekipmanı sistemden tamamen silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(docId)
                    .delete();

                await LoggerService.logAction(
                  title: "Ekipman Silindi",
                  detail: "Admin, '$docId' kodlu ekipmanı sistemden sildi.",
                  type: 'eq_remove',
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      "Ekipman başarıyla silindi!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // DÜZENLEME PENCERESİ
  Future<void> _showEditDialog(
    String docId,
    Map<String, dynamic> currentData,
  ) async {
    final typeController = TextEditingController(text: currentData['type']);
    final brandController = TextEditingController(text: currentData['brand']);
    final modelController = TextEditingController(text: currentData['model']);
    String? selectedCategory = currentData['category'];

    final List<String> categories = [
      'Bilgisayar / Laptop',
      'Telefon / Tablet',
      'Kamera / Fotoğraf',
      'Yazıcı / Tarayıcı',
      'Ağ ve Güvenlik',
      'Diğer Donanımlar',
    ];

    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.blueGrey.shade800,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$docId Düzenle',
                    style: TextStyle(
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blueGrey.shade50,
                      ),
                      items: categories
                          .map(
                            (String category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: typeController,
                      decoration: InputDecoration(
                        labelText: "Cihaz Türü",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blueGrey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandController,
                      decoration: InputDecoration(
                        labelText: "Marka",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blueGrey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelController,
                      decoration: InputDecoration(
                        labelText: "Model",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blueGrey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('equipment')
                        .doc(docId)
                        .update({
                          'type': typeController.text.trim(),
                          'brand': brandController.text.trim(),
                          'model': modelController.text.trim(),
                          'category': selectedCategory,
                        });

                    await LoggerService.logAction(
                      title: "Ekipman Düzenlendi",
                      detail:
                          "Admin, '$docId' kodlu ekipmanın bilgilerini güncelledi.",
                      type: 'eq_edit',
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green.shade600,
                        content: const Text(
                          "Ekipman başarıyla güncellendi!",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Cihaz ID veya Marka Ara...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toUpperCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipment')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(child: Text("Kayıtlı ekipman bulunamadı."));

              var filteredDocs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String docId = doc.id.toUpperCase();
                String brand = (data['brand'] ?? "").toString().toUpperCase();
                return docId.contains(searchQuery) ||
                    brand.contains(searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: filteredDocs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  var doc = filteredDocs[index];
                  var data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade100,
                        child: const Icon(
                          Icons.devices,
                          color: Colors.blueGrey,
                        ),
                      ),
                      title: Text(
                        doc.id,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${data['brand']} ${data['model']} - ${data['status']}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmDelete(doc.id),
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
    );
  }
}
