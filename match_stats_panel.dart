import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class ParticipantsPage extends StatefulWidget {
  const ParticipantsPage({super.key});

  @override
  State<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الهاتف أو معرف المباراة...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('predictions')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'حدث خطأ: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final docs = List<QueryDocumentSnapshot>.from(
                snapshot.data?.docs ?? [],
              );
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTs = aData['timestamp'] is Timestamp
                    ? (aData['timestamp'] as Timestamp).toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final bTs = bData['timestamp'] is Timestamp
                    ? (bData['timestamp'] as Timestamp).toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return bTs.compareTo(aTs);
              });

              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? docs
                  : docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final phone = (data['phoneNumber']?.toString() ?? '')
                          .toLowerCase();
                      final matchId = (data['matchId']?.toString() ?? '')
                          .toLowerCase();
                      return phone.contains(q) || matchId.contains(q);
                    }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا يوجد مشاركون بعد',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد نتائج مطابقة',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10),
                itemBuilder: (context, i) {
                  final data = filtered[i].data() as Map<String, dynamic>;
                  final phone = data['phoneNumber']?.toString() ?? '-';
                  final matchId = data['matchId']?.toString() ?? '-';
                  final team = data['winningTeam']?.toString() ?? '-';
                  final score = data['predictedScore']?.toString() ?? '-';

                  String submitted = '—';
                  if (data['timestamp'] is Timestamp) {
                    submitted = intl.DateFormat(
                      'yyyy-MM-dd HH:mm:ss',
                    ).format((data['timestamp'] as Timestamp).toDate());
                  }

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    child: ListTile(
                      title: Text(
                        phone,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('معرف المباراة: $matchId'),
                          Text('التوقع: $team $score'),
                          Text(
                            'وقت التسجيل (السيرفر): $submitted',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
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
