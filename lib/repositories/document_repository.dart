import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';

abstract interface class DocumentRepository {
  Future<List<Map<String, dynamic>>> listMyDocuments();
  Future<Map<String, dynamic>> uploadMyDocument(String filePath, {String? description});

  /// Web-safe upload: takes the picked file's bytes directly (no filesystem),
  /// so it works on Chrome where [uploadMyDocument]'s File path is unavailable.
  Future<Map<String, dynamic>> uploadMyDocumentBytes(
      Uint8List bytes, String fileName, {String? description});

  Future<void> deleteMyDocument(String id);
}

class ApiDocumentRepository implements DocumentRepository {
  ApiDocumentRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> listMyDocuments() async {
    try {
      final response = await _client.get(ApiConfig.documentsMe) as Map<String, dynamic>;
      // Backend shape: { owner, documents: { data: [...], pagination } }.
      // Fall back to a flat `data` list for older/other response shapes.
      final docs = response['documents'];
      final List<dynamic> data = docs is Map<String, dynamic>
          ? (docs['data'] as List<dynamic>? ?? [])
          : (response['data'] as List<dynamic>? ?? []);
      return data.cast<Map<String, dynamic>>();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse documents: $e'); }
  }

  @override
  Future<Map<String, dynamic>> uploadMyDocument(String filePath, {String? description}) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (description != null) 'description': description,
      });
      final response = await _client.post(
        ApiConfig.documentsMe,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ) as Map<String, dynamic>;
      return response['data'] as Map<String, dynamic>? ?? response;
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to upload document: $e'); }
  }

  @override
  Future<Map<String, dynamic>> uploadMyDocumentBytes(
      Uint8List bytes, String fileName, {String? description}) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        if (description != null) 'description': description,
      });
      final response = await _client.post(
        ApiConfig.documentsMe,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ) as Map<String, dynamic>;
      return response['data'] as Map<String, dynamic>? ?? response;
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to upload document: $e'); }
  }

  @override
  Future<void> deleteMyDocument(String id) async {
    try {
      await _client.delete(ApiConfig.documentMe(id));
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to delete document: $e'); }
  }
}

class MockDocumentRepository implements DocumentRepository {
  @override
  Future<List<Map<String, dynamic>>> listMyDocuments() async => [];

  @override
  Future<Map<String, dynamic>> uploadMyDocument(String filePath, {String? description}) async =>
      {'id': 'mock-${DateTime.now().millisecondsSinceEpoch}', 'fileName': filePath.split('/').last};

  @override
  Future<Map<String, dynamic>> uploadMyDocumentBytes(
          Uint8List bytes, String fileName, {String? description}) async =>
      {'id': 'mock-${DateTime.now().millisecondsSinceEpoch}', 'fileName': fileName};

  @override
  Future<void> deleteMyDocument(String id) async {}
}
