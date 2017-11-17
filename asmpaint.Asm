.386
.model flat, stdcall

include asmpaint.Inc

UpdateScrollBarSize proto
UpdateCursor proto

; TODO: isModified change to saved index

UndoRedo struct
    hBitmap HBITMAP ?
    nWidth DWORD ?
    nHeight DWORD ?
UndoRedo ends

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

    cannotOpenFileDialogText BYTE "无法打开该文件", 0
    cannotOpenFileDialogTitle BYTE "画图", 0
    
    confirmCloseDialogText BYTE "将更改保存到文件吗？", 0
    confirmCloseDialogName BYTE "画图", 0
    coordinateFormat BYTE "%d, %d", 0
    
    aboutDialogText BYTE "由车行、孙子平、赵尚明协作开发完成。", 0ah, "以及，辣鸡大作孽，毁我青春，掉我头发！", 0
    aboutDialogName BYTE "关于", 0

    yesText BYTE "是", 0
    noText BYTE "否", 0
    intText BYTE "%d", 0

    mainWindowModifiedTitle BYTE "*%s - 画图", 0
    mainWindowNoModifiedTitle BYTE "%s - 画图", 0

    MAX_FILE_NAME_SIZE equ 256
    MAX_ZOOM equ 8

    saveFileDialogName BYTE "另存为", 0
    defaultSaveAsName BYTE "无标题.bmp", 0
    g_bitmapName BYTE MAX_FILE_NAME_SIZE dup(0)

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
    UNDO_MAX_TIMES equ 20

    debugWndProcMsg BYTE "msg: %u %u %d",0ah,0
    debugPoint BYTE "canvas: (%4d, %4d)", 0ah, 0
    debugPrintInt BYTE "%u", 0ah, 0
    debugHelp BYTE "menu: %u (dropdown: %d)",0ah,0

    g_toolbarStatus DWORD IDM_PENCIL
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
    g_fillType DWORD FILL_DEFAULT
    g_penWidth DWORD 1
    g_eraserWidth DWORD 4
    g_hdcEraserBuf HDC NULL
    g_hdcEraserBitmap HBITMAP NULL
    
    ROUND_RECT_DEFAULT_REDIES_RAIDUS equ 10
    
    g_roundRectWidth DWORD ROUND_RECT_DEFAULT_REDIES_RAIDUS
    g_roundRectHeight DWORD ROUND_RECT_DEFAULT_REDIES_RAIDUS
    
    g_pen HPEN NULL
    g_brush HBRUSH NULL

    g_cursorInst HINSTANCE NULL
    g_cursor DWORD 0
    g_isCapturing DWORD FALSE
    g_isDrawing DWORD FALSE
    
    g_previousPoint POINT <0, 0>

    g_hasToolbar DWORD 1
    g_hasStatusBar DWORD 1

    g_undoRedoCurr DWORD 0
    g_undoRedoSize DWORD 0
    g_undoRedoSaved SDWORD 0

    g_showCursor DWORD 1

    g_isMenuOpened DWORD 0
    
    MAX_HEIGHT_WIDTH equ 4096
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
    g_hAccel HACCEL ?
    g_hMenu HMENU ?

    g_hdcDrawingBuf HDC ?
    g_hdcDrawingBitmap HBITMAP ?
    
    g_foregroundColor DWORD ?
    g_backgroundColor DWORD ?

    g_undoRedo UndoRedo UNDO_MAX_TIMES dup(<?, ?>)
    
    TEXT_BUFFER_SIZE equ 1024
    
    g_textBuffer BYTE TEXT_BUFFER_SIZE dup(?)

    g_tempInt1 DWORD ?
    g_tempInt2 DWORD ?

.code
CreateEraser proc USES ebx
    LOCAL hdc:HDC
    LOCAL eraserWidth:DWORD
    LOCAL pen:HPEN
    LOCAL brush:HBRUSH
    invoke GetDC, g_hWndCanvas
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov g_hdcEraserBuf, eax
    mov eax, g_eraserWidth
    mov ebx, g_zoom
    mul ebx
    mov eraserWidth, eax
    invoke CreateCompatibleBitmap, hdc, eraserWidth, eraserWidth
    mov g_hdcEraserBitmap, eax
    invoke SelectObject, g_hdcEraserBuf, g_hdcEraserBitmap
    invoke CreatePen, PS_SOLID, 1, 0
    mov pen, eax
    invoke SelectObject, g_hdcEraserBuf, pen
    invoke CreateSolidBrush, g_backgroundColor
    mov brush, eax
    invoke SelectObject, g_hdcEraserBuf, brush
    
    invoke Rectangle, g_hdcEraserBuf, 0, 0, eraserWidth, eraserWidth
    
    invoke DeleteObject, pen
    invoke DeleteObject, brush
    invoke ReleaseDC, g_hWndCanvas, hdc
    ret
CreateEraser endp

DestoryEraser proc
    invoke DeleteObject, g_hdcEraserBitmap
    mov g_hdcEraserBitmap, NULL
    invoke DeleteDC, g_hdcEraserBuf
    mov g_hdcEraserBuf, NULL
    ret
DestoryEraser endp

UpdateEraser proc
    .IF g_hdcEraserBuf != NULL
        invoke DestoryEraser
    .ENDIF
    invoke CreateEraser
    ret
UpdateEraser endp

RemoveUndoRedo proc uses esi edi, index:DWORD
    ; index should be in [0, g_undoRedoSize), assert g_undoRedoSize >= 1
    mov eax, index
    mov edx, sizeof UndoRedo
    mul edx
    lea edi, [g_undoRedo + eax]
    invoke DeleteObject, (UndoRedo ptr [edi]).hBitmap
    lea esi, [edi + sizeof UndoRedo]
    dec g_undoRedoSize
    mov eax, g_undoRedoSize
    sub eax, index
    .IF eax != 0
        mov edx, sizeof UndoRedo
        mul edx
        invoke crt_memmove, edi, esi, eax
    .ENDIF
    ret
RemoveUndoRedo endp

ClearUndoRedo proc
    .IF g_undoRedoSize != 0
        .WHILE g_undoRedoSize != 0
            invoke RemoveUndoRedo, 0
        .ENDW
        mov g_undoRedoCurr, 0
        invoke DeleteObject, g_hdcBitmap
    .ENDIF
    ret
ClearUndoRedo endp

RestoreHdcBuffer proc
    invoke BitBlt, g_hdcBuf, 0, 0, g_canvasWidth, g_canvasHeight, g_hdcDrawingBuf, 0, 0, SRCCOPY
    ret
RestoreHdcBuffer endp

