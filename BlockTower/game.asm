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

RGB macro red,green,blue
        xor eax,eax
        mov ah,blue
        shl eax,8
        mov ah,green
        mov al,red
endm

WinMain			PROTO	:dword, :dword, :dword, :dword
Process_Space	PROTO	:HWND
Game_Over		PROTO
Game_CleanUp	PROTO	:HWND
New_Block		PROTO
Game_Paint		PROTO	:HWND
Game_Init		PROTO	:HWND

.data
	CLASS_NAME			db	"BlockTower", 0	
	Window_NAME			db	"BlockTower", 0	;��������
	
	WINDOW_WIDTH		equ	800			;���ڿ��
	WINDOW_HEIGHT		equ 700			;���ڸ߶�
	WINDOW_X			equ	400			;���ڳ�ʼλ��
	WINDOW_Y			equ	20			;���ڳ�ʼλ��
	BLOCK_HEIGHT		equ	40			;����
	COLOR_NUM			equ	16			;��ɫ����
	speed				equ	5			;�ƶ��ٶ�
	tower_offset		equ	35			;����ƫ����

	last_time			dd	0			;ˢ��ʱ��
	now_time			dd	0			;��ǰʱ��
	refresh_time		dd	5			;����ˢ�¼��
	tmp_width			dd	500			;��ǰ��Ŀ��
	direction			dd	0			;���ƿ����ķ���left or right
	block				dd	3 dup(?)	;���λ�� x, ��� width, ��ɫid rgb
	tower_x				dd	10 dup(?)	;����λ�� x
	tower_width			dd	10 dup(?)	;���Ŀ�� width
	tower_rgb			dd	10 dup(?)	;������ɫid rgb
	score				dd	0			;�÷�
	tmp_color			dd	0			;��ǰ�����ɫid
	TowerBrush		HBRUSH  10 dup(?)	;����ɫ��ˢ
	BlockBrush		HBRUSH	?			;����ɫ��ˢ
	BackgroundBrush	HBRUSH	?			;������ɫ��ˢ
	g_hdc				HDC 0			;�ڴ��
	g_mdc				HDC 0
	g_bufdc				HDC 0
	hFont				HFONT ?			;�÷�����
	msgFont				db	"Consolas", 0	;������ʽ
	r					db	96,130,159,191,217,240,255,255,255,255,255,255,255,255,255,255 ;��ɫ
	g					db	0,0,0,0,0,0,0,53,96,121,149,170,193,217,236,247					
	b					db	48,65,80,96,108,120,128,154,175,188,202,213,224,236,245,248
	sdFmt				db	"%s%d", 0	;�÷������ʽ 
	score_str			db	"Score: ", 0 ;�÷��ַ���
	show_score			db	15 dup(?)	;�÷���ʾ�ַ���

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
		 ;������Ϸ��ʼ������
		 invoke	Game_Init, h_wnd

		 ;Step5
		 ;��Ϣѭ������
		 .WHILE msg.message != WM_QUIT 
				invoke PeekMessage, ADDR msg, 0, 0, 0, PM_REMOVE	;�õ���Ϣ
				.if eax	;��Ӧ��Ϣ
					invoke	TranslateMessage, ADDR msg 
					invoke	DispatchMessage, ADDR msg
				.else
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
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0
			.endif

			;block[0] -= speed  �����ƶ�
			mov	eax, block[0]
			sub	eax, speed
			mov	block[0], eax
		.else ;���
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			;���ҳ�����������Ϸ block[0] >= tower_x[9] + tower_width[9]
			.if	block[0] >= eax 
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0				
			.endif

			;block[0] += speed �����ƶ�
			mov	eax, block[0]
			add	eax, speed
			mov	block[0], eax
		.endif
	.elseif uMsg==WM_KEYDOWN ;������Ӧ
		.if	wParam==VK_ESCAPE ;esc �ر���Ϸ
			invoke	DestroyWindow, h_wnd
		.elseif	wParam==VK_SPACE ;�ո� 
			;��ǰ�����˳�
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			mov	ebx, block[0]
			add	ebx, block[4]
			.if	(direction && block[0] >= eax) || (!direction && ebx <= tower_x[36]) 
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0					
			.endif

			;û����ǰ��������ո���
			invoke	Process_Space, h_wnd
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
    inc score

	;step 6
	;�������֣����¼�����λ��x�Ϳ��width
    mov esi, block[0*4]
    mov edi, tower_x[9*4]
    .if esi < edi ;��߳��� block[0] < tower_x[9]
        mov eax, block[0*4]
        add eax, block[1*4]
        sub eax, tower_x[9*4]
        mov block[1*4], eax
        mov eax, tower_x[9*4]
        mov block[0*4], eax
    .else ;�ұ߳���
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

	;step 9
	;��ȡ�¿飬������
    invoke New_Block
    invoke Game_Paint, h_wnd
	ret
Process_Space endp

;��Ϸ����
Game_Over proc
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

;�������
Game_Paint proc h_wnd:HWND
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
	invoke TextOut, g_mdc, 600, 100, offset show_score, SIZEOF show_score

	;step23 ��������ѭ��10��
	mov esi, 0
	.while esi < 10
		invoke SelectObject, g_mdc, TowerBrush[esi*4]

		;WINDOW_HEIGHT - (i + 1) * BLOCK_HEIGHT - tower_offet
		mov	eax, esi
		inc	eax
		mov	ebx, BLOCK_HEIGHT
		mul	ebx
		mov	ebx, WINDOW_HEIGHT
		sub ebx, eax
		mov eax, tower_offset
		sub	ebx, eax

		;tower_x[i] + tower_width[i]
		mov ecx, tower_x[esi*4]
		add ecx, tower_width[esi*4]

		;WINDOW_HEIGHT - i * BLOCK_HEIGHT - tower_offet
		mov	eax, ebx
		mov	edi, BLOCK_HEIGHT
		add	eax, edi
		;                             ��          ��   ��   ��
		invoke Rectangle, g_mdc, tower_x[esi*4], ebx, ecx, eax
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
	LOCAL bmp:HBITMAP, bmp1:HBITMAP

	;step10
	;��ʼ������
	mov eax, 0
	mov last_time, eax
	mov now_time, eax
	mov tmp_color, eax
	mov score, eax

	;step11
	;�õ��ڴ��
	invoke GetDC, h_wnd
	mov g_hdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_mdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_bufdc, eax

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

	;step13 
	;���ü�ʱ��
	invoke SetTimer, h_wnd, 1, 1, NULL

	;step14 
	;��������
	invoke CreateFont, 40, 0, 0, 0, 700, 0, 0, 0, GB2312_CHARSET, 0, 0, 0, 0, offset msgFont
	mov hFont, eax
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step15
	;��ʾ����
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 600, 100, offset show_score, SIZEOF show_score

	;step16
	;λͼ��ʼ��
	invoke CreateCompatibleBitmap, g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov bmp, eax
	mov bmp1, eax
	invoke SelectObject, g_mdc, bmp
	invoke SelectObject, g_bufdc, bmp1

	;step17 
	;������ɫˢ
	RGB 135, 206, 250
	invoke CreateSolidBrush, eax
	mov BackgroundBrush, eax
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
end
