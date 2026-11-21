
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GeminiReply {
  const GeminiReply({
    required this.text,
    required this.interactionId,
  });

  final String text;
  final String interactionId;
}

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.8-flash';

  // Uri.https não é const. Por isso usamos static final.
  static final Uri _endpoint = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/interactions',
  );

  final http.Client _client;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<GeminiReply> sendMessage({
    required String prompt,
    required String marketContext,
    String? previousInteractionId,
  }) async {
    if (!isConfigured) {
      throw const GeminiException(
        'A chave do Gemini não foi configurada. Execute o aplicativo '
        'com --dart-define=GEMINI_API_KEY=SUA_CHAVE.',
        kind: GeminiErrorKind.notConfigured,
      );
    }

    final instructions = '''
Você é o Analista BTC, assistente do aplicativo Bitcoin Monitor AI.
Responda sempre em português do Brasil, com clareza e objetividade.
Ajude a interpretar o mercado de Bitcoin, explicar indicadores e riscos.
Não invente cotações, notícias, indicadores ou dados que não estejam no contexto.
Não prometa lucro e não trate suas respostas como recomendação financeira.
Quando os dados forem insuficientes, deixe isso explícito.

CONTEXTO ATUAL DO APLICATIVO:
$marketContext

MENSAGEM DO USUÁRIO:
$prompt
''';

    final body = <String, dynamic>{
      'model': _model,
      'input': instructions,
      if (previousInteractionId != null &&
          previousInteractionId.trim().isNotEmpty)
        'previous_interaction_id': previousInteractionId,
    };

    late http.Response response;

    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const GeminiException(
        'O Gemini demorou muito para responder. Tente novamente.',
        kind: GeminiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const GeminiException(
        'Não foi possível comunicar com o Gemini. '
        'Verifique sua conexão com a internet.',
        kind: GeminiErrorKind.connection,
      );
    } catch (_) {
      throw const GeminiException(
        'Ocorreu uma falha de comunicação com o Gemini. Tente novamente.',
        kind: GeminiErrorKind.connection,
      );
    }

    Map<String, dynamic> decoded;

    try {
      final value = jsonDecode(response.body);
      decoded = value is Map<String, dynamic>
          ? value
          : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final apiMessage =
          error is Map ? error['message']?.toString() : null;
      final apiCode = error is Map ? error['code']?.toString() : null;

      final isHighDemand = response.statusCode == 503 ||
          apiCode == 'service_unavailable' ||
          (apiMessage?.toLowerCase().contains('high demand') ?? false);

      if (isHighDemand) {
        throw const GeminiException(
          'O Gemini está com alta demanda no momento e não consegue '
          'processar novas solicitações. Aguarde alguns instantes e '
          'tente enviar sua mensagem novamente.',
          kind: GeminiErrorKind.highDemand,
          statusCode: 503,
        );
      }

      if (response.statusCode == 429) {
        throw const GeminiException(
          'O limite de solicitações do Gemini foi atingido. '
          'Aguarde um pouco antes de tentar novamente.',
          kind: GeminiErrorKind.rateLimit,
          statusCode: 429,
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw GeminiException(
          'O Google recusou a autenticação da API (HTTP '
          '${response.statusCode}). Verifique sua chave e as permissões.',
          kind: GeminiErrorKind.authentication,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 500) {
        throw GeminiException(
          'O serviço do Gemini está temporariamente indisponível '
          '(HTTP ${response.statusCode}). Tente novamente mais tarde.',
          kind: GeminiErrorKind.server,
          statusCode: response.statusCode,
        );
      }

      throw GeminiException(
        apiMessage?.isNotEmpty == true
            ? 'O Gemini retornou um erro: $apiMessage'
            : 'O Gemini retornou o erro HTTP ${response.statusCode}.',
        kind: GeminiErrorKind.request,
        statusCode: response.statusCode,
      );
    }

    final interactionId = decoded['id']?.toString();
    final answer = _extractOutputText(decoded);

    if (interactionId == null ||
        interactionId.isEmpty ||
        answer.trim().isEmpty) {
      throw const GeminiException(
        'O Gemini respondeu, mas não foi possível interpretar o conteúdo.',
        kind: GeminiErrorKind.invalidResponse,
      );
    }

    return GeminiReply(
      text: answer,
      interactionId: interactionId,
    );
  }

  String _extractOutputText(Map<String, dynamic> response) {
    final outputText = response['output_text'];

    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    final steps = response['steps'];

    if (steps is List) {
      final texts = <String>[];

      for (final step in steps) {
        if (step is! Map || step['type'] != 'model_output') {
          continue;
        }

        final content = step['content'];

        if (content is List) {
          for (final part in content) {
            if (part is Map && part['type'] == 'text') {
              final text = part['text']?.toString();

              if (text != null && text.trim().isNotEmpty) {
                texts.add(text.trim());
              }
            }
          }
        }
      }

      if (texts.isNotEmpty) {
        return texts.join('\n');
      }
    }

    return '';
  }

  void dispose() => _client.close();
}

enum GeminiErrorKind {
  notConfigured,
  highDemand,
  rateLimit,
  authentication,
  timeout,
  connection,
  server,
  request,
  invalidResponse,
}

class GeminiException implements Exception {
  const GeminiException(
    this.message, {
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
