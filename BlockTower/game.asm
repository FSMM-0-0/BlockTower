.386
.model flat, stdcall
option casemap :none

include		user32.inc
include		windows.inc
include		kernel32.inc
include		gdi32.inc
includelib	kernel32.lib
includelib	user32.lib
includelib	msvcrt.lib
includelib	gdi32.lib

sprintf	PROTO C :ptr sbyte, :vararg
strlen	PROTO C :ptr sbyte

;RGB�궨��
RGB macro red,green,blue
        xor eax,eax
        mov ah,blue
        shl eax,8
        mov ah,green
        mov al,red
endm

;��������
WinMain			PROTO	:dword, :dword, :dword, :dword
Process_Space	PROTO	:HWND
Game_Over		PROTO	:HWND
Game_CleanUp	PROTO	:HWND
New_Block		PROTO
Game_Paint		PROTO	:HWND
Game_Init		PROTO	:HWND
Start_Paint		PROTO	:HWND

.data
	CLASS_NAME			db	"BlockTower", 0	
	Window_NAME			db	"BlockTower", 0	;��������
	BUTTON_CLASS_NAME	db	"BUTTON", 0
	Easy_NAME			db	"Easy", 0
	Middle_NAME			db	"Middle", 0
	Diff_NAME			db	"Difficult", 0
	title_name			db	"BlockTower"

	easy_button_hwnd		HWND 0		;��ť���
	middle_button_hwnd		HWND 0
	difficult_button_hwnd	HWND 0
	
	WINDOW_WIDTH		equ	800			;���ڿ��
	WINDOW_HEIGHT		equ 700			;���ڸ߶�
	BUTTON_WIDTH		equ 130         ;��ť���
	BUTTON_HEIGHT		equ 60          ;��ť���
	WINDOW_X			equ	400			;���ڳ�ʼλ��
	A_WINDOW_X			equ 330         ;����ģʽ����λ��
	WINDOW_Y			equ	20			;���ڳ�ʼλ��
	E_WINDOW_Y			equ 300         ;easyģʽ����λ��
	M_WINDOW_Y			equ 400         ;middleģʽ����λ��
	D_WINDOW_Y			equ 500         ;difficultģʽ����λ��
	BLOCK_HEIGHT		equ	40			;����
	tower_offset		equ	35			;����ƫ����

	EasyID				equ	3001		;button ID
	Easy_ID			  HMENU 3001
	MiddleID			equ	3002
	Middle_ID		  HMENU 3002
	DifficultID			equ	3003
	Difficult_ID	  HMENU 3003
	TIMERID				equ 1

	history_x			dd	1024 dup(?)	;�ع�x
	history_width		dd	1024 dup(?)	;�ع�width
	history_rgb			dd	1024 dup(?)	;�ع�rgb
	total				dd	0			;������

	start_game			dd	0			;�ж���Ϸ�Ѿ���ʼ

	dispeed				equ	20			;��ʧ����
	COLOR_NUM			equ	45			;��ɫ����

	speed				dd	5			;�ƶ��ٶ�
	last_time			dd	0			;ˢ��ʱ��
	now_time			dd	0			;��ǰʱ��
	refresh_time		dd	5			;����ˢ�¼��
	score				dd	0			;�÷�

	tmp_width			dd	500			;��ǰ��Ŀ��
	direction			dd	0			;���ƿ����ķ���left or right
	block				dd	3 dup(?)	;���λ�� x, ��� width, ��ɫid rgb
	disappear			dd	5 dup(?)	;������ʧ�� x, width, y, height, rgb
	x0					dd	0			;��ʧ������x
	y0					dd	0			;��ʧ������y
	disflag				dd	0			;�Ƿ�����ʧ��
	tower_x				dd	10 dup(?)	;����λ�� x
	tower_width			dd	10 dup(?)	;���Ŀ�� width
	tower_rgb			dd	10 dup(?)	;������ɫid rgb

	tmp_color			dd	0			;��ǰ�����ɫid
	TowerBrush		HBRUSH  10 dup(?)	;����ɫ��ˢ
	BlockBrush		HBRUSH	?			;����ɫ��ˢ
	BackgroundBrush	HBRUSH	?			;������ɫ��ˢ
	DisBrush		HBRUSH	?			;��ʧ����ɫ��ˢ
	HistoryBrush	HBRUSH	?			;������ʷ��ˢ

	g_hdc				HDC 0			;�ڴ��
	g_mdc				HDC 0
	g_bufdc				HDC 0
	bmp				HBITMAP ?
	bmp1			HBITMAP ?
	hFont				HFONT ?			;�÷�����
	titleFont			HFONT ?			;��������
	buttonFont			HFONT ?			;��ť����

	msgFont				db	"Consolas", 0	;������ʽ
	msgFont2			db	"Yu Gothic UI", 0	;������ʽ
	msgFont3			db	"Cooper Black", 0	;������ʽ
	boxmsg				db	"You Get Score ", 0 ;��Ϣ��
	boxmsgout			db	50 dup(?)
	boxmsg2				db	"Do you want to try again?", 0
	boxFmt				db	"%s%d.%s", 0
	gameover			db	"Game Over", 0

	sdFmt				db	"%s%d", 0	;�÷������ʽ 
	score_str			db	"Score: ", 0 ;�÷��ַ���
	show_score			db	15 dup(?)	;�÷���ʾ�ַ���

	r					db	191,204,217,240,255,  255,255,255,255,255 ;��ɫ
						db	238,220,211,202,190,  177,168,159,153,146
						db	140,134,130,127,120,  106,125,147,170,168
						db	166,128,77,0,0,       0,0,0,0,24 
						db	48,95,143,172,182

	g					db	0,0,0,0,0,            53,96,121,149,170
						db	176,181,164,142,119,  91,72,53,40,26
						db	13,0,13,26,53,        106,125,147,170,213
						db	255,255,255,255,227,  202,174,147,121,105
						db	90,60,30,15,8

	b					db	96,102,108,120,128,   154,175,188,202,213
						db	234,255,255,255,255,  255,255,255,255,255
						db	255,255,255,255,255,  255,255,255,255,255
						db	255,255,255,255,227,  202,174,147,121,118
						db	115,108,102,99,98

	old_hInstance	HINSTANCE	?
	CommandLine		LPSTR		?

