import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';

class ExerciseApiClient {
  // Configuration for different API sources
  static const String _rapidApiUrl = 'https://exercisedb.p.rapidapi.com';
  static const String _rapidApiKey = 'YOUR_RAPIDAPI_KEY_HERE';
  
  // Self-hosted Vercel deployment (recommended - FREE!)
  static const String _selfHostedUrl = 'https://exercise-db-slwr.vercel.app';
  
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  
  final http.Client _client;
  final bool _useSelfHosted;
  
  ExerciseApiClient({
    http.Client? client, 
    bool useSelfHosted = true, // Default to self-hosted (free)
  }) : _client = client ?? http.Client(),
       _useSelfHosted = useSelfHosted;

  String get _baseUrl => _useSelfHosted ? _selfHostedUrl : _rapidApiUrl;
  
  Map<String, String> get _headers {
    if (_useSelfHosted) {
      // Self-hosted: no API key needed!
      return {
        'Content-Type': 'application/json',
      };
    } else {
      // RapidAPI: requires API key and host header
      return {
        'X-RapidAPI-Key': _rapidApiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
        'Content-Type': 'application/json',
      };
    }
  }

  /// Get all exercises with sorting and search
  Future<List<Exercise>> getAllExercises({
    String? search,
    String? sortBy,
    String? sortOrder,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = '/api/v1/exercises';
      
      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle response wrapper format: {success, metadata, data}
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          debugPrint('✅ API Success: ${responseData['data'].length} exercises'); // Debug log
          
          final List<dynamic> jsonList = responseData['data'];
          List<Exercise> exercises = jsonList.map((json) => Exercise.fromJson(json)).toList();
          
          return exercises;
        } else {
          throw ApiException('Invalid response format - success: ${responseData['success']}, data type: ${responseData['data'].runtimeType}');
        }
      } else {
        throw ApiException('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getAllExercises error: $e'); // Debug log
      throw ApiException('Error fetching exercises: $e');
    }
  }

  /// Get exercises by body part
  Future<List<Exercise>> getExercisesByBodyPart(String bodyPart, {
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = '/api/v1/bodyparts/${Uri.encodeComponent(bodyPart)}/exercises';
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle response wrapper format
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          debugPrint('✅ Body part "$bodyPart": ${responseData['data'].length} exercises'); // Debug log
          
          final List<dynamic> jsonList = responseData['data'];
          return jsonList.map((json) => Exercise.fromJson(json)).toList();
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load exercises for body part: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getExercisesByBodyPart error: $e'); // Debug log
      throw ApiException('Error fetching exercises by body part: $e');
    }
  }

  /// Search exercises with fuzzy matching
  Future<List<Exercise>> searchExercises(
    String query, {
    double threshold = 0.3,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = '/api/v1/exercises/search';
      
      final queryParams = <String, String>{
        'q': query,
        'threshold': threshold.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      
      debugPrint('🔍 SEARCH $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          debugPrint('✅ Search "$query": ${responseData['data'].length} exercises'); // Debug log
          
          final List<dynamic> jsonList = responseData['data'];
          return jsonList.map((json) => Exercise.fromJson(json)).toList();
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ searchExercises error: $e'); // Debug log
      throw ApiException('Error searching exercises: $e');
    }
  }

  /// Advanced exercise filtering
  Future<List<Exercise>> filterExercises({
    String? search,
    List<String>? muscles,
    List<String>? equipment,
    List<String>? bodyParts,
    String? sortBy,
    String? sortOrder,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = '/api/v1/exercises/filter';
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (muscles != null && muscles.isNotEmpty) {
        queryParams['muscles'] = muscles.join(',');
      }
      if (equipment != null && equipment.isNotEmpty) {
        queryParams['equipment'] = equipment.join(',');
      }
      if (bodyParts != null && bodyParts.isNotEmpty) {
        queryParams['bodyParts'] = bodyParts.join(',');
      }
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      
      debugPrint('🔍 FILTER $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          debugPrint('✅ Filter: ${responseData['data'].length} exercises'); // Debug log
          
          final List<dynamic> jsonList = responseData['data'];
          return jsonList.map((json) => Exercise.fromJson(json)).toList();
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Filter failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ filterExercises error: $e'); // Debug log
      throw ApiException('Error filtering exercises: $e');
    }
  }

  /// Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment, {
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final endpoint = '/api/v1/equipments/${Uri.encodeComponent(equipment)}/exercises';
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          debugPrint('✅ Equipment "$equipment": ${responseData['data'].length} exercises'); // Debug log
          
          final List<dynamic> jsonList = responseData['data'];
          return jsonList.map((json) => Exercise.fromJson(json)).toList();
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load exercises for equipment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getExercisesByEquipment error: $e'); // Debug log
      throw ApiException('Error fetching exercises by equipment: $e');
    }
  }

  /// Get a specific exercise by ID
  Future<Exercise> getExerciseById(String exerciseId) async {
    try {
      final endpoint = '/api/v1/exercises/$exerciseId';
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is Map<String, dynamic>) {
          
          debugPrint('✅ Exercise "$exerciseId" loaded'); // Debug log
          
          return Exercise.fromJson(responseData['data']);
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load exercise: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getExerciseById error: $e'); // Debug log
      throw ApiException('Error fetching exercise by ID: $e');
    }
  }

  /// Get all available body parts
  Future<List<String>> getBodyParts() async {
    try {
      final endpoint = '/api/v1/bodyparts';
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          final List<dynamic> jsonList = responseData['data'];
          
          // Body parts are returned as objects with "name" field: {"name": "chest"}
          final bodyParts = jsonList
              .map((item) => item is Map<String, dynamic> ? item['name'] as String : item.toString())
              .toList();
          
          debugPrint('✅ Loaded ${bodyParts.length} body parts: $bodyParts'); // Debug log
          
          return bodyParts;
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load body parts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getBodyParts error: $e'); // Debug log
      throw ApiException('Error fetching body parts: $e');
    }
  }

  /// Get all available equipment types
  Future<List<String>> getEquipmentTypes() async {
    try {
      final endpoint = '/api/v1/equipments';
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          final List<dynamic> jsonList = responseData['data'];
          
          // Equipment types are returned as objects with "name" field: {"name": "barbell"}
          final equipmentTypes = jsonList
              .map((item) => item is Map<String, dynamic> ? item['name'] as String : item.toString())
              .toList();
          
          debugPrint('✅ Loaded ${equipmentTypes.length} equipment types: $equipmentTypes'); // Debug log
          
          return equipmentTypes;
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load equipment types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getEquipmentTypes error: $e'); // Debug log
      throw ApiException('Error fetching equipment types: $e');
    }
  }

  /// Get all available muscles
  Future<List<String>> getMuscles() async {
    try {
      final endpoint = '/api/v1/muscles';
      final uri = Uri.parse('$_baseUrl$endpoint');
      
      debugPrint('🔍 GET $uri'); // Debug log
      
      final response = await _makeRequest(() => _client.get(uri, headers: _headers));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && 
            responseData['success'] == true && 
            responseData['data'] is List) {
          
          final List<dynamic> jsonList = responseData['data'];
          
          // Muscles are returned as objects with "name" field: {"name": "biceps"}
          final muscles = jsonList
              .map((item) => item is Map<String, dynamic> ? item['name'] as String : item.toString())
              .toList();
          
          debugPrint('✅ Loaded ${muscles.length} muscles: $muscles'); // Debug log
          
          return muscles;
        } else {
          throw ApiException('Invalid response format');
        }
      } else {
        throw ApiException('Failed to load muscles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getMuscles error: $e'); // Debug log
      throw ApiException('Error fetching muscles: $e');
    }
  }

  /// Make HTTP request with retry logic
  Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        debugPrint('🌐 Making HTTP request (attempt ${attempts + 1}/$_maxRetries)');
        final response = await request().timeout(_timeout);
        
        debugPrint('📊 HTTP Response: ${response.statusCode} - ${response.reasonPhrase}');
        if (response.body.isNotEmpty) {
          debugPrint('📄 Response body preview: ${response.body.length} chars');
          // Print first 200 chars for debugging
          debugPrint('🔍 Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        }
        
        // If request succeeded or has a client/server error (don't retry)
        if (response.statusCode < 500) {
          return response;
        }
        
        // Server error - retry
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts)); // Exponential backoff
        }
      } on SocketException catch (e) {
        debugPrint('🚨 SocketException: $e');
        // Network error - retry
        attempts++;
        if (attempts >= _maxRetries) {
          throw ApiException('Network error: Unable to connect to ExerciseDB API - $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } on http.ClientException catch (e) {
        debugPrint('🚨 ClientException: $e');
        // Client error - retry
        attempts++;
        if (attempts >= _maxRetries) {
          throw ApiException('Request error: Failed to connect to ExerciseDB API - $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } catch (e) {
        debugPrint('🚨 Unexpected error: $e');
        attempts++;
        if (attempts >= _maxRetries) {
          throw ApiException('Unexpected error: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    
    throw ApiException('Failed to complete request after $_maxRetries attempts');
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}