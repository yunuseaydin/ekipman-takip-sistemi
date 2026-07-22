import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import 'equipment_detail_screen.dart';

class EquipmentsScreen extends StatefulWidget {
  const EquipmentsScreen({super.key});

  @override
  State<EquipmentsScreen> createState() => _EquipmentsScreenState();
}

class _EquipmentsScreenState extends State<EquipmentsScreen> {
  String searchQuery = "";
  int _selectedTab = 0; // 0 for Depodakiler, 1 for Zimmetli Olanlar
  
  // Store all users for the autocomplete
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      var query = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> users = [];
      for (var doc in query.docs) {
        var data = doc.data();
        String name = data['name'] ?? '';
        String surname = data['surname'] ?? data['soyad'] ?? '';
        String email = data['email'] ?? '';
        String fullName = "$name $surname".trim();
        if (fullName.isNotEmpty || email.isNotEmpty) {
          users.add({
            'id': doc.id,
            'fullName': fullName.isEmpty ? 'İsimsiz Personel' : fullName,
            'email': email,
          });
        }
      }
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      debugPrint("Kullanıcıları çekerken hata: $e");
    }
  }

  // Modern BottomSheet for Assigning
  void _showTeslimEtBottomSheet(String docId, String brand, String model) {
    Map<String, dynamic>? selectedUser;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cihazı Teslim Et',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.blueGrey.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$brand $model cihazını bir personele zimmetleyin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isLoadingUsers)
                      const Center(child: CircularProgressIndicator())
                    else
                      Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => option['fullName'],
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          return _allUsers.where((user) {
                            return user['fullName']
                                .toString()
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (Map<String, dynamic> selection) {
                          setSheetState(() {
                            selectedUser = selection;
                          });
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Personel Ara (Ad Soyad)",
                              prefixIcon: const Icon(Icons.person_search_rounded),
                              suffixIcon: selectedUser != null
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.teal, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            ),
                            onChanged: (val) {
                              if (selectedUser != null) {
                                setSheetState(() {
                                  selectedUser = null;
                                });
                              }
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(16),
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 48,
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.teal.shade100,
                                        child: Text(
                                          option['fullName'].toString().substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.teal.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        option['fullName'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        option['email'],
                                        style: TextStyle(
                                          color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                                        ),
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: selectedUser == null
                          ? null
                          : () async {
                              await FirebaseFirestore.instance
                                  .collection('equipment')
                                  .doc(docId)
                                  .update({
                                    'status': 'onay_bekliyor',
                                    'assigned_to': selectedUser!['fullName'],
                                    'assigned_email': selectedUser!['email'],
                                    'assigned_date': FieldValue.serverTimestamp(),
                                  });

                              await LoggerService.logAction(
                                title: "Ekipman Onaya Gönderildi",
                                detail: "'$brand $model' cihazı '${selectedUser!['fullName']}' adlı personelin onayına sunuldu.",
                                type: 'eq_assign_pending',
                              );

                              await NotificationService.sendNotification(
                                userEmail: selectedUser!['email'],
                                title: "Ekipman Onayı Bekliyor",
                                message: "'$brand $model' cihazı size teslim edilmek üzere onayınızı bekliyor.",
                                type: "warning",
                              );

                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.orange.shade600,
                                  content: Text(
                                    "Cihaz ${selectedUser!['fullName']} adlı personelin onayına gönderildi!",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        'Cihazı Teslim Et',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modern BottomSheet for Returning
  void _showTeslimAlBottomSheet(
    String docId,
    String brand,
    String model,
    String kimeVerilmis,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_returned_rounded, color: Colors.orange.shade700, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Cihazı Depoya Geri Al',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.blueGrey.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Şu anda '),
                    TextSpan(
                      text: kimeVerilmis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                    ),
                    const TextSpan(text: ' üzerinde olan '),
                    TextSpan(
                      text: '$brand $model',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' cihazını depoya geri alıyorsunuz. Onaylıyor musunuz?'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.blueGrey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          detail: "'$brand $model' cihazı '$kimeVerilmis' kullanıcısından depoya geri alındı.",
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
                        'Evet, Geri Al',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard(String title, int count, Color color, IconData icon, bool isDark, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? color 
                : (isDark ? Colors.blueGrey.shade700.withValues(alpha: 0.3) : Colors.grey.shade200),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
          builder: (context, snapshot) {
            
            // Calculate Metrics
            int mevcutCount = 0;
            int zimmetliCount = 0;
            int onayBekleyenCount = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data['status'] == 'Mevcut') {
                  mevcutCount++;
                } else if (data['status'] == 'Zimmetli') {
                  zimmetliCount++;
                } else if (data['status'] == 'onay_bekliyor') {
                  onayBekleyenCount++;
                }
              }
            }

            return Column(
              children: [
                // Premium Compact Header with Emblem
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
                                  "Zimmet Yönetimi",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Cihazları teslim edin veya alın",
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
                      const SizedBox(height: 24),
                      // Dashboard Metrics Row
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashboardCard(
                                  "DEPODAKİLER", 
                                  mevcutCount, 
                                  Colors.teal, 
                                  Icons.inventory_2_rounded, 
                                  isDark,
                                  _selectedTab == 0,
                                  () => setState(() => _selectedTab = 0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDashboardCard(
                                  "ZİMMETLİLER", 
                                  zimmetliCount, 
                                  Colors.orange, 
                                  Icons.assignment_ind_rounded, 
                                  isDark,
                                  _selectedTab == 1,
                                  () => setState(() => _selectedTab = 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildDashboardCard(
                              "ONAY BEKLEYENLER", 
                              onayBekleyenCount, 
                              Colors.blueAccent, 
                              Icons.hourglass_empty_rounded, 
                              isDark,
                              _selectedTab == 2,
                              () => setState(() => _selectedTab = 2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cihaz ID, Marka veya Model Ara...",
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
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toUpperCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // List Area
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("Sistemde ekipman bulunmuyor."),
                        );
                      }

                      var filteredDocs = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String docId = doc.id.toUpperCase();
                        String brand = (data['brand'] ?? "").toString().toUpperCase();
                        String model = (data['model'] ?? "").toString().toUpperCase();
                        String status = data['status'] ?? 'Bilinmiyor';
                        
                        bool matchesSearch = 
                            docId.toUpperCase().contains(searchQuery) ||
                            brand.toUpperCase().contains(searchQuery) ||
                            model.toUpperCase().contains(searchQuery);

                        bool matchesTab = false;
                        if (_selectedTab == 0) {
                          matchesTab = (status == 'Mevcut');
                        } else if (_selectedTab == 1) {
                          matchesTab = (status == 'Zimmetli');
                        } else if (_selectedTab == 2) {
                          matchesTab = (status == 'onay_bekliyor');
                        }

                        return matchesSearch && matchesTab;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0 ? Icons.inventory_2_outlined : Icons.assignment_outlined,
                                size: 64,
                                color: Colors.blueGrey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTab == 0 
                                    ? "Depoda hiç uygun cihaz yok." 
                                    : "Zimmetli hiçbir cihaz yok.",
                                style: TextStyle(
                                  color: Colors.blueGrey.withValues(alpha: 0.6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          String brand = data['brand'] ?? 'Bilinmeyen';
                          String model = data['model'] ?? '';
                          String status = data['status'] ?? 'Bilinmiyor';
                          String? assignedTo = data['assigned_to'];
                          bool isAvailable = status == 'Mevcut';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.blueGrey.shade700.withValues(alpha: 0.3) : Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EquipmentDetailScreen(equipmentId: docId),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
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
                                                  docId,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "$brand $model",
                                                  style: TextStyle(
                                                    color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                if (!isAvailable && assignedTo != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: isDark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.shade100,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.person_pin_rounded,
                                                          size: 14,
                                                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                                                        ),
                                                        Text(
                                                          assignedTo + (status == 'onay_bekliyor' ? ' (Onay Bekliyor)' : ''),
                                                          style: TextStyle(
                                                            color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade300, size: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Action Button Area
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isAvailable
                                                ? (isDark ? Colors.teal.shade700 : Colors.teal.shade600)
                                                : (isDark ? Colors.orange.shade800 : Colors.orange.shade700),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          icon: Icon(
                                            isAvailable
                                                ? Icons.assignment_ind_rounded
                                                : Icons.assignment_returned_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            isAvailable ? "Personele Teslim Et" : "Depoya Geri Al",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          onPressed: () {
                                            if (isAvailable) {
                                              _showTeslimEtBottomSheet(docId, brand, model);
                                            } else {
                                              _showTeslimAlBottomSheet(
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
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
