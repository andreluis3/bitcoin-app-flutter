import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';

import '../../data/models/chat_message.dart';

import '../../services/gemini_service.dart';

import 'analyst_controller.dart';

class AnalystScreen extends ConsumerStatefulWidget {

  const AnalystScreen({super.key});

  @override

  ConsumerState<AnalystScreen> createState() => _AnalystScreenState();

}

class _AnalystScreenState extends ConsumerState<AnalystScreen> {

  final TextEditingController _promptController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override

  void dispose() {

    _promptController.dispose();

    _scrollController.dispose();

    super.dispose();

  }

  void _send([String? suggestedPrompt]) {

    final prompt = suggestedPrompt ?? _promptController.text;

    if (prompt.trim().isEmpty) return;

    _promptController.clear();

    FocusScope.of(context).unfocus();

    ref.read(analystControllerProvider.notifier).sendMessage(prompt);

  }

  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(

        _scrollController.position.maxScrollExtent,

        duration: const Duration(milliseconds: 280),

        curve: Curves.easeOut,

      );

    });

  }

  @override

  Widget build(BuildContext context) {

    final state = ref.watch(analystControllerProvider);

    final isGeminiConfigured = ref.watch(geminiServiceProvider).isConfigured;

    ref.listen<AnalystState>(analystControllerProvider, (previous, next) {

      if (previous?.messages.length != next.messages.length ||

          previous?.isSending != next.isSending) {

        _scrollToBottom();

      }

    });

    return Scaffold(

      backgroundColor: appBackground,

      body: SafeArea(

        child: Column(

          children: [

            _buildHeader(

              context,

              isGeminiConfigured: isGeminiConfigured,

              isSending: state.isSending,

            ),

            const Divider(height: 1, color: appBorder),

            Expanded(

              child: state.isLoadingHistory

                  ? const Center(

                      child: CircularProgressIndicator(color: appAccentStart),

                    )

                  : state.messages.isEmpty

                      ? _buildWelcome(isGeminiConfigured)

                      : _buildConversation(state),

            ),

            if (state.errorMessage != null)

              _buildError(state.errorMessage!),

            _buildComposer(state.isSending),

          ],

        ),

      ),

    );

  }

  Widget _buildHeader(

    BuildContext context, {

    required bool isGeminiConfigured,

    required bool isSending,

  }) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),

      child: Row(

        children: [

          Container(

            width: 42,

            height: 42,

            decoration: BoxDecoration(

              gradient: const LinearGradient(

                colors: [appAccentStart, appAccentEnd],

              ),

              borderRadius: BorderRadius.circular(14),

            ),

            child: const Icon(

              Icons.auto_awesome_rounded,

              color: Colors.white,

              size: 22,

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(

                  'Analista BTC',

                  style: TextStyle(

                    color: appTextPrimary,

                    fontSize: 17,

                    fontWeight: FontWeight.w700,

                  ),

                ),

                const SizedBox(height: 3),

                Row(

                  children: [

                    Container(

                      width: 7,

                      height: 7,

                      decoration: BoxDecoration(

                        color: isGeminiConfigured

                            ? appSuccess

                            : appTextSecondary,

                        shape: BoxShape.circle,

                      ),

                    ),

                    const SizedBox(width: 6),

                    Text(

                      isGeminiConfigured

                          ? 'Chave Gemini configurada'

                          : 'Configure sua chave Gemini',

                      style: const TextStyle(

                        color: appTextSecondary,

                        fontSize: 11,

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

          IconButton(

            tooltip: 'Nova conversa',

            onPressed: isSending

                ? null

                : () => _confirmNewConversation(context),

            icon: const Icon(Icons.add_comment_outlined),

          ),

        ],

      ),

    );

  }

  Future<void> _confirmNewConversation(BuildContext context) async {

    final shouldClear = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        backgroundColor: appSurface,

        title: const Text('Iniciar nova conversa?'),

        content: const Text(

          'O histórico desta conversa será apagado deste dispositivo.',

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Cancelar'),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(dialogContext, true),

            child: const Text('Nova conversa'),

          ),

        ],

      ),

    );

    if (shouldClear == true && mounted) {

      await ref.read(analystControllerProvider.notifier).clearConversation();

    }

  }

  Widget _buildWelcome(bool isGeminiConfigured) {

    return ListView(

      padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),

      children: [

        const SizedBox(height: 24),

        Container(

          width: 64,

          height: 64,

          alignment: Alignment.center,

          decoration: BoxDecoration(

            gradient: const LinearGradient(

              colors: [appAccentStart, appAccentEnd],

            ),

            borderRadius: BorderRadius.circular(22),

          ),

          child: const Icon(

            Icons.currency_bitcoin_rounded,

            color: Colors.white,

            size: 34,

          ),

        ),

        const SizedBox(height: 22),

        const Text(

          'Como posso ajudar?',

          style: TextStyle(

            color: appTextPrimary,

            fontSize: 26,

            fontWeight: FontWeight.w700,

          ),

        ),

        const SizedBox(height: 8),

        const Text(

          'Converse sobre o mercado de Bitcoin. Posso explicar indicadores e interpretar os dados que o aplicativo recebe da Binance.',

          style: TextStyle(

            color: appTextSecondary,

            fontSize: 14,

            height: 1.5,

          ),

        ),

        if (!isGeminiConfigured) ...[

          const SizedBox(height: 20),

          Container(

            padding: const EdgeInsets.all(13),

            decoration: BoxDecoration(

              color: appSurface,

              borderRadius: BorderRadius.circular(14),

              border: Border.all(color: appBorder),

            ),

            child: const Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Icon(Icons.key_rounded, color: appAccentEnd, size: 19),

                SizedBox(width: 10),

                Expanded(

                  child: Text(

                    'A interface está pronta. Para receber respostas reais, configure GEMINI_API_KEY ao executar o aplicativo.',

                    style: TextStyle(

                      color: appTextSecondary,

                      fontSize: 12,

                      height: 1.45,

                    ),

                  ),

                ),

              ],

            ),

          ),

        ],

        const SizedBox(height: 28),

        _SuggestionTile(

          icon: Icons.show_chart_rounded,

          title: 'Analisar o mercado agora',

          subtitle: 'Interprete a cotação e a variação atual do BTC',

          onTap: () => _send(

            'Faça uma análise do cenário atual do Bitcoin usando os dados de mercado disponíveis no aplicativo.',

          ),

        ),

        const SizedBox(height: 10),

        _SuggestionTile(

          icon: Icons.school_outlined,

          title: 'Explicar indicadores',

          subtitle: 'Entenda suporte, resistência, volume e tendência',

          onTap: () => _send(

            'Explique como posso interpretar suporte, resistência, volume e tendência no mercado de Bitcoin.',

          ),

        ),

        const SizedBox(height: 10),

        _SuggestionTile(

          icon: Icons.shield_outlined,

          title: 'Entender os riscos',

          subtitle: 'Conheça fatores de volatilidade e gestão de risco',

          onTap: () => _send(

            'Quais riscos devo observar antes de tomar uma decisão envolvendo Bitcoin?',

          ),

        ),

      ],

    );

  }

  Widget _buildConversation(AnalystState state) {

    return ListView.builder(

      controller: _scrollController,

      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),

      itemCount: state.messages.length + (state.isSending ? 1 : 0),

      itemBuilder: (context, index) {

        if (index == state.messages.length) {

          return const _TypingIndicator();

        }

        return _MessageBubble(message: state.messages[index]);

      },

    );

  }

  
