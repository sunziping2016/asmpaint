.386
.model flat, stdcall

include asmpaint.Inc

UpdateScrollBarSize proto

.data
    className BYTE "AsmPaintClass",0
    canvasClassName BYTE "AsmPaintCanvasClass",0
    appName BYTE "画图",0
   
    toolbarClassName BYTE "ToolbarWindow32",0
    statusBarClassName BYTE "msctls_statusbar32", 0

    g_tbControlButtons \
        TBBUTTON <8, 0, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_SEP, 0, 0, NULL>
        TBBUTTON <0, IDM_FREE_SELECTOR, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <1, IDM_RECT_SELECTOR, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <2, IDM_ERASER, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <3, IDM_PAINT_BARREL, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <4, IDM_COLOR_PICKER, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <5, IDM_MAGNIFIER, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <6, IDM_PENCIL, TBSTATE_ENABLED or TBSTATE_CHECKED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <7, IDM_BRASH, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <8, IDM_AIRBRUSH, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <9, IDM_TEXT, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <10, IDM_STRAIGHT_LINE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <11, IDM_CURVE, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <12, IDM_RECTANGLE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <13, IDM_POLYGON, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <14, IDM_ELLIPSE, TBSTATE_ENABLED, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <15, IDM_ROUNDED_RECTANGLE, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE or BTNS_CHECKGROUP, 0, 0, NULL>
        TBBUTTON <8, 0, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_SEP, 0, 0, NULL>
        TBBUTTON <16, IDM_FOREGROUND_COLOR, TBSTATE_ENABLED, BTNS_AUTOSIZE, 0, 0, NULL>
        TBBUTTON <17, IDM_BACKGROUND_COLOR, TBSTATE_ENABLED or TBSTATE_WRAP, BTNS_AUTOSIZE, 0, 0, NULL>
    CONTROL_BUTTON_NUM = ($ - g_tbControlButtons) / sizeof TBBUTTON

    openFileDialogName BYTE "打开", 0
    openFileFilterPattern BYTE "位图文件 (*.bmp)", 0, "*.bmp", 0, 0
    
    confirmCloseDialogText BYTE "将更改保存到文件吗？", 0
    confirmCloseDialogName BYTE "画图", 0
    coordinateFormat BYTE "%d, %d", 0
    
    aboutDialogText BYTE "由车行、孙子平、赵尚明协作开发完成。", 0ah, "以及，辣鸡大作孽，毁我青春，掉我头发！", 0
    aboutDialogName BYTE "关于", 0
    
    MAX_FILE_NAME_SIZE equ 256
    MAX_ZOOM equ 8
    MAX_COORDINATE_BUFFER equ 50

    saveFileDialogName BYTE "另存为", 0
    g_bitmapName BYTE MAX_FILE_NAME_SIZE dup(0)
    defaultSaveAsName BYTE "untitle.bmp", 0

    DEFAULT_CANVAS_WIDTH equ 800
    DEFAULT_CANVAS_HEIGHT equ 600
    g_canvasWidth DWORD DEFAULT_CANVAS_WIDTH
    g_canvasHeight DWORD DEFAULT_CANVAS_HEIGHT
    g_canvasOffsetX DWORD 0
    g_canvasOffsetY DWORD 0
    g_zoom DWORD 1

    SCROLL_STEP_PIXEL equ 4
    SCROLL_LINE_STEPS equ 25
    SCROLL_PAGE_STEPS equ 100
    CANVAS_MARGIN equ 3
    TOOLBAR_WIDTH equ 48
    STATUSBAR_INFO_MINWIDTH equ 520
    STATUSBAR_COORDINATES_WIDTH equ 120
    STATUSBAR_ENDING_WIDTH equ 24

    debugWndProcMsg BYTE "%u %u %d",0ah,0
    debugPrintInt BYTE "%d", 0ah, 0
    
    g_toolbarStatus DWORD IDM_PENCIL ;default to IDM_PENCIL
    g_customColors DWORD 16 DUP(0ffffffh)
    g_isModified DWORD 0

    g_mouseCanvasX SDWORD 0
    g_mouseCanvasY SDWORD 0
    g_mouseClientX SDWORD 0
    g_mouseClientY SDWORD 0
    g_mouseInCanvas DWORD 0
    g_mouseTracking DWORD 0
    
    FILL_DEFAULT equ 0
    FILL_WITHOUT_BORDER equ 1
    FILL_WITHOUT_FILL equ 2
    g_fillType DWORD FILL_WITHOUT_BORDER
    g_penWidth DWORD 10
    
    g_pen HPEN NULL
    g_brush HBRUSH NULL

.data?
    g_hInst HINSTANCE ?
    g_cmdLine LPTSTR ?
    g_hWnd HWND ?
    g_hWndControl HWND ?
    g_hWndCanvas HWND ?
    g_hWndStatusBar HWND ?
    g_hImageListControl HIMAGELIST ?
    g_hdcBuf HDC ?
    g_hdcBitmap HBITMAP ?
    
    g_foregroundColor DWORD ?
    g_backgroundColor DWORD ?

.code

CreateCanvas proc hWnd:HWND
    LOCAL hdc: HDC
    invoke GetDC, hWnd
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov g_hdcBuf, eax
    invoke CreateCompatibleBitmap, hdc, g_canvasWidth, g_canvasHeight
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

