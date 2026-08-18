/// Matches backend's WithdrawalOut (GET /rewards/withdrawals/{facility_id}).
class Withdrawal {
  final String id;
  final String facilityId;
  final num amount;
  final String status;
  final String? payoutTransactionRef;
  final String? failureReason;
  final String createdAt;

  Withdrawal({
    required this.id,
    required this.facilityId,
    required this.amount,
    required this.status,
    this.payoutTransactionRef,
    this.failureReason,
    required this.createdAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: json['id'].toString(),
        facilityId: (json['facility_id'] ?? '').toString(),
        amount: json['amount'] ?? 0,
        status: json['status'] ?? '',
        payoutTransactionRef: json['payout_transaction_ref'],
        failureReason: json['failure_reason'],
        createdAt: json['created_at'] ?? '',
      );
}
