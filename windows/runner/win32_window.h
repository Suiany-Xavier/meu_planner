#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// Abstração de uma janela Win32 com suporte a alta densidade de pixels, destinada a
// classes derivadas que precisem personalizar a
// renderização e o tratamento de entrada
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Cria uma janela Win32 com |title|, posicionada e dimensionada usando
  // |origin| e |size|. Novas janelas são criadas no monitor padrão. Os tamanhos
  // são informados ao sistema operacional em pixels físicos. Para garantir um
  // tamanho consistente, esta função ajusta a largura e a altura fornecidas
  // conforme o monitor padrão. A janela fica invisível até que
  // |Show| seja chamado. Retorna true se a janela for criada com sucesso.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Exibe a janela atual. Retorna true se ela for exibida com sucesso.
  bool Show();

  // Libera os recursos do sistema operacional associados à janela.
  void Destroy();

  // Insere |content| na árvore de janelas.
  void SetChildContent(HWND content);

  // Retorna o identificador da janela para permitir que os clientes definam o ícone e outras
  // propriedades. Retorna nullptr se a janela tiver sido destruída.
  HWND GetHandle();

  // Se for true, fechar esta janela encerrará o aplicativo.
  void SetQuitOnClose(bool quit_on_close);

  // Retorna um RECT com os limites da área cliente atual.
  RECT GetClientArea();

 protected:
  // Processa e encaminha mensagens relevantes da janela para tratar o mouse,
  // alterações de tamanho e DPI. Delega o tratamento a métodos sobrescritos que
  // as classes derivadas podem implementar.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Chamado durante CreateAndShow, permitindo que a subclasse configure a
  // janela. As subclasses devem retornar false se a configuração falhar.
  virtual bool OnCreate();

  // Chamado durante Destroy.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // Função de retorno do sistema chamada pelo processamento de mensagens. Trata WM_NCCREATE,
  // enviada durante a criação da área não cliente, e habilita o ajuste automático da
  // área não cliente conforme a densidade de pixels, para que ela
  // responda automaticamente às alterações de DPI. As demais mensagens são tratadas por
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Obtém o ponteiro para a instância da classe de |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Atualiza o tema da moldura da janela para acompanhar o tema do sistema.
  static void UpdateTheme(HWND const window);

  bool quit_on_close_ = false;

  // Identificador da janela principal.
  HWND window_handle_ = nullptr;

  // Identificador da janela que hospeda o conteúdo.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