DestoryCanvas proc
    invoke DeleteObject, g_hdcBitmap
    invoke DeleteDC, g_hdcBuf
    ret
DestoryCanvas endp

CalculateCanvasWindowPosition proc USES esi, hWnd:HWND, toolbarWnd:HWND, canvasRect:PTR
    ; Note: canvasRect.left = left pos,  canvasRect.right  = width
    ;       canvasRect.top  = top pos,   canvasRect.bottom = height
    LOCAL hWndRect:RECT
    LOCAL rectStatusBar:RECT
    
    invoke GetClientRect, hWnd, addr hWndRect
    invoke GetWindowRect, g_hWndStatusBar, addr rectStatusBar
    
    mov esi, canvasRect
    
    mov (RECT PTR [esi]).left, TOOLBAR_WIDTH
    mov (RECT PTR [esi]).top, 0 
    
    mov eax, hWndRect.right
    sub eax, TOOLBAR_WIDTH
    mov (RECT PTR [esi]).right, eax
    
    
    mov eax, hWndRect.bottom
    mov edx, rectStatusBar.bottom
    sub edx, rectStatusBar.top
    sub eax, edx
    mov (RECT PTR [esi]).bottom, eax
    
    ret
CalculateCanvasWindowPosition endp

OpenOpenBitmapDialog proc USES esi, 
    hWnd:HWND, pfilename:PTR
    LOCAL openFileStruct:OPENFILENAME
    ; ==== Open dialog ====
    mov openFileStruct.lStructSize, SIZEOF openFileStruct
    mov eax, hWnd
    mov openFileStruct.hwndOwner, eax
    mov openFileStruct.hInstance, NULL
    mov openFileStruct.lpstrFilter, OFFSET openFileFilterPattern
    mov openFileStruct.lpstrCustomFilter, NULL
    mov openFileStruct.nFilterIndex, 0
    mov esi, pfilename
    mov (BYTE PTR [esi]), 0
    mov eax, pfilename
    mov openFileStruct.lpstrFile, eax
    mov openFileStruct.nMaxFile, MAX_FILE_NAME_SIZE
    mov openFileStruct.lpstrFileTitle, NULL
    mov openFileStruct.nMaxFileTitle, 0
    mov openFileStruct.lpstrInitialDir, NULL
    mov openFileStruct.lpstrTitle, OFFSET openFileDialogName
    mov openFileStruct.Flags, OFN_PATHMUSTEXIST
    mov openFileStruct.lpstrDefExt, NULL
    invoke GetOpenFileName, addr openFileStruct
    ret
OpenOpenBitmapDialog endp

LoadBitmapFromFile proc hWnd:HWND, pfilename:PTR   
    LOCAL bm:BITMAP
    LOCAL bitmapHandle:HANDLE 
    ; ==== Load Bitmap ====
    invoke LoadImage, NULL, pfilename, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
    mov bitmapHandle, eax
    .IF eax == NULL
        ret
    .endif
    invoke crt_strcpy, offset g_bitmapName, pfilename
    invoke GetObject, bitmapHandle, SIZEOF bm, addr bm
    mov eax, bm.bmWidth
    mov g_canvasWidth, eax
    mov eax, bm.bmHeight
    mov g_canvasHeight, eax
    invoke DestoryCanvas
    invoke GetDC, g_hWndCanvas
    invoke CreateCompatibleDC, eax
    mov g_hdcBuf, eax
    mov eax, bitmapHandle
    mov g_hdcBitmap, eax
    invoke SelectObject, g_hdcBuf, g_hdcBitmap
    invoke UpdateScrollBarSize
    invoke InvalidateRect, g_hWndCanvas, NULL, TRUE
    ret
LoadBitmapFromFile endp

CreateBitmapInfoStruct proc USES ebx esi
    LOCAL pbmi:PTR ; Bitmap info pointer
    LOCAL cClrBits:DWORD
    LOCAL bmp:BITMAP
    
    invoke GetObject, g_hdcBitmap, SIZEOF bmp, addr bmp 
    movzx eax, bmp.bmPlanes
    movzx ebx, bmp.bmBitsPixel
    mul ebx
    mov cClrBits, eax
    .IF cClrBits == 1
        mov cClrBits, 1
    .ELSEIF cClrBits <= 4
        mov cClrBits, 4
    .ELSEIF cClrBits <= 8
        mov cClrBits, 8
    .ELSEIF cClrBits <= 16
        mov cClrBits, 16
    .ELSEIF cClrBits <= 24
        mov cClrBits, 24
    .ELSE
        mov cClrBits, 32
    .ENDIF
    .IF cClrBits < 24
        mov eax, 1
        mov ecx, cClrBits
        shl eax, cl
        mov ebx, SIZEOF RGBQUAD
        mul ebx
        add eax, SIZEOF BITMAPINFOHEADER
        invoke LocalAlloc, LMEM_FIXED or LMEM_ZEROINIT, eax
        mov pbmi, eax
    .ELSE
        invoke LocalAlloc, LMEM_FIXED or LMEM_ZEROINIT, SIZEOF BITMAPINFOHEADER
        mov pbmi, eax
    .endif
    mov esi, pbmi
    mov (BITMAPINFO PTR [esi]).bmiHeader.biSize, sizeof BITMAPINFOHEADER
    mov eax, bmp.bmWidth
    mov (BITMAPINFO PTR [esi]).bmiHeader.biWidth, eax
    mov eax, bmp.bmHeight
    mov (BITMAPINFO PTR [esi]).bmiHeader.biHeight, eax
    mov ax, bmp.bmPlanes
    mov (BITMAPINFO PTR [esi]).bmiHeader.biPlanes, ax
    mov ax, bmp.bmBitsPixel
    mov (BITMAPINFO PTR [esi]).bmiHeader.biBitCount, ax
    .IF cClrBits < 24
        mov eax, 1
        mov ecx, cClrBits
        shl eax, cl
        mov (BITMAPINFO PTR [esi]).bmiHeader.biClrUsed,  eax
    .endif
    mov (BITMAPINFO PTR [esi]).bmiHeader.biCompression, BI_RGB
    mov eax, (BITMAPINFO PTR [esi]).bmiHeader.biWidth
    mov ebx, cClrBits
    mul ebx
    add eax, 31
    and eax, 0ffffffe0h ;0ffffffe0h: ~31
    mov ebx, 8
    xor edx, edx
    div ebx
    mov ebx, (BITMAPINFO PTR [esi]).bmiHeader.biHeight
    mul ebx
    mov (BITMAPINFO PTR [esi]).bmiHeader.biSizeImage, eax
    mov (BITMAPINFO PTR [esi]).bmiHeader.biClrImportant, 0
    mov eax, pbmi
    ret
