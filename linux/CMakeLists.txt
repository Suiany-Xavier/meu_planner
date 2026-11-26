# Configuração geral do projeto.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Nome do executável criado para o aplicativo. Altere este valor para mudar
# o nome do aplicativo no disco.
set(BINARY_NAME "meu_planner")
# Identificador exclusivo deste aplicativo GTK. Consulte:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.suiany.meuplanner")

# Habilita explicitamente os comportamentos modernos do CMake para evitar avisos nas
# versões recentes do CMake.
cmake_policy(SET CMP0063 NEW)

# Carrega as bibliotecas distribuídas na pasta lib/ relativa ao executável.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Sistema de arquivos raiz para compilação cruzada.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define as opções de configuração da compilação.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Configurações de compilação aplicadas à maioria dos destinos.
#
# Tenha cuidado ao adicionar opções aqui, pois os plugins usam esta função por
# padrão. Na maioria dos casos, adicione novas opções a destinos específicos, em vez
# de modificar esta função.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Regras de compilação da biblioteca e das ferramentas Flutter.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Dependências do sistema.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Compilação do aplicativo; consulte runner/CMakeLists.txt.
add_subdirectory("runner")

# Executa as etapas de compilação da ferramenta Flutter. Não remova esta configuração.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Somente a cópia do executável incluída no pacote gerado pela instalação será iniciada
# corretamente, pois os recursos precisam estar nos caminhos relativos esperados. Para evitar
# a execução da cópia avulsa, ela é colocada em uma subpasta, em vez
# da pasta principal padrão.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Regras geradas de compilação de plugins, responsáveis por compilá-los e adicioná-los
# ao aplicativo.
include(flutter/generated_plugins.cmake)


# === Instalação ===
# Por padrão, a "instalação" apenas cria um pacote que pode ser movido na pasta de
# compilação.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Inicia cada compilação com a pasta do pacote limpa.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/runner/resources/app_icon.png"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copia os recursos nativos fornecidos pelo build.dart de todos os pacotes.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Copia novamente toda a pasta de recursos em cada compilação para evitar arquivos antigos
# de uma instalação anterior.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Instala a biblioteca AOT apenas em compilações que não sejam de depuração.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
