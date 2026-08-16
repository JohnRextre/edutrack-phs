import 'package:http/http.dart' as http;

/// Result of a QR code generation request via the external REST API.
class QrCodeResult {
  const QrCodeResult({
    required this.success,
    this.statusCode,
    this.imageUrl,
    required this.message,
  });

  final bool success;
  final int? statusCode;
  final String? imageUrl;
  final String message;

  String get statusLabel {
    if (statusCode == null) return 'Status: N/A';
    return 'Status: $statusCode ${_statusText(statusCode!)}';
  }

  Map<String, dynamic> toMap() => {
        'success': success,
        'statusCode': statusCode,
        'imageUrl': imageUrl,
        'message': message,
      };

  static String _statusText(int code) {
    switch (code) {
      case 200:
        return 'OK';
      case 400:
        return 'Bad Request';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      default:
        return '';
    }
  }
}

/// Generates QR codes dynamically from resource payload text using QuickChart.io.
class QrService {
  QrService._();

  static const String systemIdentifier = 'EduTrack PHS';
  static const String _baseUrl = 'https://quickchart.io/qr';
  static const Duration _timeout = Duration(seconds: 12);

  /// Builds a multi-line QR payload from the latest resource fields.
  static String buildResourcePayload({
    required String itemCode,
    String? itemName,
    String? mainCategory,
    String? subCategory,
  }) {
    final trimmedCode = itemCode.trim();
    if (trimmedCode.isEmpty) return '';

    final trimmedName = itemName?.trim() ?? '';
    final trimmedMainCategory = mainCategory?.trim() ?? '';
    final trimmedSubCategory = subCategory?.trim() ?? '';

    return [
      'System: $systemIdentifier',
      'Item Name: $trimmedName',
      'Item Code: $trimmedCode',
      'Category: $trimmedMainCategory / $trimmedSubCategory',
    ].join('\n');
  }

  /// Validates [qrPayload], calls the QR API, and returns a structured result.
  static Future<QrCodeResult> generateQrCode(String qrPayload) async {
    final trimmedPayload = qrPayload.trim();
    if (trimmedPayload.isEmpty) {
      return const QrCodeResult(
        success: false,
        message: 'Resource code cannot be empty.',
      );
    }

    final imageUrl =
        '$_baseUrl?text=${Uri.encodeComponent(trimmedPayload)}&size=200';

    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(_timeout);

      if (response.statusCode != 200) {
        return QrCodeResult(
          success: false,
          statusCode: response.statusCode,
          message:
              'Unable to generate QR code. Server returned status ${response.statusCode}.',
        );
      }

      if (response.bodyBytes.isEmpty) {
        return QrCodeResult(
          success: false,
          statusCode: response.statusCode,
          message:
              'Unable to generate QR code. The server returned an empty response.',
        );
      }

      return QrCodeResult(
        success: true,
        statusCode: response.statusCode,
        imageUrl: imageUrl,
        message: 'QR code generated successfully.',
      );
    } on http.ClientException {
      return const QrCodeResult(
        success: false,
        message:
            'Unable to generate QR code. Please check your internet connection.',
      );
    } catch (_) {
      return const QrCodeResult(
        success: false,
        message:
            'Unable to generate QR code. Please check your internet connection.',
      );
    }
  }
}