CreateBitmapInfoStruct endp

SaveBitmapFile proc USES ebx
    LOCAL pbi:PTR
    LOCAL hf:HANDLE
    LOCAL hdr:BITMAPFILEHEADER
    LOCAL pbih:PTR
    LOCAL lpBits:LPBYTE
    LOCAL dwTotal:DWORD
    LOCAL cb:DWORD
    LOCAL hp:PTR
    LOCAL dwTmp:DWORD
    
    invoke CreateBitmapInfoStruct
    mov pbi, eax
    mov pbih, eax
    mov esi, pbih
    invoke GlobalAlloc, GMEM_FIXED, (BITMAPINFOHEADER PTR [esi]).biSizeImage
    mov lpBits, eax
    invoke GetDIBits, g_hdcBuf, g_hdcBitmap, 0, (BITMAPINFOHEADER PTR [esi]).biHeight, lpBits, \
           pbi, DIB_RGB_COLORS
    invoke CreateFile, offset g_bitmapName, GENERIC_READ or GENERIC_WRITE, 0, NULL, \
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov hf, eax
    mov hdr.bfType, 4d42h
    mov eax, (BITMAPINFOHEADER PTR [esi]).biClrUsed
    mov ebx, SIZEOF RGBQUAD
    mul ebx
    add eax, SIZEOF BITMAPFILEHEADER
    add eax, (BITMAPINFOHEADER PTR [esi]).biSize
    mov hdr.bfOffBits, eax
    add eax, (BITMAPINFOHEADER PTR [esi]).biSizeImage
    mov hdr.bfSize, eax
    mov hdr.bfReserved1, 0
    mov hdr.bfReserved2, 0
    invoke WriteFile, hf, addr hdr, SIZEOF BITMAPFILEHEADER, addr dwTmp, NULL
    mov eax, (BITMAPINFOHEADER PTR [esi]).biClrUsed
    mov ebx, SIZEOF RGBQUAD
    mul ebx
    add eax, SIZEOF BITMAPINFOHEADER
    mov ebx, eax ; Just make masm happy
    invoke WriteFile, hf, pbih, ebx, addr dwTmp, NULL
    mov eax, (BITMAPINFOHEADER PTR [esi]).biSizeImage
    mov cb, eax
    mov eax, dwTotal
    mov eax, lpBits
    mov hp, eax
    invoke WriteFile, hf, hp, cb, addr dwTmp, NULL
    invoke CloseHandle, hf
    invoke GlobalFree, lpBits
    invoke LocalFree, pbi
    mov g_isModified, 0
    ret
SaveBitmapFile endp

; return 1 if success, NULL if user cancels
OpenSaveBitmapDialog proc
    LOCAL openFileStruct:OPENFILENAME
    LOCAL filename[MAX_FILE_NAME_SIZE]:BYTE
    .IF g_bitmapName == 0
        invoke crt_strcpy, addr filename, offset defaultSaveAsName
    .ELSE
        invoke crt_strcpy, addr filename, offset g_bitmapName
    .ENDIF
    mov openFileStruct.lStructSize, SIZEOF openFileStruct
    mov eax, g_hWnd
    mov openFileStruct.hwndOwner, eax
    mov openFileStruct.hInstance, NULL
    mov openFileStruct.lpstrFilter, OFFSET openFileFilterPattern
    mov openFileStruct.lpstrCustomFilter, NULL
    mov openFileStruct.nFilterIndex, 0
    lea eax, filename
    mov openFileStruct.lpstrFile, eax
    mov openFileStruct.nMaxFile, MAX_FILE_NAME_SIZE
    mov openFileStruct.lpstrFileTitle, NULL
    mov openFileStruct.nMaxFileTitle, 0
    mov openFileStruct.lpstrInitialDir, NULL
    mov openFileStruct.lpstrTitle, OFFSET saveFileDialogName
    mov openFileStruct.Flags, OFN_PATHMUSTEXIST
    mov openFileStruct.lpstrDefExt, NULL
    invoke GetSaveFileName, addr openFileStruct
    .IF eax != NULL
        invoke crt_strcpy, offset g_bitmapName, addr filename
        mov eax, 1
    .endif
    ret