UpdateMainWindowTitle proc
    LOCAL text[MAX_PATH]:BYTE
    .IF g_bitmapName == 0
        invoke crt_strcpy, addr text, offset defaultSaveAsName
    .ELSE
        invoke crt_strcpy, addr text, offset g_bitmapName
    .ENDIF
    invoke PathStripPath, addr text
    invoke PathRemoveExtension, addr text
    .IF g_isModified == 0
        invoke crt_sprintf, addr g_textBuffer, addr mainWindowNoModifiedTitle, addr text
    .ELSE
        invoke crt_sprintf, addr g_textBuffer, addr mainWindowModifiedTitle, addr text
    .ENDIF
    invoke SetWindowText, g_hWnd, addr g_textBuffer
    ret
UpdateMainWindowTitle endp

LoadUndoRedoCurr proc uses esi
    LOCAL hdc:HDC

    mov eax, g_undoRedoCurr
    mov edx, sizeof UndoRedo
    mul edx
    lea esi, [g_undoRedo + eax]
    mov eax, (UndoRedo ptr [esi]).hBitmap
    mov g_hdcDrawingBitmap, eax
    invoke SelectObject, g_hdcDrawingBuf, g_hdcDrawingBitmap
    mov ecx, (UndoRedo ptr [esi]).nWidth
    mov edx, (UndoRedo ptr [esi]).nHeight
    .IF g_canvasWidth != ecx || g_canvasHeight != edx
        mov g_canvasWidth, ecx
        mov g_canvasHeight, edx
        invoke DeleteObject, g_hdcBitmap
        invoke GetDC, g_hWnd
        mov hdc, eax
        invoke CreateCompatibleBitmap, hdc, g_canvasWidth, g_canvasHeight
        mov g_hdcBitmap, eax
        invoke ReleaseDC, g_hWnd, hdc
        invoke SelectObject, g_hdcBuf, g_hdcBitmap
    .ENDIF
    mov eax, g_undoRedoCurr
    .IF g_undoRedoSaved == eax
        mov g_isModified, 0
    .ELSE
        mov g_isModified, 1
    .ENDIF
    invoke UpdateMainWindowTitle
    ret
LoadUndoRedoCurr endp

UpdateUndoRedoMenu proc
    .IF g_undoRedoCurr > 0
        invoke EnableMenuItem, g_hMenu, IDM_UNDO, MF_BYCOMMAND or MF_ENABLED
    .ELSEIF
        invoke EnableMenuItem, g_hMenu, IDM_UNDO, MF_BYCOMMAND or MF_GRAYED
    .ENDIF
    mov eax, g_undoRedoCurr
    inc eax
    .IF eax < g_undoRedoSize
        invoke EnableMenuItem, g_hMenu, IDM_REDO, MF_BYCOMMAND or MF_ENABLED
    .ELSEIF
        invoke EnableMenuItem, g_hMenu, IDM_REDO, MF_BYCOMMAND or MF_GRAYED
    .ENDIF
    ret
UpdateUndoRedoMenu endp

MakeBitmapCopy proc, hdc:HDC, nWidth:DWORD, nHeight:DWORD
    LOCAL hWinDC:HDC
    LOCAL hNewDC:HDC
    LOCAL hNewBitmap:HBITMAP
    invoke GetDC, g_hWnd
    mov hWinDC, eax
    invoke CreateCompatibleDC, hWinDC
    mov hNewDC, eax
    invoke CreateCompatibleBitmap, hWinDC, nWidth, nHeight
    mov hNewBitmap, eax
    invoke ReleaseDC, g_hWnd, hWinDC
    invoke SelectObject, hNewDC, hNewBitmap
    invoke BitBlt, hNewDC, 0, 0, nWidth, nHeight, hdc, 0, 0, SRCCOPY
    invoke DeleteDC, hNewDC
    mov eax, hNewBitmap
    ret
MakeBitmapCopy endp

SaveUndoRedo proc uses ebx
    mov ebx, g_undoRedoCurr
    inc ebx
    .WHILE ebx < g_undoRedoSize
        invoke RemoveUndoRedo, ebx
    .ENDW
    .IF g_undoRedoSaved > ebx
        mov g_undoRedoSaved, -1
    .ENDIF
    .IF g_undoRedoSize == UNDO_MAX_TIMES
        invoke RemoveUndoRedo, 0
        dec g_undoRedoCurr
        .IF g_undoRedoSaved != -1
            dec g_undoRedoSaved
        .ENDIF
    .ENDIF
    mov eax, g_undoRedoSize
    mov edx, sizeof UndoRedo
    mul edx
    lea ebx, [g_undoRedo + eax]
    invoke MakeBitmapCopy, g_hdcBuf, g_canvasWidth, g_canvasHeight
    mov (UndoRedo ptr [ebx]).hBitmap, eax
    mov eax, g_canvasWidth
    mov (UndoRedo ptr [ebx]).nWidth, eax
    mov eax, g_canvasHeight
    mov (UndoRedo ptr [ebx]).nHeight, eax
    mov eax, g_undoRedoSize
    .IF g_undoRedoSize != 0
        inc g_undoRedoCurr
    .ENDIF
    inc g_undoRedoSize
    invoke LoadUndoRedoCurr
    invoke UpdateUndoRedoMenu
    ret
SaveUndoRedo endp

MarkSaved proc
    mov eax, g_undoRedoCurr
    mov g_undoRedoSaved, eax
    mov g_isModified, 0
    ret
MarkSaved endp

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

InitCanvas proc
    LOCAL hdc: HDC
    invoke GetDC, g_hWnd
    mov hdc, eax    
    invoke CreateCompatibleBitmap, hdc, g_canvasWidth, g_canvasHeight
    mov g_hdcBitmap, eax
    invoke SelectObject, g_hdcBuf, g_hdcBitmap
    invoke ReleaseDC, g_hWnd, hdc    
    ret
InitCanvas endp

InitUndoRedo proc
    LOCAL hdc: HDC
    invoke GetDC, g_hWnd
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov g_hdcBuf, eax
    invoke InitCanvas
    invoke CreateCompatibleDC, hdc
    mov g_hdcDrawingBuf, eax    
    invoke ReleaseDC, g_hWnd, hdc
    ret
InitUndoRedo endp

Undo proc
    .IF g_undoRedoCurr > 0
        dec g_undoRedoCurr
        invoke LoadUndoRedoCurr
        invoke RestoreHdcBuffer
        mov eax, 1
        invoke UpdateUndoRedoMenu
    .ELSE
        xor eax, eax
    .ENDIF
    ret
Undo endp

Redo proc
    mov eax, g_undoRedoCurr
    inc eax
    .IF eax < g_undoRedoSize
        inc g_undoRedoCurr
        invoke LoadUndoRedoCurr
        invoke RestoreHdcBuffer
        mov eax, 1
        invoke UpdateUndoRedoMenu
    .ELSE
        xor eax, eax
    .ENDIF
    ret
Redo endp

StartDrawing proc
    mov g_isDrawing, TRUE
    ret
StartDrawing endp

StopDrawing proc applyChange:DWORD ;Bool    
    .IF applyChange == TRUE
        invoke SaveUndoRedo
    .ELSE
        invoke RestoreHdcBuffer
    .ENDIF
    invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
    mov g_isDrawing, FALSE
    ret
