import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/ai_health_event.dart';
import '../../data/repositories/ai_health_repository.dart';
import '../../services/gemini_service.dart';
import '../market/market_controller.dart';

class AnalystState {
  const AnalystState({
    this.messages = const [],
    this.isLoadingHistory = true,
    this.isSending = false,
    this.errorMessage,
    this.progress,
  });

  final List<ChatMessage> messages;
  final bool isLoadingHistory;
  final bool isSending;
  final String? errorMessage;
  final GeminiProgress? progress;

  AnalystState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingHistory,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    GeminiProgress? progress,
    bool clearProgress = false,
  }) {
    return AnalystState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      progress: clearProgress ? null : progress ?? this.progress,
    );
  }
}

class AnalystController extends Notifier<AnalystState> {
  late ChatRepository _repository;
  late GeminiService _gemini;
  final AiHealthRepository _healthRepository = AiHealthRepository();

  @override
  AnalystState build() {
    _repository = ChatRepository();
    _gemini = ref.watch(geminiServiceProvider);
    Future.microtask(_loadHistory);
    return const AnalystState();
  }

  Future<void> _loadHistory() async {
    try {
      final messages = await _repository.getMessages();
      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: 'Não foi possível carregar o histórico: $error',
      );
    }
  }

  Future<void> sendMessage(String rawPrompt) async {
    await _submitPrompt(rawPrompt, appendUserMessage: true);
  }

  Future<void> retryLastMessage() async {
    if (state.isSending || state.isLoadingHistory) return;
    final lastUser = state.messages.reversed
        .cast<ChatMessage?>()
        .firstWhere((message) => message?.isUser == true, orElse: () => null);
    if (lastUser == null) return;
    await _submitPrompt(lastUser.content, appendUserMessage: false);
  }

  Future<void> _submitPrompt(
    String rawPrompt, {
    required bool appendUserMessage,
  }) async {
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty || state.isSending || state.isLoadingHistory) return;

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: prompt,
      role: ChatMessageRole.user,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: appendUserMessage
          ? [...state.messages, userMessage]
          : state.messages,
      isSending: true,
      clearError: true,
      clearProgress: true,
    );
    try {
      if (appendUserMessage) await _repository.saveMessage(userMessage);
      final marketContext = _buildMarketContext();
      final reply = await _gemini.sendMessage(
        prompt: prompt,
        marketContext: marketContext,
        previousInteractionId: _repository.getLastInteractionId(),
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
          _saveHealthEvent(progress);
        },
      );

      final assistantMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: reply.text,
        role: ChatMessageRole.assistant,
        createdAt: DateTime.now(),
      );

      await _repository.saveMessage(assistantMessage);
      await _repository.saveLastInteractionId(reply.interactionId);

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
        clearError: true,
        clearProgress: true,
      );
    } on GeminiException catch (error) {
      await _saveFailureEvent(error);
      state = state.copyWith(
        isSending: false,
        errorMessage: error.message,
      );
    } catch (error) {
      await _healthRepository.add(AiHealthEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'unexpectedError',
        message: 'Falha inesperada ao enviar mensagem.',
        createdAt: DateTime.now(),
      ));
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Ocorreu um erro ao enviar a mensagem: $error',
      );
    }
  }

  Future<void> _saveFailureEvent(GeminiException error) async {
    try {
      await _healthRepository.add(AiHealthEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'failure:${error.kind.name}',
        message: error.message,
        createdAt: DateTime.now(),
      ));
    } catch (_) {
      // Telemetria não pode bloquear o tratamento do erro do chat.
    }
  }

  Future<void> _saveHealthEvent(GeminiProgress progress) async {
    try {
      await _healthRepository.add(AiHealthEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: progress.type.name,
        message: progress.message,
        model: progress.model,
        createdAt: DateTime.now(),
      ));
    } catch (_) {
      // A falha ao salvar telemetria nunca deve interromper o chat.
    }
  }

  String _buildMarketContext() {
    try {
      final market = ref.read(marketControllerProvider);
      final currency =
          market.currency.name == 'brl' ? 'BRL' : 'USD';
      final symbol = currency == 'BRL' ? 'R\$' : '\$';

      if (market.price.price <= 0) {
        return 'Ainda não há cotação carregada no aplicativo. '
            'Moeda selecionada: $currency. '
            'Período do gráfico: ${market.selectedPeriod}.';
      }

      final candles = market.chartData;
      final high = candles.isEmpty
          ? null
          : candles.map((candle) => candle.high).reduce(
                (a, b) => a > b ? a : b,
              );
      final low = candles.isEmpty
          ? null
          : candles.map((candle) => candle.low).reduce(
                (a, b) => a < b ? a : b,
              );
      final volume = candles.isEmpty
          ? null
          : candles.fold<double>(
              0,
              (total, candle) => total + candle.volume,
            );

      return [
        'Ativo: Bitcoin (BTC).',
        'Fonte da cotação: Binance.',
        'Par consultado: ${currency == 'BRL' ? 'BTCBRL' : 'BTCUSDT'}.',
        'Preço atual: $symbol${market.price.price.toStringAsFixed(2)}.',
        'Variação em 24 horas: ${market.price.changePercent24h.toStringAsFixed(2)}%.',
        'Período selecionado no gráfico: ${market.selectedPeriod}.',
        if (high != null) 'Máxima no período carregado: $symbol${high.toStringAsFixed(2)}.',
        if (low != null) 'Mínima no período carregado: $symbol${low.toStringAsFixed(2)}.',
        if (volume != null) 'Volume agregado dos candles carregados: ${volume.toStringAsFixed(4)}.',
        'Horário da cotação: ${market.price.timestamp.toLocal().toIso8601String()}.',
      ].join('\n');
    } catch (_) {
      return 'Os dados de mercado ainda não estão disponíveis para esta solicitação.';
    }
  }

  Future<void> clearConversation() async {
    if (state.isSending) return;
    await _repository.clearConversation();
    state = const AnalystState(isLoadingHistory: false);
  }
}

final analystControllerProvider =
    NotifierProvider<AnalystController, AnalystState>(
  AnalystController.new,
);
