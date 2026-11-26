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

    // Se o ID remoto expirou, inicia uma nova interação sem apagar o histórico local.
    var interactionId = previousInteractionId;
    var retriedWithoutPreviousId = false;
    var transientAttempts = 0;

    while (true) {
      final body = <String, dynamic>{
        'model': _model,
        'input': input,
        'store': true,
        if (interactionId != null && interactionId.trim().isNotEmpty)
          'previous_interaction_id': interactionId,
      };

      http.Response response;
      try {
        response = await _client.post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey.trim(),
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 45));
      } on TimeoutException {
        if (transientAttempts++ < 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        throw const GeminiException(
          'O Gemini demorou mais que o esperado. Sua mensagem foi preservada; tente novamente.',
          kind: GeminiErrorKind.timeout,
        );
      } on SocketException {
        if (transientAttempts++ < 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        throw const GeminiException(
          'Sem conexão com a internet. A conversa local foi preservada.',
          kind: GeminiErrorKind.connection,
        );
      } on http.ClientException {
        if (transientAttempts++ < 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        throw const GeminiException(
          'Não foi possível conectar à API do Gemini. Tente novamente quando a conexão voltar.',
          kind: GeminiErrorKind.connection,
        );
      }

      final decoded = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final id = decoded['id']?.toString();
        final answer = _extractOutputText(decoded);
        if (id == null || id.isEmpty || answer.trim().isEmpty) {
          throw const GeminiException(
            'O Gemini respondeu, mas não retornou uma interação e um texto válidos.',
            kind: GeminiErrorKind.invalidResponse,
          );
        }
        return GeminiReply(text: answer.trim(), interactionId: id);
      }

      final error = decoded['error'];
      final apiMessage = error is Map
          ? (error['message'] ?? error['status'] ?? error['code'])?.toString()
          : null;
      final detail = _safeDetail(apiMessage);

      // Uma interação remota inválida não apaga nem compromete as mensagens locais.
      if (response.statusCode == 400 &&
          interactionId != null &&
          interactionId.trim().isNotEmpty &&
          !retriedWithoutPreviousId) {
        interactionId = null;
        retriedWithoutPreviousId = true;
        continue;
      }

      if ((response.statusCode == 429 || response.statusCode >= 500) &&
          transientAttempts++ < 1) {
        await Future<void>.delayed(
          Duration(seconds: response.statusCode == 429 ? 5 : 2),
        );
        continue;
      }

      switch (response.statusCode) {
        case 401:
        case 403:
          throw GeminiException(
            'O Google recusou a chave ou a permissão (HTTP ${response.statusCode}). Confira a configuração da API.',
            kind: GeminiErrorKind.authentication,
            statusCode: response.statusCode,
          );
        case 404:
          throw GeminiException(
            'O modelo "$_model" ou o endpoint Interactions não foi encontrado (HTTP 404). Confira a compatibilidade do modelo.',
            kind: GeminiErrorKind.modelOrEndpoint,
            statusCode: 404,
          );
        case 429:
          throw GeminiException(
            'O limite de requisições do Gemini foi atingido. Aguarde antes de tentar novamente.${detail == null ? '' : '\nDetalhe: $detail'}',
            kind: GeminiErrorKind.rateLimit,
            statusCode: 429,
          );
        default:
          if (response.statusCode >= 500) {
            throw GeminiException(
              'O serviço Gemini está temporariamente indisponível (HTTP ${response.statusCode}).${detail == null ? '' : '\nDetalhe: $detail'}',
              kind: GeminiErrorKind.server,
              statusCode: response.statusCode,
            );
          }
          throw GeminiException(
            'A API do Gemini rejeitou a solicitação (HTTP ${response.statusCode}).${detail == null ? '' : '\nDetalhe: $detail'}',
            kind: GeminiErrorKind.request,
            statusCode: response.statusCode,
          );
      }
    }
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
