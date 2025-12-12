import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:water_readings_app/core/services/secure_storage_service.dart';
import 'package:water_readings_app/core/config/environment.dart';

class ApiService {
  static String get baseUrl => Environment.apiBaseUrl;
  
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  ApiService(this._secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor to add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle authentication errors (401 or 500 with token error)
        final isAuthError = error.response?.statusCode == 401 ||
            (error.response?.statusCode == 500 && 
             error.response?.data?['details']?['stack']?.contains('Invalid access token') == true);
             
        if (isAuthError) {
          try {
            await _refreshToken();
            // Retry the request
            final newToken = await _secureStorage.getToken();
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // Refresh failed, clear storage
            await _secureStorage.clearAll();
            // Token refresh failed, storage cleared
          }
        }
        handler.next(error);
      },
    ));

    // Logging interceptor (disabled for production)
    // Uncomment for debugging API requests
    // _dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   requestHeader: true,
    //   responseHeader: false,
    //   error: true,
    //   logPrint: (obj) => print('[API] $obj'),
    // ));
  }

  Future<bool> _isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
           connectivityResult.contains(ConnectivityResult.wifi);
  }

  Future<void> _refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });

    final newToken = response.data['accessToken'];
    await _secureStorage.storeToken(newToken);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors - clear local storage anyway
    } finally {
      await _secureStorage.clearAll();
    }
  }

  // OTP authentication endpoints
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.post('/auth/otp/send', data: {
      'phone': phoneNumber,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String code) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.post('/auth/otp/verify', data: {
      'phone': phoneNumber,
      'code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.post('/auth/otp/resend', data: {
      'phone': phoneNumber,
    });
    return response.data;
  }

  // Condominium endpoints
  Future<List<dynamic>> getCondominiums() async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    // Request condominiums with nested blocks and units data
    final response = await _dio.get('/condominiums', queryParameters: {
      'include': 'blocks,units',
    });
    return response.data['condominiums'] ?? response.data;
  }

  Future<Map<String, dynamic>> getCondominium(String id) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/condominiums/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createCondominium(Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createCondominiumWithStructure(Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums/with-structure', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createBlock(String condominiumId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums/$condominiumId/blocks', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createUnit(String condominiumId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums/$condominiumId/units', data: data);
    return response.data;
  }

  // Blocks and Units
  Future<List<dynamic>> getCondominiumBlocks(String condominiumId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/condominiums/$condominiumId/blocks');
    return response.data;
  }

  Future<List<dynamic>> getCondominiumUnits(String condominiumId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/condominiums/$condominiumId/units');
    return response.data['units'] ?? response.data;
  }

  // Periods
  Future<List<dynamic>> getCondominiumPeriods(String condominiumId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/condominium/$condominiumId');
    return response.data['periods'] ?? response.data;
  }

  Future<Map<String, dynamic>> createPeriod(String condominiumId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    // Add condominiumId to the data since the endpoint expects it in the body
    final requestData = {
      'condominiumId': condominiumId,
      ...data,
    };
    
    final response = await _dio.post('/periods', data: requestData);
    return response.data;
  }

  // Readings
  Future<Map<String, dynamic>> createReading(String periodId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/periods/$periodId/readings', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateReading(String periodId, String readingId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/periods/$periodId/readings/$readingId', data: data);
    return response.data;
  }

  Future<List<dynamic>> getPeriodReadings(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/$periodId/readings');
    return response.data['readings'] ?? response.data;
  }

  Future<List<dynamic>> getPendingUnits(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/$periodId/pending');
    return response.data['units'] ?? response.data;
  }

  Future<Map<String, dynamic>> validateReading(String periodId, String readingId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/periods/$periodId/readings/$readingId/validate', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> validateAllReadings(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/periods/$periodId/readings/validate-all');
    return response.data;
  }

  // File upload
  Future<String> uploadPhoto(String filePath, String readingId, int photoNumber) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      'readingId': readingId,
      'photoNumber': photoNumber,
    });

    final response = await _dio.post('/readings/upload-photo', data: formData);
    return response.data['url'];
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Clear authentication when token is invalid
  Future<void> clearAuthenticationData() async {
    await _secureStorage.clearAll();
  }

  // Residents endpoints
  Future<Map<String, dynamic>> createResident(String condominiumId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums/$condominiumId/residents', data: data);
    return response.data;
  }

  Future<List<dynamic>> getCondominiumResidents(String condominiumId, {int? page, int? limit, String? search}) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final response = await _dio.get('/condominiums/$condominiumId/residents', queryParameters: queryParams);
    return response.data['residents'] ?? response.data;
  }

  Future<Map<String, dynamic>> updateResident(String condominiumId, String residentId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/condominiums/$condominiumId/residents/$residentId', data: data);
    return response.data;
  }

  // Multiple residents per unit endpoints
  Future<Map<String, dynamic>> addResidentToUnit(String condominiumId, String unitId, String residentId, {bool isPrimary = false}) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/condominiums/$condominiumId/units/$unitId/residents', data: {
      'residentId': residentId,
      'isPrimary': isPrimary,
    });
    return response.data;
  }

  Future<void> removeResidentFromUnit(String condominiumId, String unitId, String residentId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    await _dio.delete('/condominiums/$condominiumId/units/$unitId/residents/$residentId');
  }

  Future<List<dynamic>> getUnitResidents(String condominiumId, String unitId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/condominiums/$condominiumId/units/$unitId/residents');
    return response.data['residents'] ?? [];
  }

  // Legacy single resident methods (for backwards compatibility)
  Future<Map<String, dynamic>> assignResidentToUnit(String condominiumId, String unitId, String residentId) async {
    // Use the new multiple residents endpoint with isPrimary = true
    return await addResidentToUnit(condominiumId, unitId, residentId, isPrimary: true);
  }

  // Additional periods endpoints
  Future<Map<String, dynamic>> getPeriod(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/$periodId');
    return response.data;
  }

  Future<Map<String, dynamic>> updatePeriod(String periodId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/periods/$periodId', data: data);
    return response.data;
  }

  Future<void> closePeriod(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    await _dio.put('/periods/$periodId/close');
  }

  Future<void> deletePeriod(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    await _dio.delete('/periods/$periodId');
  }

  Future<Map<String, dynamic>> resetPeriodStatus(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.put('/periods/$periodId/reset');
    return response.data;
  }

  // Get previous period readings for consumption calculation
  Future<List<dynamic>> getPreviousPeriodReadings(String condominiumId, String currentPeriodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/$currentPeriodId/previous-readings');
    return response.data['readings'] ?? [];
  }

  // Stored calculations endpoints
  Future<Map<String, dynamic>> saveCalculations(String periodId, Map<String, dynamic> calculationsData) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.post('/periods/$periodId/calculations', data: calculationsData);
    return response.data;
  }

  Future<Map<String, dynamic>> getStoredCalculations(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }
    
    final response = await _dio.get('/periods/$periodId/calculations');
    return response.data;
  }

  Future<Map<String, dynamic>> deleteCalculations(String periodId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.delete('/periods/$periodId/calculations');
    return response.data;
  }

  // Users management endpoints
  Future<List<dynamic>> getCondominiumUsers(String condominiumId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.get('/condominiums/$condominiumId/users');
    return response.data;
  }

  Future<Map<String, dynamic>> createCondominiumUser(String condominiumId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.post('/condominiums/$condominiumId/users', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCondominiumUser(String condominiumId, String userId, Map<String, dynamic> data) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    final response = await _dio.put('/condominiums/$condominiumId/users/$userId', data: data);
    return response.data;
  }

  Future<void> deleteCondominiumUser(String condominiumId, String userId) async {
    if (!await _isConnected()) {
      throw const ConnectionException('No internet connection');
    }

    await _dio.delete('/condominiums/$condominiumId/users/$userId');
  }
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException(this.message);

  @override
  String toString() => 'ConnectionException: $message';
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return ApiService(secureStorage);
});