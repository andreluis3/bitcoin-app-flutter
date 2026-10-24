class GeminiService {
  Future<String> generateDemoAnalysis({required String prompt}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return 'Resumo demonstrativo: o mercado de BTC continua com estrutura de tendência de alta, '
        'com sinais de liquidez e pressão no suporte. A integração com a API do Gemini '
        'está pendente e esta resposta é apenas uma simulação visual do fluxo futuro.';
  }
}
