.386
.model flat, stdcall

include asmpaint.Inc

.data


    className BYTE "AsmPaintClass",0
    canvasClassName BYTE "AsmPaintCanvasClass",0
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

    g_canvasWidth DWORD 800
    g_canvasHeight DWORD 600
    g_canvasOffsetX DWORD 0
    g_canvasOffsetY DWORD 0
    
    SCROLL_STEP_PIXEL equ 5
    SCROLL_MOVE_STEPS equ 20

    debugWndProcMsg BYTE "%u %u %d",0ah,0
    debugPrintInt BYTE "%d", 0ah, 0
    ;showRegs BYTE "%d",0ah,0; debug
    
    g_toolbarStatus DWORD IDM_PENCIL ;default to IDM_PENCIL
.data?
    g_hInst HINSTANCE ?
    g_cmdLine LPTSTR ?
    g_hWnd HWND ?
    g_hWndControl HWND ?
    g_hWndCanvas HWND ?
    g_hImageListControl HIMAGELIST ?
    g_hdcBuf HDC ?
    g_hdcBitmap HBITMAP ?
    
.code

CalculateCanvasWindowPosition proc USES esi, hWnd:HWND, toolbarWnd:HWND, canvasRect:PTR
    ; Note: canvasRect.left = left pos,  canvasRect.right  = width
    ;       canvasRect.top  = top pos,   canvasRect.bottom = height
    LOCAL toolbarRect:RECT
    LOCAL hWndRect:RECT
    
    invoke GetWindowRect, toolbarWnd, addr toolbarRect
    invoke GetClientRect, hWnd, addr hWndRect
    
    mov esi, canvasRect
    mov eax, hWndRect.left
    mov (RECT PTR [esi]).left, eax
    
    mov eax, toolbarRect.bottom
    sub eax, toolbarRect.top
    mov (RECT PTR [esi]).top, eax 
    
    mov eax, hWndRect.right
    sub eax, (RECT PTR [esi]).left
    mov (RECT PTR [esi]).right, eax
    
    mov eax, hWndRect.bottom
    sub eax, (RECT PTR [esi]).top
    mov (RECT PTR [esi]).bottom, eax
    
    ret
CalculateCanvasWindowPosition endp


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hBmp:HBITMAP
    LOCAL canvasWndRect:RECT
    
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
        
        ; ===== Create Canvas Child Window =====
        invoke CalculateCanvasWindowPosition, hWnd, g_hWndControl, addr canvasWndRect
        invoke CreateWindowEx, 0, addr canvasClassName, NULL, WS_CHILD or WS_HSCROLL or WS_VSCROLL, \
               canvasWndRect.left, canvasWndRect.top, canvasWndRect.right, canvasWndRect.bottom, \
               hWnd, NULL, g_hInst, NULL
        mov g_hWndCanvas, eax
        
        invoke ShowWindow, g_hWndCanvas, SW_SHOW        
    .ELSEIF uMsg == WM_SIZE
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
        invoke CalculateCanvasWindowPosition, g_hWnd, g_hWndControl, addr canvasWndRect
        invoke SetWindowPos, g_hWndCanvas, HWND_TOP, canvasWndRect.left, canvasWndRect.top, \
               canvasWndRect.right, canvasWndRect.bottom, SWP_SHOWWINDOW
    .ELSEIF uMsg == WM_COMMAND
        invoke crt_printf, offset debugWndProcMsg, uMsg, wParam, lParam
        mov eax, wParam
        mov g_toolbarStatus, eax
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam      
        ret
    .ENDIF
    
    xor eax,eax
    ret
WndProc endp

CreateCanvas proc hWnd:HWND
    LOCAL hdc: HDC
    invoke GetDC, hWnd
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov g_hdcBuf, eax
    invoke CreateCompatibleBitmap, hdc, g_canvasWidth, g_canvasWidth
    mov g_hdcBitmap, eax
    invoke SelectObject, g_hdcBuf, g_hdcBitmap
    invoke ReleaseDC, hWnd, hdc
    ret
CreateCanvas endp

