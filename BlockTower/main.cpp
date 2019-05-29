#ifndef UNICODE
#define UNICODE
#endif 

#include <windows.h>
#include <stdio.h>

#define WINDOW_WIDTH 800                          
#define WINDOW_HEIGHT 700  
#define BLOCK_HEIGHT 40
#define BUTTON_WIDTH 130
#define BUTTON_HEIGHT 60
#define COLOR_NUM 16
#define EasyID 3001
#define MiddleID 3002
#define	DifficultID 3003

#define TIMERID	1	

HDC g_hdc = NULL, g_mdc = NULL, g_bufdc = NULL;
HBRUSH BackgroundBrush, TowerBrush[10], BlockBrush, DisBrush, HistoryBrush; //颜色画刷
HWND easy_button_hwnd = NULL, middle_button_hwnd = NULL, difficult_button_hwnd = NULL; //按钮句柄
HFONT hFont, titleFont, buttonFont;
const wchar_t BUTTON_CLASS_NAME[] = L"BUTTON";
const wchar_t Easy_NAME[] = L"Easy";
const wchar_t Middle_NAME[] = L"Middle";
const wchar_t Diff_NAME[] = L"Difficult";
wchar_t title_name[] = L"BlockTower";
long long last_time, now_time; //刷新时间
int refresh_time = 5; //画面刷新间隔
int tmp_width = 500; //当前块的宽度
int tmp_color; //当前块的颜色id
int tower_x[10]; //x
int tower_width[10]; //width
int tower_rgb[10]; //rgb
int history_x[1024]; //回顾x
int history_width[1024]; //回顾width
int history_rgb[1024]; //回顾rgb
int total; //总塔高
int block[3]; //x, width, rgb
int disappear[5]; //多余消失块 x, width, y, height, rgb
int x0, y0; //消失块中心
RECT rect; //消失块绘制
int direction; //left or right
const int tower_offset = 38; //调整偏移量
int speed = 5; //移动速度 
const int dispeed = 20; //消失速率
int disflag = 0; //是否有消失块
int score; //得分
int start_game = 0; //判断游戏已经开始
int r[100] = { 96,130,159,191,217,240,255,255,255,255,255,255,255,255,255,255 };
int g[100] = { 0,0,0,0,0,0,0,53,96,121,149,170,193,217,236,247 };
int b[100] = { 48,65,80,96,108,120,128,154,175,188,202,213,224,236,245,248 };
char score_str[] = "Score:";
char show_score[15];
wchar_t* show_score_t;


LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
void Game_Init(HWND hwnd); //resource init
void Start_Paint(HWND hwnd);
void Game_Paint(HWND hwnd); //draw again
void New_Block(); //get new block
void Game_CleanUp(HWND hwnd); //release resource
void Game_Over(HWND hwnd);
void Process_Space(HWND hwnd);