Widget _buildError(String message) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: appDanger.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: appDanger.withValues(alpha: 0.38),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: appDanger,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível obter resposta do Gemini',
                style: TextStyle(
                  color: appTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: appTextSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildComposer(bool isSending) {

    return Container(

      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),

      decoration: const BoxDecoration(

        color: appBackground,

        border: Border(top: BorderSide(color: appBorder)),

      ),

      child: Container(

        padding: const EdgeInsets.fromLTRB(15, 4, 6, 4),

        decoration: BoxDecoration(

          color: appSurface,

          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: appBorder),

        ),

        child: Row(

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [

            Expanded(

              child: TextField(

                controller: _promptController,

                minLines: 1,

                maxLines: 5,

                textCapitalization: TextCapitalization.sentences,

                textInputAction: TextInputAction.send,

                onSubmitted: (_) => _send(),

                decoration: const InputDecoration(

                  hintText: 'Pergunte ao analista...',

                  border: InputBorder.none,

                  enabledBorder: InputBorder.none,

                  focusedBorder: InputBorder.none,

                  filled: false,

                  contentPadding: EdgeInsets.symmetric(vertical: 12),

                ),

              ),

            ),

            const SizedBox(width: 8),

            Padding(

              padding: const EdgeInsets.only(bottom: 3),

              child: IconButton.filled(

                tooltip: 'Enviar mensagem',

                onPressed: isSending ? null : _send,

                style: IconButton.styleFrom(

                  backgroundColor: appAccentStart,

                  foregroundColor: Colors.white,

                  disabledBackgroundColor: appAccentStart.withValues(alpha: 0.4),

                  fixedSize: const Size(42, 42),

                ),

                icon: isSending

                    ? const SizedBox(

                        width: 18,

                        height: 18,

                        child: CircularProgressIndicator(

                          strokeWidth: 2,

                          color: Colors.white,

                        ),

                      )

                    : const Icon(Icons.arrow_upward_rounded, size: 21),

              ),

            ),

          ],

        ),

      ),

    );

  }

}

