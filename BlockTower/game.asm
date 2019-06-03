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

;RGB宏定义
RGB macro red,green,blue
        xor eax,eax
        mov ah,blue
        shl eax,8
        mov ah,green
        mov al,red
endm

;函数声明
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
	Window_NAME			db	"BlockTower", 0	;窗口名称
	BUTTON_CLASS_NAME	db	"BUTTON", 0
	Easy_NAME			db	"Easy", 0
	Middle_NAME			db	"Middle", 0
	Diff_NAME			db	"Difficult", 0
	title_name			db	"BlockTower"

	easy_button_hwnd		HWND 0		;按钮句柄
	middle_button_hwnd		HWND 0
	difficult_button_hwnd	HWND 0
	
	WINDOW_WIDTH		equ	800			;窗口宽度
	WINDOW_HEIGHT		equ 700			;窗口高度
	BUTTON_WIDTH		equ 130         ;按钮宽度
	BUTTON_HEIGHT		equ 60          ;按钮宽度
	WINDOW_X			equ	400			;窗口初始位置
	A_WINDOW_X			equ 330         ;所有模式窗口位置
	WINDOW_Y			equ	20			;窗口初始位置
	E_WINDOW_Y			equ 300         ;easy模式窗口位置
	M_WINDOW_Y			equ 400         ;middle模式窗口位置
	D_WINDOW_Y			equ 500         ;difficult模式窗口位置
	BLOCK_HEIGHT		equ	40			;块宽度
	tower_offset		equ	35			;调整偏移量

	EasyID				equ	3001		;button ID
	Easy_ID			  HMENU 3001
	MiddleID			equ	3002
	Middle_ID		  HMENU 3002
	DifficultID			equ	3003
	Difficult_ID	  HMENU 3003
	TIMERID				equ 1

	history_x			dd	1024 dup(?)	;回顾x
	history_width		dd	1024 dup(?)	;回顾width
	history_rgb			dd	1024 dup(?)	;回顾rgb
	total				dd	0			;总塔高

	start_game			dd	0			;判断游戏已经开始

	dispeed				equ	20			;消失速率
	COLOR_NUM			equ	45			;颜色数量

	speed				dd	5			;移动速度
	last_time			dd	0			;刷新时间
	now_time			dd	0			;当前时间
	refresh_time		dd	5			;画面刷新间隔
	score				dd	0			;得分

	tmp_width			dd	500			;当前块的宽度
	direction			dd	0			;控制块来的方向left or right
	block				dd	3 dup(?)	;块的位置 x, 宽度 width, 颜色id rgb
	disappear			dd	5 dup(?)	;多余消失块 x, width, y, height, rgb
	x0					dd	0			;消失块中心x
	y0					dd	0			;消失块中心y
	disflag				dd	0			;是否有消失块
	tower_x				dd	10 dup(?)	;塔的位置 x
	tower_width			dd	10 dup(?)	;塔的宽度 width
	tower_rgb			dd	10 dup(?)	;塔的颜色id rgb

	tmp_color			dd	0			;当前块的颜色id
	TowerBrush		HBRUSH  10 dup(?)	;塔颜色画刷
	BlockBrush		HBRUSH	?			;块颜色画刷
	BackgroundBrush	HBRUSH	?			;背景颜色画刷
	DisBrush		HBRUSH	?			;消失块颜色画刷
	HistoryBrush	HBRUSH	?			;结束历史画刷

	g_hdc				HDC 0			;内存块
	g_mdc				HDC 0
	g_bufdc				HDC 0
	bmp				HBITMAP ?
	bmp1			HBITMAP ?
	hFont				HFONT ?			;得分字体
	titleFont			HFONT ?			;标题字体
	buttonFont			HFONT ?			;按钮字体

	msgFont				db	"Consolas", 0	;字体样式
	msgFont2			db	"Yu Gothic UI", 0	;字体样式
	msgFont3			db	"Cooper Black", 0	;字体样式
	boxmsg				db	"You Get Score ", 0 ;消息框
	boxmsgout			db	50 dup(?)
	boxmsg2				db	"Do you want to try again?", 0
	boxFmt				db	"%s%d.%s", 0
	gameover			db	"Game Over", 0

	sdFmt				db	"%s%d", 0	;得分输出格式 
	score_str			db	"Score: ", 0 ;得分字符串
	show_score			db	15 dup(?)	;得分显示字符串

	r					db	191,204,217,240,255,  255,255,255,255,255 ;颜色
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
		 ;绘制主界面
		 invoke	Start_Paint, h_wnd

		 ;Step5
		 ;消息循环接收
		 .WHILE msg.message != WM_QUIT 
				invoke PeekMessage, ADDR msg, 0, 0, 0, PM_REMOVE	;得到消息
				.if eax	;响应消息
					invoke	TranslateMessage, ADDR msg 
					invoke	DispatchMessage, ADDR msg
				.elseif	start_game != 0
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
				invoke	Game_Over, h_wnd
			.else
				;block[0] -= speed  向左移动
				mov	eax, block[0]
				sub	eax, speed
				mov	block[0], eax
			.endif
		.else ;左边
			mov	eax, tower_x[36]
			add	eax, tower_width[36]
			;向右超过，结束游戏 block[0] >= tower_x[9] + tower_width[9]
			.if	block[0] >= eax 
				invoke	Game_Over, h_wnd
			.else
				;block[0] += speed 向右移动
				mov	eax, block[0]
				add	eax, speed
				mov	block[0], eax
			.endif
		.endif
	.elseif uMsg==WM_KEYDOWN ;按键响应
		.if	wParam==VK_ESCAPE ;esc 关闭游戏
			invoke	DestroyWindow, h_wnd
		.elseif	wParam==VK_SPACE ;空格 
			.if start_game != 0
				;提前按，退出
				mov	eax, tower_x[36]
				add	eax, tower_width[36]
				mov	ebx, block[0]
				add	ebx, block[4]
				.if	(direction && block[0] >= eax) || (!direction && ebx <= tower_x[36]) 
					invoke	Game_Over, h_wnd
				.else
					;没有提前按，处理空格函数
					invoke	Process_Space, h_wnd
				.endif
				
			.endif

		.endif
	.elseif uMsg==WM_COMMAND	;button响应
		.if	wParam==EasyID
			invoke	DestroyWindow, easy_button_hwnd	;删除按钮
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd	
			mov speed, 3	;设置速度
			invoke	Game_Init, h_wnd	;游戏初始化
			mov	start_game, 1	;调用游戏参数
		.elseif	wParam==MiddleID
			invoke	DestroyWindow, easy_button_hwnd	;删除按钮
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd
			mov speed, 6	
			invoke	Game_Init, h_wnd	
			mov	start_game, 1	
		.elseif	wParam==DifficultID
			invoke	DestroyWindow, easy_button_hwnd	;删除按钮
			invoke	DestroyWindow, middle_button_hwnd	
			invoke	DestroyWindow, difficult_button_hwnd
			mov speed, 10
			invoke	Game_Init, h_wnd	
			mov	start_game, 1			
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
    
	;加1分
	inc score

	;new 0
	;有消失块
	mov disflag, 1
	;消失块的 y, height, rgb
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
	;消失块的中心 y0
	mov eax, disappear[3*4]
	mov ebx, 2
	div ebx
	add eax, disappear[2*4]
	mov y0, eax

	;step 6
	;超出部分，重新计算块的位置x和宽度width
    mov esi, block[0*4]
    mov edi, tower_x[9*4]
    .if esi < edi ;左边超出 block[0] < tower_x[9]
		;new1
		;消失块x, width
		mov eax, block[0*4]
		mov disappear[0*4], eax
		mov eax, tower_x[9*4]
		mov ebx, block[0*4]
		sub eax, ebx
		mov disappear[1*4], eax
		;消失块中心 x0
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
    .else ;右边超出
		;new 2
		;消失块 x, width
		mov eax, tower_width[9*4]
		add eax, tower_x[9*4]
		mov disappear[0*4],eax
		mov eax, block[0*4]
		add eax, block[1*4]
		sub eax, tower_x[9*4]
		sub eax, tower_width[9*4]
		mov disappear[1*4],eax
		;消失块中心 x0		
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
	;获取新块，并绘制
    invoke New_Block
    invoke Game_Paint, h_wnd
	ret