StopDrawing endp

StartCapture proc
    mov g_isCapturing, TRUE
    invoke SetCapture, g_hWndCanvas
    ret
StartCapture endp

StopCapture proc
    mov g_isCapturing, FALSE
    invoke ReleaseCapture
    invoke UpdateCursor
    ret
StopCapture endp

IsSamePoint proc point1X:DWORD, point1Y:DWORD, point2X:DWORD, point2Y:DWORD
    mov eax, FALSE
    mov edx, point1X
    .IF edx == point2X
        mov edx, point1Y
        .IF edx == point2Y
            mov eax, TRUE
        .ENDIF
    .ENDIF
    ret
IsSamePoint endp

IsSameRowOrColumn proc point1X:DWORD, point1Y:DWORD, point2X:DWORD, point2Y:DWORD
    
    mov eax, point1X
    mov edx, point1Y
    .IF eax == point2X || ebx == point2Y
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IsSameRowOrColumn endp

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

UpdateCanvasWindowPosition proc
    LOCAL rect:RECT
    LOCAL rectStatusBar:RECT

    invoke GetClientRect, g_hWnd, addr rect
    
    .IF g_hasToolbar
        add rect.left, TOOLBAR_WIDTH
    .ENDIF
    .IF g_hasStatusBar
        invoke GetWindowRect, g_hWndStatusBar, addr rectStatusBar
        mov eax, rectStatusBar.bottom
        sub eax, rectStatusBar.top
        sub rect.bottom, eax
    .ENDIF
    
    mov ecx, rect.right
    sub ecx, rect.left
    mov edx, rect.bottom
    sub edx, rect.top
    invoke SetWindowPos, g_hWndCanvas, HWND_TOP, rect.left, rect.top, \
        ecx, edx, SWP_SHOWWINDOW
    ret
UpdateCanvasWindowPosition endp

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
        invoke MessageBox, g_hWnd, offset cannotOpenFileDialogText, offset cannotOpenFileDialogTitle, MB_OK or MB_ICONEXCLAMATION
        ret
    .ENDIF
    invoke crt_strcpy, offset g_bitmapName, pfilename
    invoke GetObject, bitmapHandle, SIZEOF bm, addr bm
    mov eax, bm.bmWidth
    mov g_canvasWidth, eax
    mov eax, bm.bmHeight
    mov g_canvasHeight, eax
    mov eax, bitmapHandle
    mov g_hdcBitmap, eax
    invoke SelectObject, g_hdcBuf, g_hdcBitmap
    invoke ClearUndoRedo
    invoke SaveUndoRedo
    invoke MarkSaved
    invoke UpdateScrollBarSize
    invoke UpdateMainWindowTitle
    invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
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
    invoke MarkSaved
    invoke UpdateMainWindowTitle
    ret
SaveBitmapFile endp

; return 1 if success, NULL if user cancels
OpenSaveBitmapDialog proc
    LOCAL openFileStruct:OPENFILENAME
    .IF g_bitmapName == 0
        invoke crt_strcpy, offset g_textBuffer, offset defaultSaveAsName
    .ELSE
        invoke crt_strcpy, offset g_textBuffer, offset g_bitmapName
    .ENDIF
    mov openFileStruct.lStructSize, SIZEOF openFileStruct
    mov eax, g_hWnd
    mov openFileStruct.hwndOwner, eax
    mov openFileStruct.hInstance, NULL
    mov openFileStruct.lpstrFilter, OFFSET openFileFilterPattern
    mov openFileStruct.lpstrCustomFilter, NULL
    mov openFileStruct.nFilterIndex, 0
    lea eax, g_textBuffer
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
        invoke crt_strcpy, offset g_bitmapName, offset g_textBuffer
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
    
    invoke InvalidateRect, g_hWndControl, NULL, FALSE
    ret
SetCanvasColor endp

ResizeCanvas proc, newWidth:DWORD, newHeight:DWORD
    LOCAL hdc:HDC
    LOCAL hNewDC:HDC
    LOCAL hNewBitmap:HBITMAP
    LOCAL rect:RECT
    invoke GetDC, g_hWnd
    mov hdc, eax
    invoke CreateCompatibleDC, hdc
    mov hNewDC, eax
    invoke CreateCompatibleBitmap, hdc, newWidth, newHeight
    mov hNewBitmap, eax
    invoke ReleaseDC, g_hWnd, hdc
    invoke SelectObject, hNewDC, hNewBitmap
    mov rect.left, 0
    mov rect.top, 0
    mov eax, newWidth
    mov rect.right, eax
    mov eax, newHeight
    mov rect.bottom, eax
    invoke FillRect, hNewDC, addr rect, WHITE_BRUSH
    invoke BitBlt, hNewDC, 0, 0, g_canvasWidth, g_canvasHeight, g_hdcBuf, 0, 0, SRCCOPY
    invoke DeleteObject, g_hdcBitmap
    invoke DeleteDC, g_hdcBuf
    mov eax, hNewDC
    mov g_hdcBuf, eax
    mov eax, hNewBitmap
    mov g_hdcBitmap, eax
    mov eax, newWidth
    mov g_canvasWidth, eax
    mov eax, newHeight
    mov g_canvasHeight, eax
    ret
ResizeCanvas endp

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

UpdateStatusBarInfo proc, id:DWORD
    invoke crt_printf, offset debugHelp, id, g_isMenuOpened
    ; g_textBuffer
    .IF id != 0
        ; display help message
    .ELSEIF g_isMenuOpened != 0
        ; display empty message
        mov g_textBuffer, 0
    .ELSE
        ; display welcome message
    .ENDIF
    ret
UpdateStatusBarInfo endp

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

