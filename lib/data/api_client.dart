import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Kesalahan komunikasi dengan API, dengan pesan yang siap ditampilkan.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Mengubah error apa pun menjadi pesan untuk pengguna.
String pesanError(Object e) =>
    e is ApiException ? e.message : 'Terjadi kesalahan: $e';

/// Klien HTTP JSON tipis. Menggantikan DatabaseHelper (sqflite) pada
/// workbook: Flutter tidak berbicara langsung ke MySQL, melainkan lewat API.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;

  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) =>
      _kirim(() => _client.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, Object?> body) => _kirim(
        () => _client.post(_uri(path),
            headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> put(String path, Map<String, Object?> body) => _kirim(
        () =>
            _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> delete(String path) =>
      _kirim(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _kirim(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(
          'Server tidak merespons. Pastikan API StudyLog sedang berjalan.');
    } on SocketException {
      throw const ApiException(
          'Tidak dapat terhubung ke server. Periksa API dan alamatnya.');
    } on http.ClientException {
      throw const ApiException(
          'Tidak dapat terhubung ke server. Periksa API dan alamatnya.');
    }

    dynamic body;
    if (res.bodyBytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          throw const ApiException('Respons server tidak valid.');
        }
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final pesan = body is Map && body['error'] is String
        ? body['error'] as String
        : 'Permintaan gagal (${res.statusCode}).';
    throw ApiException(pesan, statusCode: res.statusCode);
  }
}