int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR pCmdLine, int nCmdShow)
{
	//Step1
	// Register the window class.
	const wchar_t CLASS_NAME[] = L"BlockTower";
	const wchar_t Window_NAME[] = L"BlockTower";

	WNDCLASS wc = { };

	wc.lpfnWndProc = WindowProc;
	wc.hInstance = hInstance;
	wc.lpszClassName = CLASS_NAME;

	RegisterClass(&wc);

	//Step2
	// Create the window.
	HWND hwnd = CreateWindowEx(
		0,                              // Optional window styles.
		CLASS_NAME,                     // Window class
		Window_NAME,    // Window text
		WS_OVERLAPPEDWINDOW^WS_THICKFRAME,            // Window style, not change size
		// Size and position
		400, 20, WINDOW_WIDTH, WINDOW_HEIGHT,
		NULL,       // Parent window    
		NULL,       // Menu
		hInstance,  // Instance handle
		NULL        // Additional application data
	);

	if (hwnd == NULL)
	{
		return 0;
	}

	//Step3
	ShowWindow(hwnd, nCmdShow);
	UpdateWindow(hwnd);

	//Step4
	//绘制主界面
	Start_Paint(hwnd);

	//Step5
	// Run the message loop.
	MSG msg = { };
	while (msg.message != WM_QUIT)
	{
		if (PeekMessage(&msg, 0, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		else if (start_game)
		{
			now_time = GetTickCount();
			if (now_time - last_time >= refresh_time)
				Game_Paint(hwnd);
		}
	}

	UnregisterClass(CLASS_NAME, wc.hInstance);  //程序准备结束，注销窗口类
	return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{
	case WM_TIMER:
	{
		//move
		if (direction)
		{
			if (block[0] + block[1] <= tower_x[9])
			{
				Game_Over(hwnd);
			}
			else
			{
				block[0] -= speed;
			}
		}
		else
		{
			if (block[0] >= tower_x[9] + tower_width[9])
			{
				Game_Over(hwnd);
			}
			else 
			{
				block[0] += speed;
			}
		}
		break;
	}
	case WM_KEYDOWN:	//按键响应
	{
		switch (wParam)
		{
		case VK_ESCAPE: //关闭游戏
			DestroyWindow(hwnd);
			break;
		case VK_SPACE:
			if (start_game)
			{
				//提前按下
				if ((direction && block[0] >= tower_x[9] + tower_width[9]) ||
					(!direction && block[0] + block[1] <= tower_x[9]))
				{
					Game_Over(hwnd);
				}
				else
				{
					Process_Space(hwnd);
				}
			}
			break;
		}
		break;
	}
	case WM_COMMAND: //按钮响应
	{
		switch (LOWORD(wParam))
		{
		case EasyID:
			DestroyWindow(easy_button_hwnd); //删除按钮
			DestroyWindow(middle_button_hwnd);
			DestroyWindow(difficult_button_hwnd);
			speed = 3; //设置速度
			Game_Init(hwnd); //游戏初始化
			start_game = 1; //调用游戏参数
			break;
		case MiddleID:
			DestroyWindow(easy_button_hwnd);
			DestroyWindow(middle_button_hwnd);
			DestroyWindow(difficult_button_hwnd);
			speed = 6;
			Game_Init(hwnd);
			start_game = 1;
			break;
		case DifficultID:
			DestroyWindow(easy_button_hwnd);
			DestroyWindow(middle_button_hwnd);
			DestroyWindow(difficult_button_hwnd);
			speed = 10;
			Game_Init(hwnd);
			start_game = 1;
			break;
		default:
			break;
		}
		return 0;
	}
	case WM_DESTROY:
	{
		Game_CleanUp(hwnd);
		PostQuitMessage(0);
		return 0;
	}
	case WM_PAINT:
	{
		PAINTSTRUCT ps;
		HDC hdc = BeginPaint(hwnd, &ps);

		EndPaint(hwnd, &ps);
	}

	return 0;
	}
	return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void Process_Space(HWND hwnd)
{
	//add score
	score++;

	//new 0
	disflag = 1;
	disappear[2] = WINDOW_HEIGHT - 10 * BLOCK_HEIGHT - tower_offset;
	disappear[3] = BLOCK_HEIGHT;
	disappear[4] = block[2];
	y0 = disappear[2] + disappear[3] / 2;
	//new 0

	//Step6
	if (block[0] < tower_x[9]) //left over
	{
		//new 1
		disappear[0] = block[0];
		disappear[1] = tower_x[9] - block[0];
		x0 = disappear[0] + disappear[1] / 2;
		//new 1

		block[1] = block[0] + block[1] - tower_x[9];
		block[0] = tower_x[9];
	}
	else //right over
	{
		//new 2
		disappear[0] = tower_x[9] + tower_width[9];
		disappear[1] = block[0] + block[1] - tower_x[9] - tower_width[9];
		x0 = disappear[0] + disappear[1] / 2;
		//new 2

		block[1] = tower_x[9] + tower_width[9] - block[0];
	}

	//Step7
	for (int i = 1; i < 10; i++) {
		tower_x[i - 1] = tower_x[i];
		tower_width[i - 1] = tower_width[i];
		tower_rgb[i - 1] = tower_rgb[i];
		TowerBrush[i - 1] = TowerBrush[i];
	}

	//Step8
	tower_x[9] = block[0];
	tower_width[9] = block[1];
	tower_rgb[9] = block[2];
	TowerBrush[9] = BlockBrush;

	//over 1
	history_x[total] = block[0];
	history_width[total] = block[1];
	history_rgb[total] = block[2];
	total++;
	//over 1

	//Step9
	New_Block();
	Game_Paint(hwnd);
}

void Game_Over(HWND hwnd)
{
	//Step 37
	//界面刷新停止
	start_game = 0;
	KillTimer(hwnd, TIMERID);
	//重新绘制
	SelectObject(g_mdc, BackgroundBrush);
	Rectangle(g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

	//Step 38
	//总高度
	int use_height = WINDOW_HEIGHT - 50 - 100;
	//每块高度
	int mini_height = use_height / total;
	//宽度缩小比例
	int mini_ratio = 2;

	//Step 39
 	for (int i = 0; i < total; i++)
	{
		history_x[i] = history_x[i] / mini_ratio;
		history_width[i] = history_width[i] / mini_ratio;
	}

	//Step 40
	//绘制
	for (int i = 0; i < total; i++) {
		HistoryBrush = CreateSolidBrush(RGB(r[history_rgb[i]], g[history_rgb[i]], b[history_rgb[i]]));
		//SelectObject(g_mdc, HistoryBrush);

		rect.left = history_x[i] + 200;
		rect.top = WINDOW_HEIGHT - (i + 1) * mini_height - 50;
		rect.right = history_x[i] + history_width[i] + 200;
		rect.bottom = WINDOW_HEIGHT - i * mini_height - 50;
		FillRect(g_mdc, &rect, HistoryBrush);

		//Rectangle(g_mdc, history_x[i] + 200, WINDOW_HEIGHT - (i + 1) * mini_height - 50, history_x[i] + history_width[i] + 200, WINDOW_HEIGHT - i * mini_height - 50);
	}

	//显示
	BitBlt(g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY);

	//Step 41
	//消息框
	char message[100] = "You Get Score ";
	char message2[30] = "Do you want to try again?";
	wchar_t* message_t;
	sprintf(message, "%s%d.\n%s", message, score, message2);

	//Step42
	int len = MultiByteToWideChar(CP_ACP, 0, message, -1, NULL, 0);
	message_t = (wchar_t *)malloc(len * sizeof(wchar_t));
	MultiByteToWideChar(CP_ACP, 0, message, -1, message_t, len);
	int msgBox = MessageBox(hwnd, message_t, L"Game Over", MB_OKCANCEL);
	if (msgBox == IDOK)
	{
		Start_Paint(hwnd);
	}
	else if (msgBox == IDCANCEL)
	{
		Game_CleanUp(hwnd);
		PostQuitMessage(0);
	}
}

void Game_CleanUp(HWND hwnd)
{
	DeleteObject(BackgroundBrush);
	DeleteObject(BlockBrush);
	for (int i = 0; i < 10; i++) {
		DeleteObject(TowerBrush[i]);
	}
	DeleteDC(g_bufdc);
	DeleteDC(g_mdc);
	ReleaseDC(hwnd, g_hdc);
}

void Game_Init(HWND hwnd)
{
	//Step10
	last_time = 0;
	now_time = 0;
	tmp_color = 0;
	score = 0;

	//Step12
	//tower init
	for (int i = 0; i < 10; i++) {
		tower_x[i] = (WINDOW_WIDTH - tmp_width) / 2;
		tower_width[i] = tmp_width;
		tower_rgb[i] = tmp_color;
		tmp_color = (tmp_color + 1) % COLOR_NUM;
	}

	//over 0
	//记录初始塔
	for (int i = 0; i < 10; i++) {
		history_x[i] = tower_x[i];
		history_width[i] = tower_width[i];
		history_rgb[i] = tower_rgb[i];
	}
	total = 10;
	//over 0

	//Step13
	//set timer
	SetTimer(hwnd, TIMERID, 1, NULL);

	//创建字体
	//Step14
	hFont = CreateFont(60, 0, 0, 0, 700, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, TEXT("Consolas"));
	SelectObject(g_mdc, hFont);
	SetBkMode(g_mdc, TRANSPARENT);
	SetTextColor(g_mdc, RGB(0, 0, 0));

	//Step15
	//显示分数
	sprintf(show_score, "%s%d", score_str, score);
	int len = MultiByteToWideChar(CP_ACP, 0, show_score, -1, NULL, 0);
	show_score_t = (wchar_t *)malloc(len * sizeof(wchar_t));
	MultiByteToWideChar(CP_ACP, 0, show_score, -1, show_score_t, len);
	TextOut(g_mdc, 300, 80, show_score_t, wcslen(show_score_t));

	//Step17
	//background color
	SelectObject(g_mdc, BackgroundBrush);
	Rectangle(g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

	//Step18
	//tower color
	for (int i = 0; i < 10; i++) {
		TowerBrush[i] = CreateSolidBrush(RGB(r[tower_rgb[i]], g[tower_rgb[i]], b[tower_rgb[i]]));
	}

	//Step19
	//get new block
	New_Block();

	Game_Paint(hwnd);
}

void Start_Paint(HWND hwnd)
{
	//Step11
	g_hdc = GetDC(hwnd);
	g_mdc = CreateCompatibleDC(g_hdc);
	g_bufdc = CreateCompatibleDC(g_hdc);

	//Step16
	HBITMAP bmp, bmp1;
	bmp = CreateCompatibleBitmap(g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT);
	bmp1 = CreateCompatibleBitmap(g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT);
	SelectObject(g_mdc, bmp);
	SelectObject(g_bufdc, bmp1);

	//Step30
	//背景
	BackgroundBrush = CreateSolidBrush(RGB(255, 236, 245));
	SelectObject(g_mdc, BackgroundBrush);
	Rectangle(g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

	//Step31
	//按钮字体
	buttonFont = CreateFont(40, 0, 0, 0, FW_NORMAL, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, TEXT("Yu Gothic UI"));

	//Step32
	//创建按钮
	easy_button_hwnd = CreateWindowEx(0, BUTTON_CLASS_NAME, Easy_NAME, WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON, 
		330, 300, BUTTON_WIDTH, BUTTON_HEIGHT,
		hwnd,      
		(HMENU)EasyID,     
		(HINSTANCE)hwnd, 
		NULL      
	);
	ShowWindow(easy_button_hwnd, SW_SHOW);
	SendMessage(easy_button_hwnd, WM_SETFONT, (WPARAM)buttonFont, 1);

	//Step33
	middle_button_hwnd = CreateWindowEx(0, BUTTON_CLASS_NAME, Middle_NAME, WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
		330, 400, BUTTON_WIDTH, BUTTON_HEIGHT,
		hwnd,      
		(HMENU)MiddleID,    
		(HINSTANCE)hwnd, 
		NULL      
	);
	ShowWindow(middle_button_hwnd, SW_SHOW);
	SendMessage(middle_button_hwnd, WM_SETFONT, (WPARAM)buttonFont, 1);

	//Step34
	difficult_button_hwnd = CreateWindowEx(0, BUTTON_CLASS_NAME, Diff_NAME, WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
		// Size and position
		330, 500, BUTTON_WIDTH, BUTTON_HEIGHT,
		hwnd,       // Parent window    
		(HMENU)DifficultID,       // Menu
		(HINSTANCE)hwnd,  // Instance handle
		NULL        // Additional application data
	);
	ShowWindow(difficult_button_hwnd, SW_SHOW);
	SendMessage(difficult_button_hwnd, WM_SETFONT, (WPARAM)buttonFont, 1);

	//Step35
	//标题
	titleFont = CreateFont(100, 0, 0, 0, FW_EXTRABOLD, 0, 0, 0, ANSI_CHARSET, 0, 0, 0, 0, TEXT("Cooper Black"));
	SelectObject(g_mdc, titleFont);
	SetBkMode(g_mdc, TRANSPARENT);
	SetTextColor(g_mdc, RGB(0, 0, 0));
	TextOut(g_mdc, 130, 100, title_name, wcslen(title_name));

	//Step36
	//将最后的画面显示在窗口中
	BitBlt(g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY);
}

void Game_Paint(HWND hwnd)
{
	//Step20
	//background
	SelectObject(g_mdc, BackgroundBrush);
	Rectangle(g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

	//score show
	//Step21
	SelectObject(g_mdc, hFont);
	SetBkMode(g_mdc, TRANSPARENT);
	SetTextColor(g_mdc, RGB(0, 0, 0));
	//Step22
	sprintf(show_score, "%s%d", score_str, score);
	int len = MultiByteToWideChar(CP_ACP, 0, show_score, -1, NULL, 0);
	show_score_t = (wchar_t *)malloc(len * sizeof(wchar_t));
	MultiByteToWideChar(CP_ACP, 0, show_score, -1, show_score_t, len);
	TextOut(g_mdc, 300, 80, show_score_t, wcslen(show_score_t));

	//Step23
	//draw tower
	for (int i = 0; i < 10; i++) {
		//SelectObject(g_mdc, TowerBrush[i]);

		rect.left = tower_x[i];
		rect.top = WINDOW_HEIGHT - (i + 1) * BLOCK_HEIGHT - tower_offset;
		rect.right = tower_x[i] + tower_width[i];
		rect.bottom = WINDOW_HEIGHT - i * BLOCK_HEIGHT - tower_offset;
		FillRect(g_mdc, &rect, TowerBrush[i]);

		//Rectangle(g_mdc, tower_x[i], WINDOW_HEIGHT - (i + 1) * BLOCK_HEIGHT - tower_offset, tower_x[i] + tower_width[i], WINDOW_HEIGHT - i * BLOCK_HEIGHT - tower_offset);
	}

	//Step24
	//draw block
	SelectObject(g_mdc, BlockBrush);
	//              贴到目标上的坐标                                              宽         高            源               
	BitBlt(g_mdc, block[0], WINDOW_HEIGHT - 11 * BLOCK_HEIGHT - tower_offset, block[1], BLOCK_HEIGHT, g_bufdc, 0, 0, PATCOPY);

	//new 3
	if (disflag)
	{
		DisBrush = CreateSolidBrush(RGB(r[disappear[4]], g[disappear[4]], b[disappear[4]]));
		rect.left = disappear[0];
		rect.top = disappear[2];
		rect.right = disappear[0] + disappear[1];
		rect.bottom = disappear[2] + disappear[3];
		FillRect(g_mdc, &rect, DisBrush);

		if (disappear[1] / dispeed == 0 || disappear[3] / dispeed == 0)
		{
			FillRect(g_mdc, &rect, BackgroundBrush);
			disflag = 0;
		}
		else
		{
			disappear[1] = disappear[1] - disappear[1] / dispeed;
			disappear[3] = disappear[3] - disappear[3] / dispeed;
			disappear[0] = x0 - disappear[1] / 2;
			disappear[2] = y0 - disappear[3] / 2;
		}
	}
	//new 3

	//Step25
	//将最后的画面显示在窗口中
	BitBlt(g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY);

	//Step26
	last_time = GetTickCount();
}

void New_Block()
{
	//Step27
	block[1] = tower_width[9];
	block[2] = tmp_color;

	//Step28
	direction = !direction;
	if (direction)
		block[0] = WINDOW_WIDTH;
	else
		block[0] = 0;

	//Step29
	tmp_color = (tmp_color + 1) % COLOR_NUM;
	BlockBrush = CreateSolidBrush(RGB(r[block[2]], g[block[2]], b[block[2]]));
	return;
}