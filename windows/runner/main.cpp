#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Detect whether this process was launched as a sub-window by desktop_multi_window.
  // Sub-windows receive "multi_window <id> <args>" as the command-line.
  const bool is_sub_window = !command_line_arguments.empty() &&
                             command_line_arguments[0] == "multi_window";

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  // Use a compact initial size for sub-windows to minimize the flash before
  // the Dart side reconfigures the window via window_manager.
  Win32Window::Size size = is_sub_window ? Win32Window::Size(320, 220)
                                         : Win32Window::Size(1280, 720);

  // Sub-windows are borderless (WS_POPUP) and always-on-top (WS_EX_TOPMOST).
  // WS_EX_TOOLWINDOW keeps them out of the taskbar and Alt+Tab list.
  const DWORD win_style    = is_sub_window ? WS_POPUP : WS_OVERLAPPEDWINDOW;
  const DWORD win_ex_style = is_sub_window
      ? (WS_EX_TOPMOST | WS_EX_TOOLWINDOW)
      : 0;

  if (!window.Create(L"greenish", origin, size, win_style, win_ex_style)) {
    return EXIT_FAILURE;
  }

  // Only the main window should quit the whole app on close.
  // Sub-windows are short-lived reminders and must NOT terminate the process.
  if (!is_sub_window) {
    window.SetQuitOnClose(true);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
