import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/gemini_service.dart';
import 'widgets/analysis_card.dart';

class AnalystScreen extends ConsumerStatefulWidget {
  const AnalystScreen({super.key});

  @override
  ConsumerState<AnalystScreen> createState() => _AnalystScreenState();
}

class _AnalystScreenState extends ConsumerState<AnalystScreen> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _messages = [
    'Resumo demonstrativo: tendência de alta estável, suporte forte e cenário de alavancagem mínima.',
  ];
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateAnalysis() async {
    setState(() => _isGenerating = true);
    final service = GeminiService();
    final response = await service.generateDemoAnalysis(
      prompt: _promptController.text.trim().isEmpty
          ? 'Mercado BTC geral'
          : _promptController.text.trim(),
    );
    setState(() {
      _messages.add(response);
      _isGenerating = false;
    });
    _promptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analista IA',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateAnalysis,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isGenerating ? 'Gerando...' : 'Gerar Análise Completa',
                ),
              ),
              const SizedBox(height: 16),
              const AnalysisCard(
                summary:
                    'Resumo demonstrativo: o Bitcoin mantém um cenário de alta com volatilidade moderada. '
                    'A integração com Gemini está pendente e toda resposta atual é ilustrativa.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pergunte ao analista',
                  hintText: 'Ex.: Como está o cenário de BTC hoje?',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateAnalysis,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Enviar'),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    color: appTextSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Integração com Gemini ainda não está conectada. Esta conversa é um fluxo demonstrativo.',
                      style: TextStyle(color: appTextSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: appBorder),
                      ),
                      child: Text(message),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