OpenSaveBitmapDialog endp

SetCanvasColor proc index:DWORD, color:DWORD
    ; if index == 0, set `color' as foreground color
    ;    index == 1, set `color' as background color
    LOCAL hdcWnd:HDC
    LOCAL hdc:HDC
    LOCAL hBmp:HBITMAP
    LOCAL hBmpMask: HBITMAP
    LOCAL hBrush:HBRUSH
    LOCAL rect:RECT

    mov eax, color
    .IF index == 0
        mov g_foregroundColor, eax
    .ELSE
        mov g_backgroundColor, eax
    .ENDIF
    mov eax, index
    add eax, 16
    mov index, eax
    
    mov rect.left, 0
    mov rect.top, 0
    mov rect.right, 16
    mov rect.bottom, 16

    invoke GetDC, g_hWnd
    mov hdcWnd, eax
    
    invoke CreateCompatibleDC, hdcWnd
    mov hdc, eax
    invoke CreateCompatibleBitmap, hdcWnd, 16, 16
    mov hBmp, eax
    invoke SelectObject, hdc, hBmp
    invoke CreateSolidBrush, color
    mov hBrush, eax
    invoke FillRect, hdc, addr rect, hBrush
    invoke DeleteObject, hBrush
    invoke CreateCompatibleBitmap, hdcWnd, 16, 16
    mov hBmpMask, eax
    invoke SelectObject, hdc, hBmpMask
    invoke CreateSolidBrush, 0
    mov hBrush, eax
    invoke FillRect, hdc, addr rect, hBrush
    invoke DeleteObject, hBrush
    invoke DeleteDC, hdc

    invoke ImageList_Replace, g_hImageListControl, index, hBmp, hBmpMask

    invoke DeleteObject, hBmp
    invoke DeleteObject, hBmpMask
    invoke DeleteDC, hdcWnd
    
    invoke InvalidateRect, g_hWndControl, NULL, TRUE
    ret 
SetCanvasColor endp

PromptColor proc, index: DWORD
    LOCAL choose:CHOOSECOLOR
    mov choose.lStructSize, sizeof CHOOSECOLOR
    mov eax, g_hWnd
    mov choose.hwndOwner, eax 
    .IF index == 0
        mov eax, g_foregroundColor
    .ELSE
        mov eax, g_backgroundColor
    .ENDIF
    mov choose.rgbResult, eax
    mov choose.lpCustColors, offset g_customColors
    mov choose.Flags, CC_RGBINIT
    invoke ChooseColor, addr choose
    invoke SetCanvasColor, index, choose.rgbResult
    ret
PromptColor endp

; return 0: user cancels operation, 1: user has decided whether to save the modified
ConfirmSaveModify proc
    LOCAL return:DWORD
    invoke MessageBox, g_hWnd, offset confirmCloseDialogText, offset confirmCloseDialogName, MB_YESNOCANCEL or MB_ICONEXCLAMATION
    .IF eax == IDYES
        invoke OpenSaveBitmapDialog
        .IF eax != NULL
            invoke SaveBitmapFile
            mov return, 1
        .ELSE
            mov return, 0
        .ENDIF
    .ELSEIF eax == IDNO
        mov return, 1
    .ELSE
        mov return, 0
    .ENDIF
    mov eax, return
    ret
ConfirmSaveModify endp

UpdateStatusBarSize proc
    LOCAL clientRect:RECT
    LOCAL statusBarEdges[4]:DWORD
    invoke GetClientRect, g_hWnd, addr clientRect
    .IF clientRect.right > STATUSBAR_INFO_MINWIDTH + 2 * STATUSBAR_COORDINATES_WIDTH + STATUSBAR_ENDING_WIDTH
        mov eax, clientRect.right
        mov statusBarEdges[12], eax
        sub eax, STATUSBAR_ENDING_WIDTH
        mov statusBarEdges[8], eax
        sub eax, STATUSBAR_COORDINATES_WIDTH
        mov statusBarEdges[4], eax
        sub eax, STATUSBAR_COORDINATES_WIDTH
        mov statusBarEdges[0], eax
    .ELSE
        mov eax, STATUSBAR_INFO_MINWIDTH
        mov statusBarEdges[0], eax
        add eax, STATUSBAR_COORDINATES_WIDTH
        mov statusBarEdges[4], eax
        add eax, STATUSBAR_COORDINATES_WIDTH
        mov statusBarEdges[8], eax
        add eax, STATUSBAR_ENDING_WIDTH
        mov statusBarEdges[12], eax
    .ENDIF
    invoke SendMessage, g_hWndStatusBar, SB_SETPARTS, 4, addr statusBarEdges
    ret