Process_Space endp

;游戏结束
Game_Over proc	h_wnd:HWND
	LOCAL	use_height:dword
	LOCAL	mini_height:dword
	LOCAL	mini_ratio:dword
	LOCAL	rect:RECT 

	;Step 37
	;界面刷新停止
	mov start_game, 0
	invoke KillTimer, h_wnd, TIMERID

	;重新绘制
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;Step 38
	;总高度
	mov use_height, WINDOW_HEIGHT - 50 - 100
	;每块高度 use_height / total
	xor edx, edx
	mov eax, use_height
	div total
	mov mini_height, eax
	;宽度缩小比例
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
	;绘制
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

	;显示
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	;Step 41
	;消息框
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

;主界面绘制
Game_Paint proc h_wnd:HWND
	LOCAL	rect:RECT ;消失块的绘制

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
	invoke TextOut, g_mdc, 300, 80, offset show_score, SIZEOF show_score

	;step23 绘制塔，循环10层
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
		;                             左          上   右   下
		;invoke Rectangle, g_mdc, tower_x[esi*4], ebx, ecx, eax
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

	;new 3
	;消失块的绘制
	.if disflag == 1 ;有消失块
		
		;消失块坐标
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
		;绘制消失块
		invoke FillRect, g_mdc, addr rect, DisBrush
		
		;消失块缩小
		mov eax, disappear[1*4]
		mov ebx, dispeed
		div ebx
		mov edx, eax
		mov eax, disappear[3*4]
		mov ebx, dispeed
		div ebx
		.if eax == 0 || edx == 0 ;不能再缩了
			;填充为底色
			invoke FillRect, g_mdc, addr rect, BackgroundBrush
			;标志为0
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

	;step10
	;初始化清零
	mov eax, 0
	mov last_time, eax
	mov now_time, eax
	mov tmp_color, eax
	mov score, eax

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

	;over 0
	;记录初始塔
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
	;设置计时器
	invoke SetTimer, h_wnd, TIMERID, 1, NULL

	;step14 
	;创建字体
	invoke CreateFont, 40, 0, 0, 0, 700, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont
	mov hFont, eax
	invoke SelectObject, g_mdc, hFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax

	;step15
	;显示分数
	invoke sprintf, offset show_score, offset sdFmt, offset score_str, score
	invoke TextOut, g_mdc, 300, 80, offset show_score, SIZEOF show_score

	;step17 
	;背景
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