class _MessageBubble extends StatelessWidget {

  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override

  Widget build(BuildContext context) {

    if (message.isUser) {

      return Padding(

        padding: const EdgeInsets.only(left: 42, bottom: 18),

        child: Align(

          alignment: Alignment.centerRight,

          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            decoration: BoxDecoration(

              gradient: const LinearGradient(

                colors: [appAccentStart, appAccentEnd],

              ),

              borderRadius: const BorderRadius.only(

                topLeft: Radius.circular(20),

                topRight: Radius.circular(20),

                bottomLeft: Radius.circular(20),

                bottomRight: Radius.circular(5),

              ),

            ),

            child: SelectableText(

              message.content,

              style: const TextStyle(

                color: Colors.white,

                fontSize: 14,

                height: 1.5,

              ),

            ),

          ),

        ),

      );

    }

    return Padding(

      padding: const EdgeInsets.only(right: 18, bottom: 22),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            width: 30,

            height: 30,

            decoration: BoxDecoration(

              color: appAccentStart.withValues(alpha: 0.18),

              borderRadius: BorderRadius.circular(10),

            ),

            child: const Icon(

              Icons.auto_awesome_rounded,

              color: appAccentEnd,

              size: 17,

            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Padding(

              padding: const EdgeInsets.only(top: 3),

              child: SelectableText(

                message.content,

                style: const TextStyle(

                  color: appTextPrimary,

                  fontSize: 14,

                  height: 1.65,

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}

class _TypingIndicator extends StatelessWidget {

  const _TypingIndicator();

  @override

  Widget build(BuildContext context) {

    return const Padding(

      padding: EdgeInsets.fromLTRB(2, 2, 0, 20),

      child: Row(

        children: [

          SizedBox(

            width: 18,

            height: 18,

            child: CircularProgressIndicator(

              strokeWidth: 2,

              color: appAccentEnd,

            ),

          ),

          SizedBox(width: 10),

          Text(

            'Analista BTC está pensando...',

            style: TextStyle(color: appTextSecondary, fontSize: 12),

          ),

        ],

      ),

    );

  }

}

class _SuggestionTile extends StatelessWidget {

  const _SuggestionTile({

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onTap,

  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  @override

  Widget build(BuildContext context) {

    return Material(

      color: appSurface,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Container(

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: appBorder),

          ),

          child: Row(

            children: [

              Icon(icon, color: appAccentEnd, size: 21),

              const SizedBox(width: 13),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style: const TextStyle(

                        color: appTextPrimary,

                        fontSize: 13,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    const SizedBox(height: 3),

                    Text(

                      subtitle,

                      style: const TextStyle(

                        color: appTextSecondary,

                        fontSize: 11,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons.arrow_forward_ios_rounded,

                color: appTextSecondary,

                size: 14,

              ),

            ],

          ),

        ),

      ),

    );

  }

}