.code
main	proc	C 
	invoke	GetModuleHandle, NULL
	mov		old_hInstance, eax
	invoke	GetCommandLine
	mov		CommandLine, eax
	invoke	WinMain, old_hInstance, NULL, CommandLine, SW_SHOWDEFAULT ;���ô���������
	invoke	ExitProcess, eax
	ret
main	endp

WinMain		proc	hInstance:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		;Step1
		;�������ʼ��
		LOCAL	wc:WNDCLASSEX                                  
		LOCAL	msg:MSG 
		LOCAL	h_wnd:HWND

		 mov	wc.cbSize,SIZEOF WNDCLASSEX
		 mov	wc.style, CS_HREDRAW or CS_VREDRAW 
		 mov	wc.lpfnWndProc, OFFSET WindowProc 
		 mov	wc.cbClsExtra,NULL 
		 mov	wc.cbWndExtra,NULL 
		 push	hInstance
		 pop	wc.hInstance
		 mov	wc.hbrBackground,COLOR_WINDOW+1 
		 mov	wc.lpszMenuName,NULL 
		 mov	wc.lpszClassName,OFFSET CLASS_NAME 
		 invoke LoadIcon,NULL,IDI_APPLICATION 
		 mov	wc.hIcon,eax 
		 mov	wc.hIconSm,eax
		 invoke LoadCursor,NULL,IDC_ARROW 
		 mov	wc.hCursor,eax 

		 invoke RegisterClassEx, addr wc

		 ;Step2
		 ;����������
		 invoke CreateWindowEx,NULL,\ 
                ADDR CLASS_NAME,\ 
                ADDR Window_NAME,\ 
                WS_OVERLAPPEDWINDOW,\  ;;;;;;;;;;;;;;;;;;;;
                WINDOW_X,\ ;x
                WINDOW_Y,\ ;y
                WINDOW_WIDTH,\ ;��
                WINDOW_HEIGHT,\ ;��
                NULL,\ 
                NULL,\ 
                hInstance,\ 
                NULL 
		 mov  	h_wnd,eax 

		 ;Step3
		 invoke ShowWindow, h_wnd, CmdShow ; ��������ʾ
		 invoke UpdateWindow, h_wnd        ; ���������

		 ;Step4
		 ;����������
		 invoke	Start_Paint, h_wnd

		 ;Step5
		 ;��Ϣѭ������
		 .WHILE msg.message != WM_QUIT 
				invoke PeekMessage, ADDR msg, 0, 0, 0, PM_REMOVE	;�õ���Ϣ
				.if eax	;��Ӧ��Ϣ
					invoke	TranslateMessage, ADDR msg 
					invoke	DispatchMessage, ADDR msg
				.elseif	start_game != 0
					invoke	GetTickCount ;��õ�ǰʱ��
					mov	now_time, eax
					sub	eax, last_time
					.if eax >= refresh_time ;ˢ�»���
						invoke	Game_Paint, h_wnd	;ˢ��
					.endif
				.endif
		 .ENDW

		 mov     eax,msg.wParam
		 invoke	UnregisterClass, CLASS_NAME, wc.hInstance	;�˳�ע��������
		 ret
