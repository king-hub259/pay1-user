import 'package:intl/intl.dart';

class DateConverter {
  static String estimatedDate(
    DateTime dateTime, {
    String format = 'dd MMM yyyy',
  }) {
    return DateFormat(format).format(dateTime);
  }

  static String estimatedDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy - hh:mm:ss a').format(dateTime);
  }

  static String estimatedTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  static String formatTimeAndDate(DateTime dateTime) {
    try {
      return DateFormat('h:mma dd-MM-yyyy').format(dateTime).toLowerCase();
    } catch (e) {
      return DateFormat(
        'h:mma dd-MM-yyyy',
      ).format(DateTime.now()).toLowerCase();
    }
  }

  static DateTime convertStringToDatetime(String dateTime) {
    return DateFormat("yyyy-MM-ddTHH:mm:ss.mmm").parse(dateTime);
  }

  static String convertIsoToString(
    String dateTime, {
    String outputFormat = "dd MMM yyyy hh:mm aa",
  }) {
    DateTime time = convertStringToDatetime(dateTime);
    String result = DateFormat(outputFormat).format(time);
    return result;
  }

  static String isoToLocalDateAndTime(
    String dateTime, {
    String errorResult = '--',
  }) {
    String date = '';
    if (dateTime.isEmpty || dateTime == 'null') {
      date = '';
    }
    try {
      date = DateFormat('dd MMM yyyy').format(isoStringToLocalDate(dateTime));
    } catch (v) {
      date = '';
    }
    String time = isoStringToLocalTimeOnly(dateTime);
    return '$date, $time';
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateFormat(
      'yyyy-MM-ddTHH:mm:ss.SSS',
    ).parse(dateTime, true).toLocal();
  }

  static String isoStringToLocalTimeOnly(String dateTime) {
    return DateFormat('hh:mm aa').format(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    try {
      return DateFormat('dd MMM yyyy').format(isoStringToLocalDate(dateTime));
    } catch (v) {
      return "--";
    }
  }

  static String getFormattedSubtractTime(
    String time, {
    bool numericDates = false,
  }) {
    final date1 = DateTime.now();
    final isoDate = isoStringToLocalDate(time);
    final difference = date1.difference(isoDate);

    if ((difference.inDays / 365).floor() >= 1) {
      int year = (difference.inDays / 365).floor();
      return '$year year ago';
    } else if ((difference.inDays / 30).floor() >= 1) {
      int month = (difference.inDays / 30).floor();
      return '$month month ago';
    } else if ((difference.inDays / 7).floor() >= 1) {
      int week = (difference.inDays / 7).floor();
      return '$week week ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
}
