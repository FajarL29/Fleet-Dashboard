class DrowsinessModel {
  final int id;
  final String status;
  final String imgPath;
  final String powerbiPreview;
  final DateTime time;

  DrowsinessModel({
    required this.id,
    required this.status,
    required this.imgPath,
    required this.powerbiPreview,
    required this.time,
  });

  factory DrowsinessModel.fromJson(Map<String, dynamic> json) {
    return DrowsinessModel(
      id: json['drowsiness_id'],
      status: json['status'] ?? "Unknown",
      imgPath: json['img_path'] ?? "",
      powerbiPreview: json['powerbi_preview'] ?? "",
      time: DateTime.parse(json['time']),
    );
  }
}