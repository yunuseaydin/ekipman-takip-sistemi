import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String searchQuery = "";

  Map<String, dynamic> _getIconStyleForAction(String type) {
    switch (type) {
      case 'user_add':
        return {'icon': Icons.person_add_alt_1_rounded, 'color': Colors.green};
      case 'user_remove':
        return {'icon': Icons.person_remove_rounded, 'color': Colors.red};
      case 'user_role':
        return {
          'icon': Icons.admin_panel_settings_rounded,
          'color': Colors.amber.shade700,
        };
      case 'eq_add':
        return {'icon': Icons.add_to_queue_rounded, 'color': Colors.blue};
      case 'eq_remove':
        return {'icon': Icons.delete_sweep_rounded, 'color': Colors.redAccent};
      case 'eq_edit':
        return {'icon': Icons.edit_note_rounded, 'color': Colors.orange};
      case 'eq_assign':
        return {'icon': Icons.assignment_ind_rounded, 'color': Colors.teal};
      case 'eq_return':
        return {
          'icon': Icons.assignment_returned_rounded,
          'color': Colors.purple,
        };
      default:
        return {'icon': Icons.history_rounded, 'color': Colors.blueGrey};
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "İşlem Geçmişi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blueGrey.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueGrey.shade900,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Kullanıcı, cihaz veya işlem ara...",
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.blueGrey,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 64,
                          color: Colors.blueGrey.shade200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Henüz bir işlem geçmişi bulunmuyor.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var logs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  String detail = (data['detail'] ?? '')
                      .toString()
                      .toLowerCase();
                  String actionBy = (data['action_by'] ?? '')
                      .toString()
                      .toLowerCase();

                  return title.contains(searchQuery) ||
                      detail.contains(searchQuery) ||
                      actionBy.contains(searchQuery);
                }).toList();

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      '"$searchQuery" ile eşleşen sonuç bulunamadı.',
                      style: TextStyle(color: Colors.blueGrey.shade400),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var data = logs[index].data() as Map<String, dynamic>;

                    String title = data['title'] ?? 'Bilinmeyen İşlem';
                    String detail = data['detail'] ?? 'Detay yok.';
                    String type = data['type'] ?? 'unknown';
                    String actionBy =
                        data['action_by'] ??
                        'Sistem Yöneticisi'; 

                    var style = _getIconStyleForAction(type);
                    Color iconColor = style['color'];
                    IconData iconData = style['icon'];

                    String timeString = "Tarih Bekleniyor...";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      timeString =
                          "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, thickness: 1),
                            ),

                            Row(
                              children: [
                                Icon(
                                  Icons.account_circle_rounded,
                                  size: 16,
                                  color: Colors.blueGrey.shade400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Ä°ÅŸlemi Yapan: $actionBy",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Text(
                              detail,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.blueGrey.shade600,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade600,
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