WinMain	endp

WindowProc proc h_wnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	hdc:HDC

	.if uMsg==WM_TIMER	;��ʱ����Ϣ, �������������ƶ�
		.if direction	;�ұ�
			mov	eax, block[0]
			add	eax, block[4]
			;���󳬹���������Ϸ block[0] + block[1] <= tower_x[9]
			.if	eax <= tower_x[36] 
				invoke	Game_Over, h_wnd
			.else
				;block[0] -= speed  �����ƶ�
				mov	eax, block[0]
				sub	eax, speed
				mov	block[0], eax
			.endif
		.else ;���
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			;���ҳ�����������Ϸ block[0] >= tower_x[9] + tower_width[9]
			.if	block[0] >= eax 
				invoke	Game_Over, h_wnd
			.else
				;block[0] += speed �����ƶ�
				mov	eax, block[0]
				add	eax, speed
				mov	block[0], eax
			.endif
		.endif
	.elseif uMsg==WM_KEYDOWN ;������Ӧ
		.if	wParam==VK_ESCAPE ;esc �ر���Ϸ
			invoke	DestroyWindow, h_wnd
		.elseif	wParam==VK_SPACE ;�ո� 
			.if start_game != 0
				;��ǰ�����˳�
				mov	eax, tower_x[36]
				add	eax, tower_width[36]
				mov	ebx, block[0]
				add	ebx, block[4]
				.if	(direction && block[0] >= eax) || (!direction && ebx <= tower_x[36]) 
					invoke	Game_Over, h_wnd
				.else
					;û����ǰ��������ո���
					invoke	Process_Space, h_wnd
				.endif
				
			.endif

		.endif
	.elseif uMsg==WM_COMMAND	;button��Ӧ
		.if	wParam==EasyID
			invoke	DestroyWindow, easy_button_hwnd	;ɾ����ť
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd	
			mov speed, 3	;�����ٶ�
			invoke	Game_Init, h_wnd	;��Ϸ��ʼ��
			mov	start_game, 1	;������Ϸ����
		.elseif	wParam==MiddleID
			invoke	DestroyWindow, easy_button_hwnd	;ɾ����ť
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd
			mov speed, 6	
			invoke	Game_Init, h_wnd	
			mov	start_game, 1	
		.elseif	wParam==DifficultID
			invoke	DestroyWindow, easy_button_hwnd	;ɾ����ť
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd
			mov speed, 10
			invoke	Game_Init, h_wnd	
			mov	start_game, 1			
		.endif
	.elseif uMsg==WM_DESTROY ;�ر���Ϣ
		invoke	Game_CleanUp, h_wnd
		invoke	PostQuitMessage, 0	
	.elseif uMsg==WM_PAINT	;������Ϣ
		invoke	BeginPaint, h_wnd, ADDR ps
		mov	hdc, eax

		invoke	EndPaint, h_wnd, ADDR ps
	.endif

	invoke	DefWindowProc, h_wnd, uMsg, wParam, lParam
	ret 
