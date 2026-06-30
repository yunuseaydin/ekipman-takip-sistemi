import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart'; // LOG SERVİSİ İÇE AKTARILDI

class EquipmentsScreen extends StatefulWidget {
  const EquipmentsScreen({super.key});

  @override
  State<EquipmentsScreen> createState() => _EquipmentsScreenState();
}

class _EquipmentsScreenState extends State<EquipmentsScreen> {
  String searchQuery = "";

  Future<void> _teslimEtDialog(String docId, String brand, String model) async {
    TextEditingController emailController = TextEditingController();
    String? foundName;
    bool isSearching = false;
    String? errorMessage;

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
              title: Text(
                '$brand $model Teslim Et',
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Personelin e-posta adresini girin:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "E-posta Adresi",
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.blueGrey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.person_search_rounded),
                    label: const Text(
                      "Kullanıcıyı Sorgula",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: isSearching
                        ? null
                        : () async {
                            if (emailController.text.trim().isEmpty) return;

                            setDialogState(() {
                              isSearching = true;
                              errorMessage = null;
                              foundName = null;
                            });

                            try {
                              var query = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where(
                                    'email',
                                    isEqualTo: emailController.text.trim(),
                                  )
                                  .limit(1)
                                  .get();

                              if (query.docs.isEmpty) {
                                setDialogState(() {
                                  isSearching = false;
                                  errorMessage =
                                      "Kullanıcı sisteme kayıtlı değil!";
                                });
                              } else {
                                // AD VE SOYAD ÇEKME KISMI
                                var userData = query.docs.first.data();
                                String ad = userData['name'] ?? '';
                                String soyad =
                                    userData['surname'] ??
                                    userData['soyad'] ??
                                    '';

                                setDialogState(() {
                                  isSearching = false;
                                  foundName = "$ad $soyad".trim();
                                });
                              }
                            } catch (e) {
                              setDialogState(() {
                                isSearching = false;
                                errorMessage = "Sorgulama hatası: $e";
                              });
                            }
                          },
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (foundName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Bulunan Kişi: $foundName",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                  onPressed: foundName == null
                      ? null
                      : () async {
                          await FirebaseFirestore.instance
                              .collection('equipment')
                              .doc(docId)
                              .update({
                                'status': 'Zimmetli',
                                'assigned_to': foundName,
                                'assigned_email': emailController.text.trim(),
                                'assigned_date': FieldValue.serverTimestamp(),
                              });

                          // --- LOG EKLEME KISMI (TESLİM ET) ---
                          await LoggerService.logAction(
                            title: "Ekipman Teslim Edildi",
                            detail:
                                "'$brand $model' cihazı '$foundName' adlı personele teslim edildi.",
                            type: 'eq_assign',
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green.shade600,
                              content: Text(
                                "Cihaz $foundName adlı personele başarıyla teslim edildi!",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    'Teslim Et',
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

  // Cihazı Geri Alma
  Future<void> _teslimAlDialog(
    String docId,
    String brand,
    String model,
    String kimeVerilmis,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cihazı Geri Al',
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Şu anda "$kimeVerilmis" üzerinde olan $brand $model cihazını depoya geri alıyorsunuz. Onaylıyor musunuz?',
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
                backgroundColor: Colors.orange.shade700,
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
                      'status': 'Mevcut',
                      'assigned_to': null,
                      'assigned_email': null,
                      'returned_date': FieldValue.serverTimestamp(),
                    });

                await LoggerService.logAction(
                  title: "Ekipman Teslim Alındı",
                  detail:
                      "'$brand $model' cihazı '$kimeVerilmis' kullanıcısından depoya geri alındı.",
                  type: 'eq_return',
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.orange,
                    content: Text(
                      "Cihaz depoya başarıyla geri alındı!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              child: const Text(
                'Teslim Al',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text(
          "Tüm Ekipmanlar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ARAMA ÇUBUĞU
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
                  return const Center(
                    child: Text("Sistemde ekipman bulunmuyor."),
                  );

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
                    String? assignedTo = data['assigned_to'];

                    bool isAvailable = status == 'Mevcut';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  docId,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: isAvailable
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$brand $model",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isAvailable && assignedTo != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_pin_rounded,
                                    size: 20,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Kullanan: $assignedTo",
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAvailable
                                      ? Colors.teal.shade600
                                      : Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: Icon(
                                  isAvailable
                                      ? Icons.assignment_ind_rounded
                                      : Icons.assignment_returned_rounded,
                                ),
                                label: Text(
                                  isAvailable ? "Teslim Et" : "Teslim Al",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  if (isAvailable) {
                                    _teslimEtDialog(docId, brand, model);
                                  } else {
                                    _teslimAlDialog(
                                      docId,
                                      brand,
                                      model,
                                      assignedTo ?? 'Bilinmeyen Personel',
                                    );
                                  }
                                },
                              ),
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
    );
  }
}