UpdateStatusBarSize endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hBmp:HBITMAP
    LOCAL canvasWndRect:RECT
    LOCAL filenameTemp[MAX_FILE_NAME_SIZE]:BYTE

    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSEIF uMsg == WM_CREATE
        mov eax, hWnd
        mov g_hWnd, eax
        ; ==== Create Left Control Toolbar ====
        invoke CreateWindowEx, 0, addr toolbarClassName, NULL, \
            CCS_VERT or CCS_NODIVIDER or WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, 0, 0, 0, 0, \
            hWnd, NULL, g_hInst, NULL
        mov g_hWndControl, eax
        invoke ImageList_Create, 16, 16, ILC_COLOR16 or ILC_MASK, 18, 0
        mov g_hImageListControl, eax
        invoke LoadBitmap, g_hInst, IDB_CONTROLS
		mov hBmp, eax
		invoke ImageList_AddMasked, g_hImageListControl, hBmp, 0ffh
		invoke DeleteObject, hBmp
    	invoke SetCanvasColor, 0, 0
    	invoke SetCanvasColor, 1, 0ffffffh
        invoke SendMessage, g_hWndControl, TB_SETIMAGELIST, 0, g_hImageListControl
        invoke SendMessage, g_hWndControl, TB_LOADIMAGES, IDB_STD_LARGE_COLOR, HINST_COMMCTRL
        invoke SendMessage, g_hWndControl, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0
        invoke SendMessage, g_hWndControl, TB_ADDBUTTONS, CONTROL_BUTTON_NUM, offset g_tbControlButtons
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
        ; ===== Create Canvas Child Window =====
        invoke CalculateCanvasWindowPosition, hWnd, g_hWndControl, addr canvasWndRect
        invoke CreateWindowEx, 0, addr canvasClassName, NULL, WS_CHILD or WS_HSCROLL or WS_VSCROLL, \
               canvasWndRect.left, canvasWndRect.top, canvasWndRect.right, canvasWndRect.bottom, \
               hWnd, NULL, g_hInst, NULL        
        invoke ShowWindow, g_hWndCanvas, SW_SHOW
        ; ===== Create Coordinate status bar =====
        invoke CreateWindowEx, 0, addr statusBarClassName, NULL, WS_CHILD or WS_VISIBLE, 0, 0, 0, 0, \
            hWnd, NULL, g_hInst, NULL
        mov g_hWndStatusBar, eax
    .ELSEIF uMsg == WM_SIZE
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
        invoke CalculateCanvasWindowPosition, g_hWnd, g_hWndControl, addr canvasWndRect
        invoke SetWindowPos, g_hWndCanvas, HWND_TOP, canvasWndRect.left, canvasWndRect.top, \
               canvasWndRect.right, canvasWndRect.bottom, SWP_SHOWWINDOW
        invoke SendMessage, g_hWndStatusBar, WM_SIZE, 0, 0
        invoke UpdateStatusBarSize        
    .ELSEIF uMsg == WM_HOTKEY
    	invoke SendMessage, g_hWndControl, WM_COMMAND, wParam, 0
    .ELSEIF uMsg == WM_COMMAND
        invoke crt_printf, offset debugWndProcMsg, uMsg, wParam, lParam
        .IF wParam == IDM_OPEN
            .IF g_isModified == 1
                invoke ConfirmSaveModify
                .IF eax == 0
                    jmp DontOpenFile
                .endif
            .ENDIF
            invoke OpenOpenBitmapDialog, g_hWnd, addr filenameTemp
            .IF eax != NULL
                invoke LoadBitmapFromFile, g_hWndCanvas, addr filenameTemp
            .endif
            DontOpenFile:
        .ELSEIF wParam == IDM_NEW
            .IF g_isModified == 1
                invoke ConfirmSaveModify
                .IF eax == 0
                    jmp DontNewCanvas
                .endif
            .ENDIF
            invoke DestoryCanvas
            mov g_canvasWidth, DEFAULT_CANVAS_WIDTH
            mov g_canvasHeight, DEFAULT_CANVAS_HEIGHT
            mov g_isModified, 0
            mov g_bitmapName, 0
            invoke CreateCanvas, g_hWndCanvas
            invoke ClearCanvas
            invoke UpdateScrollBarSize
            invoke InvalidateRect, g_hWndCanvas, NULL, TRUE
            DontNewCanvas:
        .ELSEIF wParam == IDM_SAVE
            .IF g_isModified != 0
                .IF g_bitmapName == 0
                    invoke SendMessage, g_hWndControl, WM_COMMAND, IDM_SAVEAS, lParam
                .ELSE
                    invoke SaveBitmapFile
                .ENDIF
            .ENDIF
        .ELSEIF wParam == IDM_SAVEAS
            invoke OpenSaveBitmapDialog
            .IF eax != NULL
                invoke SaveBitmapFile
            .endif
        .ELSEIF wParam == IDM_FOREGROUND_COLOR
            invoke PromptColor, 0
        .ELSEIF wParam == IDM_BACKGROUND_COLOR
            invoke PromptColor, 1
        .ELSEIF wParam == IDM_EXIT
            invoke SendMessage, hWnd, WM_CLOSE, 0, 0
        .ELSEIF wParam == IDM_ABOUT
            invoke MessageBox, hWnd, offset aboutDialogText, offset aboutDialogName, MB_OK or MB_ICONINFORMATION
        .ELSE
            mov eax, wParam
            mov g_toolbarStatus, eax
        .ENDIF
    .ELSEIF uMsg == WM_DROPFILES
    	invoke DragQueryFile, wParam, 0, addr filenameTemp, MAX_FILE_NAME_SIZE
    	.IF eax != 0
    	    invoke LoadBitmapFromFile, g_hWndCanvas, addr filenameTemp
    	.ENDIF
    .ELSEIF uMsg == WM_CLOSE
        .IF g_isModified == 1
            invoke ConfirmSaveModify
            .IF eax != 0
                invoke DestroyWindow, hWnd
            .ENDIF
        .ELSE
            invoke DestroyWindow, hWnd
        .ENDIF
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF

    xor eax,eax
    ret
