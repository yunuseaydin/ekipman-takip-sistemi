import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipment_detail_screen.dart';

class UserEquipmentsScreen extends StatefulWidget {
  const UserEquipmentsScreen({super.key});

  @override
  State<UserEquipmentsScreen> createState() => _UserEquipmentsScreenState();
}

class _UserEquipmentsScreenState extends State<UserEquipmentsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Tüm Ekipman Durumları",
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ARAMA Ã‡UBUÄU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Cihaz ID, Marka veya Model Ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Sistemde ekipman bulunmuyor."),
                  );
                }

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String docId = doc.id.toUpperCase();
                  String brand = (data['brand'] ?? "").toString().toUpperCase();
                  String model = (data['model'] ?? "").toString().toUpperCase();
                  return docId.contains(searchQuery) ||
                      brand.contains(searchQuery) ||
                      model.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    String brand = data['brand'] ?? 'Bilinmeyen';
                    String model = data['model'] ?? '';
                    String status = data['status'] ?? 'Mevcut';

                    bool isAvailable = status == 'Mevcut';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? Colors.blueGrey.shade700.withValues(alpha: 0.3) : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentDetailScreen(equipmentId: docId),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? Colors.green.shade500.withValues(alpha: 0.1)
                                      : Colors.red.shade500.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  isAvailable ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                                  color: isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "$brand $model",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                          child: Text(
                                            isAvailable ? "Boşta" : "Zimmetli",
                                            style: TextStyle(
                                              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code_rounded, size: 14, color: Colors.blueGrey.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          docId,
                                          style: TextStyle(
                                            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.shade300),
                              ),
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
      ),
    );
  }
}

