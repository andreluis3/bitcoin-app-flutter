# Como executar o projeto BTC Monitor AI

## 1. Pré-requisitos

Antes de executar o projeto, certifique-se de ter instalado:

- Flutter SDK
- Dart SDK
- Android Studio ou Visual Studio Code
- Extensão Flutter e Dart no VS Code
- Um dispositivo Android conectado via USB ou um emulador configurado

Para verificar se o ambiente está configurado corretamente, execute:

```bash
flutter doctor
```

## 2. Instalar as dependências

Na raiz do projeto, execute:

```bash
flutter pub get
```

Esse comando instala todas as dependências necessárias para executar o aplicativo.

## 3. Configurar a chave da API Gemini

O aplicativo utiliza a API do Google Gemini para seus recursos de inteligência artificial.

Para que a integração funcione, é necessário criar um arquivo chamado `env.json` na raiz do projeto, no mesmo nível do arquivo `pubspec.yaml`.

O arquivo deve seguir esta estrutura:

```json
{
  "GEMINI_API_KEY": "SUA_CHAVE_DA_API_GEMINI"
}
```

Substitua `SUA_CHAVE_DA_API_GEMINI` pela sua chave válida da API Gemini.

**Importante:**
- O arquivo `env.json` não deve ser enviado ao GitHub, pois contém uma chave privada.
- Cada desenvolvedor deve configurar sua própria chave de API.
- Sem essa configuração, os recursos que dependem do Gemini poderão não funcionar corretamente.

## 4. Executar o aplicativo

**Atenção: não utilize apenas `flutter run`.**

É necessário informar ao Flutter que ele deve carregar as variáveis definidas no arquivo `env.json`.

Execute o seguinte comando na raiz do projeto:

```bash
flutter run --dart-define-from-file=env.json
```

Esse comando carrega a chave da API Gemini durante a inicialização do aplicativo.

### Executar em um dispositivo específico

Caso existam vários dispositivos conectados, primeiro consulte os dispositivos disponíveis:

```bash
flutter devices
```

Depois, execute informando o identificador do dispositivo:

```bash
flutter run -d ID_DO_DISPOSITIVO --dart-define-from-file=env.json
```

Exemplo:

```bash
flutter run --dart-define-from-file=env.json -d EQSGMRVKPVK7VWJB
```

## 5. Executar pelo VS Code

Também é possível executar o projeto pelo terminal integrado do VS Code.

Abra a pasta do projeto, acesse:

**Terminal → New Terminal**

E execute:

```bash
flutter run --dart-define-from-file=env.json
```

## 6. Comandos úteis

| Comando | Finalidade |
|---|---|
| `flutter pub get` | Instalar dependências |
| `flutter devices` | Listar dispositivos disponíveis |
| `flutter clean` | Limpar arquivos de compilação |
| `dart analyze lib` | Analisar o código Dart |
| `flutter build apk --debug --dart-define-from-file=env.json` | Gerar APK de depuração |
| `flutter run --dart-define-from-file=env.json` | Executar o aplicativo carregando a API |

---

**Observação:** sempre que executar o aplicativo em um novo ambiente, confira se o arquivo `env.json` foi criado e se contém uma chave Gemini válida. O parâmetro `--dart-define-from-file=env.json` é necessário para disponibilizar essa configuração ao aplicativo.