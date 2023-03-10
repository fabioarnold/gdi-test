const std = @import("std");
const win32 = @import("zigwin32");
const windows = win32.everything;

const classname = std.unicode.utf8ToUtf16LeStringLiteral("GDITEST");
const window_title = std.unicode.utf8ToUtf16LeStringLiteral("GDI-Test");
const w = 600;
const h = 400;

pub fn main() !void {
    const module_handle = windows.GetModuleHandleW(null);

    const window_class_info = windows.WNDCLASSEXW{
        .cbSize = @sizeOf(windows.WNDCLASSEXW),
        .style = windows.WNDCLASS_STYLES.initFlags(.{.HREDRAW = 1, .VREDRAW = 1}),
        .lpfnWndProc = &wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = @ptrCast(windows.HINSTANCE, module_handle),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = classname,
        .hIconSm = null,
    };

    if (windows.RegisterClassExW(&window_class_info) == 0) {
        return error.RegisterClassFailed;
    }

    const ex_style = windows.WINDOW_EX_STYLE.initFlags(.{});
    const x = windows.CW_USEDEFAULT;
    const y = windows.CW_USEDEFAULT;
    const style = windows.WS_OVERLAPPEDWINDOW;
    const window_handle = windows.CreateWindowExW(ex_style, classname, window_title, style, x, y, w, h, null, null, module_handle, null) orelse return error.CreateWindowFailed;

    _ = windows.ShowWindow(window_handle, windows.SHOW_WINDOW_CMD.SHOWNORMAL);
    _ = windows.UpdateWindow(window_handle);

    var msg: windows.MSG = undefined;
    while (windows.GetMessageW(&msg, null, 0, 0) != 0) {
        _ = windows.TranslateMessage(&msg);
        _ = windows.DispatchMessageW(&msg);
    }
}

fn wndProc(hwnd: windows.HWND, uMsg: u32, wParam: usize, lParam: isize) callconv(.C) isize {
    switch (uMsg) {
        windows.WM_CLOSE => {
            _ = windows.DestroyWindow(hwnd);
        },
        windows.WM_DESTROY => {
            _ = windows.PostQuitMessage(0);
        },
        windows.WM_MOUSEMOVE => {
            // clear
            const hdc = windows.GetDC(hwnd);
            var rect = windows.RECT{ .left = 0, .top = 0, .right = w, .bottom = h };
            const white_brush = windows.CreateSolidBrush(255 | 255 << 8 | 255 << 16);
            _ = windows.FillRect(hdc, &rect, white_brush);

            // draw rect at mouse position
            const pos = @bitCast([2]u16, @intCast(u32, lParam));
            rect.left = pos[0];
            rect.top = pos[1];
            rect.right = rect.left + 20;
            rect.bottom = rect.top + 20;
            const black_brush = windows.CreateSolidBrush(0);
            _ = windows.FillRect(hdc, &rect, black_brush);
        },
        else => {
            return windows.DefWindowProcW(hwnd, uMsg, wParam, lParam);
        },
    }
    return 0;
}