PropertyDialogProc proc uses ebx esi, hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL handle:HWND
    .IF uMsg == WM_INITDIALOG
        .IF g_isModified == 0
            mov eax, offset yesText
        .ELSE
            mov eax, offset noText
        .ENDIF            
        invoke SetDlgItemText, hWnd, IDC_PROPERTY_SAVED, eax
        invoke crt_sprintf, offset g_textBuffer, offset intText, g_canvasWidth
        invoke SetDlgItemText, hWnd, IDC_PROPERTY_WIDTH, offset g_textBuffer
        invoke crt_sprintf, offset g_textBuffer, offset intText, g_canvasHeight
        invoke SetDlgItemText, hWnd, IDC_PROPERTY_HEIGHT, offset g_textBuffer
        invoke GetDlgItem, hWnd, IDC_PROPERTY_WIDTH
        mov handle, eax
        invoke PostMessage, hWnd, WM_NEXTDLGCTL, handle, TRUE
        invoke SendMessage, handle, EM_SETLIMITTEXT, 4, 0
        invoke GetDlgItem, hWnd, IDC_PROPERTY_HEIGHT
        mov handle, eax
        invoke SendMessage, handle, EM_SETLIMITTEXT, 4, 0
        invoke GetDlgItem, hWnd, IDC_PROPERTY_WIDTH_UDN
        mov handle, eax
        invoke SendMessage, handle, UDM_SETRANGE, 0, 1 * 10000h + 9999
        invoke GetDlgItem, hWnd, IDC_PROPERTY_HEIGHT_UDN
        mov handle, eax
        invoke SendMessage, handle, UDM_SETRANGE, 0, 1 * 10000h + 9999
        mov eax, g_canvasWidth
        mov g_tempInt1, eax
        mov eax, g_canvasHeight
        mov g_tempInt2, eax
	.ELSEIF uMsg == WM_COMMAND
	    .IF wParam == IDC_PROPERTY_OKAY
	        invoke EndDialog, hWnd, 1
	    .ELSEIF wParam == IDC_PROPERTY_CANCEL || wParam == IDCANCEL
	        invoke EndDialog, hWnd, 0
	    .ELSEIF wParam == IDC_PROPERTY_DEFAULT
	        mov g_tempInt1, DEFAULT_CANVAS_WIDTH
	        mov g_tempInt2, DEFAULT_CANVAS_HEIGHT
            invoke crt_sprintf, offset g_textBuffer, offset intText, DEFAULT_CANVAS_WIDTH
            invoke SetDlgItemText, hWnd, IDC_PROPERTY_WIDTH, offset g_textBuffer
            invoke crt_sprintf, offset g_textBuffer, offset intText, DEFAULT_CANVAS_HEIGHT
            invoke SetDlgItemText, hWnd, IDC_PROPERTY_HEIGHT, offset g_textBuffer
	    .ELSE
	        mov eax, wParam
	        movzx ebx, ax
	        shr eax, 16
	        .IF eax == EN_CHANGE && (ebx == IDC_PROPERTY_WIDTH || ebx == IDC_PROPERTY_HEIGHT)
	            .IF ebx == IDC_PROPERTY_WIDTH
	                mov esi, offset g_tempInt1
	            .ELSE
	                mov esi, offset g_tempInt2
	            .ENDIF
                invoke GetDlgItemText, hWnd, ebx, offset g_textBuffer, TEXT_BUFFER_SIZE
                invoke crt_atol, offset g_textBuffer
                .IF (SDWORD ptr eax) < 1 || (SDWORD ptr eax) >= MAX_HEIGHT_WIDTH
                    mov eax, [esi]
                    invoke crt_sprintf, offset g_textBuffer, offset intText, eax
                    invoke SetDlgItemText, hWnd, ebx, offset g_textBuffer
                .ELSE
                    mov [esi], eax
                .ENDIF
	        .ENDIF
	    .ENDIF
	.ENDIF
	xor eax, eax
	ret
PropertyDialogProc endp

WndProc proc USES ebx, hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hBmp:HBITMAP
    LOCAL canvasWndRect:RECT

    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSEIF uMsg == WM_CREATE
        mov eax, hWnd
        mov g_hWnd, eax
        ; ===== Create Coordinate status bar =====
        invoke CreateWindowEx, 0, addr statusBarClassName, NULL, WS_CHILD or WS_VISIBLE, 0, 0, 0, 0, \
            hWnd, NULL, g_hInst, NULL
        mov g_hWndStatusBar, eax
        invoke GetMenu, hWnd
        mov g_hMenu, eax
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
        invoke CreateWindowEx, 0, addr canvasClassName, NULL, WS_CHILD or WS_HSCROLL or WS_VSCROLL, \
               0, 0, 0, 0, \
               hWnd, NULL, g_hInst, NULL        
        invoke UpdateCanvasWindowPosition
        invoke UpdateStatusBarInfo, 0
        invoke ShowWindow, g_hWndCanvas, SW_SHOW
    .ELSEIF uMsg == WM_SIZE
        invoke SendMessage, g_hWndControl, TB_AUTOSIZE, 0, 0
        invoke SendMessage, g_hWndStatusBar, WM_SIZE, 0, 0
        invoke UpdateCanvasWindowPosition
        invoke UpdateStatusBarSize
    .ELSEIF uMsg == WM_COMMAND
        invoke crt_printf, offset debugWndProcMsg, uMsg, wParam, lParam
        mov eax, wParam
        movzx eax, ax
        .IF eax == IDM_OPEN
            .IF g_isModified == 1
                invoke ConfirmSaveModify
                .IF eax == 0
                    jmp DontOpenFile
                .endif
            .ENDIF
            invoke OpenOpenBitmapDialog, g_hWnd, addr g_textBuffer
            .IF eax != NULL
                invoke LoadBitmapFromFile, g_hWndCanvas, addr g_textBuffer
            .endif
            DontOpenFile:
        .ELSEIF eax == IDM_NEW
            .IF g_isModified == 1
                invoke ConfirmSaveModify
                .IF eax == 0
                    jmp DontNewCanvas
                .endif
            .ENDIF
            mov g_canvasWidth, DEFAULT_CANVAS_WIDTH
            mov g_canvasHeight, DEFAULT_CANVAS_HEIGHT
            mov g_bitmapName, 0
            invoke DeleteObject, g_hdcBitmap
            invoke InitCanvas
            invoke ClearCanvas
            invoke ClearUndoRedo
            invoke SaveUndoRedo
            invoke MarkSaved
            invoke UpdateScrollBarSize
            invoke UpdateMainWindowTitle
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
            DontNewCanvas:
        .ELSEIF eax == IDM_SAVE
            .IF g_isModified != 0
                .IF g_bitmapName == 0
                    invoke SendMessage, g_hWndControl, WM_COMMAND, IDM_SAVEAS, lParam
                .ELSE
                    invoke SaveBitmapFile
                .ENDIF
            .ENDIF
        .ELSEIF eax == IDM_SAVEAS
            invoke OpenSaveBitmapDialog
            .IF eax != NULL
                invoke SaveBitmapFile
            .endif
        .ELSEIF eax == IDM_UNDO
            .IF g_isDrawing == 0
                invoke Undo
                invoke UpdateScrollBarSize
                invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
            .ENDIF
        .ELSEIF eax == IDM_REDO
            .IF g_isDrawing == 0
                invoke Redo
                invoke UpdateScrollBarSize
                invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
            .ENDIF
        .ELSEIF eax == IDM_EXIT
            invoke SendMessage, hWnd, WM_CLOSE, 0, 0
        .ELSEIF eax == IDM_TOOLBAR
            .IF g_hasToolbar == 0
                invoke CheckMenuItem, g_hMenu, IDM_TOOLBAR, MF_BYCOMMAND or MF_CHECKED
                invoke ShowWindow, g_hWndControl, SW_SHOW
                mov eax, 1
            .ELSE
                invoke CheckMenuItem, g_hMenu, IDM_TOOLBAR, MF_BYCOMMAND or MF_UNCHECKED
                invoke ShowWindow, g_hWndControl, SW_HIDE
                mov eax, 0
            .ENDIF
            mov g_hasToolbar, eax
            invoke UpdateCanvasWindowPosition
            invoke InvalidateRect, hWnd, NULL, FALSE
        .ELSEIF eax == IDM_STATUSBAR
            .IF g_hasStatusBar == 0
                invoke CheckMenuItem, g_hMenu, IDM_STATUSBAR, MF_BYCOMMAND or MF_CHECKED
                invoke ShowWindow, g_hWndStatusBar, SW_SHOW
                mov eax, 1
            .ELSE
                invoke CheckMenuItem, g_hMenu, IDM_STATUSBAR, MF_BYCOMMAND or MF_UNCHECKED
                invoke ShowWindow, g_hWndStatusBar, SW_HIDE
                mov eax, 0
            .ENDIF
            mov g_hasStatusBar, eax
            invoke UpdateCanvasWindowPosition
            invoke InvalidateRect, hWnd, NULL, FALSE
        .ELSEIF eax == IDM_CLEAR
            .IF g_isDrawing == 0
                invoke ClearCanvas
                invoke SaveUndoRedo
                invoke InvalidateRect, hWnd, NULL, FALSE
            .ENDIF
        .ELSEIF eax == IDM_FOREGROUND_COLOR
            invoke PromptColor, 0
        .ELSEIF eax == IDM_BACKGROUND_COLOR
            invoke PromptColor, 1
        .ELSEIF eax == IDM_ABOUT
            invoke MessageBox, hWnd, offset aboutDialogText, offset aboutDialogName, MB_OK or MB_ICONINFORMATION
        .ELSEIF eax == IDM_PROPERTY
            invoke DialogBoxParam, g_hInst, IDD_PROPERTY, g_hWnd, offset PropertyDialogProc, 0
            .IF eax != 0
                mov ecx, g_tempInt1
                mov edx, g_tempInt2
                .IF ecx != g_canvasWidth || edx != g_canvasHeight
                    invoke ResizeCanvas, ecx, edx
                    invoke SaveUndoRedo
                    invoke UpdateScrollBarSize
                    invoke UpdateMainWindowTitle
                    invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
                .ENDIF
            .ENDIF
        .ELSEIF eax >= IDM_TOOLBAR_FIRST && eax <=IDM_TOOLBAR_LAST
            mov eax, wParam
            mov g_toolbarStatus, eax
        .ENDIF
    .ELSEIF uMsg == WM_MENUSELECT
        .IF wParam == 0ffff0000h
            mov g_isMenuOpened, 0
            invoke UpdateStatusBarInfo, 0
        .ELSE
            mov eax, wParam
            shr eax, 16
            and eax, MF_POPUP
            .IF eax == 0
                mov eax, wParam
                movzx eax, ax
                invoke UpdateStatusBarInfo, eax
            .ELSE
                mov g_isMenuOpened, 1
                invoke UpdateStatusBarInfo, 0
            .ENDIF
        .ENDIF
    .ELSEIF uMsg == WM_NOTIFY
        mov edx, lParam
        mov eax, (NMHDR ptr [edx]).code
        .IF eax == TBN_HOTITEMCHANGE
            invoke UpdateStatusBarInfo, (NMTBHOTITEM ptr [edx]).idNew
        .ENDIF
    .ELSEIF uMsg == WM_DROPFILES
    	invoke DragQueryFile, wParam, 0, addr g_textBuffer, MAX_FILE_NAME_SIZE
    	.IF eax != 0
    	    .IF g_isModified == TRUE
    	        invoke ConfirmSaveModify
                .IF eax == 0
                    jmp DontOpenDropFile
                .endif
            .ENDIF
    	    invoke LoadBitmapFromFile, g_hWndCanvas, addr g_textBuffer
    	.ENDIF
    	DontOpenDropFile:
    .ELSEIF uMsg == WM_CLOSE
        .IF g_isModified == 1
            invoke ConfirmSaveModify
            .IF eax != 0
                invoke DestroyWindow, hWnd
            .ENDIF
        .ELSE
            invoke DestroyWindow, hWnd
        .ENDIF
    .ELSEIF uMsg == WM_ERASEBKGND
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