WindowProc endp

;��Ӧ�ո�����������ۼ�
Process_Space proc h_wnd:HWND
    
	;��1��
	inc score

	;new 0
	;����ʧ��
	mov disflag, 1
	;��ʧ��� y, height, rgb
	mov eax, BLOCK_HEIGHT
	mov ebx, 10
	mul ebx
	mov ebx, WINDOW_HEIGHT  
	sub ebx, eax
	sub ebx, tower_offset 
	mov disappear[2*4], ebx
	mov eax, BLOCK_HEIGHT
	mov disappear[3*4], eax
	mov eax, block[2*4]
	mov disappear[4*4], eax
	;��ʧ������� y0
	mov eax, disappear[3*4]
	mov ebx, 2
	div ebx
	add eax, disappear[2*4]
	mov y0, eax

	;step 6
	;�������֣����¼�����λ��x�Ϳ��width
    mov esi, block[0*4]
    mov edi, tower_x[9*4]
    .if esi < edi ;��߳��� block[0] < tower_x[9]
		;new1
		;��ʧ��x, width
		mov eax, block[0*4]
		mov disappear[0*4], eax
		mov eax, tower_x[9*4]
		mov ebx, block[0*4]
		sub eax, ebx
		mov disappear[1*4], eax
		;��ʧ������ x0
		mov eax, disappear[1*4]
		mov ebx, 2
		div ebx
		add eax, disappear[0*4]
		mov x0, eax
		;new1

        mov eax, block[0*4]
        add eax, block[1*4]
        sub eax, tower_x[9*4]
        mov block[1*4], eax
        mov eax, tower_x[9*4]
        mov block[0*4], eax
    .else ;�ұ߳���
		;new 2
		;��ʧ�� x, width
		mov eax, tower_width[9*4]
		add eax, tower_x[9*4]
		mov disappear[0*4],eax
		mov eax, block[0*4]
		add eax, block[1*4]
		sub eax, tower_x[9*4]
		sub eax, tower_width[9*4]
		mov disappear[1*4],eax
		;��ʧ������ x0		
		mov eax, disappear[1*4]
		mov ebx, 2
		div ebx
		add eax, disappear[0*4]
		mov x0, eax
		;new 2

        mov eax, tower_x[9*4]
        add eax, tower_width[9*4]
        sub eax, block[0*4]
        mov block[1*4], eax
    .endif

	;step 7
	;�������ײ�飬���θ�ֵ��tower[i - 1] = tower[i]
    mov esi, 1
    .while esi < 10
        mov eax, tower_x[esi*4]
		mov tower_x[esi*4-4],eax

		mov eax, tower_width[esi*4]
		mov tower_width[esi*4-4],eax

        mov eax, tower_rgb[esi*4]
		mov tower_rgb[esi*4-4],eax

		mov eax, TowerBrush[esi*4]
		mov TowerBrush[esi*4-4],eax
        inc esi
    .endw
	

	;step 8
	;���鸳ֵ�������� tower[9] = block[0]
	mov eax, block[0*4]
	mov tower_x[9*4], eax

	mov eax, block[1*4]
	mov tower_width[9*4], eax	

	mov eax, block[2*4]
	mov tower_rgb[9*4], eax

    mov eax, BlockBrush
    mov TowerBrush[9*4], eax

	;over 1
	mov eax, total
	mov ebx, block[0]
	mov history_x[eax * 4], ebx
	mov ebx, block[1*4]
	mov history_width[eax * 4],ebx
	mov ebx, block[2*4]
	mov history_rgb[eax * 4], ebx
	inc total
	;

	;step 9
	;��ȡ�¿飬������
    invoke New_Block
    invoke Game_Paint, h_wnd
	ret
