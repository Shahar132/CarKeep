class VehicleDateUtils {
  static String getExpiryText(
    DateTime? expiryDate, {
    DateTime? currentDate,
  }) {
    if (expiryDate == null) {
      return 'לא הוגדר';
    }

    final now =
        currentDate ?? DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    final days =
        expiry.difference(today).inDays;

    if (days < -1) {
      return 'פג לפני ${days.abs()} ימים';
    }

    if (days == -1) {
      return 'פג אתמול';
    }

    if (days == 0) {
      return 'פג היום';
    }

    if (days == 1) {
      return 'פג מחר';
    }

    return 'בעוד $days ימים';
  }
}