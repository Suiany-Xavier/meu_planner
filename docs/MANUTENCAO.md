# Guia de manutenção

Detalhes técnicos para quem vai alterar o Meu Planner. A visão geral está no [README](../README.md) e os builds e assinaturas, em [DISTRIBUICAO.md](DISTRIBUICAO.md).

## Ambiente de referência

| Item | Versão |
| --- | --- |
| Flutter | **3.47.7**, canal stable |
| Dart | **3.13.5**, incluído no Flutter |
| Aplicativo | **1.0.0+1**, em [pubspec.yaml](../pubspec.yaml) |

A automação fixa a versão do Flutter em [.github/workflows/flutter.yml](../.github/workflows/flutter.yml). Para conferir o ambiente local:

```bash
flutter --version
flutter doctor -v
flutter devices
```

- **Web:** é preciso ter um navegador.
- **Android:** é preciso o SDK Android, o JDK e um emulador ou aparelho.
- **Linux:** são necessárias as ferramentas nativas de compilação e o GTK 3 de desenvolvimento.

Python, PyGObject/Rsvg e Pillow só são necessários para regenerar os ícones (`python3 tool/generate_icons.py`).

## Arquitetura

- As telas recebem seus serviços pelo construtor.
- `AuthService` não acessa `TaskStore`: o `MeuPlannerApp` coordena a troca de usuário e a atualização das telas com `ChangeNotifier` e `ListenableBuilder`.
- `MeuPlannerApp` aceita `authService` e `taskStore` para testes. Ele descarta os serviços que cria; quem fornece instâncias é responsável por chamar `dispose()`.
- `Task` é imutável. Alterações de título, data ou conclusão passam por `TaskStore`, que notifica a interface. As consultas retornam listas imutáveis.
- As senhas são guardadas como hash SHA-256 com salt aleatório por usuário (pacote `crypto`).
- Cores e estilos ficam em `lib/theme.dart` (`AppColors`, `AppText`). Os componentes visuais compartilhados ficam em `lib/widgets.dart`.

## Testes

```bash
flutter analyze
flutter test -j 2            # -j limita os arquivos em paralelo (útil com pouca memória)
flutter test --coverage      # gera coverage/lcov.info
flutter test test/calendar_dates_test.dart   # um grupo só
```

| Cenários | Arquivos |
| --- | --- |
| Cadastro, login e regras de tarefas | [widget_test.dart](../test/widget_test.dart), [services_test.dart](../test/services_test.dart), [edge_cases_test.dart](../test/edge_cases_test.dart) |
| Isolamento dos serviços e ciclo de vida | [dependencies_test.dart](../test/dependencies_test.dart) |
| Fevereiro, anos bissextos, virada do ano e navegação | [calendar_dates_test.dart](../test/calendar_dates_test.dart), [regression_test.dart](../test/regression_test.dart) |
| Edição, transferência, exclusão, desfazer e troca de contas | [task_actions_test.dart](../test/task_actions_test.dart), [user_flows_test.dart](../test/user_flows_test.dart) |
| Teclado, descrições acessíveis e texto a 200% | [accessibility_test.dart](../test/accessibility_test.dart), [large_text_test.dart](../test/large_text_test.dart) |
| Painéis lado a lado e redimensionamento | [desktop_layout_test.dart](../test/desktop_layout_test.dart) |

O GitHub Actions roda a instalação com o arquivo de lock, a análise e os testes em todo push e pull request.

## Rotina de manutenção

1. Localize a responsabilidade na arquitetura acima e atualize os testes do comportamento alterado.
2. Rode a análise e o grupo de testes afetado. Antes de enviar, rode a suíte completa.
3. Se alterar arquivos nativos ou a identidade visual, compile também a plataforma afetada (veja [DISTRIBUICAO.md](DISTRIBUICAO.md)).
4. Ao mudar dependências, rode `flutter pub get` e versione `pubspec.yaml` e `pubspec.lock` juntos. Ao mudar a versão do Flutter, atualize também o workflow e este guia.
5. Atualize as capturas em `docs/images/` (com dados fictícios e os mesmos nomes) quando a interface mudar.

`generated_plugin_registrant.*`, `generated_plugins.cmake` e o conteúdo de `ephemeral/` são recriados pelo Flutter. Altere as configurações que os geram, nunca esses arquivos.

## Diagnóstico rápido

| Situação | O que verificar |
| --- | --- |
| Conta ou tarefas sumiram após reiniciar | O armazenamento é em memória. Cadastre de novo. |
| Dependências não resolvem com o lock | Confira a versão do SDK e se `pubspec.yaml` e `pubspec.lock` são da mesma revisão. |
| `flutter test` é encerrado sem mensagem | Falta de memória. Use `flutter test -j 2` ou rode um arquivo por vez. |
| Android release pede assinatura | Siga [DISTRIBUICAO.md](DISTRIBUICAO.md) e configure sua chave local. |
| Calendário e tarefas aparecem em uma coluna | O layout lado a lado depende da largura da janela e da escala do texto. |
| Dispositivo não aparece | Use `flutter doctor -v` e `flutter devices`. |

## Plataformas verificadas (10/11/2026)

| Plataforma | Situação |
| --- | --- |
| Web | Build release concluído. |
| Android | APK de depuração compilado; o release assinado depende da chave de publicação. |
| Linux | Pacote release compilado. |
| Windows | Configuração pronta; compilação pendente em uma máquina Windows. |
| iOS e macOS | Configuração pronta; compilação e assinatura pendentes em um Mac com Xcode. |