Process_Space endp

;��Ϸ����
Game_Over proc	h_wnd:HWND
	LOCAL	use_height:dword
	LOCAL	mini_height:dword
	LOCAL	mini_ratio:dword
	LOCAL	rect:RECT 

	;Step 37
	;����ˢ��ֹͣ
	mov start_game, 0
	invoke KillTimer, h_wnd, TIMERID

	;���»���
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;Step 38
	;�ܸ߶�
	mov use_height, WINDOW_HEIGHT - 50 - 100
	;ÿ��߶� use_height / total
	xor edx, edx
	mov eax, use_height
	div total
	mov mini_height, eax
	;�����С����
	mov mini_ratio, 2

	;Step 39
	xor esi, esi
	.while esi < total
		xor edx, edx
		mov eax, history_x[esi * 4]
		div mini_ratio
		mov history_x[esi * 4], eax

		xor edx, edx
		mov eax, history_width[esi * 4]
		div mini_ratio
		mov history_width[esi * 4], eax

		inc esi
	.endw

	;Step 40
	;����
	xor esi, esi
	.while esi < total
		mov ebx, history_rgb[esi*4]
		RGB	r[ebx], g[ebx], b[ebx]
		invoke CreateSolidBrush, eax
		mov HistoryBrush, eax
		
		;rect.left = history_x[i] + 200;
		mov eax, history_x[esi * 4]
		add eax, 200
		mov rect.left, eax

		;WINDOW_HEIGHT - (i + 1) * mini_height - 50
		mov	eax, esi
		inc	eax
		mov	ebx, mini_height
		mul	ebx
		mov	ebx, WINDOW_HEIGHT
		sub ebx, eax
		mov eax, 50
		sub	ebx, eax
		mov rect.top, ebx

		;history_x[i] + history_width[i] + 200
		mov ecx, history_x[esi*4]
		add ecx, history_width[esi*4]
		add ecx, 200
		mov rect.right, ecx

		;WINDOW_HEIGHT - i * mini_height - 50
		mov	eax, ebx
		mov	edi, mini_height
		add	eax, edi
		mov rect.bottom, eax
		invoke FillRect, g_mdc, addr rect, HistoryBrush

		inc esi
	.endw

	;��ʾ
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	;Step 41
	;��Ϣ��
	invoke sprintf, offset boxmsgout, offset boxFmt, offset boxmsg, score, offset boxmsg2
	invoke MessageBox, h_wnd, offset boxmsgout, offset gameover, MB_OKCANCEL
	.if eax == IDOK
		invoke Start_Paint, h_wnd
	.elseif eax == IDCANCEL
		invoke Game_CleanUp, h_wnd
		invoke PostQuitMessage, 0
	.endif

	ret 
Game_Over endp

;�ͷ���Դ
Game_CleanUp proc h_wnd:HWND
    invoke DeleteObject, BlockBrush 
    invoke DeleteObject, BackgroundBrush
    mov esi, 0
    .while esi < 10
        invoke DeleteObject, TowerBrush[esi*4]
        inc esi
    .endw
    invoke 	DeleteDC, g_bufdc
	invoke DeleteDC, g_mdc
	invoke ReleaseDC, h_wnd, g_hdc
	ret
Game_CleanUp endp

