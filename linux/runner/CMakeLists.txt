cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define o destino de compilação do aplicativo. Para renomeá-lo, altere BINARY_NAME no
# CMakeLists.txt principal, em vez do valor daqui; caso contrário, `flutter run` deixará de
# funcionar.
#
# Adicione aqui todos os novos arquivos-fonte incluídos no aplicativo.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Aplica as configurações padrão de compilação. Esta chamada pode ser removida em aplicativos
# que precisem de configurações diferentes.
apply_standard_settings(${BINARY_NAME})

# Adiciona as definições do pré-processador para o identificador do aplicativo.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Adiciona as bibliotecas de dependências. Inclua aqui as dependências específicas do aplicativo.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
