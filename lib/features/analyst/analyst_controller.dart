import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../services/gemini_service.dart';
import '../market/market_controller.dart';

class AnalystState {
  const AnalystState({
    this.messages = const [],
    this.isLoadingHistory = true,
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoadingHistory;
  final bool isSending;
  final String? errorMessage;

  AnalystState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingHistory,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalystState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AnalystController extends Notifier<AnalystState> {
  late ChatRepository _repository;
  late GeminiService _gemini;

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
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty || state.isSending || state.isLoadingHistory) return;

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: prompt,
      role: ChatMessageRole.user,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );
    try {
      await _repository.saveMessage(userMessage);
      final marketContext = _buildMarketContext();
      final reply = await _gemini.sendMessage(
        prompt: prompt,
        marketContext: marketContext,
        previousInteractionId: _repository.getLastInteractionId(),
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
      );
    } on GeminiException catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Ocorreu um erro ao enviar a mensagem: $error',
      );
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