;�õ��¿�
New_Block proc
	;step 27
	;�¿�
    mov eax, tower_width[36]
    mov block[4], eax
    mov eax, tmp_color
    mov block[8], eax

	;step 28
	;��һ�鷽��ת�� direction = !direction;
    mov eax, direction
    not eax
    mov direction, eax
    .if direction == 0
        mov eax, 0
        mov block[0], eax
    .else
        mov eax, WINDOW_WIDTH 
        mov block[0], eax
    .endif

	;step 29
	;%ѭ��ȡ��һ����ɫ tmp_color = (tmp_color + 1) % COLOR_NUM;
	xor edx, edx
	mov	eax, tmp_color
	inc eax
	mov	ebx, COLOR_NUM
	div	ebx
	mov	tmp_color, edx

	;BlockBursh = CreateSolidBrush(RGB(r[block[2]], g[block[2]], b[block[2]]));
	mov	ebx, block[8]
	RGB	r[ebx], g[ebx], b[ebx] 
    invoke CreateSolidBrush, eax
    mov BlockBrush, eax
	ret 
New_Block endp

;���������
Game_Paint proc h_wnd:HWND
	LOCAL	rect:RECT ;��ʧ��Ļ���

	;step20 ������ɫ
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;step21 �÷�����
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step22 ��ʾ����
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 300, 80, offset show_score, SIZEOF show_score

	;step23 ��������ѭ��10��
	mov esi, 0
	.while esi < 10
		invoke SelectObject, g_mdc, TowerBrush[esi*4]
		;tower_x[i]
		mov eax, tower_x[esi * 4]
		mov rect.left, eax

		;WINDOW_HEIGHT - (i + 1) * BLOCK_HEIGHT - tower_offset
		mov	eax, esi
		inc	eax
		mov	ebx, BLOCK_HEIGHT
		mul	ebx
		mov	ebx, WINDOW_HEIGHT
		sub ebx, eax
		mov eax, tower_offset
		sub	ebx, eax
		mov rect.top, ebx

		;tower_x[i] + tower_width[i]
		mov ecx, tower_x[esi*4]
		add ecx, tower_width[esi*4]
		mov rect.right, ecx

		;WINDOW_HEIGHT - i * BLOCK_HEIGHT - tower_offset
		mov	eax, ebx
		mov	edi, BLOCK_HEIGHT
		add	eax, edi
		mov rect.bottom, eax

		invoke FillRect, g_mdc, addr rect, TowerBrush[esi * 4]
		;                             ��          ��   ��   ��
		;invoke Rectangle, g_mdc, tower_x[esi*4], ebx, ecx, eax
		inc esi
	.endw


	;step24 ��Ļ���
	invoke SelectObject, g_mdc, BlockBrush 

	mov	eax, WINDOW_HEIGHT
	mov	ebx, 11 * BLOCK_HEIGHT
	sub eax, ebx
	sub	eax, tower_offset
	mov	edx, eax
	;����Ŀ���ϵ�����        x  y:WINDOW_HEIGHT - 11 * BLOCK_HEIGHT - tower_offet     
	invoke BitBlt, g_mdc, block[0], edx, block[4], BLOCK_HEIGHT, g_bufdc, 0, 0, PATCOPY
	;										��         ��            Դ

	;new 3
	;��ʧ��Ļ���
	.if disflag == 1 ;����ʧ��
		
		;��ʧ������
		mov edx, disappear[4*4]
		RGB r[edx], g[edx], b[edx]
		invoke CreateSolidBrush, eax
		mov DisBrush, eax
		mov eax, disappear[0*4]
		mov rect.left, eax
		mov eax, disappear[2*4]
		mov rect.top, eax
		mov eax, disappear[0*4]
		add eax, disappear[1*4]
		mov rect.right, eax
		mov eax, disappear[2*4]
		add eax, disappear[3*4]
		mov rect.bottom, eax
		;������ʧ��
		invoke FillRect, g_mdc, addr rect, DisBrush
		
		;��ʧ����С
		mov eax, disappear[1*4]
		mov ebx, dispeed
		div ebx
		mov edx, eax
		mov eax, disappear[3*4]
		mov ebx, dispeed
		div ebx
		.if eax == 0 || edx == 0 ;����������
			;���Ϊ��ɫ
			invoke FillRect, g_mdc, addr rect, BackgroundBrush
			;��־Ϊ0
			mov disflag, 0
		.else
			;disappear[1] = disappear[1] - disappear[1] / dispeed;
			xor edx, edx
			mov eax, disappear[1*4]
			mov ebx, dispeed
			div ebx
			mov ebx, eax
			mov eax, disappear[1*4]
			sub eax, ebx
			mov disappear[1*4], eax
			;disappear[3] = disappear[3] - disappear[3] / dispeed;
			xor edx, edx
			mov eax, disappear[3*4]
			mov ebx, dispeed
			div ebx
			mov ebx, eax
			mov eax, disappear[3*4]
			sub eax, ebx
			mov disappear[3*4], eax
			;disappear[0] = x0 - disappear[1] / 2;
			xor edx, edx
			mov eax, disappear[1*4]
			mov ebx, 2
			div ebx
			mov ebx, eax
			mov eax, x0
			sub eax, ebx
			mov disappear[0*4], eax
			;disappear[2] = y0 - disappear[3] / 2;
			xor edx, edx
			mov eax, disappear[3*4]
			mov ebx, 2
			div ebx
			mov ebx, eax
			mov eax, y0
			sub eax, ebx
			mov disappear[2*4], eax

		.endif

	.endif
	;new 3

	;step25
	;�����Ļ�����ʾ�ڴ�����
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	;step26
	;��ȡʱ�䣨�ϴΣ�
	invoke GetTickCount
	mov last_time, eax
	ret
