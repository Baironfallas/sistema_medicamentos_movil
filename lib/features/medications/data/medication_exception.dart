class MedicationException implements Exception {
  const MedicationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
