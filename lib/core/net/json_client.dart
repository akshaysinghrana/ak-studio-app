import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// A user-facing failure from an online service (never contains keys).
class OnlineFailure implements Exception {
  const OnlineFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Small JSON-over-HTTPS helper shared by the online clients (ADR 0004).
class JsonClient {
  JsonClient(this._http, {this.timeout = const Duration(seconds: 15)});

  final http.Client _http;
  final Duration timeout;

  /// GETs [uri] and decodes a JSON object. [describeError] turns a non-2xx
  /// response into a message; the default is generic.
  Future<Map<String, dynamic>> get(
    Uri uri, {
    Map<String, String>? headers,
    String Function(int status, Map<String, dynamic>? body)? describeError,
  }) async {
    final http.Response response;
    try {
      response = await _http.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw const OnlineFailure('The service took too long to answer.');
    } on SocketException {
      throw const OnlineFailure(
        'No connection. Online search needs the internet; your library '
        'still works offline.',
      );
    } on http.ClientException {
      throw const OnlineFailure('Could not reach the service.');
    }
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OnlineFailure(
        describeError?.call(response.statusCode, body) ??
            'The service returned an error (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (body == null) {
      throw const OnlineFailure('The service sent an unexpected answer.');
    }
    return body;
  }
}
