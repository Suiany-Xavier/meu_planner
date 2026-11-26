cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define o destino de compilação do aplicativo. Para renomeá-lo, altere BINARY_NAME no
# CMakeLists.txt principal, em vez do valor daqui; caso contrário, `flutter run` deixará de
# funcionar.
#
# Adicione aqui todos os novos arquivos-fonte incluídos no aplicativo.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Aplica as configurações padrão de compilação. Esta chamada pode ser removida em aplicativos
# que precisem de configurações diferentes.
apply_standard_settings(${BINARY_NAME})

# Adiciona as definições do pré-processador para a versão da compilação.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Desativa as macros do Windows que entram em conflito com funções da biblioteca padrão do C++.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Adiciona as bibliotecas de dependências e as pastas de inclusão. Inclua aqui as dependências
# específicas do aplicativo.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Executa as etapas de compilação da ferramenta Flutter. Não remova esta configuração.
add_dependencies(${BINARY_NAME} flutter_assemble)
