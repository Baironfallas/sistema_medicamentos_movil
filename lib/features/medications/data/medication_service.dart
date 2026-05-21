import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/data/auth_storage.dart';
import '../models/medication.dart';
import '../models/medication_intake.dart';
import 'medication_exception.dart';

class MedicationService {
  MedicationService({http.Client? client, AuthStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? AuthStorage();

  final http.Client _client;
  final AuthStorage _storage;

  Future<List<Medication>> getMedications() async {
    return _guard(() async {
      final response = await _client
          .get(
            ApiConfig.endpoint('/medications'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final items = _extractList(decoded, [
        'data',
        'items',
        'medications',
        'results',
      ]);

      return items
          .whereType<Map>()
          .map((item) => Medication.fromJson(item.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<Medication> getMedicationById(int id) async {
    return _guard(() async {
      final response = await _client
          .get(
            ApiConfig.endpoint('/medications/$id'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final data = _extractObject(decoded, ['data', 'medication']);
      if (data.isEmpty) {
        throw const MedicationException('No se pudo leer el medicamento.');
      }

      return Medication.fromJson(data);
    });
  }

  Future<void> createMedication(MedicationDraft draft) async {
    return _guard(() async {
      final endpoint = ApiConfig.endpoint('/medications');
      final payload = draft.toCreateJson();

      debugPrint('POST $endpoint');
      debugPrint('POST /medications body: ${jsonEncode(payload)}');

      final response = await _client
          .post(
            endpoint,
            headers: await _authHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'POST /medications response: ${response.statusCode} ${_bodyText(response.bodyBytes)}',
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);
    });
  }

  Future<void> updateMedication(int id, MedicationDraft draft) async {
    return _guard(() async {
      final response = await _client
          .patch(
            ApiConfig.endpoint('/medications/$id'),
            headers: await _authHeaders(),
            body: jsonEncode(draft.toUpdateJson()),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);
    });
  }

  Future<void> deleteMedication(int id) async {
    return _guard(() async {
      final response = await _client
          .delete(
            ApiConfig.endpoint('/medications/$id'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);
    });
  }

  Future<List<MedicationIntake>> getTodayIntakes() async {
    return _guard(() async {
      final response = await _client
          .get(
            ApiConfig.endpoint('/medications/today-intakes'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final items = _extractList(decoded, [
        'data',
        'items',
        'intakes',
        'todayIntakes',
        'medicationIntakes',
      ]);

      return items
          .whereType<Map>()
          .map(
            (item) => MedicationIntake.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    });
  }

  Future<void> confirmIntake(int intakeId, {String status = 'taken'}) async {
    return _guard(() async {
      final response = await _client
          .patch(
            ApiConfig.endpoint('/medication-intakes/$intakeId/confirm'),
            headers: await _authHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MedicationException {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('MedicationService client error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw MedicationException(
        'No se pudo completar la solicitud. Verifica que el backend este disponible en ${ApiConfig.baseUrl} y que CORS permita la peticion.',
      );
    } on SocketException {
      throw const MedicationException('No se pudo conectar con el servidor.');
    } on TimeoutException {
      throw const MedicationException(
        'La conexion tardo demasiado. Intenta nuevamente.',
      );
    } on FormatException {
      throw const MedicationException(
        'El servidor respondio con datos invalidos.',
      );
    } catch (error, stackTrace) {
      debugPrint('MedicationService unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const MedicationException(
        'No se pudo completar la solicitud. Revisa la consola para ver el detalle del error.',
      );
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const MedicationException('Sesion no valida. Inicia sesion.');
    }

    debugPrint('MedicationService auth token available: true');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    final body = _bodyText(response.bodyBytes);
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      debugPrint('MedicationService invalid JSON response: $error');
      debugPrint('MedicationService raw response: $body');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        rethrow;
      }
      return null;
    }
  }

  String _bodyText(List<int> bodyBytes) {
    return utf8.decode(bodyBytes, allowMalformed: true);
  }

  void _throwIfNotSuccess(
    http.Response response,
    dynamic decoded, [
    List<int>? rawBodyBytes,
  ]) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw MedicationException(
      _friendlyMessage(
        response.statusCode,
        decoded,
        rawBodyBytes == null ? null : _bodyText(rawBodyBytes),
      ),
      statusCode: response.statusCode,
    );
  }

  String _friendlyMessage(int statusCode, dynamic decoded, String? rawBody) {
    final backendMessage = _extractBackendMessage(decoded);

    if (statusCode == 401) {
      return backendMessage ?? 'Sesion expirada. Inicia sesion nuevamente.';
    }

    if (statusCode == 403) {
      return 'No tienes permisos para realizar esta accion.';
    }

    if (statusCode == 404) {
      return 'No se encontro el recurso solicitado.';
    }

    if (statusCode == 400) {
      return backendMessage ?? 'Solicitud invalida. Verifica los datos.';
    }

    if (statusCode >= 500) {
      return backendMessage ??
          'El servidor no respondio correctamente. Intenta mas tarde.';
    }

    if (rawBody != null && rawBody.trim().isNotEmpty) {
      return rawBody.trim();
    }

    return backendMessage ??
        'La solicitud fallo con estado HTTP $statusCode. Intenta nuevamente.';
  }

  String? _extractBackendMessage(dynamic decoded) {
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join('\n');
      }
      final text = message?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }
    return null;
  }

  List<dynamic> _extractList(dynamic decoded, List<String> keys) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map) {
      for (final key in keys) {
        final value = decoded[key];
        if (value is List) {
          return value;
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _extractObject(dynamic decoded, List<String> keys) {
    if (decoded is Map<String, dynamic>) {
      for (final key in keys) {
        final value = decoded[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
        if (value is Map) {
          return value.cast<String, dynamic>();
        }
      }
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return {};
  }
}