WndProc endp

ClientToCanvasX proc pos:DWORD
    mov eax, pos
    sub eax, CANVAS_MARGIN
    cdq
    idiv g_zoom
    add eax, g_canvasOffsetX
    ret
ClientToCanvasX endp

ClientToCanvasY proc pos:DWORD
    mov eax, pos
    sub eax, CANVAS_MARGIN
    cdq
    idiv g_zoom
    add eax, g_canvasOffsetY
    ret
ClientToCanvasY endp

UpdateMousePos proc
    LOCAL point:POINT
    invoke GetCursorPos, addr point
    invoke ScreenToClient, g_hWndCanvas, addr point
    mov eax, point.x
    mov g_mouseClientX, eax
    mov eax, point.y
    mov g_mouseClientY, eax
    invoke ClientToCanvasX, g_mouseClientX
    mov g_mouseCanvasX, eax
    invoke ClientToCanvasY, g_mouseClientY
    mov g_mouseCanvasY, eax
    mov ecx, g_canvasWidth
    mov edx, g_canvasHeight
    .IF g_mouseCanvasX >= 0 && g_mouseCanvasX < ecx && g_mouseCanvasY >= 0 && g_mouseCanvasY < edx
        mov g_mouseInCanvas, 1
    .ELSE
        mov g_mouseInCanvas, 0
    .ENDIF
    ret
UpdateMousePos endp

UpdateStatusBarMouseCoordinate proc
    LOCAL buffer[MAX_COORDINATE_BUFFER]:BYTE
    .IF g_mouseInCanvas != 0
        invoke crt_sprintf, addr buffer, offset coordinateFormat, g_mouseCanvasX, g_mouseCanvasY
    .ELSE
        mov al, 0
        mov buffer, al
    .ENDIF
    invoke SendMessage, g_hWndStatusBar, SB_SETTEXT, 1, addr buffer
    ret
UpdateStatusBarMouseCoordinate endp

UpdateScrollPosition proc USES ebx, index:DWORD, mode:DWORD, value:DWORD
    ; mode: 0 value, 1 delta, 2 trackPos
    LOCAL scrollbarInfo:SCROLLINFO
    LOCAL oldPos:DWORD
    mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
    mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE or SIF_POS or SIF_TRACKPOS
    .IF index == 0
        mov ebx, SB_VERT
    .ELSE
        mov ebx, SB_HORZ
    .ENDIF
    invoke GetScrollInfo, g_hWndCanvas, ebx, addr scrollbarInfo
    mov eax, scrollbarInfo.nPos
    mov oldPos, eax
    .IF mode == 0
        mov eax, value
        mov scrollbarInfo.nPos, eax
    .ELSEIF mode == 1
        mov eax, value
        add scrollbarInfo.nPos, eax
    .ELSE
        mov eax, scrollbarInfo.nTrackPos
        mov scrollbarInfo.nPos, eax
    .ENDIF 
    mov scrollbarInfo.fMask, SIF_POS
    invoke SetScrollInfo, g_hWndCanvas, ebx, addr scrollbarInfo, TRUE
    invoke GetScrollInfo, g_hWndCanvas, ebx, addr scrollbarInfo
    mov eax, scrollbarInfo.nPos
    .IF eax != oldPos
        mov edx, SCROLL_STEP_PIXEL
        mul edx
        xor edx, edx
        div g_zoom
        .IF index == 0
            mov g_canvasOffsetY, eax
        .ELSE
            mov g_canvasOffsetX, eax
        .ENDIF
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        invoke UpdateMousePos
        invoke UpdateStatusBarMouseCoordinate
    .ENDIF
    ret
UpdateScrollPosition endp

