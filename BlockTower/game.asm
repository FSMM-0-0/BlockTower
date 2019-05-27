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
	Window_NAME			db	"BlockTower", 0	;窗口名称
	
	WINDOW_WIDTH		equ	800			;窗口宽度
	WINDOW_HEIGHT		equ 700			;窗口高度
	WINDOW_X			equ	400			;窗口初始位置
	WINDOW_Y			equ	20			;窗口初始位置
	BLOCK_HEIGHT		equ	40			;块宽度
	COLOR_NUM			equ	16			;颜色数量
	speed				equ	5			;移动速度
	tower_offset		equ	35			;调整偏移量

	last_time			dd	0			;刷新时间
	now_time			dd	0			;当前时间
	refresh_time		dd	5			;画面刷新间隔
	tmp_width			dd	500			;当前块的宽度
	direction			dd	0			;控制块来的方向left or right
	block				dd	3 dup(?)	;块的位置 x, 宽度 width, 颜色id rgb
	tower_x				dd	10 dup(?)	;塔的位置 x
	tower_width			dd	10 dup(?)	;塔的宽度 width
	tower_rgb			dd	10 dup(?)	;塔的颜色id rgb
	score				dd	0			;得分
	tmp_color			dd	0			;当前块的颜色id
	TowerBrush		HBRUSH  10 dup(?)	;塔颜色画刷
	BlockBrush		HBRUSH	?			;块颜色画刷
	BackgroundBrush	HBRUSH	?			;背景颜色画刷
	g_hdc				HDC 0			;内存块
	g_mdc				HDC 0
	g_bufdc				HDC 0
	hFont				HFONT ?			;得分字体
	msgFont				db	"Consolas", 0	;字体样式
	r					db	96,130,159,191,217,240,255,255,255,255,255,255,255,255,255,255 ;颜色
	g					db	0,0,0,0,0,0,0,53,96,121,149,170,193,217,236,247					
	b					db	48,65,80,96,108,120,128,154,175,188,202,213,224,236,245,248
	sdFmt				db	"%s%d", 0	;得分输出格式 
	score_str			db	"Score: ", 0 ;得分字符串
	show_score			db	15 dup(?)	;得分显示字符串

	old_hInstance	HINSTANCE	?
	CommandLine		LPSTR		?

.code
main	proc	C 
	invoke	GetModuleHandle, NULL
	mov		old_hInstance, eax
	invoke	GetCommandLine
	mov		CommandLine, eax
	invoke	WinMain, old_hInstance, NULL, CommandLine, SW_SHOWDEFAULT ;调用窗口主函数
	invoke	ExitProcess, eax
	ret
main	endp

WinMain		proc	hInstance:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		;Step1
		;主窗体初始化
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
		 ;创建主窗体
		 invoke CreateWindowEx,NULL,\ 
                ADDR CLASS_NAME,\ 
                ADDR Window_NAME,\ 
                WS_OVERLAPPEDWINDOW,\  ;;;;;;;;;;;;;;;;;;;;
                WINDOW_X,\ ;x
                WINDOW_Y,\ ;y
                WINDOW_WIDTH,\ ;宽
                WINDOW_HEIGHT,\ ;高
                NULL,\ 
                NULL,\ 
                hInstance,\ 
                NULL 
		 mov  	h_wnd,eax 

		 ;Step3
		 invoke ShowWindow, h_wnd, CmdShow ; 主窗体显示
		 invoke UpdateWindow, h_wnd        ; 主窗体更新

		 ;Step4
		 ;调用游戏初始化函数
		 invoke	Game_Init, h_wnd

		 ;Step5
		 ;消息循环接收
		 .WHILE msg.message != WM_QUIT 
				invoke PeekMessage, ADDR msg, 0, 0, 0, PM_REMOVE	;得到消息
				.if eax	;响应消息
					invoke	TranslateMessage, ADDR msg 
					invoke	DispatchMessage, ADDR msg
				.else
					invoke	GetTickCount ;获得当前时间
					mov	now_time, eax
					sub	eax, last_time
					.if eax >= refresh_time ;刷新画面
						invoke	Game_Paint, h_wnd	;刷新
					.endif
				.endif
		 .ENDW

		 mov     eax,msg.wParam
		 invoke	UnregisterClass, CLASS_NAME, wc.hInstance	;退出注销窗口类
		 ret
WinMain	endp

WindowProc proc h_wnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	hdc:HDC

	.if uMsg==WM_TIMER	;计时器消息, 处理超出，设置移动
		.if direction	;右边
			mov	eax, block[0]
			add	eax, block[4]
			;向左超过，结束游戏 block[0] + block[1] <= tower_x[9]
			.if	eax <= tower_x[36] 
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0
			.endif

			;block[0] -= speed  向左移动
			mov	eax, block[0]
			sub	eax, speed
			mov	block[0], eax
		.else ;左边
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			;向右超过，结束游戏 block[0] >= tower_x[9] + tower_width[9]
			.if	block[0] >= eax 
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0				
			.endif

			;block[0] += speed 向右移动
			mov	eax, block[0]
			add	eax, speed
			mov	block[0], eax
		.endif
	.elseif uMsg==WM_KEYDOWN ;按键响应
		.if	wParam==VK_ESCAPE ;esc 关闭游戏
			invoke	DestroyWindow, h_wnd
		.elseif	wParam==VK_SPACE ;空格 
			;提前按，退出
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			mov	ebx, block[0]
			add	ebx, block[4]
			.if	(direction && block[0] >= eax) || (!direction && ebx <= tower_x[36]) 
				invoke	Game_Over
				invoke	Game_CleanUp, h_wnd
				invoke	PostQuitMessage, 0					
			.endif

			;没有提前按，处理空格函数
			invoke	Process_Space, h_wnd
		.endif
	.elseif uMsg==WM_DESTROY ;关闭消息
		invoke	Game_CleanUp, h_wnd
		invoke	PostQuitMessage, 0	
	.elseif uMsg==WM_PAINT	;绘制消息
		invoke	BeginPaint, h_wnd, ADDR ps
		mov	hdc, eax

		invoke	EndPaint, h_wnd, ADDR ps
	.endif

	invoke	DefWindowProc, h_wnd, uMsg, wParam, lParam
	ret 
