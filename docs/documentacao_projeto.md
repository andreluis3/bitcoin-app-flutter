# Documentação técnica — BTC App

## 1. Introdução

O BTC App, também identificado no código como Bitcoin Monitor AI, é um aplicativo móvel desenvolvido em Flutter para acompanhar informações do mercado de Bitcoin. A tela de mercado apresenta preço, variação em 24 horas e gráfico, enquanto o sistema de alertas permite definir limites próprios para acompanhar mudanças de preço.

O projeto também apresenta uma área de análise com interface conversacional. No estado atual, essa área é demonstrativa: ela não consulta um modelo de inteligência artificial nem produz análises a partir de dados reais do mercado.

## 2. Objetivos do projeto

Os objetivos do aplicativo são:

- facilitar a consulta de cotações e do histórico recente do Bitcoin;
- permitir que cada usuário configure limites superior e inferior de preço;
- avisar o usuário quando uma cotação observada cruzar um desses limites;
- explorar, como evolução futura, recursos de IA para interpretar dados e complementar os alertas.

O monitoramento de mercado e os alertas locais estão implementados. A integração efetiva com IA e a criação de um backend são propostas futuras, não funcionalidades concluídas.

## 3. Arquitetura e funcionamento

O aplicativo segue a estrutura de um projeto Flutter em Dart, organizado por responsabilidades. A inicialização ocorre em `lib/main.dart`; a configuração visual e o tema ficam em `lib/app`. A navegação inferior dá acesso às áreas **Mercado**, **Alertas** e **Analista IA**.

As telas e componentes são agrupados em `lib/features`. A funcionalidade de mercado, por exemplo, reúne a tela, widgets para preço, gráfico e formulário de limites, além de um controlador de estado. O estado é gerenciado com Riverpod. Em `lib/data`, modelos como preço, candle e alerta representam os dados usados pela interface; o repositório de Bitcoin concentra as consultas externas.

O fluxo de dados de mercado funciona assim:

1. A tela solicita os dados ao controlador.
2. O repositório faz requisições HTTP aos endpoints públicos da API da Binance, sem chave para leitura.
3. O aplicativo interpreta a cotação e os candles e atualiza a tela com preço, variação percentual e gráfico.

São consultados os pares BTC/USDT e BTC/BRL. O gráfico oferece os períodos de 1 hora, 24 horas, 7 dias, 1 mês e 1 ano. Enquanto o aplicativo está ativo, a consulta é repetida a cada cinco segundos; também há atualização manual. Quando o app fica inativo, a atualização periódica é interrompida e retomada quando ele volta ao primeiro plano.

Os serviços em `lib/services` separam operações como consulta de mercado, regras de alerta e notificações. O gerenciamento desses dados é feito com `SharedPreferences`, um armazenamento local simples do Flutter, e não com um banco de dados remoto. Os limites são armazenados separadamente para USD e BRL. O histórico dos alertas é serializado em JSON e salvo na chave `btc_market_alert_history_v1`, com até 100 registros. Portanto, esses dados permanecem no dispositivo e não são sincronizados entre dispositivos.

## 4. Sistema de alertas UP e DOWN

O usuário configura um limite superior e um inferior, que devem ser numéricos, positivos, e o superior deve ser maior que o inferior. Esses limites — chamados de **UP** (superior) e **DOWN** (inferior) — são salvos no `SharedPreferences` em chaves próprias por moeda (`btc_alert_upper_USD`, `btc_alert_lower_USD`, `btc_alert_upper_BRL` e `btc_alert_lower_BRL`). Se ainda não houver limites válidos armazenados, o controlador usa como referência valores 5% acima e abaixo da cotação observada.

Em cada atualização, o serviço compara a cotação atual com a anterior, na mesma moeda:

- **UP:** registra um evento quando o preço passa de abaixo para igual ou acima do limite superior.
- **DOWN:** registra um evento quando o preço passa de acima para igual ou abaixo do limite inferior.

Assim, permanecer além de um limite não gera um novo evento em toda consulta; o registro depende do cruzamento observado entre duas cotações. Cada evento registra sua direção (`up` ou `down`), preço, limite, moeda e data/hora. O serviço serializa esses registros como JSON na chave `btc_market_alert_history_v1` do `SharedPreferences`, mantendo os 100 mais recentes, e o aplicativo tenta exibir uma notificação local. Como a verificação depende das consultas feitas pelo app, ela não é um serviço remoto: não há garantia de monitoramento ou aviso com o aplicativo encerrado ou suspenso. A disponibilidade das notificações também depende das permissões e da configuração da plataforma.

## 5. Inteligência Artificial

A tela **Analista IA** e o serviço associado demonstram o fluxo de uma futura interação por texto. Atualmente, as respostas são fixas e explicitamente identificadas como demonstrativas; a entrada do usuário não é enviada ao Gemini nem a outro modelo conectado. Portanto, o app ainda não realiza interpretação automatizada de dados, diagnóstico de movimentações ou recomendações.

Como evolução, propõe-se integrar um serviço de IA para apoiar a leitura de informações de mercado, resumir movimentações e auxiliar no ajuste ou contextualização dos alertas. Essa integração deverá utilizar dados apropriados e proteger credenciais fora do aplicativo cliente. O diretório `backend` contém apenas uma descrição de responsabilidades futuras — como processar alertas e integrar notificações remotas — e não uma implementação funcional.

## 6. Versionamento e colaboração

O projeto está em um repositório GitHub originado de um fork. O fork mantém uma cópia independente do projeto de referência, permitindo desenvolver e validar alterações sem modificar diretamente o repositório original.

Para integrar o trabalho paralelo de Rafael, o fluxo adotado utiliza uma branch de trabalho específica. O **rebase** reaplica os commits dessa branch sobre uma versão atualizada da branch-base, ajudando a manter uma sequência de alterações organizada e facilitando sua revisão e integração. Se houver conflitos, eles devem ser resolvidos e testados antes de concluir a integração. Recomenda-se manter commits com escopo claro e revisar as diferenças antes de atualizar a branch compartilhada.

## 7. Considerações finais

O BTC App já oferece consulta de mercado via Binance, visualização de dados em gráfico, configuração de limites e registro local de alertas por cruzamento. A interface de análise por IA e o backend permanecem como demonstrações ou propostas. Como próximos passos, o projeto pode conectar uma IA por meio seguro, desenvolver o backend previsto e avaliar uma estratégia de monitoramento que funcione independentemente do ciclo de vida do aplicativo.
