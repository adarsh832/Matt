import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/ai_model.dart';
import '../models/conversation.dart';

class ApiService {
  final StorageService _storageService;

  ApiService(this._storageService);

  Future<bool> checkHealth(String serverUrl) async {
    try {
      final uri = Uri.parse('$serverUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> pairDevice(String serverUrl, String deviceName, String pairingToken) async {
    try {
      final uri = Uri.parse('$serverUrl/pair');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_name': deviceName,
          'pairing_token': pairingToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['device_id'] as String?;
      }
    } catch (e) {
      // Handle or log error accordingly
    }
    return null;
  }
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getDeviceToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'X-Device-Token': token,
    };
  }

  Future<String?> _getServerUrl() async {
    return await _storageService.getServerUrl();
  }

  Future<List<AiModel>> getModels() async {
    try {
      final baseUrl = await _getServerUrl();
      if (baseUrl == null) throw Exception('Server URL not set');

      final uri = Uri.parse('$baseUrl/models');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AiModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }

  Future<bool> loadModel(String modelId) async {
    try {
      final baseUrl = await _getServerUrl();
      if (baseUrl == null) throw Exception('Server URL not set');

      // We use Uri.encodeComponent to handle any special characters in the model ID
      final uri = Uri.parse('$baseUrl/models/${Uri.encodeComponent(modelId)}/load');
      final headers = await _getHeaders();

      // We give it a generous timeout (120 seconds) because model loading can take time
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 120));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final baseUrl = await _getServerUrl();
      if (baseUrl == null) throw Exception('Server URL not set');

      final uri = Uri.parse('$baseUrl/conversations');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  Future<Conversation> getConversation(String id) async {
    try {
      final baseUrl = await _getServerUrl();
      if (baseUrl == null) throw Exception('Server URL not set');

      final uri = Uri.parse('$baseUrl/conversations/$id');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }

  Future<bool> deleteConversation(String id) async {
    try {
      final baseUrl = await _getServerUrl();
      if (baseUrl == null) throw Exception('Server URL not set');

      final uri = Uri.parse('$baseUrl/conversations/$id');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Stream<Map<String, dynamic>> streamChat({
    String? conversationId,
    required String model,
    required String message,
    required String personality,
  }) async* {
    final baseUrl = await _getServerUrl();
    if (baseUrl == null) throw Exception('Server URL not set');

    final uri = Uri.parse('$baseUrl/chat');
    final headers = await _getHeaders();

    final request = http.Request('POST', uri);
    request.headers.addAll(headers);
    request.body = jsonEncode({
      if (conversationId != null) 'conversation_id': conversationId,
      'model': model,
      'message': message,
      'personality': personality,
    });

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final stream = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr.isEmpty) continue;
            
            try {
              final data = jsonDecode(dataStr) as Map<String, dynamic>;
              yield data;
            } catch (e) {
              // Ignore invalid JSON chunks
            }
          }
        }
      } else {
        throw Exception('Chat stream failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in chat stream: $e');
    }
  }
}
