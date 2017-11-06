.386
.model flat, stdcall

include asmpaint.Inc

.data
   ClassName BYTE "AsmPaintClass",0
   AppName BYTE "»­Í¼",0


   debugWndProcMsg BYTE "%d %u %u %d",0ah,0
.code

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    invoke crt_printf, offset debugWndProcMsg, hWnd, uMsg, wParam, lParam
    
    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg==WM_CREATE
        ;
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
    LOCAL hWnd:HWND
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    mov eax, hInst
    mov wc.hInstance, eax
    mov wc.hbrBackground, COLOR_BTNFACE + 1
    mov wc.lpszMenuName, IDR_MENU
    mov wc.lpszClassName, OFFSET ClassName
    
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    invoke RegisterClassEx, addr wc
    INVOKE CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, \
           CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, \
           hInst, NULL
    mov hWnd, eax
    
    invoke ShowWindow, hWnd, cmdShow
    invoke UpdateWindow, hWnd
    
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
    LOCAL hInstance:HINSTANCE
    LOCAL commandLine:LPTSTR
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke GetCommandLine
    mov commandLine, eax
    invoke InitCommonControls
    invoke WinMain, hInstance, NULL, commandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax
start endp
    
end start