;开始界面绘制
Start_Paint	proc h_wnd:HWND

	;step11
	;得到内存块
	invoke GetDC, h_wnd
	mov g_hdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_mdc, eax
	invoke CreateCompatibleDC, g_hdc
	mov g_bufdc, eax

	;step16
	;位图初始化
	invoke CreateCompatibleBitmap, g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT
	mov bmp, eax
	mov bmp1, eax
	invoke SelectObject, g_mdc, bmp
	invoke SelectObject, g_bufdc, bmp1

	;Step30
	;背景颜色刷
	RGB 255, 236, 245
	invoke CreateSolidBrush, eax
	mov BackgroundBrush, eax
	invoke SelectObject, g_mdc, BackgroundBrush
	invoke Rectangle, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	;Step31
	;按钮字体
	invoke CreateFont, 40, 0, 0, 0, FW_NORMAL, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont2
	mov buttonFont, eax

	;Step32
	;创建按钮
	mov ebx, WS_CHILD 
	or ebx, WS_VISIBLE
	or ebx, BS_DEFPUSHBUTTON
	invoke CreateWindowEx, NULL,\
                ADDR BUTTON_CLASS_NAME,\ 
                ADDR Easy_NAME,\ 
                ebx,\  ;;;;;;;;;;;;;;;;;;;;
                A_WINDOW_X,\ ;x
                E_WINDOW_Y,\ ;y
                BUTTON_WIDTH,\ ;宽
                BUTTON_HEIGHT,\ ;高
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
                BUTTON_WIDTH,\ ;宽
                BUTTON_HEIGHT,\ ;高
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
                BUTTON_WIDTH,\ ;宽
                BUTTON_HEIGHT,\ ;高
                h_wnd,\ 
                Difficult_ID,\ 
                h_wnd,\ 
                NULL 
	mov difficult_button_hwnd, eax 
	invoke ShowWindow, difficult_button_hwnd, SW_SHOW
	invoke SendMessage, difficult_button_hwnd, WM_SETFONT, buttonFont, 1

	;Step35
	;标题
	invoke CreateFont, 100, 0, 0, 0, FW_EXTRABOLD, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, offset msgFont3
	mov titleFont, eax
	invoke SelectObject, g_mdc, titleFont
	invoke SetBkMode, g_mdc, TRANSPARENT
	RGB 0, 0, 0
	invoke SetTextColor, g_mdc, eax
	invoke TextOut, g_mdc, 130, 100, offset title_name, SIZEOF title_name

	;Step36
	;将最后的画面显示在窗口中
	invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY

	ret
Start_Paint	endp
end
