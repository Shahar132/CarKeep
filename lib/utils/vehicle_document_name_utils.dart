class VehicleDocumentNameUtils {
  static String vehicleLicense(
    DateTime expiryDate,
  ) {
    return 'רישיון רכב '
        '${expiryDate.year} - '
        '${_formatDate(expiryDate)}';
  }

  static String test(
    DateTime expiryDate,
  ) {
    return 'טסט '
        '${expiryDate.year} - '
        '${_formatDate(expiryDate)}';
  }

  static String insurance({
    required String insuranceType,
    required DateTime expiryDate,
  }) {
    return '$insuranceType '
        '${expiryDate.year} - '
        '${_formatDate(expiryDate)}';
  }

  static String service({
    required int mileage,
    required DateTime serviceDate,
  }) {
    return 'טיפול '
        '${_formatNumber(mileage)} ק"מ - '
        '${_formatDate(serviceDate)}';
  }

  static String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatNumber(
    int number,
  ) {
    final text = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final positionFromEnd =
          text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 &&
          positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}