import 'package:cloud_firestore/cloud_firestore.dart';

class WinnerModel {
  final String id;
  final String matchId;
  final String matchName;
  final int position;
  final String phoneNumber;
  final String winningTeam;
  final String predictedScore;
  final String prizeType;
  final String prizeDescription;

  /// Full structured prize snapshot (discount/buyXGetY/freeItem details +
  /// the real menu items it references), stored alongside the
  /// human-readable prizeType/prizeDescription above.
  final Map<String, dynamic> prizeData;

  final String winnerCode;
  final DateTime? submissionTimestamp;
  final bool redeemed;
  final DateTime? redeemedAt;
  final DateTime? calculationDate;
  final DateTime? confirmedAt;

  const WinnerModel({
    required this.id,
    required this.matchId,
    required this.matchName,
    required this.position,
    required this.phoneNumber,
    required this.winningTeam,
    required this.predictedScore,
    required this.prizeType,
    required this.prizeDescription,
    required this.prizeData,
    required this.winnerCode,
    required this.submissionTimestamp,
    required this.redeemed,
    required this.redeemedAt,
    required this.calculationDate,
    required this.confirmedAt,
  });

  factory WinnerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WinnerModel(
      id: doc.id,
      matchId: data['matchId']?.toString() ?? '',
      matchName: data['matchName']?.toString() ?? '',
      position: (data['position'] as num?)?.toInt() ?? 0,
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      winningTeam: data['winningTeam']?.toString() ?? '',
      predictedScore: data['predictedScore']?.toString() ?? '',
      prizeType: data['prizeType']?.toString() ?? '',
      prizeDescription: data['prizeDescription']?.toString() ?? '',
      prizeData: data['prizeData'] is Map
          ? Map<String, dynamic>.from(data['prizeData'] as Map)
          : const {},
      winnerCode: data['winnerCode']?.toString() ?? '',
      submissionTimestamp: data['submissionTimestamp'] is Timestamp
          ? (data['submissionTimestamp'] as Timestamp).toDate()
          : null,
      redeemed: data['redeemed'] == true,
      redeemedAt: data['redeemedAt'] is Timestamp
          ? (data['redeemedAt'] as Timestamp).toDate()
          : null,
      calculationDate: data['calculationDate'] is Timestamp
          ? (data['calculationDate'] as Timestamp).toDate()
          : null,
      confirmedAt: data['confirmedAt'] is Timestamp
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'matchId': matchId,
    'matchName': matchName,
    'position': position,
    'phoneNumber': phoneNumber,
    'winningTeam': winningTeam,
    'predictedScore': predictedScore,
    'prizeType': prizeType,
    'prizeDescription': prizeDescription,
    'prizeData': prizeData,
    'winnerCode': winnerCode,
    'submissionTimestamp': submissionTimestamp != null
        ? Timestamp.fromDate(submissionTimestamp!)
        : FieldValue.serverTimestamp(),
    'redeemed': redeemed,
    'calculationDate': calculationDate != null
        ? Timestamp.fromDate(calculationDate!)
        : FieldValue.serverTimestamp(),
    'confirmedAt': FieldValue.serverTimestamp(),
  };

  String get medal {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }
}