CanvasToClientX proc pos:DWORD
    mov eax, pos
    sub eax, g_canvasOffsetX
    mov edx, g_zoom
    mul edx
    add eax, CANVAS_MARGIN
    ret
CanvasToClientX endp

CanvasToClientY proc pos:DWORD
    mov eax, pos
    sub eax, g_canvasOffsetY
    mov edx, g_zoom
    mul edx
    add eax, CANVAS_MARGIN
    ret
CanvasToClientY endp

UpdateMousePos proc
    LOCAL point:POINT
    LOCAL rect:RECT
    invoke GetCursorPos, addr point
    invoke ScreenToClient, g_hWndCanvas, addr point
    invoke GetClientRect, g_hWndCanvas, addr rect
    mov eax, point.x
    mov g_mouseClientX, eax
    mov eax, point.y
    mov g_mouseClientY, eax
    invoke ClientToCanvasX, g_mouseClientX
    mov g_mouseCanvasX, eax
    invoke ClientToCanvasY, g_mouseClientY
    mov g_mouseCanvasY, eax
    mov ecx, rect.right
    mov edx, rect.bottom
    .IF g_mouseClientX >= 0 && g_mouseClientX < ecx && g_mouseClientY >= 0 && g_mouseClientY < edx
        mov ecx, g_canvasWidth
        mov edx, g_canvasHeight
        .IF g_mouseCanvasX >= 0 && g_mouseCanvasX < ecx && g_mouseCanvasY >= 0 && g_mouseCanvasY < edx
            mov g_mouseInCanvas, 1
        .ELSE
            mov g_mouseInCanvas, 0
        .ENDIF
    .ELSE
        mov g_mouseInCanvas, 0
    .ENDIF
    ret
UpdateMousePos endp

UpdateStatusBarMouseCoordinate proc
    .IF g_mouseInCanvas == 1 || g_isDrawing == 1
        invoke crt_sprintf, addr g_textBuffer, offset coordinateFormat, g_mouseCanvasX, g_mouseCanvasY
    .ELSE
        mov al, 0
        mov g_textBuffer, al
    .ENDIF
    invoke SendMessage, g_hWndStatusBar, SB_SETTEXT, 1, addr g_textBuffer
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
        invoke UpdateMousePos
        invoke UpdateStatusBarMouseCoordinate
        invoke UpdateCursor
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
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

UpdateZoom proc uses ebx, mode:DWORD, value:DWORD, canvasX:SDWORD, canvasY:SDWORD
    ; TODO: set scroll center
    ; mode: 0 value, 1 delta
    LOCAL zoomDelta:SWORD
    .IF mode == 1
        mov ebx, g_zoom
        add ebx, value
    .ELSE
        mov ebx, value
    .ENDIF
    .IF ebx != 0 && ebx <= MAX_ZOOM && ebx != g_zoom
        mov eax, g_zoom
        mov g_zoom, ebx
        sub ebx, eax
        invoke UpdateScrollBarSize
        mov eax, canvasY
        imul ebx
        mov ecx, SCROLL_STEP_PIXEL
        idiv ecx
        invoke UpdateScrollPosition, 0, 1, eax
        mov eax, canvasX
        imul ebx
        mov ecx, SCROLL_STEP_PIXEL
        idiv ecx
        invoke UpdateScrollPosition, 1, 1, eax
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
    .ENDIF
    ret
