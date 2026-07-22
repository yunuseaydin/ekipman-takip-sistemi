import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/logger_service.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;
  final bool isAdmin;

  const EquipmentDetailScreen({
    super.key,
    required this.equipmentId,
    this.isAdmin = false,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  Future<List<Map<String, dynamic>>> _fetchHistoryLogs() async {
    // Fetch logs that mention this equipmentId
    try {
      var query = await FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> relatedLogs = [];
      for (var doc in query.docs) {
        var data = doc.data();
        String detail = (data['detail'] ?? '').toString();
        // Since we don't have equipmentId stored explicitly in logs, we check if detail contains it
        if (detail.contains(widget.equipmentId)) {
          relatedLogs.add(data);
        }
      }
      return relatedLogs;
    } catch (e) {
      return [];
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    if (timestamp is Timestamp) {
      return DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('equipment').doc(widget.equipmentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            body: Center(
              child: Text(
                "Ekipman bulunamadı.",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String brand = data['brand'] ?? 'Bilinmiyor';
        String model = data['model'] ?? 'Bilinmiyor';
        String type = data['type'] ?? 'Bilinmiyor';
        String category = data['category'] ?? 'Diğer';
        String status = data['status'] ?? 'Bilinmiyor';
        String assignedTo = data['assigned_to'] ?? '';
        dynamic assignedDate = data['assigned_date'];
        
        bool isAvailable = status == 'Mevcut';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          bottomNavigationBar: widget.isAdmin ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.blue.shade600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.blue.shade600,
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text("Düzenle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () => _showEditDialog(data),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text("Sil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
          ) : null,
          body: CustomScrollView(
            slivers: [
              // Hero AppBar
              SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade900,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background pattern or gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDark ? const Color(0xFF0F172A) : Colors.blueGrey.shade900,
                              isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade700,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Animated glowing orb effect behind icon
                      Positioned(
                        top: 40,
                        right: -40,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.tealAccent.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withValues(alpha: 0.2),
                                blurRadius: 100,
                                spreadRadius: 50,
                              )
                            ],
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "$brand $model",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.equipmentId,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
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

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      _buildStatusCard(isAvailable, assignedTo, assignedDate, isDark),
                      const SizedBox(height: 24),
                      
                      // General Info
                      Text(
                        "Genel Bilgiler",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoGrid(type, category, data['addedDate'], isDark),
                      
                      const SizedBox(height: 32),
                      
                      // History Timeline
                      Text(
                        "Geçmiş İşlemler",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHistoryTimeline(isDark),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(bool isAvailable, String assignedTo, dynamic assignedDate, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAvailable
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable ? Icons.check_circle_rounded : Icons.person_pin_rounded,
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? "Zimmetlenmeye Hazır" : "Şu an Zimmetli",
                  style: TextStyle(
                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isAvailable && assignedTo.isNotEmpty)
                  Text(
                    "Kullanan: $assignedTo",
                    style: TextStyle(
                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (!isAvailable && assignedDate != null)
                  Text(
                    "Tarih: ${_formatDate(assignedDate)}",
                    style: TextStyle(
                      color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                      fontSize: 13,
                    ),
                  ),
                if (isAvailable)
                  Text(
                    "Cihaz depoda ve yeni bir personele verilmek için uygun.",
                    style: TextStyle(
                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
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

  Widget _buildInfoGrid(String type, String category, dynamic addedDate, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow("Kategori", category, Icons.category_rounded, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          _buildInfoRow("Cihaz Türü", type, Icons.devices_rounded, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          _buildInfoRow("Kayıt Tarihi", _formatDate(addedDate), Icons.date_range_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey.shade400, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
            fontSize: 15,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.blueGrey.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTimeline(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchHistoryLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.blueGrey.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  "Henüz bir geçmiş kaydı yok.",
                  style: TextStyle(color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> logs = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            var log = logs[index];
            bool isFirst = index == 0;
            bool isLast = index == logs.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline line & dot
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          color: isFirst ? Colors.transparent : (isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.shade400,
                            border: Border.all(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              width: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isLast ? Colors.transparent : (isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Log Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.blueGrey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log['title'] ?? 'İşlem',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                ),
                              ),
                              Text(
                                _formatDate(log['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log['detail'] ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 14, color: Colors.blueGrey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                log['action_by'] ?? 'Bilinmiyor',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } // build metodu sonu

  final List<String> _categories = [
    'Bilgisayar',
    'Telefon/Tablet',
    'Yazıcı/Tarayıcı',
    'Ağ/Güvenlik',
    'Kamera/Fotoğraf',
    'Aksesuar',
    'Diğer'
  ];

  void _confirmDelete() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 28),
              const SizedBox(width: 8),
              Text(
                'Ekipmanı Sil',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${widget.equipmentId} kodlu ekipmanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            style: TextStyle(
              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
              fontSize: 16,
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
            TextButton(
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // dialog kapat
                
                await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(widget.equipmentId)
                    .delete();

                await LoggerService.logAction(
                  title: "Ekipman Silindi",
                  detail: "Admin, '${widget.equipmentId}' kodlu ekipmanı sistemden sildi.",
                  type: 'eq_remove',
                );

                if (!context.mounted) return;
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
                Navigator.of(context).pop(); // detay ekranını kapat
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> currentData) async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final typeController = TextEditingController(text: currentData['type']?.toString() ?? '');
    final brandController = TextEditingController(text: currentData['brand']?.toString() ?? '');
    final modelController = TextEditingController(text: currentData['model']?.toString() ?? '');
    String? selectedCategory = currentData['category']?.toString();

    final List<String> categories = List.from(_categories);
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
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: isDark ? Colors.white : Colors.blueGrey.shade800,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.equipmentId} Düzenle',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
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
                    _buildDropdown(
                      label: "Kategori",
                      value: selectedCategory,
                      items: categories,
                      isDark: isDark,
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDialogTextField(typeController, "Cihaz Türü", isDark),
                    const SizedBox(height: 16),
                    _buildDialogTextField(brandController, "Marka", isDark),
                    const SizedBox(height: 16),
                    _buildDialogTextField(modelController, "Model", isDark),
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
                        .doc(widget.equipmentId)
                        .update({
                      'type': typeController.text.trim(),
                      'brand': brandController.text.trim(),
                      'model': modelController.text.trim(),
                      'category': selectedCategory,
                    });

                    await LoggerService.logAction(
                      title: "Ekipman Düzenlendi",
                      detail:
                          "Admin, '${widget.equipmentId}' kodlu ekipmanın bilgilerini güncelledi.",
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
}