UpdateScrollBarSize proc USES ebx
    LOCAL scrollbarInfo:SCROLLINFO
    LOCAL clientRect:RECT
    
    invoke GetClientRect, g_hWndCanvas, addr clientRect
    
    ; ==== Update Vertical Scrollbar ====
    mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
    mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE
    mov scrollbarInfo.nMin, 0
    mov eax, clientRect.bottom
    mov ebx, SCROLL_STEP_PIXEL
    xor edx, edx
    div ebx
    mov scrollbarInfo.nPage, eax
    mov eax, g_canvasHeight
    mov edx, g_zoom
    mul edx
    add eax, 2 * CANVAS_MARGIN
    mov ebx, SCROLL_STEP_PIXEL
    xor edx, edx
    div ebx 
    mov scrollbarInfo.nMax, eax
    invoke SetScrollInfo, g_hWndCanvas, SB_VERT, addr scrollbarInfo, TRUE
    mov scrollbarInfo.fMask, SIF_POS
    invoke GetScrollInfo, g_hWndCanvas, SB_VERT, addr scrollbarInfo
    mov eax, scrollbarInfo.nPos
    mov edx, SCROLL_STEP_PIXEL
    mul edx
    xor edx, edx
    div g_zoom
    mov g_canvasOffsetY, eax

    ; ==== Update Horizontal Scrollbar ====
    mov scrollbarInfo.cbSize, SIZEOF scrollbarInfo
    mov scrollbarInfo.fMask, SIF_RANGE or SIF_PAGE
    mov scrollbarInfo.nMin, 0
    mov eax, clientRect.right
    mov ebx, SCROLL_STEP_PIXEL
    xor edx, edx
    div ebx
    mov scrollbarInfo.nPage, eax
    mov eax, g_canvasWidth
    mov edx, g_zoom
    mul edx
    add eax, 2 * CANVAS_MARGIN
    mov ebx, SCROLL_STEP_PIXEL
    xor edx, edx
    div ebx 
    mov scrollbarInfo.nMax, eax
    invoke SetScrollInfo, g_hWndCanvas, SB_HORZ, addr scrollbarInfo, TRUE
    mov scrollbarInfo.fMask, SIF_POS
    invoke GetScrollInfo, g_hWndCanvas, SB_HORZ, addr scrollbarInfo
    mov eax, scrollbarInfo.nPos
    mov edx, SCROLL_STEP_PIXEL
    mul edx
    xor edx, edx
    div g_zoom
    mov g_canvasOffsetX, eax
    invoke UpdateMousePos
    invoke UpdateStatusBarMouseCoordinate

    ret
UpdateScrollBarSize endp

UpdateZoom proc mode:DWORD, value:DWORD
    ; TODO: set scroll center
    ; mode: 0 value, 1 delta
    .IF mode == 0
        mov eax, value
    .ELSEIF mode == 1
        mov eax, g_zoom
        add eax, value
    .ENDIF
    .IF eax != 0 && eax <= MAX_ZOOM && eax != g_zoom
        mov g_zoom, eax
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        invoke UpdateScrollBarSize
    .ENDIF
    ret
UpdateZoom endp

SetPen proc hdc:HDC
    invoke CreatePen, PS_SOLID, g_penWidth, g_foregroundColor
    mov g_pen, eax
    invoke SelectObject, hdc, eax
    ret
SetPen endp

SetBrush proc hdc:HDC
    .IF g_fillType == FILL_WITHOUT_BORDER
        invoke CreatePen, PS_NULL, g_penWidth, g_foregroundColor
        mov g_pen, eax
    .ELSE
        invoke CreatePen, PS_SOLID, g_penWidth, g_foregroundColor
        mov g_pen, eax
    .ENDIF
    
    .IF g_fillType == FILL_WITHOUT_FILL
        invoke crt_printf, offset debugPrintInt, 22222
        invoke GetStockObject, NULL_BRUSH
        mov g_brush, eax
    .ELSE
        invoke CreateSolidBrush, g_backgroundColor
        mov g_brush, eax
    .ENDIF
    invoke SelectObject, hdc, g_pen
    invoke SelectObject, hdc, g_brush
    ret
SetBrush endp

DeletePen proc
    .IF g_pen != NULL
        invoke DeleteObject, g_pen
        mov g_pen, NULL
    .endif
    ret
DeletePen endp

DeleteBrush proc
    .IF g_pen != NULL
        invoke DeleteObject, g_pen
        mov g_pen, NULL
    .endif
    .IF g_brush != NULL
        invoke DeleteObject, g_brush
        mov g_brush, NULL
    .endif
    ret
DeleteBrush endp

Render proc hWnd:HWND
    LOCAL hdc:HDC
    LOCAL hdcBuffer:HDC
    LOCAL hBitmapBuffer:HBITMAP
    LOCAL rect:RECT
    LOCAL rectCanvas:RECT
    LOCAL hBrush:HBRUSH
    LOCAL ps:PAINTSTRUCT
    LOCAL widthAfterZoom:DWORD
    LOCAL heightAfterZoom:DWORD
    LOCAL canvasWidthMinusOffsetX:DWORD
    LOCAL canvasHeightMinusOffsetY:DWORD

    invoke GetClientRect, hWnd, addr rect
    invoke GetDC, hWnd
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov hdcBuffer, eax
    mov eax, rect.right
    sub eax, rect.left
    mov rectCanvas.left, 0
    mov rectCanvas.right, eax
    mov eax, rect.bottom
    sub eax, rect.top
    mov rectCanvas.top, 0
    mov rectCanvas.bottom, eax
    invoke CreateCompatibleBitmap, hdc, rectCanvas.right, rectCanvas.bottom
    mov hBitmapBuffer, eax
    invoke ReleaseDC, hWnd, hdc
    invoke SelectObject, hdcBuffer, hBitmapBuffer

    invoke CreateSolidBrush, 0abababh
    mov hBrush, eax
    invoke FillRect, hdcBuffer, addr rect, hBrush
    invoke DeleteObject, hBrush 
    
    mov eax, g_canvasWidth
    sub eax, g_canvasOffsetX
    mov canvasWidthMinusOffsetX, eax
    mov ebx, g_zoom
    mul ebx
    mov widthAfterZoom, eax
    mov eax, g_canvasHeight
    sub eax, g_canvasOffsetY
    mov canvasHeightMinusOffsetY, eax
    mov ebx, g_zoom
    mul ebx
    mov heightAfterZoom, eax
    
    
    ;invoke SetBrush, g_hdcBuf
    ;invoke Rectangle, g_hdcBuf, 10, 10, 100, 100
    ;invoke Rectangle, g_hdcBuf, 50, 50, 200, 200
    ;invoke DeleteBrush
    
    invoke StretchBlt, hdcBuffer, CANVAS_MARGIN, CANVAS_MARGIN, widthAfterZoom, heightAfterZoom, \
           g_hdcBuf, g_canvasOffsetX, g_canvasOffsetY, canvasWidthMinusOffsetX, canvasHeightMinusOffsetY, \
           SRCCOPY
    
    invoke BeginPaint, hWnd, addr ps
    mov hdc, eax
    invoke BitBlt, hdc, rect.left, rect.top, rectCanvas.right, rectCanvas.bottom, \
           hdcBuffer, 0, 0, SRCCOPY
    invoke EndPaint, hWnd, addr ps
    invoke DeleteObject, hBitmapBuffer
    invoke DeleteDC, hdcBuffer
    ret
