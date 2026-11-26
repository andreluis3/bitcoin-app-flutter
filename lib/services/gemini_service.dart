
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GeminiReply {
  const GeminiReply({required this.text, required this.interactionId, required this.model});
  final String text, interactionId, model;
}
enum GeminiProgressType { retrying, switchingModel, circuitOpen, recovered }
class GeminiProgress {
  const GeminiProgress(this.type, this.message, {this.model, this.attempt});
  final GeminiProgressType type;
  final String message;
  final String? model;
  final int? attempt;
  bool get isRecovery => type != GeminiProgressType.recovered;
}
typedef GeminiProgressCallback = void Function(GeminiProgress progress);

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _configuredModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.7-flash');
  static final Uri _endpoint = Uri.https('generativelanguage.googleapis.com', '/v1beta/interactions');
  static const List<String> _fallbackModels = [
    'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-3.5-flash-lite', 'gemini-3.8-flash',
  ];
  final http.Client _client;
  int _failures = 0;
  DateTime? _circuitOpenedAt;
  bool _probeInProgress = false;
  static const _threshold = 3;
  static const _cooldown = Duration(seconds: 30);
  bool get isConfigured => _apiKey.trim().isNotEmpty;
  String get modelName => _configuredModel;

  Future<GeminiReply> sendMessage({
    required String prompt, required String marketContext,
    String? previousInteractionId, GeminiProgressCallback? onProgress,
  }) async {
    if (!isConfigured) throw const GeminiException('A chave do Gemini não foi carregada. Use --dart-define-from-file=env.json.', kind: GeminiErrorKind.notConfigured);
    if (_circuitOpenedAt != null) {
      final remaining = _cooldown - DateTime.now().difference(_circuitOpenedAt!);
      if (remaining > Duration.zero) {
        onProgress?.call(GeminiProgress(GeminiProgressType.circuitOpen, 'Proteção ativa. Nova tentativa em ${remaining.inSeconds}s.'));
        throw GeminiException('Gemini temporariamente pausado após falhas consecutivas. Aguarde ${remaining.inSeconds}s.', kind: GeminiErrorKind.circuitOpen);
      }
      if (_probeInProgress) throw const GeminiException('Verificando a conexão. Tente novamente em instantes.', kind: GeminiErrorKind.circuitOpen);
      _probeInProgress = true;
    }
    final input = '''
CONTEXTO DO SISTEMA:
Você é o Analista BTC do aplicativo Bitcoin Monitor AI.
Responda em português do Brasil, com clareza e objetividade.
Não prometa lucro nem invente cotações, notícias ou indicadores. Informe quando os dados forem insuficientes.
CONTEXTO DE MERCADO:
$marketContext
MENSAGEM DO USUÁRIO:
$prompt
''';
    final models = <String>[_configuredModel, ..._fallbackModels.where((m) => m != _configuredModel)];
    var lastError = const GeminiException('Não foi possível obter resposta do Gemini.');
    try {
      for (var mi = 0; mi < models.length; mi++) {
        final model = models[mi];
        if (mi > 0) onProgress?.call(GeminiProgress(GeminiProgressType.switchingModel, 'Alternando para $model...', model: model));
        // O ID remoto é enviado somente ao modelo original; histórico local permanece intacto.
        final previousId = mi == 0 ? previousInteractionId : null;
        for (var attempt = 1; attempt <= 2; attempt++) {
          http.Response response;
          try {
            response = await _post(model, input, previousId).timeout(const Duration(seconds: 40));
          } on TimeoutException {
            lastError = const GeminiException('Tempo limite ao aguardar o Gemini.', kind: GeminiErrorKind.timeout);
            if (attempt == 1) {
              onProgress?.call(GeminiProgress(GeminiProgressType.retrying, 'Tempo esgotado. Tentando novamente...', model: model, attempt: 2));
              await Future<void>.delayed(const Duration(seconds: 2)); continue;
            }
            break;
          } on SocketException {
            lastError = const GeminiException('Sem conexão com a internet.', kind: GeminiErrorKind.connection);
            if (attempt == 1) {
              onProgress?.call(GeminiProgress(GeminiProgressType.retrying, 'Falha de conexão. Tentando novamente...', model: model, attempt: 2));
              await Future<void>.delayed(const Duration(seconds: 2)); continue;
            }
            break;
          } on http.ClientException {
            lastError = const GeminiException('Não foi possível conectar à API do Gemini.', kind: GeminiErrorKind.connection);
            if (attempt == 1) {
              onProgress?.call(GeminiProgress(GeminiProgressType.retrying, 'Conexão instável. Tentando novamente...', model: model, attempt: 2));
              await Future<void>.delayed(const Duration(seconds: 2)); continue;
            }
            break;
          }
          final data = _decode(response.body);
          if (response.statusCode >= 200 && response.statusCode < 300) {
            final id = data['id']?.toString(), answer = _extract(data);
            if (id == null || id.isEmpty || answer.trim().isEmpty) {
              lastError = const GeminiException('Resposta sem texto ou ID de interação válidos.', kind: GeminiErrorKind.invalidResponse);
              break;
            }
            _failures = 0; _circuitOpenedAt = null;
            onProgress?.call(GeminiProgress(GeminiProgressType.recovered, 'Conexão restabelecida com $model.', model: model));
            return GeminiReply(text: answer.trim(), interactionId: id, model: model);
          }
          final detail = _detail(data);
          if (response.statusCode == 401 || response.statusCode == 403) {
            throw GeminiException('Chave ou permissão recusada (HTTP ${response.statusCode}).', kind: GeminiErrorKind.authentication, statusCode: response.statusCode);
          }
          if (response.statusCode == 429) {
            if (attempt == 1) {
              onProgress?.call(GeminiProgress(GeminiProgressType.retrying, 'Limite atingido. Aguardando para tentar novamente...', model: model, attempt: 2));
              await Future<void>.delayed(const Duration(seconds: 8)); continue;
            }
            throw GeminiException('Limite de requisições atingido. Aguarde antes de tentar novamente.${detail == null ? '' : ' $detail'}', kind: GeminiErrorKind.rateLimit, statusCode: 429);
          }
          if (response.statusCode == 400 && previousId != null) {
            // Interação remota expirada: refaz sem o ID, sem apagar histórico local.
            final retry = await _post(model, input, null).timeout(const Duration(seconds: 40));
            final retryData = _decode(retry.body);
            if (retry.statusCode >= 200 && retry.statusCode < 300) {
              final id = retryData['id']?.toString(), answer = _extract(retryData);
              if (id != null && id.isNotEmpty && answer.trim().isNotEmpty) {
                _failures = 0; _circuitOpenedAt = null;
                onProgress?.call(GeminiProgress(GeminiProgressType.recovered, 'Conversa retomada.', model: model));
                return GeminiReply(text: answer.trim(), interactionId: id, model: model);
              }
            }
            lastError = GeminiException('Interação anterior rejeitada (HTTP 400).', kind: GeminiErrorKind.request, statusCode: 400);
            break;
          }
          if (response.statusCode == 404) {
            lastError = GeminiException('Modelo $model não encontrado (HTTP 404).', kind: GeminiErrorKind.modelOrEndpoint, statusCode: 404);
            break;
          }
          if (response.statusCode >= 500) {
            lastError = GeminiException('Servidor temporariamente indisponível (HTTP ${response.statusCode}).', kind: GeminiErrorKind.server, statusCode: response.statusCode);
            if (attempt == 1) {
              onProgress?.call(GeminiProgress(GeminiProgressType.retrying, 'Servidor instável. Tentando novamente...', model: model, attempt: 2));
              await Future<void>.delayed(const Duration(seconds: 2)); continue;
            }
            break;
          }
          throw GeminiException('API rejeitou a solicitação (HTTP ${response.statusCode}).${detail == null ? '' : ' $detail'}', kind: GeminiErrorKind.request, statusCode: response.statusCode);
        }
        // 404, timeout, conexão e 5xx permitem testar o próximo modelo.
        if (lastError.kind == GeminiErrorKind.request) throw lastError;
      }
      _failures++;
      if (_failures >= _threshold) _circuitOpenedAt = DateTime.now();
      throw lastError;
    } finally {
      _probeInProgress = false;
    }
  }

  Future<http.Response> _post(String model, String input, String? previousId) {
    return _client.post(_endpoint, headers: {
      'Content-Type': 'application/json', 'x-goog-api-key': _apiKey.trim(),
    }, body: jsonEncode({
      'model': model, 'input': input, 'store': true,
      if (previousId != null && previousId.trim().isNotEmpty) 'previous_interaction_id': previousId,
    }));
  }
  Map<String, dynamic> _decode(String body) {
    try { final v = jsonDecode(body); return v is Map<String, dynamic> ? v : {}; }
    on FormatException { return {}; }
  }
  String? _detail(Map<String, dynamic> data) {
    final e = data['error']; if (e is! Map) return null;
    final s = (e['message'] ?? e['status'])?.toString(); if (s == null) return null;
    final safe = _apiKey.isEmpty ? s : s.replaceAll(_apiKey, '[REDACTED]');
    return safe.length > 200 ? safe.substring(0, 200) : safe;
  }
  String _extract(Map<String, dynamic> data) {
    final direct = data['output_text'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    final result = <String>[];
    void collect(dynamic list) {
      if (list is! List) return;
      for (final item in list) {
        if (item is! Map) continue;
        final t = item['text']?.toString();
        if (t != null && t.trim().isNotEmpty) result.add(t.trim());
        final content = item['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map && part['type'] == 'text') {
              final value = part['text']?.toString();
              if (value != null && value.trim().isNotEmpty) {
                result.add(value.trim());
              }
            }
          }
        }
      }
    }
    collect(data['outputs']); collect(data['steps']);
    return result.join('\n');
  }
  void dispose() => _client.close();
}

enum GeminiErrorKind { notConfigured, rateLimit, authentication, modelOrEndpoint, timeout, connection, server, request, invalidResponse, circuitOpen }
class GeminiException implements Exception {
  const GeminiException(this.message, {this.kind = GeminiErrorKind.request, this.statusCode});
  final String message; final GeminiErrorKind kind; final int? statusCode;
  @override String toString() => message;
}
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final service = GeminiService(); ref.onDispose(service.dispose); return service;
});
