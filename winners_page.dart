import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/winner_service.dart';
import 'preview_winners_page.dart';

const Map<String, String> _statusLabelsAr = {
  'Upcoming': 'قادمة',
  'Live': 'مباشرة',
  'Finished': 'منتهية',
  'Disabled': 'متوقفة',
};

String _statusLabel(String status) => _statusLabelsAr[status] ?? status;

class MatchDetailPage extends StatefulWidget {
  final String matchId;
  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _g1.dispose();
    _g2.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _finishMatch(MatchModel match) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('إنهاء المباراة'),
        content: const Text(
          'هل تريد تحديد هذه المباراة كمنتهية وإدخال النتيجة الرسمية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(match.id)
          .update({'matchStatus': 'Finished'});
    } catch (e) {
      _snack('حدث خطأ: $e');
      return;
    }
    if (match.team1Goals != null) {
      _g1.text = '${match.team1Goals}';
      _g2.text = '${match.team2Goals}';
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveResult(MatchModel match) async {
    final g1 = int.tryParse(_g1.text.trim());
    final g2 = int.tryParse(_g2.text.trim());
    if (g1 == null || g2 == null || g1 < 0 || g2 < 0) {
      _snack('أدخل عدد أهداف صحيح لكل فريق');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(match.id)
          .update({
            'team1Goals': g1,
            'team2Goals': g2,
            'resultSaved': true,
            'matchStatus': 'Finished',
          });
      _snack('تم حفظ النتيجة الرسمية', color: Colors.green);
    } catch (e) {
      _snack('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _calculate(MatchModel match) async {
    if (!match.resultSaved) {
      _snack('احفظ النتيجة الرسمية أولاً');
      return;
    }
    if (match.winnersLocked) {
      _snack('الفائزون مقفلون. قم بإعادة التصفير أولاً لإعادة الحساب.');
      return;
    }
    setState(() => _busy = true);
    try {
      final winners = await WinnerService.calculateWinners(match);
      await WinnerService.savePendingPreview(match.id, winners);
      if (!mounted) return;
      if (winners.isEmpty) {
        _snack('لا توجد توقعات صحيحة');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PreviewWinnersPage(matchId: match.id, winners: winners),
        ),
      );
    } catch (e) {
      _snack('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset(MatchModel match) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('إعادة تصفير الفائزين'),
        content: const Text(
          'سيتم حذف جميع الفائزين المؤكدين لهذه المباراة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'إعادة تصفير',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await WinnerService.resetWinners(match.id);
      _snack('تمت إعادة تصفير الفائزين');
    } catch (e) {
      _snack('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: const Text('التحكم في المباراة'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('حدث خطأ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(
              child: Text(
                'تم حذف هذه المباراة',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final match = MatchModel.fromFirestore(snap.data!);
          if (match.team1Goals != null && _g1.text.isEmpty) {
            _g1.text = '${match.team1Goals}';
            _g2.text = '${match.team2Goals}';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  match.matchName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC5A059),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${match.team1} ضد ${match.team2}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'الحالة: ${_statusLabel(match.matchStatus)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 24),
                if (match.matchStatus != 'Finished' && !match.resultSaved)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy ? null : () => _finishMatch(match),
                    icon: const Icon(Icons.flag),
                    label: const Text(
                      'إنهاء المباراة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (match.matchStatus == 'Finished' || match.resultSaved) ...[
                  const Text(
                    'النتيجة الرسمية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _g1,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'أهداف ${match.team1}',
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('—', style: TextStyle(fontSize: 24)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _g2,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'أهداف ${match.team2}',
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A059),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy ? null : () => _saveResult(match),
                    child: Text(
                      _busy ? 'جارٍ الحفظ...' : 'حفظ النتيجة الرسمية',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (match.resultSaved) ...[
                    const SizedBox(height: 8),
                    Text(
                      'النتيجة الحالية: ${match.officialScore} · الفائز: ${match.officialWinningTeam == 'Draw' ? 'تعادل' : match.officialWinningTeam}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy || match.winnersLocked
                        ? null
                        : () => _calculate(match),
                    icon: const Icon(Icons.calculate),
                    label: Text(
                      _busy ? 'جارٍ الحساب...' : 'احسب الفائزين',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (match.pendingWinners.isNotEmpty &&
                      !match.winnersLocked) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreviewWinnersPage(
                            matchId: match.id,
                            winners: match.pendingWinners,
                          ),
                        ),
                      ),
                      child: Text(
                        'مراجعة المعاينة المعلقة (${match.pendingWinners.length})',
                      ),
                    ),
                  ],
                  if (match.winnersLocked) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purpleAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'تم تأكيد الفائزين وقفل النتائج.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.purpleAccent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: _busy ? null : () => _reset(match),
                      child: const Text('إعادة تصفير الفائزين'),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
