#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Cria um console para o processo e redireciona stdout e stderr para ele,
// tanto para o inicializador quanto para a biblioteca Flutter.
void CreateAndAttachConsole();

// Recebe um wchar_t* em UTF-16 terminado em nulo e retorna uma std::string
// em UTF-8. Retorna uma std::string vazia em caso de falha.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Obtém os argumentos da linha de comando como std::vector<std::string>,
// em UTF-8. Retorna um std::vector<std::string> vazio em caso de falha.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
