# Identidade e distribuição do Meu Planner

## Identidade definida

- Nome exibido: **Meu Planner**.
- Descrição: **Organize suas tarefas por dia com o Meu Planner. Suas tarefas, no seu ritmo.**
- Idioma: **pt-BR**.
- Identificador Android, iOS e macOS: **com.suiany.meuplanner**.
- Identificador de aplicação Linux: **com.suiany.meuplanner**.
- Executáveis Linux e Windows: **meu_planner** e **meu_planner.exe**.
- Pacote macOS: **meu_planner.app**, com nome de exibição **Meu Planner**.
- Cor principal: **#0821AF**, acompanhada de rosa, ciano, verde e bordas escuras.
- Versão inicial: **1.0.0+1**, definida em `pubspec.yaml`.

O identificador foi alterado antes da primeira publicação. Depois de publicar, mantenha o identificador da loja para que novas versões sejam reconhecidas como atualizações. A instalação anterior com o identificador de exemplo é um aplicativo diferente.

## Ícones

A fonte editável está em `assets/branding/app_icon.svg`. As exportações estão nos diretórios nativos de Android, iOS, macOS, Linux e Windows e em `web/`. O PNG de 512 px para materiais de distribuição fica em `assets/branding/app_icon_512.png`.

O ícone tem fundo opaco e conteúdo centralizado, inclusive nas variantes maskable da web e no ícone adaptativo do Android. As imagens de iOS são exportadas sem canal alfa.

Para gerar novamente os ícones, em um ambiente Linux com Python, Pillow e PyGObject/Rsvg instalados:

```bash
python3 tool/generate_icons.py
```

No Ubuntu, as dependências do gerador são fornecidas pelos pacotes `python3-pil`, `python3-gi` e `gir1.2-rsvg-2.0`. O gerador não é necessário para compilar o aplicativo: as imagens exportadas já fazem parte do projeto.

## Android: chave de publicação

As versões de depuração continuam usando a assinatura de desenvolvimento. As versões **release exigem uma chave própria**; não há mais substituição pela chave debug quando faltam as credenciais.

Se já tiver uma chave de upload, use-a. Caso precise criar a primeira, execute localmente o comando abaixo com o JDK instalado, escolhendo um caminho privado fora do repositório:

```bash
keytool -genkeypair -v -keystore /caminho/privado/meu-planner-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

O comando solicitará os dados e senhas interativamente. Não coloque senhas na linha de comando nem em arquivos versionados.

Copie `android/key.properties.example` para `android/key.properties` e preencha:

```properties
storeFile=/caminho/privado/meu-planner-upload.jks
storePassword=SUA_SENHA_LOCAL
keyAlias=upload
keyPassword=SUA_SENHA_LOCAL
```

`storeFile` aceita um caminho absoluto ou relativo à pasta `android/`. No Windows, use barras `/`, por exemplo `C:/Users/seu-usuario/chaves/upload.jks`.

O `.gitignore` exclui `key.properties`, keystores e certificados. Guarde uma cópia segura da chave e de suas credenciais. Não as inclua em mensagens, commits ou artefatos públicos.

Para verificar a configuração sem gerar um release, na pasta `android/`:

```bash
./gradlew :app:validateReleaseSigning
```

A verificação informa se as quatro propriedades e o arquivo de keystore estão presentes. A validade da senha, do alias e do certificado é conferida pelo Android ao assinar o release.

Na raiz do projeto, gere o pacote destinado ao Google Play:

```bash
flutter build appbundle --release
```

Artefato: `build/app/outputs/bundle/release/app-release.aab`.

Para distribuição de APK fora da loja:

```bash
flutter build apk --release --split-per-abi
```

Artefatos: `build/app/outputs/flutter-apk/`. O build de release falha com uma orientação de configuração quando falta a chave.

Esses passos seguem a [documentação oficial de distribuição Android do Flutter](https://docs.flutter.dev/deployment/android). O cadastro da conta da loja e o envio do aplicativo são etapas separadas.

## Web

```bash
flutter build web --release
```

Publique o conteúdo completo de `build/web/` em uma hospedagem com HTTPS. Para servir em uma subpasta, ajuste o build, por exemplo:

```bash
flutter build web --release --base-href /meu-planner/
```

O `<base>` do HTML é preenchido pelo Flutter. `start_url`, `scope` e `id` do manifesto são relativos à pasta publicada. A orientação não fica limitada ao modo retrato, permitindo o layout de computador.

## Linux, Windows e Apple

No sistema correspondente:

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
flutter build ipa --release
```

Distribua a pasta completa do bundle Linux (`build/linux/x64/release/bundle/`) e, no Windows, a pasta de release com o executável e suas bibliotecas (`build/windows/x64/runner/Release/`). Esses comandos geram os arquivos do aplicativo; instaladores e assinatura de executáveis são etapas posteriores de empacotamento.

As compilações iOS e macOS exigem um Mac com Xcode. Selecione a equipe da sua conta Apple e configure os certificados e perfis de assinatura no projeto Runner. Nenhuma equipe, credencial Apple ou certificado de publicação foi inventado ou incluído neste projeto.

## Atualizações e validação

Atualize a versão em `pubspec.yaml`, por exemplo `1.0.1+2`. A parte após `+` é o número do build e deve avançar nas próximas publicações. Teste a instalação e a atualização em dispositivos reais antes de distribuir.

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
```

A preparação de identidade e empacotamento não modifica o armazenamento: contas e tarefas continuam em memória. A autenticação atual é de demonstração, conforme documentado no README. A publicação em lojas e a implantação de um backend não foram realizadas.
