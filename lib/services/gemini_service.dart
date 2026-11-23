import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GeminiReply {
  const GeminiReply({required this.text, required this.interactionId});
  final String text;
  final String interactionId;
}

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  // Set at build/run time. Never print this value in logs.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.8-flash');

  static final Uri _endpoint = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/interactions',
  );

  final http.Client _client;
  bool get isConfigured => _apiKey.trim().isNotEmpty;
  String get modelName => _model;

  Future<GeminiReply> sendMessage({
    required String prompt,
    required String marketContext,
    String? previousInteractionId,
  }) async {
    if (!isConfigured) {
      throw const GeminiException(
        'A chave do Gemini não foi carregada. Inicie o app com '
        '--dart-define-from-file=env.json (arquivo JSON local).',
        kind: GeminiErrorKind.notConfigured,
      );
    }

    final input = '''
CONTEXTO DO SISTEMA:
Você é o Analista BTC do aplicativo Bitcoin Monitor AI.
Responda em português do Brasil, com clareza e objetividade.
Explique o mercado e indicadores, sem prometer lucro ou dar recomendação financeira.
Não invente cotações, notícias, indicadores ou dados ausentes.
Se os dados forem insuficientes, informe isso explicitamente.

CONTEXTO DE MERCADO DISPONÍVEL:
$marketContext

MENSAGEM DO USUÁRIO:
$prompt
''';

    final body = <String, dynamic>{
      'model': _model,
      'input': input,
      'store': true,
      if (previousInteractionId != null &&
          previousInteractionId.trim().isNotEmpty)
        'previous_interaction_id': previousInteractionId,
    };

    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey.trim(),
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const GeminiException(
        'A solicitação excedeu 60 segundos. Verifique a conexão e tente novamente.',
        kind: GeminiErrorKind.timeout,
      );
    } on SocketException {
      throw const GeminiException(
        'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        kind: GeminiErrorKind.connection,
      );
    } on http.ClientException {
      throw const GeminiException(
        'Não foi possível estabelecer conexão com a API do Google Gemini.',
        kind: GeminiErrorKind.connection,
      );
    }

    final decoded = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final apiMessage = error is Map
          ? (error['message'] ?? error['status'] ?? error['code'])?.toString()
          : null;
      final detail = _safeDetail(apiMessage);

      switch (response.statusCode) {
        case 400:
          throw GeminiException(
            'A API rejeitou a requisição (HTTP 400). Verifique o modelo, '
            'o formato da solicitação e o ID da interação anterior.'
            '${detail == null ? '' : '\nDetalhe do Google: $detail'}',
            kind: GeminiErrorKind.request,
            statusCode: 400,
          );
        case 401:
        case 403:
          throw GeminiException(
            'A API recusou a autenticação/autorização (HTTP ${response.statusCode}). '
            'Confira se a chave é válida e se a Gemini API está habilitada.',
            kind: GeminiErrorKind.authentication,
            statusCode: response.statusCode,
          );
        case 404:
          throw GeminiException(
            'O recurso não foi encontrado (HTTP 404). Confira o identificador '
            'do modelo "$_model" e a disponibilidade do endpoint Interactions.'
            '${detail == null ? '' : '\nDetalhe do Google: $detail'}',
            kind: GeminiErrorKind.modelOrEndpoint,
            statusCode: 404,
          );
        case 429:
          throw GeminiException(
            'A cota ou o limite de requisições do Gemini foi atingido (HTTP 429). '
            'Confira os limites do projeto no Google AI Studio e tente novamente.'
            '${detail == null ? '' : '\nDetalhe do Google: $detail'}',
            kind: GeminiErrorKind.rateLimit,
            statusCode: 429,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw GeminiException(
            'O serviço do Google Gemini está temporariamente indisponível '
            '(HTTP ${response.statusCode}). Isso não confirma, por si só, '
            'que seja alta demanda. Tente novamente mais tarde.'
            '${detail == null ? '' : '\nDetalhe do Google: $detail'}',
            kind: GeminiErrorKind.server,
            statusCode: response.statusCode,
          );
        default:
          throw GeminiException(
            'A API do Gemini retornou HTTP ${response.statusCode}.'
            '${detail == null ? '' : '\nDetalhe do Google: $detail'}',
            kind: GeminiErrorKind.request,
            statusCode: response.statusCode,
          );
      }
    }

    final interactionId = decoded['id']?.toString();
    final answer = _extractOutputText(decoded);
    if (interactionId == null || interactionId.isEmpty || answer.trim().isEmpty) {
      throw const GeminiException(
        'A API respondeu com sucesso, mas o formato da resposta não contém '
        'um ID de interação e um texto reconhecível.',
        kind: GeminiErrorKind.invalidResponse,
      );
    }
    return GeminiReply(text: answer.trim(), interactionId: interactionId);
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String? _safeDetail(String? message) {
    if (message == null || message.trim().isEmpty) return null;
    final redacted = _apiKey.isEmpty
        ? message
        : message.replaceAll(_apiKey, '[REDACTED]');
    return redacted.length > 300 ? redacted.substring(0, 300) : redacted;
  }

  String _extractOutputText(Map<String, dynamic> response) {
    final outputText = response['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    final outputs = response['outputs'];
    if (outputs is List) {
      final texts = <String>[];
      for (final output in outputs) {
        if (output is! Map) continue;
        final directText = output['text']?.toString();
        if (directText != null && directText.trim().isNotEmpty) {
          texts.add(directText.trim());
        }
        final content = output['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map && part['type'] == 'text') {
              final text = part['text']?.toString();
              if (text != null && text.trim().isNotEmpty) texts.add(text.trim());
            }
          }
        }
      }
      if (texts.isNotEmpty) return texts.join('\n');
    }

    final steps = response['steps'];
    if (steps is List) {
      final texts = <String>[];
      for (final step in steps) {
        if (step is! Map) continue;
        final type = step['type']?.toString();
        if (type != 'model_output' && type != 'output_text') continue;
        final content = step['content'];
        if (content is String && content.trim().isNotEmpty) {
          texts.add(content.trim());
        } else if (content is List) {
          for (final part in content) {
            if (part is Map && part['type'] == 'text') {
              final text = part['text']?.toString();
              if (text != null && text.trim().isNotEmpty) texts.add(text.trim());
            }
          }
        }
      }
      if (texts.isNotEmpty) return texts.join('\n');
    }
    return '';
  }

  void dispose() => _client.close();
}

enum GeminiErrorKind {
  notConfigured,
  rateLimit,
  authentication,
  modelOrEndpoint,
  timeout,
  connection,
  server,
  request,
  invalidResponse,
}

class GeminiException implements Exception {
  const GeminiException(this.message, {
    this.kind = GeminiErrorKind.request,
    this.statusCode,
  });
  final String message;
  final GeminiErrorKind kind;
  final int? statusCode;
  @override
  String toString() => message;
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final service = GeminiService();
  ref.onDispose(service.dispose);
  return service;
});
