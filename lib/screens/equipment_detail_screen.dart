import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailScreen({super.key, required this.equipmentId});

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

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains("bilgisayar") || category.toLowerCase().contains("laptop")) return Icons.laptop_mac_rounded;
    if (category.toLowerCase().contains("telefon") || category.toLowerCase().contains("tablet")) return Icons.phone_iphone_rounded;
    if (category.toLowerCase().contains("kamera") || category.toLowerCase().contains("fotoğraf")) return Icons.camera_alt_rounded;
    if (category.toLowerCase().contains("yazıcı") || category.toLowerCase().contains("tarayıcı")) return Icons.print_rounded;
    if (category.toLowerCase().contains("ağ") || category.toLowerCase().contains("güvenlik")) return Icons.router_rounded;
    return Icons.devices_other_rounded;
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('equipment').doc(widget.equipmentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Ekipman bulunamadı.",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
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

          return CustomScrollView(
            slivers: [
              // Hero AppBar
              SliverAppBar(
                expandedHeight: 280.0,
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
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "$brand $model",
                              style: const TextStyle(
                                fontSize: 26,
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
          );
        },
      ),
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
  }
}
