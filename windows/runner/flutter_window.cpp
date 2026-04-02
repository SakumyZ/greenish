#include "flutter_window.h"

#include <optional>

#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

/// Called by desktop_multi_window after a sub-window's Flutter engine is created.
/// Makes the sub-window borderless (no title bar) and always-on-top.
void OnSubWindowCreated(void* flutter_view_controller) {
  auto controller =
      static_cast<flutter::FlutterViewController*>(flutter_view_controller);
  auto view_hwnd = controller->view()->GetNativeWindow();
  auto hwnd = GetAncestor(view_hwnd, GA_ROOT);
  if (!hwnd) return;

  // Remove decorations, add WS_POPUP for borderless appearance
  LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU |
             WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
  style |= WS_POPUP | WS_CLIPCHILDREN;
  SetWindowLongPtr(hwnd, GWL_STYLE, style);

  // Topmost + tool window (skip taskbar and Alt+Tab)
  LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  exStyle |= WS_EX_TOPMOST | WS_EX_TOOLWINDOW;
  exStyle &= ~WS_EX_APPWINDOW;
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);

  // Apply changes and pin to HWND_TOPMOST z-order
  SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::RegisterWindowMetricsChannel() {
  window_metrics_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "greenish/window_metrics",
          &flutter::StandardMethodCodec::GetInstance());

  window_metrics_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "getCurrentMonitorMetrics") {
          result->NotImplemented();
          return;
        }

        // Use the primary monitor (origin point 0,0) so the reminder popup
        // always appears on the user's primary display, regardless of which
        // monitor the main window is currently on.
        const POINT origin = {0, 0};
        const HMONITOR monitor = MonitorFromPoint(origin, MONITOR_DEFAULTTOPRIMARY);
        MONITORINFO monitor_info;
        monitor_info.cbSize = sizeof(monitor_info);
        if (!GetMonitorInfo(monitor, &monitor_info)) {
          result->Error("monitor-unavailable", "Failed to query monitor work area.");
          return;
        }

        const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
        const double scale_factor = static_cast<double>(dpi) / 96.0;
        const RECT work_area = monitor_info.rcWork;

        flutter::EncodableMap metrics;
        metrics[flutter::EncodableValue("left")] =
            flutter::EncodableValue(static_cast<double>(work_area.left));
        metrics[flutter::EncodableValue("top")] =
            flutter::EncodableValue(static_cast<double>(work_area.top));
        metrics[flutter::EncodableValue("width")] =
            flutter::EncodableValue(static_cast<double>(work_area.right - work_area.left));
        metrics[flutter::EncodableValue("height")] =
            flutter::EncodableValue(static_cast<double>(work_area.bottom - work_area.top));
        metrics[flutter::EncodableValue("scaleFactor")] =
            flutter::EncodableValue(scale_factor);
        result->Success(flutter::EncodableValue(metrics));
      });
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterWindowMetricsChannel();

  // When desktop_multi_window creates a reminder sub-window, apply borderless
  // + topmost styles. The callback runs on the UI thread right after the
  // sub-window's Flutter engine is created.
  DesktopMultiWindowSetWindowCreatedCallback(OnSubWindowCreated);

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
