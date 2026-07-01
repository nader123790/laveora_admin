import 'package:cloud_firestore/cloud_firestore.dart';
import 'prize_position.dart';

class MatchModel {
  static const List<String> statusOptions = [
    'Upcoming',
    'Live',
    'Finished',
    'Disabled',
  ];

  final String id;
  final String matchName;
  final String team1;
  final String team2;
  final String team1Logo;
  final String team2Logo;
  final String date;
  final String time;
  final String timePeriod;
  final List<PrizePosition> prizePositions;
  final String matchStatus;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? kickoffAt;
  final DateTime? predictionClosesAt;
  final int? team1Goals;
  final int? team2Goals;
  final bool resultSaved;
  final bool winnersLocked;
  final List<Map<String, dynamic>> pendingWinners;

  const MatchModel({
    required this.id,
    required this.matchName,
    required this.team1,
    required this.team2,
    required this.team1Logo,
    required this.team2Logo,
    required this.date,
    required this.time,
    required this.timePeriod,
    required this.prizePositions,
    required this.matchStatus,
    required this.enabled,
    required this.createdAt,
    required this.kickoffAt,
    required this.predictionClosesAt,
    required this.team1Goals,
    required this.team2Goals,
    required this.resultSaved,
    required this.winnersLocked,
    required this.pendingWinners,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final team1 = data['team1']?.toString().trim() ?? '';
    final team2 = data['team2']?.toString().trim() ?? '';

    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }
    DateTime? kickoff;
    if (data['kickoffAt'] is Timestamp) {
      kickoff = (data['kickoffAt'] as Timestamp).toDate();
    }
    DateTime? closes;
    if (data['predictionClosesAt'] is Timestamp) {
      closes = (data['predictionClosesAt'] as Timestamp).toDate();
    }

    List<PrizePosition> prizes = [];
    if (data['prizePositions'] is List) {
      prizes =
          (data['prizePositions'] as List)
              .map(
                (e) =>
                    PrizePosition.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position));
    }

    String status = data['matchStatus']?.toString() ?? 'Upcoming';
    if (!statusOptions.contains(status)) status = 'Upcoming';

    List<Map<String, dynamic>> pending = [];
    if (data['pendingWinners'] is List) {
      pending = (data['pendingWinners'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // FIX: goals were previously read with `as int?`, which silently returns
    // null whenever Firestore stores the value as a double (e.g. 2.0) instead
    // of an int. That made `officialScore`/`officialWinningTeam` return null
    // even though resultSaved was true, which made every prediction look
    // "incorrect" downstream. Always coerce through `num` first.
    final team1Goals = (data['team1Goals'] as num?)?.toInt();
    final team2Goals = (data['team2Goals'] as num?)?.toInt();

    return MatchModel(
      id: doc.id,
      matchName: data['matchName']?.toString() ?? '$team1 VS $team2',
      team1: team1,
      team2: team2,
      team1Logo: data['team1Logo']?.toString() ?? '',
      team2Logo: data['team2Logo']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      time: data['time']?.toString() ?? '',
      timePeriod: data['timePeriod']?.toString() ?? 'PM',
      prizePositions: prizes,
      matchStatus: status,
      enabled: data['enabled'] != false && status != 'Disabled',
      createdAt: created,
      kickoffAt: kickoff,
      predictionClosesAt: closes,
      team1Goals: team1Goals,
      team2Goals: team2Goals,
      resultSaved: data['resultSaved'] == true,
      winnersLocked: data['winnersLocked'] == true,
      pendingWinners: pending,
    );
  }

  String? get officialScore {
    if (team1Goals == null || team2Goals == null) return null;
    return '$team1Goals-$team2Goals';
  }

  String? get officialWinningTeam {
    if (team1Goals == null || team2Goals == null) return null;
    if (team1Goals! > team2Goals!) return team1;
    if (team2Goals! > team1Goals!) return team2;
    return 'Draw';
  }

  static DateTime? parseKickoff(String date, String time, String period) {
    if (date.isEmpty || time.isEmpty) return null;
    try {
      DateTime base;
      if (date.contains('-')) {
        final p = date.split('-');
        if (p.length != 3) return null;
        base = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } else if (date.contains('/')) {
        final p = date.split('/');
        if (p.length != 3) return null;
        base = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else {
        return null;
      }
      final tp = time.split(':');
      if (tp.length < 2) return null;
      int hour = int.parse(tp[0]);
      final minute = int.parse(tp[1]);
      final per = period.toUpperCase();
      if (per == 'PM' && hour < 12) hour += 12;
      if (per == 'AM' && hour == 12) hour = 0;
      return DateTime(base.year, base.month, base.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final kickoff = parseKickoff(date, time, timePeriod);
    final closes = kickoff?.subtract(const Duration(minutes: 1));
    return {
      'matchName': matchName,
      'team1': team1,
      'team2': team2,
      'team1Logo': team1Logo,
      'team2Logo': team2Logo,
      'date': date,
      'time': time,
      'timePeriod': timePeriod,
      'prizePositions': prizePositions.map((e) => e.toMap()).toList(),
      'matchStatus': matchStatus,
      'enabled': enabled && matchStatus != 'Disabled',
      if (kickoff != null) 'kickoffAt': Timestamp.fromDate(kickoff),
      if (closes != null) 'predictionClosesAt': Timestamp.fromDate(closes),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'resultSaved': resultSaved,
      // FIX: write goals as 0 instead of omitting the key when one side is
      // 0-0 -- previously `if (team1Goals != null)` meant a 0 goal value was
      // written fine (0 is not null), so this was actually safe; kept as-is
      // but made explicit / symmetrical with team2Goals for clarity.
      if (team1Goals != null) 'team1Goals': team1Goals,
      if (team2Goals != null) 'team2Goals': team2Goals,
      'winnersLocked': winnersLocked,
      'pendingWinners': pendingWinners,
    };
  }
}
