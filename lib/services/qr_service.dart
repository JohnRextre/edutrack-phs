import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a QR code generation request via the external REST API.
class QrCodeResult {
  const QrCodeResult({
    required this.success,
    this.statusCode,
    this.imageUrl,
    required this.message,
    this.jsonResponse,
  });

  final bool success;
  final int? statusCode;
  final String? imageUrl;
  final String message;
  final Map<String, dynamic>? jsonResponse;

  String get statusLabel {
    if (statusCode == null) return 'Status: N/A';
    return 'Status: $statusCode ${_statusText(statusCode!)}';
  }

  Map<String, dynamic> toMap() => {
        'success': success,
        'statusCode': statusCode,
        'imageUrl': imageUrl,
        'message': message,
        'jsonResponse': jsonResponse,
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
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

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
      return QrCodeResult(
        success: false,
        message: 'Resource code cannot be empty.',
        jsonResponse: _buildJsonResponse(
          requestUrl: '',
          payloadSent: '',
          statusOverride: 'Validation Error',
        ),
      );
    }

    final requestUrl =
        '$_baseUrl?text=${Uri.encodeComponent(trimmedPayload)}&size=200';

    try {
      final response = await http.get(Uri.parse(requestUrl)).timeout(_timeout);
      final jsonResponse = _buildJsonResponse(
        statusCode: response.statusCode,
        requestUrl: requestUrl,
        payloadSent: trimmedPayload,
        contentType: response.headers['content-type'],
      );
      _logJsonResponse(jsonResponse);

      if (response.statusCode != 200) {
        return QrCodeResult(
          success: false,
          statusCode: response.statusCode,
          message:
              'Unable to generate QR code. Server returned status ${response.statusCode}.',
          jsonResponse: jsonResponse,
        );
      }

      if (response.bodyBytes.isEmpty) {
        return QrCodeResult(
          success: false,
          statusCode: response.statusCode,
          message:
              'Unable to generate QR code. The server returned an empty response.',
          jsonResponse: jsonResponse,
        );
      }

      return QrCodeResult(
        success: true,
        statusCode: response.statusCode,
        imageUrl: requestUrl,
        message: 'QR code generated successfully.',
        jsonResponse: jsonResponse,
      );
    } on http.ClientException {
      return QrCodeResult(
        success: false,
        message:
            'Unable to generate QR code. Please check your internet connection.',
        jsonResponse: _buildJsonResponse(
          requestUrl: requestUrl,
          payloadSent: trimmedPayload,
          statusOverride: 'Network Error',
        ),
      );
    } catch (_) {
      return QrCodeResult(
        success: false,
        message:
            'Unable to generate QR code. Please check your internet connection.',
        jsonResponse: _buildJsonResponse(
          requestUrl: requestUrl,
          payloadSent: trimmedPayload,
          statusOverride: 'Network Error',
        ),
      );
    }
  }

  static Map<String, dynamic> _buildJsonResponse({
    int? statusCode,
    required String requestUrl,
    required String payloadSent,
    String? contentType,
    String? statusOverride,
  }) {
    return {
      'statusCode': statusCode,
      'status': statusOverride ??
          (statusCode != null ? QrCodeResult._statusText(statusCode) : 'Error'),
      'contentType': contentType ?? '',
      'requestUrl': requestUrl,
      'payloadSent': payloadSent,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static void _logJsonResponse(Map<String, dynamic> jsonResponse) {
    debugPrint(
      '[QrService] JSON Response Sample:\n${_jsonEncoder.convert(jsonResponse)}',
    );
  }
}
