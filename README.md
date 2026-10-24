# Bitcoin Monitor AI

Aplicativo Flutter para monitoramento do preço do Bitcoin com foco em arquitetura inicial, interface visual e navegação entre Mercado, Alertas e Analista IA.

## Funcionalidades atuais

- Navegação com três abas: Mercado, Alertas e Analista IA.
- Tema visual escuro com Material 3.
- Cotações públicas de BTC via Binance: preço, variação em 24h e candles.
- Gráfico em `fl_chart` com períodos de 1 hora a 1 ano.
- Modelo de dados em Dart para preços, candles e alertas.
- Estado inicial com `flutter_riverpod`.
- Interface de demonstração para alertas e análise IA.

## Importante

- O mercado consulta os endpoints públicos da Binance; não precisa de chave API para leitura.
- A opção USD usa o par BTC/USDT e a opção BRL usa BTC/BRL. As consultas ocorrem ao abrir a tela, trocar moeda/período ou tocar em Atualizar.
- A chave do Gemini deve ficar protegida no backend para uma aplicação compartilhada ou publicada.
- O Firebase Cloud Messaging exige configuração do projeto e backend ou serviço responsável por disparar mensagens.
- O backend será desenvolvido em uma fase futura.
- Os dados da interface atual são demonstrativos.

## Executando o projeto

```bash
flutter pub get
flutter run
```

## Estrutura principal

- `lib/app` — configuração do app e tema.
- `lib/features` — telas e widgets por funcionalidade.
- `lib/data` — modelos e repositórios.
- `lib/services` — serviços e integrações futuras.
- `lib/navigation` — navegação principal.