Game_Paint endp

;��Ϸ�����ʼ��
Game_Init proc h_wnd:HWND

	;step10
	;��ʼ������
	mov eax, 0
	mov last_time, eax
	mov now_time, eax
	mov tmp_color, eax
	mov score, eax

	;step12 
	;����ʼ�� 10�� λ�� �߶� ��ɫ
	mov esi, 0
	.while esi < 10
		;tower_x[i] = (WINDOW_WIDTH - tmp_width) / 2
		mov eax, WINDOW_WIDTH
		sub eax, tmp_width
		shr	eax, 1 ;/2
		mov tower_x[esi*4], eax

		;tower_width[i] = tmp_width
		mov ecx, tmp_width
		mov tower_width[esi*4], ecx

		;tower_rgb[i] = tmp_color
		mov edi, tmp_color
		mov tower_rgb[esi*4], edi

		;tmp_color = (tmp_color + 1) % COLOR_NUM
		mov eax, tmp_color
		inc eax
		xor	edx, edx
		mov ebx, COLOR_NUM
		div ebx
		mov tmp_color, edx
		inc esi
	.endw

	;over 0
	;��¼��ʼ��
	mov esi, 0
	.while esi < 10
		;history_x[i] = tower_x[i];
		mov eax, tower_x[esi * 4]
		mov history_x[esi * 4], eax

		;history_width[i] = tower_width[i];
		mov eax, tower_width[esi * 4]
		mov history_width[esi * 4], eax

		;history_rgb[i] = tower_rgb[i];
		mov eax, tower_rgb[esi * 4]
		mov history_rgb[esi * 4], eax

		inc esi
	.endw
	mov total, 10

	;step13 
	;���ü�ʱ��
	invoke SetTimer, h_wnd, TIMERID, 1, NULL

	;step14 
	;��������
	invoke CreateFont, 40, 0, 0, 0, 700, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont
	mov hFont, eax
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step15
	;��ʾ����
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 300, 80, offset show_score, SIZEOF show_score

	;step17 
	;����
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;step18 
	;����ɫˢ
	mov esi, 0
	.while esi < 10
		mov ebx, tower_rgb[esi*4]
		RGB	r[ebx], g[ebx], b[ebx]
		invoke CreateSolidBrush, eax
		mov TowerBrush[esi*4], eax
		inc esi
	.endw

	;step19 
	;�õ��¿�
	invoke New_Block

	;����
	invoke Game_Paint, h_wnd
	ret
