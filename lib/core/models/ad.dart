class Ad {
  final String id;
  final String title;
  final String? imageUrl;
  final String status;
  final String? facilityId;

  Ad({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.status,
    this.facilityId,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        imageUrl: json['image_url'],
        status: json['status'] ?? 'pending',
        facilityId: json['facility_id']?.toString(),
      );
}

class AppBanner {
  final String id;
  final String? imageUrl;
  final String? title;
  final String? linkUrl;

  AppBanner({required this.id, this.imageUrl, this.title, this.linkUrl});

  factory AppBanner.fromJson(Map<String, dynamic> json) => AppBanner(
        id: json['id'].toString(),
        imageUrl: json['image_url'],
        title: json['title'],
        linkUrl: json['link_url'],
      );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        body: json['body'] ?? json['message'] ?? '',
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'],
      );
}

class Review {
  final String id;
  final String reviewerName;
  final double rating;
  final String? comment;
  final String? createdAt;

  Review({
    required this.id,
    required this.reviewerName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        reviewerName: json['reviewer_name'] ?? json['patient_name'] ?? 'Patient',
        rating: (json['rating'] ?? 0).toDouble(),
        comment: json['comment'],
        createdAt: json['created_at'],
      );
}

class ReviewSummary {
  final double average;
  final int total;
  ReviewSummary({required this.average, required this.total});
  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
        average: (json['average_rating'] ?? json['average'] ?? 0).toDouble(),
        total: json['total_reviews'] ?? json['total'] ?? 0,
      );
}
