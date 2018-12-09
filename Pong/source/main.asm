TITLE Windows Application                   (WinApp.asm)

; This program displays a resizable application window and
; several popup message boxes.
; Thanks to Tom Joyce for creating a prototype
; from which this program was derived.
; Last update: 9/24/01

INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

DTFLAGS = 25h  ; Needed for drawtext

;==================== DATA =======================
.data

AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
PopupText  BYTE "This window was activated by a "
	       BYTE "WM_LBUTTONDOWN message",0

PopupTitle2 BYTE "Popup Window",0
PopupText2  BYTE "This window was activated by a "
	       BYTE "VK_DOWN message",0


GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

CloseMsg   BYTE "WM_CLOSE message received",0

HelloStr   BYTE "Hello World",0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

msg	     MSGStruct <>
winRect   RECT <>

;Structs
rc RECT <20,350,30,550>
rc2 RECT <1890,350,1900,550>
ball RECT <950, 450, 975, 475>
ps PAINTSTRUCT <?>

;Handles
hdc DWORD ?
hMainWnd  DWORD ?
hInstance DWORD ?
hbrush DWORD ?
colorref DWORD ?

;Regions
leftPaddle DWORD ?
rightPaddle DWORD ?
ballRegn DWORD ?

;Directions
ballxdir SDWORD 10    ; direction of box in x
ballydir SDWORD 10    ; direction of box in y
LPaddledir SDWORD 20		 ; direction of left paddle
RPaddledir SDWORD 20		 ; direction of right paddle

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>
;=================== CODE =========================
.code
main PROC
; Get a handle to the current process.
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Display a greeting message.
	INVOKE MessageBox, hMainWnd, ADDR GreetText,
	  ADDR GreetTitle, MB_OK

; Setup a timer
	INVOKE SetTimer, hMainWnd, 0, 30, 0

; Show and draw the window.
	INVOKE ShowWindow, hMainWnd, SW_SHOW
	INVOKE UpdateWindow, hMainWnd

; Begin the program's message-handling loop.
Message_Loop:
	; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
	  INVOKE ExitProcess,0
main ENDP

DrawLeftPaddle PROC
		INVOKE CreateRectRgn, rc.left, rc.top, rc.right, rc.bottom
		mov leftPaddle, eax
		INVOKE FillRgn, hdc, leftPaddle, hbrush
		ret
DrawLeftPaddle ENDP

DrawRightPaddle PROC
		INVOKE CreateRectRgn, rc2.left, rc2.top, rc2.right, rc2.bottom
		mov rightPaddle, eax
		INVOKE FillRgn, hdc, rightPaddle, hbrush
		ret
DrawRightPaddle ENDP

DrawBall PROC
		INVOKE CreateRectRgn, ball.left, ball.top, ball.right, ball.bottom
		mov ballRegn, eax
		INVOKE FillRgn, hdc, ballRegn, hbrush
		ret
DrawBall ENDP

MoveBall PROC
		mov ebx, ballxdir
		add ball.left, ebx
		add ball.right, ebx
		mov ebx, ballydir
		add ball.top, ebx
		add ball.bottom, ebx
		ret
MoveBall ENDP

;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------
	mov eax, localMsg
	.IF eax == WM_LBUTTONDOWN		; mouse button?
	  INVOKE MessageBox, hWnd, ADDR PopupText,
	    ADDR PopupTitle, MB_OK
	  jmp WinProcExit
	.ELSEIF wParam == VK_UP		;keyboard?
		mov ebx, RPaddledir
		sub rc2.top, ebx
		sub rc2.bottom, ebx
	.ELSEIF wParam == VK_DOWN		;keyboard?
		mov ebx, RPaddledir
		add rc2.top, ebx
		add rc2.bottom, ebx
	.ELSEIF wParam == 57h		;keyboard?
		mov ebx, RPaddledir
		sub rc.top, ebx
		sub rc.bottom, ebx
	.ELSEIF wParam == 53h		;keyboard?
		mov ebx, RPaddledir
		add rc.top, ebx
		add rc.bottom, ebx
	.ELSEIF eax == WM_CREATE		; create window?
	  INVOKE MessageBox, hWnd, ADDR AppLoadMsgText,
	    ADDR AppLoadMsgTitle, MB_OK
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
	  INVOKE MessageBox, hWnd, ADDR CloseMsg,
	    ADDR WindowName, MB_OK
	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSEIF eax == WM_TIMER     ; did a timer fire?
	  INVOKE InvalidateRect, hWnd, 0, 1
	  jmp WinProcExit
	.ELSEIF eax == WM_PAINT		; window needs redrawing? 
	  INVOKE BeginPaint, hWnd, ADDR ps 
	  mov hdc, eax

		mov colorref, 00000000h
		INVOKE CreateSolidBrush, colorref
		mov hbrush, eax
		
		call DrawLeftPaddle
		call DrawRightPaddle
		
		call DrawBall
		call MoveBall

	  ; output text
	  ;INVOKE DrawTextA, hdc, ADDR HelloStr, -1, ADDR rc, DTFLAGS 
	  INVOKE EndPaint, hWnd, ADDR ps
	  jmp WinProcExit
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF

WinProcExit:
	ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

	  ; inc x position of the box
	  ;mov ebx, xloc         
	  ;add ebx, xdir
	  ;mov xloc, ebx

	  ; inc y position of the box
	  ;mov ecx, yloc
	  ;add ecx, ydir
	  ;mov yloc, ecx
	  
	  ; draw the box
	  ;INVOKE MoveToEx, hdc, xloc, yloc, 0
	  ;mov ebx, xloc
	  ;add ebx, 50
	  ;INVOKE LineTo, hdc, ebx, yloc
	  ;mov ebx, xloc
	  ;add ebx, 50
	  ;mov ecx, yloc
	  ;add ecx, 50	  	  
	  ;INVOKE LineTo, hdc, ebx, ecx
	  ;mov ecx, yloc
	  ;add ecx, 50
	  ;INVOKE LineTo, hdc, xloc,   ecx
	  ;INVOKE LineTo, hdc, xloc,   yloc

	  ; reflect xdir
		; Bug in assembler can't use .IF here for some reason...
		;cmp xloc, 200
	  ;jl L1
		;   mov eax, 0
	  ;   sub eax, xdir
		;   mov xdir, eax
	  ;L1:

		;cmp xloc, 0
		;jg L2
		;   mov eax, 0
	  ;   sub eax, xdir
		;   mov xdir, eax
	  ;L2:

	  ; reflect ydir
		;cmp yloc, 200
		;jl L3
		;   mov eax, 0
	  ;   sub eax, ydir
		;   mov ydir, eax
	  ;L3:

		;cmp yloc, 0
		;jg L4
		;   mov eax, 0
	  ;   sub eax, ydir
		;   mov ydir, eax
	  ;L4:



END