WindowProc endp

;响应空格键，处理块的累加
Process_Space proc h_wnd:HWND
    inc score

	;step 6
	;超出部分，重新计算块的位置x和宽度width
    mov esi, block[0*4]
    mov edi, tower_x[9*4]
    .if esi < edi ;左边超出 block[0] < tower_x[9]
        mov eax, block[0*4]
        add eax, block[1*4]
        sub eax, tower_x[9*4]
        mov block[1*4], eax
        mov eax, tower_x[9*4]
        mov block[0*4], eax
    .else ;右边超出
        mov eax, tower_x[9*4]
        add eax, tower_width[9*4]
        sub eax, block[0*4]
        mov block[1*4], eax
    .endif

	;step 7
	;消掉塔底层块，依次赋值，tower[i - 1] = tower[i]
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
	;将块赋值给塔顶层 tower[9] = block[0]
	mov eax, block[0*4]
	mov tower_x[9*4], eax

	mov eax, block[1*4]
	mov tower_width[9*4], eax	

	mov eax, block[2*4]
	mov tower_rgb[9*4], eax

    mov eax, BlockBrush
    mov TowerBrush[9*4], eax

	;step 9
	;获取新块，并绘制
    invoke New_Block
    invoke Game_Paint, h_wnd
	ret
Process_Space endp

;游戏结束
Game_Over proc
	ret 
Game_Over endp

;释放资源
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

;得到新块
New_Block proc
	;step 27
	;新块
    mov eax, tower_width[36]
    mov block[4], eax
    mov eax, tmp_color
    mov block[8], eax

	;step 28
	;下一块方向转换 direction = !direction;
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
	;%循环取下一个颜色 tmp_color = (tmp_color + 1) % COLOR_NUM;
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

;界面绘制
Game_Paint proc h_wnd:HWND
	;step20 背景颜色
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;step21 得分设置
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step22 显示分数
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 600, 100, offset show_score, SIZEOF show_score

	;step23 绘制塔，循环10层
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
		;                             左          上   右   下
		invoke Rectangle, g_mdc, tower_x[esi*4], ebx, ecx, eax
		inc esi
	.endw


	;step24 块的绘制
	invoke SelectObject, g_mdc, BlockBrush 

	mov	eax, WINDOW_HEIGHT
	mov	ebx, 11 * BLOCK_HEIGHT
	sub eax, ebx
	sub	eax, tower_offset
	mov	edx, eax
	;贴到目标上的坐标        x  y:WINDOW_HEIGHT - 11 * BLOCK_HEIGHT - tower_offet     
	invoke BitBlt, g_mdc, block[0], edx, block[4], BLOCK_HEIGHT, g_bufdc, 0, 0, PATCOPY
	;										宽         高            源

	;step25
	;将最后的画面显示在窗口中
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	;step26
	;获取时间（上次）
	invoke GetTickCount
	mov last_time, eax
	ret
Game_Paint endp

;游戏界面初始化
Game_Init proc h_wnd:HWND
	LOCAL bmp:HBITMAP, bmp1:HBITMAP

	;step10
	;初始化清零
	mov eax, 0
	mov last_time, eax
	mov now_time, eax
	mov tmp_color, eax
	mov score, eax

	;step11
	;得到内存块
	invoke GetDC, h_wnd
	mov g_hdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_mdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_bufdc, eax

	;step12 
	;塔初始化 10层 位置 高度 颜色
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
	;设置计时器
	invoke SetTimer, h_wnd, 1, 1, NULL

	;step14 
	;创建字体
	invoke CreateFont, 40, 0, 0, 0, 700, 0, 0, 0, GB2312_CHARSET, 0, 0, 0, 0, offset msgFont
	mov hFont, eax
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step15
	;显示分数
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 600, 100, offset show_score, SIZEOF show_score

	;step16
	;位图初始化
	invoke CreateCompatibleBitmap, g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov bmp, eax
	mov bmp1, eax
	invoke SelectObject, g_mdc, bmp
	invoke SelectObject, g_bufdc, bmp1

	;step17 
	;背景颜色刷
	RGB 135, 206, 250
	invoke CreateSolidBrush, eax
	mov BackgroundBrush, eax
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;step18 
	;塔颜色刷
	mov esi, 0
	.while esi < 10
		mov ebx, tower_rgb[esi*4]
		RGB	r[ebx], g[ebx], b[ebx]
		invoke CreateSolidBrush, eax
		mov TowerBrush[esi*4], eax
		inc esi
	.endw

	;step19 
	;得到新块
	invoke New_Block
	;绘制
	invoke Game_Paint, h_wnd
	ret
Game_Init endp 
end
