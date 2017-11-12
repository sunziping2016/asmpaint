.386
.model flat, stdcall

include asmpaint.Inc

.data


    className BYTE "AsmPaintClass",0
    appName BYTE "»­Í¼",0
   
    toolbarClassName BYTE "ToolbarWindow32",0
   
    CONTROL_BUTTON_NUM equ 16
    g_tbControlButtons \
        TBBUTTON <0, IDM_FREE_SELECTOR, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <1, IDM_RECT_SELECTOR, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <2, IDM_ERASER, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <3, IDM_PAINT_BARREL, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <4, IDM_COLOR_PICKER, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <5, IDM_MAGNIFIER, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <6, IDM_PENCIL, TBSTATE_ENABLED or TBSTATE_CHECKED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <7, IDM_BRASH, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <8, IDM_AIRBRUSH, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <9, IDM_TEXT, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <10, IDM_STRAIGHT_LINE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <11, IDM_CURVE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <12, IDM_RECTANGLE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <13, IDM_POLYGON, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <14, IDM_ELLIPSE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>
        TBBUTTON <15, IDM_ROUNDED_RECTANGLE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, NULL>

    debugWndProcMsg BYTE "%u %u %d",0ah,0
    
    toolbar_status DWORD 00000000h ; zero if no button in menu clicked, else the ID of the button clicked
.data?
    g_hInst HINSTANCE ?
    g_cmdLine LPTSTR ?
    g_hWnd HWND ?
    g_hWndLeftReBar HWND ?
    g_hWndControl HWND ?
    g_hImageListControl HIMAGELIST ?
.code


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hBmp:HBITMAP
    ;invoke crt_printf, offset debugWndProcMsg, uMsg, wParam, lParam
    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSEIF uMsg == WM_CREATE
        ; ==== Create Left Control Toolbar ====
        invoke CreateWindowEx, 0, addr toolbarClassName, NULL, \
            CCS_NODIVIDER or WS_CHILD or WS_VISIBLE, 0, 0, 0, 0, \
            hWnd, NULL, g_hInst, NULL
        mov g_hWndControl, eax
        invoke ImageList_Create, 16, 16, ILC_COLOR16 or ILC_MASK, CONTROL_BUTTON_NUM, 0
        mov g_hImageListControl, eax
        invoke LoadBitmap, g_hInst, IDB_CONTROLS
		mov hBmp, eax
		invoke ImageList_AddMasked, g_hImageListControl, hBmp, 0ffh
		invoke DeleteObject, hBmp
        invoke SendMessage, g_hWndControl, TB_SETIMAGELIST, IDB_CONTROLS, g_hImageListControl
        invoke SendMessage, g_hWndControl, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
        invoke SendMessage, g_hWndControl, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
        invoke SendMessage, g_hWndControl, TB_ADDBUTTONS, CONTROL_BUTTON_NUM, offset g_tbControlButtons
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
    .ELSEIF uMsg == WM_SIZE
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
    .ELSEIF uMsg == WM_COMMAND
        invoke crt_printf, offset debugWndProcMsg, uMsg, wParam, lParam
        mov toolbar_status, 00000000h
        mov eax, wParam
        mov toolbar_status, eax
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam      
        ret
    .ENDIF
    
    xor eax,eax
    ret
WndProc endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, cmdLine:LPSTR, cmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    mov eax, hInst
    mov wc.hInstance, eax
    invoke GetStockObject, GRAY_BRUSH
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, IDR_MENU
    mov wc.lpszClassName, OFFSET className
    
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    invoke RegisterClassEx, addr wc
    invoke CreateWindowEx, NULL, ADDR className, ADDR appName, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, \
           CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, \
           hInst, NULL

    mov g_hWnd, eax
    
    invoke ShowWindow, g_hWnd, cmdShow
    invoke UpdateWindow, g_hWnd
    
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .BREAK .IF !eax
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    
    mov eax,msg.wParam
    ret
WinMain endp

start proc
    LOCAL iccx:INITCOMMONCONTROLSEX
    invoke GetModuleHandle, NULL
    mov g_hInst, eax
    invoke GetCommandLine
    mov g_cmdLine, eax
    mov iccx.dwSize, sizeof INITCOMMONCONTROLSEX
    mov iccx.dwICC, ICC_BAR_CLASSES
    invoke InitCommonControlsEx, addr iccx
    invoke WinMain, g_hInst, NULL, g_cmdLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax
start endp
    
end start