ClearCanvas proc
    LOCAL canvasRect:RECT
    mov canvasRect.left, 0
    mov canvasRect.top, 0
    mov eax, g_canvasWidth
    mov canvasRect.right, eax
    mov eax, g_canvasHeight
    mov canvasRect.bottom, eax
    invoke FillRect, g_hdcBuf, addr canvasRect, WHITE_BRUSH
    ret
ClearCanvas endp

CanvasWinProc proc USES ebx,
    hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hdc:HDC
    LOCAL ps:PAINTSTRUCT
    LOCAL canvasWndRect:RECT
    LOCAL scrollbarInfo:SCROLLINFO
    LOCAL cxClient:DWORD
    LOCAL cyClient:DWORD
    LOCAL iVertPos:DWORD
    LOCAL iHorzPos:DWORD
    LOCAL scrollBarMsgPara:DWORD
    
    .IF uMsg == WM_CREATE
        ; ===== Create HDC Buffer =====
        invoke CreateCanvas, hWnd
        invoke ClearCanvas
    .ELSEIF uMsg == WM_SIZE
        mov eax, lParam
        movzx edx, ax
        mov cxClient, edx
        shr eax, 16
        mov cyClient, eax
        
        ; ==== Update Vertical Scrollbar ====
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE
        mov scrollbarInfo.nMin, 0
        mov eax, cyClient
        mov ebx, SCROLL_STEP_PIXEL
        xor edx, edx
        div ebx
        mov scrollbarInfo.nPage, eax
        mov eax, g_canvasHeight
        mov ebx, SCROLL_STEP_PIXEL
        xor edx, edx
        div ebx 
        mov scrollbarInfo.nMax, eax
        
        invoke SetScrollInfo, hWnd, SB_VERT, addr scrollbarInfo, TRUE
        
        ; ==== Update Horizontal Scrollbar ====
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE
        mov scrollbarInfo.nMin, 0
        mov eax, cxClient
        mov ebx, SCROLL_STEP_PIXEL
        xor edx, edx
        div ebx
        mov scrollbarInfo.nPage, eax
        mov eax, g_canvasWidth
        mov ebx, SCROLL_STEP_PIXEL
        xor edx, edx
        div ebx 
        mov scrollbarInfo.nMax, eax
        
        invoke SetScrollInfo, hWnd, SB_HORZ, addr scrollbarInfo, TRUE
    .ELSEIF uMsg == WM_VSCROLL
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE or SIF_POS or SIF_TRACKPOS
        invoke GetScrollInfo, hWnd, SB_VERT, addr scrollbarInfo
        mov eax, scrollbarInfo.nPos
        mov iVertPos, eax
        
        mov esi, wParam
        mov eax, esi
        movzx edx, ax
        mov scrollBarMsgPara, edx
        .IF scrollBarMsgPara == SB_LINEUP
            sub scrollbarInfo.nPos, SCROLL_MOVE_STEPS
        .ELSEIF scrollBarMsgPara == SB_LINEDOWN
            add scrollbarInfo.nPos, SCROLL_MOVE_STEPS
        .ELSEIF scrollBarMsgPara == SB_THUMBTRACK
            mov eax, scrollbarInfo.nTrackPos
            mov scrollbarInfo.nPos, eax
        .ENDIF
        mov scrollbarInfo.fMask, SIF_POS
        invoke SetScrollInfo, hWnd, SB_VERT, addr scrollbarInfo, TRUE
        invoke GetScrollInfo, hWnd, SB_VERT, addr scrollbarInfo
        mov eax, iVertPos
        .IF eax != scrollbarInfo.nPos
            invoke InvalidateRect, hWnd, NULL, FALSE
        .ENDIF  
        
    .ELSEIF uMsg == WM_HSCROLL
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE or SIF_POS or SIF_TRACKPOS
        invoke GetScrollInfo, hWnd, SB_HORZ, addr scrollbarInfo
        mov eax, scrollbarInfo.nPos
        mov iHorzPos, eax
        
        mov esi, wParam
        mov eax, esi
        movzx edx, ax
        mov scrollBarMsgPara, edx
        .IF scrollBarMsgPara == SB_LINELEFT
            sub scrollbarInfo.nPos, SCROLL_MOVE_STEPS
        .ELSEIF scrollBarMsgPara == SB_LINERIGHT
            add scrollbarInfo.nPos, SCROLL_MOVE_STEPS
        .ELSEIF scrollBarMsgPara == SB_THUMBTRACK
            mov eax, scrollbarInfo.nTrackPos
            mov scrollbarInfo.nPos, eax
        .ENDIF
        mov scrollbarInfo.fMask, SIF_POS
        invoke SetScrollInfo, hWnd, SB_HORZ, addr scrollbarInfo, TRUE
        invoke GetScrollInfo, hWnd, SB_HORZ, addr scrollbarInfo
        mov eax, iHorzPos
        .IF eax != scrollbarInfo.nPos
            invoke InvalidateRect, hWnd, NULL, FALSE
        .ENDIF
        
    .ELSEIF uMsg == WM_PAINT
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE or SIF_POS or SIF_TRACKPOS
        invoke GetScrollInfo, hWnd, SB_VERT, addr scrollbarInfo
        mov eax, scrollbarInfo.nPos
        mov edx, SCROLL_STEP_PIXEL
        mul edx
        mov g_canvasOffsetY, eax
        mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
        mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE or SIF_POS or SIF_TRACKPOS
        invoke GetScrollInfo, hWnd, SB_HORZ, addr scrollbarInfo
        mov eax, scrollbarInfo.nPos
        mov edx, SCROLL_STEP_PIXEL
        mul edx
        mov g_canvasOffsetX, eax
        invoke crt_printf, offset debugPrintInt, g_canvasOffsetX
        invoke crt_printf, offset debugPrintInt, g_canvasOffsetY
        
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke MoveToEx, g_hdcBuf, 0, 0, NULL
        ;invoke crt_rand
        invoke LineTo, g_hdcBuf, 900, 900
        
        invoke SetDCBrushColor, hdc, 0abababh
        invoke Rectangle, hdc, 0, 0, g_canvasWidth, g_canvasHeight
        
        mov eax, g_canvasWidth
        sub eax, g_canvasOffsetX
        mov edx, g_canvasHeight
        sub edx, g_canvasOffsetY
        invoke BitBlt, hdc, 0, 0, eax, \
               edx, g_hdcBuf, g_canvasOffsetX, g_canvasOffsetY, SRCCOPY
        invoke EndPaint, hWnd, addr ps
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
CanvasWinProc endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, cmdLine:LPSTR, cmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL cwc:WNDCLASSEX
    LOCAL msg:MSG
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    mov eax, hInst
    mov wc.hInstance, eax
    invoke GetStockObject, WHITE_BRUSH
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, IDR_MENU
    mov wc.lpszClassName, OFFSET className
    
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    invoke RegisterClassEx, addr wc
    
    mov cwc.cbSize, SIZEOF WNDCLASSEX
    mov cwc.style, CS_HREDRAW or CS_VREDRAW
    mov cwc.lpfnWndProc, OFFSET CanvasWinProc
    mov cwc.cbClsExtra, NULL
    mov cwc.cbWndExtra, NULL
    mov eax, hInst
    mov cwc.hInstance, eax
    mov cwc.hIcon, NULL
    invoke LoadCursor, NULL, IDC_ARROW
    mov cwc.hCursor, eax
    invoke CreateSolidBrush, 0abababh
    mov cwc.hbrBackground, eax
    mov cwc.lpszMenuName, NULL
    mov cwc.lpszClassName, OFFSET canvasClassName
    mov cwc.hIconSm, NULL
    invoke RegisterClassEx, addr cwc
    
    invoke CreateWindowEx, 0, ADDR className, ADDR appName, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, \
           CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, \
           hInst, NULL

    mov g_hWnd, eax
    
    invoke ShowWindow, g_hWnd, cmdShow
    invoke UpdateWindow, g_hWnd
    
    invoke RegisterHotKey, g_hWnd, IDHK_NEW, MOD_CONTROL or MOD_NOREPEAT, 'N'
    invoke RegisterHotKey, g_hWnd, IDHK_OPEN, MOD_CONTROL or MOD_NOREPEAT, 'O'
    invoke RegisterHotKey, g_hWnd, IDHK_SAVE, MOD_CONTROL or MOD_NOREPEAT, 'S'
    invoke RegisterHotKey, g_hWnd, IDHK_QUIT, MOD_ALT or MOD_NOREPEAT, VK_F4
    
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