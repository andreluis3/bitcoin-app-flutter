Bitcoin Monitor AI

Aplicativo desenvolvido em Flutter para monitoramento do mercado de Bitcoin, visualização de indicadores de mercado e integração com Inteligência Artificial utilizando Google Gemini.

O projeto busca evoluir de um monitor de cotações para uma plataforma inteligente capaz de interpretar informações do mercado, identificar possíveis oportunidades e emitir alertas sobre movimentos de alta e baixa do Bitcoin.

Funcionalidades

📊 Mercado

Consulta de cotações públicas da Binance.

Monitoramento dos pares BTC/USDT e BTC/BRL.

Visualização do preço atual do Bitcoin.

Variação percentual nas últimas 24 horas.

Gráfico interativo desenvolvido com fl_chart.

Diferentes períodos de análise: 1H, 24H, 7D, 1M e 1Y.

Atualização manual das informações de mercado.

🔔 Sistema de Alertas

Configuração de limites de preço para o Bitcoin.

Monitoramento de possíveis movimentos de alta e baixa.

Histórico local de alertas.

Estrutura preparada para futuras notificações inteligentes.

🤖 Analista IA — Google Gemini

Integração com o modelo de Inteligência Artificial Google Gemini.

A proposta do módulo é oferecer uma experiência de análise de mercado por meio de linguagem natural.

Funcionalidades previstas para evolução:

Interpretação de informações do mercado.

Análise contextual do comportamento do Bitcoin.

Explicação de possíveis movimentos de alta e baixa.

Identificação de possíveis oportunidades de mercado.

Integração com indicadores técnicos.

Geração de análises e alertas inteligentes.

Segurança: a chave de API do Gemini deve ser protegida no backend, evitando sua exposição no aplicativo Flutter.

💾 Banco de Dados e Persistência

O projeto possui uma estrutura de armazenamento local para preservar informações do aplicativo.

A persistência local é importante para manter dados disponíveis mesmo após fechar e abrir novamente o aplicativo.

Estrutura planejada para armazenamento:

Histórico de alertas.

Registros de sinais de mercado.

Configurações dos limites de preço.

Histórico de análises realizadas.

O mecanismo de persistência e suas tabelas devem ser documentados conforme a implementação efetiva dos repositórios locais.

Observação: o armazenamento local é independente da API pública da Binance. As cotações são consultadas diretamente na API e não representam, por si só, um banco de dados histórico local.

Tecnologias utilizadas

Tecnologia

Aplicação

Flutter

Desenvolvimento multiplataforma

Dart

Linguagem de programação

Riverpod

Gerenciamento de estado

Material 3

Interface e componentes visuais

fl_chart

Gráficos de mercado

Binance API

Consulta de dados financeiros

Google Gemini

Inteligência Artificial

Persistência local

Armazenamento de informações

Firebase Cloud Messaging

Infraestrutura planejada para notificações push

Arquitetura do projeto

O projeto utiliza uma organização modular, separando interface, gerenciamento de estado, dados e serviços.

lib/
│
├── app/
│   ├── Configurações do aplicativo
│   └── Tema visual
│
├── features/
│   ├── market/
│   │   ├── Mercado
│   │   └── Gráficos
│   │
│   ├── alerts/
│   │   └── Sistema de alertas
│   │
│   └── ai_analyst/
│       └── Analista IA
│
├── data/
│   ├── models/
│   └── repositories/
│
├── services/
│   ├── Binance API
│   ├── Gemini AI
│   └── Serviços auxiliares
│
└── navigation/
    └── Navegação principal

Integrações externas

Binance API

O aplicativo utiliza endpoints públicos da Binance para consultar informações do mercado.

Não é necessária uma chave de API para as consultas públicas de leitura.

Os dados são obtidos conforme a interação do usuário:

Abertura da tela de mercado.

Alteração da moeda.

Alteração do período do gráfico.

Atualização manual.

Google Gemini API

A integração com Gemini permite incorporar recursos de Inteligência Artificial ao módulo Analista IA.

A arquitetura deve manter a comunicação protegida, preferencialmente intermediada por um backend responsável por armazenar a chave de API e controlar as requisições.

Firebase Cloud Messaging

O Firebase Cloud Messaging será utilizado como infraestrutura para notificações push.

Sua implementação depende da configuração do Firebase e de um backend ou serviço responsável por identificar os eventos e disparar as mensagens.


Integração de alertas inteligentes na Home.

Implementação de notificações push.

Desenvolvimento de backtesting para avaliação das estratégias.

Executando o projeto

Clone o repositório:

git clone URL_DO_REPOSITORIO

Acesse a pasta:

cd monitor_btc_ai

Instale as dependências:

flutter pub get

Execute o aplicativo:

flutter run

Objetivo do projeto

Desenvolver uma aplicação inteligente para monitoramento do Bitcoin, combinando dados financeiros em tempo real, persistência local, análise técnica e Inteligência Artificial.

A proposta é utilizar tecnologias modernas para transformar informações do mercado em análises compreensíveis e alertas que auxiliem o usuário na tomada de decisões.

Desenvolvido por André Luis de Sousa Santos.