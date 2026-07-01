import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';
import '../models/prize_position.dart';

class WinnerService {
  static final _db = FirebaseFirestore.instance;
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Normalizes a predicted/official score string so that things like
  /// "2 - 1", "2:1", "٢-١", full-width digits, extra spaces, or different
  /// dash characters (-, –, —) all collapse to the same canonical form
  /// (e.g. "2-1").
  static String normalizeScore(String s) {
    String clean = s.trim();
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      clean = clean.replaceAll(arabic[i], english[i]);
      clean = clean.replaceAll(persian[i], english[i]);
    }
    // collapse all whitespace
    clean = clean.replaceAll(RegExp(r'\s+'), '');
    // unify every dash-like / colon separator to a single hyphen
    clean = clean.replaceAll(RegExp(r'[:\-–—_xX*]'), '-');
    // collapse repeated separators ("2--1" -> "2-1")
    clean = clean.replaceAll(RegExp(r'-+'), '-');
    return clean.toLowerCase();
  }

  static String normalizeTeam(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// The score alone fully determines the winning team, so we only compare
  /// the normalized predicted score against the normalized official score.
  /// We do not cross-check the free-text `winningTeam` field for
  /// correctness (it is still stored for display purposes only) since
  /// differences in casing/localization/whitespace there previously caused
  /// otherwise-correct predictions to be rejected.
  static bool isPredictionCorrect(Map<String, dynamic> pred, MatchModel match) {
    if (match.team1Goals == null || match.team2Goals == null) return false;

    final official = '${match.team1Goals}-${match.team2Goals}';
    final predScoreRaw = pred['predictedScore']?.toString() ?? '';
    if (predScoreRaw.trim().isEmpty) return false;

    final predScore = normalizeScore(predScoreRaw);
    final officialScore = normalizeScore(official);

    return predScore == officialScore;
  }

  /// Generates a winner code that is unique against both the codes already
  /// stored in Firestore (`existingCodes`, fetched once per calculation
  /// batch) and the codes already issued earlier in the current batch
  /// (`issuedThisBatch`). This avoids issuing one Firestore read per
  /// winner (previous implementation queried Firestore for every single
  /// code it generated, which made "Calculate Winners" slow for matches
  /// with many prize positions).
  static String _generateCode(
    Random rand,
    Set<String> existingCodes,
    Set<String> issuedThisBatch,
  ) {
    for (int i = 0; i < 50; i++) {
      final code =
          'WC-${List.generate(6, (_) => _chars[rand.nextInt(_chars.length)]).join()}';
      if (existingCodes.contains(code) || issuedThisBatch.contains(code)) {
        continue;
      }
      issuedThisBatch.add(code);
      return code;
    }
    // Astronomically unlikely fallback (33^6 ≈ 1.29 billion combinations).
    final fallback =
        'WC-${DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    issuedThisBatch.add(fallback);
    return fallback;
  }

  static Future<List<Map<String, dynamic>>> calculateWinners(
    MatchModel match,
  ) async {
    if (match.team1Goals == null || match.team2Goals == null) {
      throw StateError('لم يتم حفظ النتيجة الرسمية لهذه المباراة بعد.');
    }
    if (match.winnersLocked) {
      throw StateError(
        'الفائزون مؤكدون بالفعل. قم بإعادة التصفير أولاً لإعادة الحساب.',
      );
    }

    final predsSnap = await _db
        .collection('matches')
        .doc(match.id)
        .collection('predictions')
        .get();

    final correct = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in predsSnap.docs) {
      final data = doc.data();
      if (isPredictionCorrect(data, match)) correct.add(doc);
    }

    // Sort strictly by the Firestore server timestamp ("timestamp" field,
    // written via FieldValue.serverTimestamp() by the player app) so
    // ranking is based on the trusted server clock, not a possibly-missing
    // or client-forged value. Predictions without a resolved timestamp yet
    // are pushed to the end instead of being treated as "earliest".
    correct.sort((a, b) {
      final aTs = a.data()['timestamp'];
      final bTs = b.data()['timestamp'];
      final aHas = aTs is Timestamp;
      final bHas = bTs is Timestamp;
      if (aHas && bHas) {
        return (aTs as Timestamp).compareTo(bTs as Timestamp);
      }
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      return 0;
    });

    final prizes = List<PrizePosition>.from(match.prizePositions)
      ..sort((a, b) => a.position.compareTo(b.position));

    // Single read of every winner code already issued, instead of one
    // Firestore query per generated code.
    final existingCodesSnap = await _db.collection('winners').get();
    final existingCodes = existingCodesSnap.docs
        .map((d) => d.data()['winnerCode']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
    final issuedThisBatch = <String>{};
    final rand = Random();

    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < correct.length && i < prizes.length; i++) {
      final pred = correct[i].data();
      final prize = prizes[i];
      final code = _generateCode(rand, existingCodes, issuedThisBatch);
      final ts = pred['timestamp'] is Timestamp
          ? (pred['timestamp'] as Timestamp).toDate()
          : null;

      results.add({
        'position': prize.position,
        'phoneNumber': pred['phoneNumber']?.toString() ?? '',
        'winningTeam': pred['winningTeam']?.toString() ?? '',
        'predictedScore': pred['predictedScore']?.toString() ?? '',
        'prediction':
            '${pred['winningTeam'] ?? ''} ${pred['predictedScore'] ?? ''}'
                .trim(),
        'prizeType': prize.prizeType,
        'prizeDescription': prize.prizeDescription,
        'prizeData': prize.toMap(),
        'winnerCode': code,
        'submissionTimestamp': ts?.toIso8601String(),
        'submissionTimestampRaw': pred['timestamp'],
        'redeemed': false,
        'matchId': match.id,
        'matchName': match.matchName,
      });
    }
    return results;
  }

  static Future<void> savePendingPreview(
    String matchId,
    List<Map<String, dynamic>> winners,
  ) async {
    // pendingWinners previously stored the raw Firestore Timestamp object
    // (`submissionTimestampRaw`) inside an array field, which caused
    // inconsistent re-reads in some SDK versions; we persist a plain
    // ISO-8601 string instead and keep the Timestamp only in-memory for the
    // preview screen.
    final sanitized = winners
        .map((w) => {...w, 'submissionTimestampRaw': null})
        .toList();
    await _db.collection('matches').doc(matchId).update({
      'pendingWinners': sanitized,
    });
  }

  static Future<void> confirmWinners(
    MatchModel match,
    List<Map<String, dynamic>> winners,
  ) async {
    if (winners.isEmpty) {
      throw StateError('لا يوجد فائزون لتأكيدهم.');
    }
    if (match.winnersLocked) {
      throw StateError('الفائزون مؤكدون ومقفلون بالفعل لهذه المباراة.');
    }

    final batch = _db.batch();
    final calcTs = FieldValue.serverTimestamp();

    for (final w in winners) {
      final ref = _db.collection('winners').doc();
      final rawTs = w['submissionTimestampRaw'];
      batch.set(ref, {
        'matchId': match.id,
        'matchName': match.matchName,
        'position': w['position'],
        'phoneNumber': w['phoneNumber'],
        'winningTeam': w['winningTeam'],
        'predictedScore': w['predictedScore'],
        'prizeType': w['prizeType'],
        'prizeDescription': w['prizeDescription'],
        'prizeData': w['prizeData'] ?? const {},
        'winnerCode': w['winnerCode'],
        // Fall back to the ISO string (preserved from preview) instead of
        // always re-stamping "now" when the raw Timestamp was stripped by
        // savePendingPreview's sanitization.
        'submissionTimestamp': rawTs is Timestamp
            ? rawTs
            : (w['submissionTimestamp'] != null
                  ? Timestamp.fromDate(
                      DateTime.parse(w['submissionTimestamp'] as String),
                    )
                  : calcTs),
        'redeemed': false,
        'calculationDate': calcTs,
        'confirmedAt': calcTs,
      });
    }

    batch.update(_db.collection('matches').doc(match.id), {
      'pendingWinners': [],
      'winnersLocked': true,
      'winnersConfirmed': true,
    });

    await batch.commit();
  }

  static Future<void> resetWinners(String matchId) async {
    final winners = await _db
        .collection('winners')
        .where('matchId', isEqualTo: matchId)
        .get();

    // Firestore batches are capped at 500 operations; chunk deletions for
    // matches with a large number of winners instead of silently failing.
    const chunkSize = 450;
    for (var start = 0; start < winners.docs.length; start += chunkSize) {
      final chunk = winners.docs.skip(start).take(chunkSize);
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      if (start + chunkSize >= winners.docs.length) {
        batch.update(_db.collection('matches').doc(matchId), {
          'pendingWinners': [],
          'winnersLocked': false,
          'winnersConfirmed': false,
        });
      }
      await batch.commit();
    }
    if (winners.docs.isEmpty) {
      await _db.collection('matches').doc(matchId).update({
        'pendingWinners': [],
        'winnersLocked': false,
        'winnersConfirmed': false,
      });
    }
  }

  static Future<void> markRedeemed(String winnerId, bool redeemed) async {
    await _db.collection('winners').doc(winnerId).update({
      'redeemed': redeemed,
      'redeemedAt': redeemed ? FieldValue.serverTimestamp() : null,
    });
  }
}