UpdateZoom endp

SetPen proc hdc:HDC
    invoke CreatePen, PS_SOLID, g_penWidth, g_foregroundColor
    mov g_pen, eax
    invoke SelectObject, hdc, eax
    ret
SetPen endp

DeletePen proc
    .IF g_pen != NULL
        invoke DeleteObject, g_pen
        mov g_pen, NULL
    .endif
    ret
DeletePen endp

SetBrush proc hdc:HDC
    .IF g_fillType == FILL_WITHOUT_BORDER
        invoke GetStockObject, NULL_PEN
        mov g_pen, eax
    .ELSE
        invoke CreatePen, PS_SOLID, g_penWidth, g_foregroundColor
        mov g_pen, eax
    .ENDIF
    
    .IF g_fillType == FILL_WITHOUT_FILL
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

SetRectanglePen proc hdc:HDC, color:DWORD, penWidth:DWORD
    LOCAL canvasHdc:HDC
    LOCAL hdcTemp:HDC
    LOCAL bitmapTemp:HBITMAP
    LOCAL rect:RECT
    LOCAL brush:HBRUSH
    LOCAL br:LOGBRUSH
    invoke GetDC, g_hWndCanvas
    mov canvasHdc, eax
    invoke CreateCompatibleDC, canvasHdc
    mov hdcTemp, eax
    invoke CreateCompatibleBitmap, canvasHdc, penWidth, penWidth
    mov bitmapTemp, eax
    invoke SelectObject, hdcTemp, bitmapTemp
    mov rect.left, 0
    mov rect.top, 0
    mov eax, penWidth
    mov rect.right, eax
    mov rect.bottom, eax
    invoke CreateSolidBrush, color
    mov brush, eax
    invoke FillRect, hdcTemp, addr rect, brush
    mov br.lbStyle, BS_PATTERN
    mov br.lbColor, 0
    mov eax, bitmapTemp
    mov br.lbHatch, eax
    invoke ExtCreatePen,PS_SOLID or PS_GEOMETRIC, penWidth, addr br, 0, 0
    mov g_pen, eax
    invoke SelectObject, hdc, eax
    invoke DeleteObject, bitmapTemp
    invoke DeleteObject, brush
    invoke DeleteDC, hdcTemp
    invoke ReleaseDC, g_hWndCanvas, canvasHdc
    invoke CreateSolidBrush, color
    mov g_brush, eax
    ret
SetRectanglePen endp

DeleteRectanglePen proc
    .IF g_pen != NULL
        invoke DeleteObject, g_pen
        mov g_pen, NULL
    .endif
    .IF g_brush != NULL
        invoke DeleteObject, g_brush
        mov g_brush, NULL
    .endif
    ret
DeleteRectanglePen endp

DrawEraser proc hdc:HDC
    LOCAL eraserLeftCanvas:DWORD
    LOCAL eraserTopCanvas:DWORD
    LOCAL eraserFromX:DWORD
    LOCAL eraserFromY:DWORD
    LOCAL eraserToX:DWORD
    LOCAL eraserToY:DWORD
    LOCAL eraserWidth:DWORD
    LOCAL eraserHeight:DWORD
    LOCAL canvasFromX:DWORD
    LOCAL canvasFromY:DWORD
    
    mov eax, g_eraserWidth
    shr eax, 1
    mov edx, g_mouseCanvasX
    sub edx, eax
    mov eraserLeftCanvas, edx
    .IF SDWORD PTR edx > 0
        mov eraserFromX, edx
    .ELSE
        mov eraserFromX, 0
    .ENDIF
    mov edx, g_mouseCanvasY
    sub edx, eax
    mov eraserTopCanvas, edx
    .IF SDWORD PTR edx > 0
        mov eraserFromY, edx
    .ELSE
        mov eraserFromY, 0
    .ENDIF
    mov edx, g_mouseCanvasX
    add edx, eax
    .IF SDWORD PTR edx < g_canvasWidth
        mov eraserToX, edx
    .ELSE
        mov edx, g_canvasWidth
        mov eraserToX, edx
    .ENDIF
    mov edx, g_mouseCanvasY
    add edx, eax
    .IF SDWORD PTR edx < g_canvasHeight
        mov eraserToY, edx
    .ELSE
        mov edx, g_canvasHeight
        mov eraserToY, edx
    .ENDIF
    
    invoke CanvasToClientX, eraserLeftCanvas
    mov eraserLeftCanvas, eax
    invoke CanvasToClientY, eraserTopCanvas
    mov eraserTopCanvas, eax
    invoke CanvasToClientX, eraserFromX
    .IF SDWORD PTR eax < CANVAS_MARGIN
        mov eax, CANVAS_MARGIN
    .endif
    mov eraserFromX, eax
    mov canvasFromX, eax
    invoke CanvasToClientY, eraserFromY
    .IF SDWORD PTR eax < CANVAS_MARGIN
        mov eax, CANVAS_MARGIN
    .endif
    mov eraserFromY, eax
    mov canvasFromY, eax
    invoke CanvasToClientX, eraserToX
    mov eraserToX, eax
    invoke CanvasToClientY, eraserToY
    mov eraserToY, eax
    
    mov eax, eraserToX
    sub eax, eraserFromX
    mov eraserWidth, eax
    
    mov eax, eraserFromX
    sub eax, eraserLeftCanvas
    mov eraserFromX, eax
    
    mov eax, eraserToY
    sub eax, eraserFromY
    mov eraserHeight, eax
    mov eax, eraserFromY
    sub eax, eraserTopCanvas
    mov eraserFromY, eax
    
    invoke BitBlt, hdc, canvasFromX, canvasFromY, eraserWidth, eraserHeight, g_hdcEraserBuf, eraserFromX, eraserFromY, SRCCOPY
    
    ret
DrawEraser endp

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
    
    invoke StretchBlt, hdcBuffer, CANVAS_MARGIN, CANVAS_MARGIN, widthAfterZoom, heightAfterZoom, \
           g_hdcBuf, g_canvasOffsetX, g_canvasOffsetY, canvasWidthMinusOffsetX, canvasHeightMinusOffsetY, \
           SRCCOPY
    
    .IF g_toolbarStatus == IDM_ERASER && g_mouseInCanvas == TRUE
        invoke UpdateEraser
        invoke DrawEraser, hdcBuffer
    .ENDIF  
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