Game_Init endp 

;��ʼ�������
Start_Paint	proc h_wnd:HWND

	;step11
	;�õ��ڴ��
	invoke GetDC, h_wnd
	mov g_hdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_mdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_bufdc, eax

	;step16
	;λͼ��ʼ��
	invoke CreateCompatibleBitmap, g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov bmp, eax
	mov bmp1, eax
	invoke SelectObject, g_mdc, bmp
	invoke SelectObject, g_bufdc, bmp1

	;Step30
	;������ɫˢ
	RGB 255, 236, 245
	invoke CreateSolidBrush, eax
	mov BackgroundBrush, eax
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;Step31
	;��ť����
	invoke CreateFont, 40, 0, 0, 0, FW_NORMAL, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont2
	mov buttonFont, eax

	;Step32
	;������ť
	mov ebx, WS_CHILD 
	or ebx, WS_VISIBLE
	or ebx, BS_DEFPUSHBUTTON
	invoke CreateWindowEx, NULL,\
                ADDR BUTTON_CLASS_NAME,\ 
                ADDR Easy_NAME,\ 
                ebx,\  ;;;;;;;;;;;;;;;;;;;;
                A_WINDOW_X,\ ;x
                E_WINDOW_Y,\ ;y
                BUTTON_WIDTH,\ ;��
                BUTTON_HEIGHT,\ ;��
                h_wnd,\ 
                Easy_ID,\ 
                h_wnd,\ 
                NULL 
	mov easy_button_hwnd, eax 
	invoke ShowWindow, easy_button_hwnd, SW_SHOW
	invoke SendMessage, easy_button_hwnd, WM_SETFONT, buttonFont, 1

	;Step33
	mov ebx, WS_CHILD 
	or ebx, WS_VISIBLE
	or ebx, BS_DEFPUSHBUTTON
	invoke CreateWindowEx,NULL,\ 
                ADDR BUTTON_CLASS_NAME,\ 
                ADDR Middle_NAME,\ 
                ebx,\  ;;;;;;;;;;;;;;;;;;;;
                A_WINDOW_X,\ ;x
                M_WINDOW_Y,\ ;y
                BUTTON_WIDTH,\ ;��
                BUTTON_HEIGHT,\ ;��
                h_wnd,\ 
                Middle_ID,\ 
                h_wnd,\ 
                NULL 
	mov middle_button_hwnd, eax 
	invoke ShowWindow, middle_button_hwnd, SW_SHOW
	invoke SendMessage, middle_button_hwnd, WM_SETFONT, buttonFont, 1

	;Step34
	mov ebx, WS_CHILD 
	or ebx, WS_VISIBLE
	or ebx, BS_DEFPUSHBUTTON
	invoke CreateWindowEx,NULL,\ 
                ADDR BUTTON_CLASS_NAME,\ 
                ADDR Diff_NAME,\ 
                ebx,\  ;;;;;;;;;;;;;;;;;;;;
                A_WINDOW_X,\ ;x
                D_WINDOW_Y,\ ;y
                BUTTON_WIDTH,\ ;��
                BUTTON_HEIGHT,\ ;��
                h_wnd,\ 
                Difficult_ID,\ 
                h_wnd,\ 
                NULL 
	mov difficult_button_hwnd, eax 
	invoke ShowWindow, difficult_button_hwnd, SW_SHOW
	invoke SendMessage, difficult_button_hwnd, WM_SETFONT, buttonFont, 1

	;Step35
	;����
	invoke CreateFont, 100, 0, 0, 0, FW_EXTRABOLD, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont3
	mov titleFont, eax
	invoke SelectObject, g_mdc, titleFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax
	invoke TextOut, g_mdc, 130, 100, offset title_name, SIZEOF title_name

	;Step36
	;�����Ļ�����ʾ�ڴ�����
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	ret
Start_Paint	endp
end