Render endp

CanvasTrackMouse proc
    LOCAL trackMouseEvent:TRACKMOUSEEVENT
    .IF g_mouseTracking == 0
        mov trackMouseEvent.cbSize, sizeof TRACKMOUSEEVENT 
        mov trackMouseEvent.dwFlags, TME_LEAVE
        mov eax, g_hWndCanvas
        mov trackMouseEvent.hwndTrack, eax
        invoke TrackMouseEvent, addr trackMouseEvent
        mov g_mouseTracking, 1
    .ENDIF
    ret
CanvasTrackMouse endp

CanvasWinProc proc USES ebx esi,
    hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    .IF uMsg == WM_CREATE
        mov eax, hWnd
        mov g_hWndCanvas, eax
        ; ===== Create HDC Buffer =====
        invoke CreateCanvas, hWnd
        invoke ClearCanvas
        invoke DragAcceptFiles, hWnd, TRUE
        invoke CanvasTrackMouse
    .ELSEIF uMsg == WM_SIZE
        invoke UpdateScrollBarSize
    .ELSEIF uMsg == WM_VSCROLL
        mov eax, wParam
        movzx eax, ax
        .IF eax == SB_LINEUP
            invoke UpdateScrollPosition, 0, 1, -SCROLL_LINE_STEPS
        .ELSEIF eax == SB_LINEDOWN
            invoke UpdateScrollPosition, 0, 1, SCROLL_LINE_STEPS
        .ELSEIF eax == SB_PAGEUP
            invoke UpdateScrollPosition, 0, 1, -SCROLL_PAGE_STEPS
        .ELSEIF eax == SB_PAGEDOWN
            invoke UpdateScrollPosition, 0, 1, SCROLL_PAGE_STEPS
        .ELSEIF eax == SB_THUMBTRACK
            invoke UpdateScrollPosition, 0, 2, 0
        .ENDIF
    .ELSEIF uMsg == WM_HSCROLL
        mov eax, wParam
        movzx eax, ax
        .IF eax == SB_LINEUP
            invoke UpdateScrollPosition, 1, 1, -SCROLL_LINE_STEPS
        .ELSEIF eax == SB_LINEDOWN
            invoke UpdateScrollPosition, 1, 1, SCROLL_LINE_STEPS
        .ELSEIF eax == SB_PAGEUP
            invoke UpdateScrollPosition, 1, 1, -SCROLL_PAGE_STEPS
        .ELSEIF eax == SB_PAGEDOWN
            invoke UpdateScrollPosition, 1, 1, SCROLL_PAGE_STEPS
        .ELSEIF eax == SB_THUMBTRACK
            invoke UpdateScrollPosition, 1, 2, 0
        .ENDIF
    .ELSEIF uMsg == WM_DROPFILES
        invoke SendMessage, g_hWnd, uMsg, wParam, lParam
    .ELSEIF uMsg == WM_MOUSEWHEEL
        mov eax, wParam
        sar eax, 16
        cdq
        mov ebx, 120
        idiv ebx
        mov ebx, wParam
        and ebx, MK_CONTROL
        .IF ebx == 0
            mov ebx, SCROLL_LINE_STEPS
            imul ebx
            neg eax
            invoke UpdateScrollPosition, 0, 1, eax
        .ELSE
            invoke UpdateZoom, 1, eax            
        .ENDIF
    .ELSEIF uMsg == WM_PAINT
        invoke Render, hWnd
    .ELSEIF uMsg == WM_MOUSEMOVE
        invoke CanvasTrackMouse
        invoke UpdateMousePos
        invoke UpdateStatusBarMouseCoordinate
    .ELSEIF uMsg == WM_MOUSELEAVE
        mov g_mouseInCanvas, 0
        mov g_mouseTracking, 0
        invoke UpdateStatusBarMouseCoordinate
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
    
    invoke ShowWindow, g_hWnd, cmdShow
    invoke UpdateWindow, g_hWnd
    
    invoke RegisterHotKey, g_hWnd, IDM_NEW, MOD_CONTROL or MOD_NOREPEAT, 'N'
    invoke RegisterHotKey, g_hWnd, IDM_OPEN, MOD_CONTROL or MOD_NOREPEAT, 'O'
    invoke RegisterHotKey, g_hWnd, IDM_SAVE, MOD_CONTROL or MOD_NOREPEAT, 'S'

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