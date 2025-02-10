import 'dart:convert';
import 'dart:io';
import '../utils/constants.dart';

class DocumentUploadService {
  // 💡 Simple document upload with direct endpoint
  Future<bool> uploadDocument({
    required String nationalId,
    required String documentType,
    required String filePath,
    required String fileName,
    required String productType, // 'card' or 'loan'
  }) async {
    HttpClient? client;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Error: File not found at path: $filePath');
        return false;
      }

      // 💡 Create multipart request using HttpClient
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final uri = Uri.parse('${Constants.apiBaseUrl}/documents/upload');
      final request = await client.postUrl(uri);

      // Generate a unique boundary
      final boundary = '-------------${DateTime.now().millisecondsSinceEpoch}';
      
      // First set default headers
      Constants.defaultHeaders.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers.set(key, value);
        }
      });
      
      // Then set the multipart form-data content type
      request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

      // Prepare the request body
      final fullDocumentType = '$productType/$documentType';
      var requestBody = <List<int>>[];

      // Add form fields
      requestBody.add(utf8.encode('--$boundary\r\n'));
      requestBody.add(utf8.encode('Content-Disposition: form-data; name="nationalId"\r\n\r\n'));
      requestBody.add(utf8.encode('$nationalId\r\n'));

      requestBody.add(utf8.encode('--$boundary\r\n'));
      requestBody.add(utf8.encode('Content-Disposition: form-data; name="documentType"\r\n\r\n'));
      requestBody.add(utf8.encode('$fullDocumentType\r\n'));

      // Add file
      requestBody.add(utf8.encode('--$boundary\r\n'));
      requestBody.add(utf8.encode('Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'));
      requestBody.add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
      requestBody.add(await file.readAsBytes());
      requestBody.add(utf8.encode('\r\n'));

      // Add closing boundary
      requestBody.add(utf8.encode('--$boundary--\r\n'));

      // Calculate total length
      var totalLength = 0;
      for (var bytes in requestBody) {
        totalLength += bytes.length;
      }
      request.contentLength = totalLength;

      // Write all parts to the request
      for (var bytes in requestBody) {
        request.add(bytes);
      }

      print('Uploading document with:');
      print('National ID: $nationalId');
      print('Document Type: $fullDocumentType');
      print('File Name: $fileName');
      print('File Path: $filePath');
      print('Upload URL: ${Constants.apiBaseUrl}/documents/upload');
      print('Headers: ${request.headers}');
      print('Content-Type: ${request.headers.value('content-type')}');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('Document upload response status: ${response.statusCode}');
      print('Document upload response body: $responseBody');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return responseData['success'] ?? false;
      } else {
        print('Error: Upload failed with status ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('Error uploading document: $e');
      return false;
    } finally {
      client?.close();
    }
  }

  // 💡 Simple document status check
  Future<String?> getDocumentStatus({
    required String nationalId,
    required String documentType,
    required String productType, // 'card' or 'loan'
  }) async {
    HttpClient? client;
    try {
      final fullDocumentType = '$productType/$documentType';
      
      // 💡 Create HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(
        Uri.parse('${Constants.apiBaseUrl}/documents/status/$nationalId/$fullDocumentType')
      );
      
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Document status response: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return responseData['status'];
      }
      
      return null;
    } catch (e) {
      print('Error getting document status: $e');
      return null;
    } finally {
      client?.close();
    }
  }
} 