UpdateCursor proc
    .IF g_isCapturing == FALSE
        .IF g_mouseInCanvas == 1
            .IF g_toolbarStatus == IDM_PAINT_BARREL
                mov edx, g_hInst
                mov ecx, IDC_BUCKET
            .ELSEIF g_toolbarStatus == IDM_COLOR_PICKER
                mov edx, g_hInst
                mov ecx, IDC_PICK
            .ELSEIF g_toolbarStatus == IDM_MAGNIFIER
                mov edx, g_hInst
                mov ecx, IDC_ZOOM
            .ELSEIF g_toolbarStatus == IDM_PENCIL
                mov edx, g_hInst
                mov ecx, IDC_PEN
            .ELSEIF g_toolbarStatus == IDM_BRASH
                mov edx, g_hInst
                mov ecx, IDC_BRUSH
            .ELSEIF g_toolbarStatus == IDM_AIRBRUSH
                mov edx, g_hInst
                mov ecx, IDC_SPRAY
            .ELSEIF g_toolbarStatus == IDM_ERASER
                mov edx, NULL
                mov ecx, IDC_ARROW
            .ELSE
                mov edx, g_hInst
                mov ecx, IDC_SELECT
            .ENDIF
        .ELSE
            mov edx, NULL
            mov ecx, IDC_ARROW
        .ENDIF
        .IF g_cursorInst != edx || g_cursor != ecx
            mov g_cursorInst, edx
            mov g_cursor, ecx
            invoke LoadCursor, g_cursorInst, g_cursor
            invoke SetCursor, eax
        .ENDIF
    .ENDIF
    .IF g_mouseInCanvas == 1 && g_toolbarStatus == IDM_ERASER && g_showCursor == 1
        invoke ShowCursor, FALSE
        mov g_showCursor, 0
    .ELSEIF (g_mouseInCanvas != 1 || g_toolbarStatus != IDM_ERASER) && g_showCursor == 0
        invoke ShowCursor, TRUE
        mov g_showCursor, 1
    .ENDIF
    ret
UpdateCursor endp

SaveCurrentPos proc Uses esi, posX:DWORD, posY:DWORD, point:PTR
    mov esi, point
    mov eax, posX
    mov (POINT PTR [esi]).x, eax
    mov eax, posY
    mov (POINT PTR [esi]).y, eax
    ret
SaveCurrentPos endp

FillWithBarrel proc fillColor:DWORD
    LOCAL crFill:DWORD
    LOCAL barrelBrush:DWORD
    invoke GetPixel, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
    mov crFill, eax
    invoke CreateSolidBrush, fillColor
    mov barrelBrush, eax
    invoke SelectObject, g_hdcBuf, barrelBrush
    invoke ExtFloodFill, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY, crFill, FLOODFILLSURFACE
    invoke DeleteObject, barrelBrush
    ret
FillWithBarrel endp

CalculateSquare proc USES esi,
    x1:SDWORD, y1:SDWORD, x2:SDWORD, y2:SDWORD, newX2:PTR, newY2:PTR
    ; eax: width
    mov eax, x2
    sub eax, x1
    .IF SDWORD PTR eax < 0
        neg eax
    .endif
    ; edx: height
    mov edx, y2
    sub edx, y1
    .IF SDWORD PTR edx < 0
        neg edx
    .endif
    .IF eax < edx
        mov edx, y1
        .IF y2 < edx
            sub edx, eax
        .ELSE
            add edx, eax
        .ENDIF
        mov eax, x2
    .ELSE
        mov eax, x1
        .IF x2 < eax
            sub eax, edx
        .ELSE
            add eax, edx
        .ENDIF
        mov edx, y2
    .endif
    mov esi, newX2
    mov (SDWORD PTR [esi]), eax
    mov esi, newY2
    mov (SDWORD PTR [esi]), edx
    ret
CalculateSquare endp

HandleLButtonDownMessage proc wParam:WPARAM
    LOCAL eraserRect:RECT
    invoke StartCapture
    .IF g_toolbarStatus == IDM_PENCIL
        invoke StartDrawing
        invoke SetRectanglePen, g_hdcBuf, g_foregroundColor, g_penWidth
        ;.IF g_penWidth == 1
        ;    invoke SetPixel, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY, g_foregroundColor
        ;.ELSE
            invoke MoveToEx, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY, NULL
            invoke LineTo, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
        ;.ENDIF
        invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
    .ELSEIF g_toolbarStatus == IDM_STRAIGHT_LINE
        invoke StartDrawing
        invoke SetPen, g_hdcBuf
        invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
    .ELSEIF g_toolbarStatus == IDM_RECTANGLE || g_toolbarStatus == IDM_ELLIPSE || g_toolbarStatus == IDM_ROUNDED_RECTANGLE
        invoke StartDrawing
        invoke SetBrush, g_hdcBuf
        invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
    .ELSEIF g_toolbarStatus == IDM_COLOR_PICKER
        invoke GetPixel, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
        invoke SetCanvasColor, 0, eax
    .ELSEIF g_toolbarStatus == IDM_PAINT_BARREL
        invoke StartDrawing
        invoke FillWithBarrel, g_foregroundColor
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        invoke StopDrawing, TRUE
    .ELSEIF g_toolbarStatus == IDM_ERASER
        invoke StartDrawing
        invoke SetRectanglePen, g_hdcBuf, g_backgroundColor, g_eraserWidth
        mov eax, g_eraserWidth
        shr eax, 1
        mov edx, g_mouseCanvasX
        sub edx, eax
        mov eraserRect.left, edx
        add edx, g_eraserWidth
        mov eraserRect.right, edx
        mov edx, g_mouseCanvasY
        sub edx, eax
        mov eraserRect.top, edx
        add edx, g_eraserWidth
        mov eraserRect.bottom, edx
        invoke FillRect, g_hdcBuf, addr eraserRect, g_brush
        invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
    .ENDIF
    ret
HandleLButtonDownMessage endp

HandleMouseMoveMessage proc wParam:WPARAM
    LOCAL x2:SDWORD
    LOCAL y2:SDWORD
    mov eax, wParam
    and eax, MK_LBUTTON
    .IF eax != 0
        .IF g_toolbarStatus == IDM_PENCIL
            invoke MoveToEx, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, NULL
            invoke LineTo, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
            invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ELSEIF g_toolbarStatus == IDM_STRAIGHT_LINE
            invoke RestoreHdcBuffer
            invoke IsSamePoint, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
            .IF eax == FALSE
                invoke MoveToEx, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, NULL
                invoke LineTo, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
            .ENDIF
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ELSEIF g_toolbarStatus == IDM_RECTANGLE
            invoke RestoreHdcBuffer
            invoke IsSameRowOrColumn, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
            .IF eax == FALSE
                mov eax, wParam
                and eax, MK_SHIFT
                .IF eax == 0
                    mov eax, g_mouseCanvasX
                    mov x2, eax
                    mov ebx, g_mouseCanvasY
                    mov y2, ebx
                .ELSE
                    invoke CalculateSquare, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY, addr x2, addr y2
                .ENDIF
                invoke Rectangle, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, x2, y2
            .endif
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ELSEIF g_toolbarStatus == IDM_ELLIPSE
            invoke RestoreHdcBuffer
            invoke IsSameRowOrColumn, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
            .IF eax == FALSE
                mov eax, wParam
                and eax, MK_SHIFT
                .IF eax == 0
                    mov eax, g_mouseCanvasX
                    mov x2, eax
                    mov ebx, g_mouseCanvasY
                    mov y2, ebx
                .ELSE
                    invoke CalculateSquare, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY, addr x2, addr y2
                .ENDIF
                invoke Ellipse, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, x2, y2
            .endif
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ELSEIF g_toolbarStatus == IDM_ROUNDED_RECTANGLE
            invoke RestoreHdcBuffer
            invoke IsSameRowOrColumn, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
            .IF eax == FALSE
                mov eax, wParam
                and eax, MK_SHIFT
                .IF eax == 0
                    mov eax, g_mouseCanvasX
                    mov x2, eax
                    mov ebx, g_mouseCanvasY
                    mov y2, ebx
                .ELSE
                    invoke CalculateSquare, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY, addr x2, addr y2
                .ENDIF
                invoke RoundRect, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, x2, y2, g_roundRectWidth, g_roundRectHeight
            .endif
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ELSEIF g_toolbarStatus == IDM_ERASER
            invoke MoveToEx, g_hdcBuf, g_previousPoint.x, g_previousPoint.y, NULL
            invoke LineTo, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
            invoke SaveCurrentPos, g_mouseCanvasX, g_mouseCanvasY, addr g_previousPoint
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ENDIF
    .ENDIF
    .IF g_toolbarStatus == IDM_COLOR_PICKER
        .IF g_mouseInCanvas == TRUE
            invoke GetPixel, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
            mov edx, wParam
            and edx, MK_LBUTTON
            .IF edx != 0
                invoke SetCanvasColor, 0, eax
            .ELSE
                invoke SetCanvasColor, 1, eax
            .ENDIF
        .ENDIF
    .ENDIF
    ret
HandleMouseMoveMessage endp

HandleLButtonUpMessage proc wParam:WPARAM
    LOCAL eraserRect:RECT
    invoke ReleaseCapture
    invoke UpdateCursor
    .IF g_toolbarStatus == IDM_PENCIL
        invoke DeleteRectanglePen
        invoke StopDrawing, TRUE
    .ELSEIF g_toolbarStatus == IDM_STRAIGHT_LINE
        invoke DeletePen
        invoke IsSamePoint, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
        .IF eax == TRUE
            invoke StopDrawing, FALSE
        .ELSE
            invoke StopDrawing, TRUE
        .ENDIF
    .ELSEIF g_toolbarStatus == IDM_RECTANGLE || g_toolbarStatus == IDM_ELLIPSE || g_toolbarStatus == IDM_ROUNDED_RECTANGLE
        invoke DeleteBrush
        invoke IsSameRowOrColumn, g_previousPoint.x, g_previousPoint.y, g_mouseCanvasX, g_mouseCanvasY
        .IF eax == TRUE
            invoke StopDrawing, FALSE
        .ELSE
            invoke StopDrawing, TRUE
        .endif
    .ELSEIF g_toolbarStatus == IDM_ERASER
        mov eax, g_eraserWidth
        shr eax, 1
        mov edx, g_mouseCanvasX
        sub edx, eax
        mov eraserRect.left, edx
        add edx, g_eraserWidth
        mov eraserRect.right, edx
        mov edx, g_mouseCanvasY
        sub edx, eax
        mov eraserRect.top, edx
        add edx, g_eraserWidth
        mov eraserRect.bottom, edx
        invoke FillRect, g_hdcBuf, addr eraserRect, g_brush
        invoke DeleteRectanglePen
        invoke StopDrawing, TRUE
    .ENDIF
    invoke StopCapture
    ret
HandleLButtonUpMessage endp

HandleRButtonDownMessage proc wParam
    invoke StartCapture
    .IF g_toolbarStatus == IDM_COLOR_PICKER
        invoke GetPixel, g_hdcBuf, g_mouseCanvasX, g_mouseCanvasY
        invoke SetCanvasColor, 1, eax
    .ELSEIF g_toolbarStatus == IDM_PAINT_BARREL
        invoke StartDrawing
        invoke FillWithBarrel, g_backgroundColor
        invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        invoke StopDrawing, TRUE
    .ENDIF
    ret
HandleRButtonDownMessage endp

CanvasWinProc proc USES ebx esi,
    hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_CREATE
        mov eax, hWnd
        mov g_hWndCanvas, eax
        invoke InitUndoRedo
        invoke ClearCanvas
        invoke SaveUndoRedo
        invoke MarkSaved
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
            invoke UpdateZoom, 1, eax, g_mouseCanvasX, g_mouseCanvasY
        .ENDIF
    .ELSEIF uMsg == WM_PAINT
        invoke Render, hWnd
    .ELSEIF uMsg == WM_LBUTTONDOWN
        .IF g_mouseInCanvas == TRUE
            invoke HandleLButtonDownMessage, wParam
        .ENDIF
    .ELSEIF uMsg == WM_MOUSEMOVE
        invoke CanvasTrackMouse
        invoke UpdateMousePos
        invoke UpdateStatusBarMouseCoordinate
        invoke UpdateCursor
        .IF g_isCapturing == TRUE
            invoke HandleMouseMoveMessage, wParam
        .ELSEIF g_toolbarStatus == IDM_ERASER
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ENDIF
    .ELSEIF uMsg == WM_LBUTTONUP
        .IF g_isCapturing == TRUE
            invoke HandleLButtonUpMessage, wParam
        .ENDIF
    .ELSEIF uMsg == WM_RBUTTONDOWN
        .IF g_mouseInCanvas == TRUE
            invoke HandleRButtonDownMessage, wParam
        .ENDIF
    .ELSEIF uMsg == WM_RBUTTONUP
        .IF g_isCapturing == TRUE
            invoke StopCapture
        .ENDIF
    .ELSEIF uMsg == WM_MOUSELEAVE
        mov g_mouseInCanvas, 0
        mov g_mouseTracking, 0
        invoke UpdateStatusBarMouseCoordinate
        invoke UpdateCursor
        .IF g_toolbarStatus == IDM_ERASER
            invoke InvalidateRect, g_hWndCanvas, NULL, FALSE
        .ENDIF
    .ELSEIF uMsg == WM_SETCURSOR
        invoke UpdateCursor
    .ELSEIF uMsg == WM_ERASEBKGND
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

    invoke LoadAccelerators, g_hInst, IDR_ACL
    mov g_hAccel, eax 

    .WHILE TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
        .BREAK .IF !eax
        invoke TranslateAccelerator, g_hWnd, g_hAccel, addr msg
        .IF eax == 0
            invoke TranslateMessage, addr msg
            invoke DispatchMessage, addr msg
        .ENDIF
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