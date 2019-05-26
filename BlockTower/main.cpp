#ifndef UNICODE
#define UNICODE
#endif 

#include <windows.h>
#include <stdio.h>

#define WINDOW_WIDTH 800                          
#define WINDOW_HEIGHT 700  
#define BLOCK_HEIGHT 40
#define COLOR_NUM 16

HDC g_hdc = NULL, g_mdc = NULL, g_bufdc = NULL;
HBRUSH BackgroundBrush, TowerBrush[10], BlockBursh; //��ɫ��ˢ
HFONT hFont;
long long last_time, now_time; //ˢ��ʱ��
int refresh_time = 5; //����ˢ�¼��
int tmp_width = 500; //��ǰ��Ŀ��
int tmp_color; //��ǰ�����ɫid
int tower[10][3]; //x, width, rgb
int block[3]; //x, width, rgb
int direction; //left or right
const int tower_offet = 38; //����ƫ����
const int speed = 5; //�ƶ��ٶ� 
int score; //�÷�
int r[100] = {96,130,159,191,217,240,255,255,255,255,255,255,255,255,255,255};
int g[100] = {0,0,0,0,0,0,0,53,96,121,149,170,193,217,236,247};
int b[100] = {48,65,80,96,108,120,128,154,175,188,202,213,224,236,245,248};
char score_str[] = "Score:";
char show_score[15];
wchar_t* show_score_t;


LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
void Game_Init(HWND hwnd); //resource init
void Game_Paint(HWND hwnd); //draw again
void New_Block(); //get new block
void Game_CleanUp(HWND hwnd); //release resource
void Game_Over();
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
	Game_Init(hwnd);

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
		else
		{
			now_time = GetTickCount();
			if (now_time - last_time >= refresh_time)
				Game_Paint(hwnd);
		}
	}

	UnregisterClass(CLASS_NAME, wc.hInstance);  //����׼��������ע��������
	return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{
	case WM_TIMER:
		//move
		if (direction)
		{
			if (block[0] + block[1] <= tower[9][0])
			{
				Game_Over();
				Game_CleanUp(hwnd);
				PostQuitMessage(0);
			}
			block[0] -= speed;
		}
		else
		{
			if (block[0] >= tower[9][0] + tower[9][1])
			{
				Game_Over();
				Game_CleanUp(hwnd);
				PostQuitMessage(0);
			}
			block[0] += speed;
		}
		break;

	case WM_KEYDOWN:
		switch (wParam)
		{
		case VK_ESCAPE: //�ر���Ϸ
			DestroyWindow(hwnd);
			break;
		case VK_SPACE:
			//��ǰ����
			if ((direction && block[0] >= tower[9][0] + tower[9][1]) ||
				(!direction && block[0] + block[1] <= tower[9][0]))
			{
				Game_Over();
				Game_CleanUp(hwnd);
				PostQuitMessage(0);
			}
			Process_Space(hwnd);
			break;
		}
		break;

	case WM_DESTROY:
		Game_CleanUp(hwnd);
		PostQuitMessage(0);
		return 0;

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

	//Step6
	if (block[0] < tower[9][0]) //left over
	{
		block[1] = block[0] + block[1] - tower[9][0];
		block[0] = tower[9][0];
	}
	else //right over
	{
		block[1] = tower[9][0] + tower[9][1] - block[0];
	}

	//Step7
	for (int i = 1; i < 10; i++) {
		for (int j = 0; j < 3; j++) {
			tower[i - 1][j] = tower[i][j];
		}
		TowerBrush[i - 1] = TowerBrush[i];
	}

	//Step8
	for (int i = 0; i < 3; i++)
		tower[9][i] = block[i];
	TowerBrush[9] = BlockBursh;
	
	//Step9
	New_Block();
	Game_Paint(hwnd);
}

void Game_Over()
{

}

void Game_CleanUp(HWND hwnd)
{
	DeleteObject(BackgroundBrush);
	DeleteObject(BlockBursh);
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

	//Step11
	g_hdc = GetDC(hwnd);
	g_mdc = CreateCompatibleDC(g_hdc);
	g_bufdc = CreateCompatibleDC(g_hdc);

	//Step12
	//tower init
	for (int i = 0; i < 10; i++) {
		tower[i][0] = (WINDOW_WIDTH - tmp_width) / 2;
		tower[i][1] = tmp_width;
		tower[i][2] = tmp_color;
		tmp_color = (tmp_color + 1) % COLOR_NUM;
	}

	//Step13
	//set timer
	SetTimer(hwnd, 1, 1, NULL);

	//��������
	//Step14
	hFont = CreateFont(40, 0, 0, 0, 700, 0, 0, 0, GB2312_CHARSET, 0, 0, 0, 0, TEXT("Consolas")); 
	SelectObject(g_mdc, hFont); 
	SetBkMode(g_mdc, TRANSPARENT);   
	SetTextColor(g_mdc, RGB(0, 0, 0)); 
	//Step15
	sprintf(show_score, "%s%d", score_str, score);
	int len = MultiByteToWideChar(CP_ACP, 0, show_score, -1, NULL, 0);
	show_score_t = (wchar_t *)malloc(len * sizeof(wchar_t));
	MultiByteToWideChar(CP_ACP, 0, show_score, -1, show_score_t, len);
	TextOut(g_mdc, 600, 100, show_score_t, wcslen(show_score_t));

	//Step16
	HBITMAP bmp, bmp1;
	bmp = CreateCompatibleBitmap(g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT);
	bmp1 = CreateCompatibleBitmap(g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT);
	SelectObject(g_mdc, bmp);
	SelectObject(g_bufdc, bmp1);
	
	//Step17
	//background color
	BackgroundBrush = CreateSolidBrush(RGB(135, 206, 250));
	SelectObject(g_mdc, BackgroundBrush);
	Rectangle(g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	
	//Step18
	//tower color
	for (int i = 0; i < 10; i++) {
		TowerBrush[i] = CreateSolidBrush(RGB(r[tower[i][2]], g[tower[i][2]], b[tower[i][2]]));
	}

	//Step19
	//get new block
	New_Block();

	Game_Paint(hwnd);
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
	TextOut(g_mdc, 600, 100, show_score_t, wcslen(show_score_t));

	//Step23
	//draw tower
	for (int i = 0; i < 10; i++) {
		SelectObject(g_mdc, TowerBrush[i]);
		Rectangle(g_mdc, tower[i][0], WINDOW_HEIGHT - (i + 1) * BLOCK_HEIGHT - tower_offet, tower[i][0] + tower[i][1], WINDOW_HEIGHT - i * BLOCK_HEIGHT - tower_offet);
	}

	//Step24
	//draw block
	SelectObject(g_mdc, BlockBursh);
    //              ����Ŀ���ϵ�����                                              ��         ��            Դ               
	BitBlt(g_mdc, block[0], WINDOW_HEIGHT - 11 * BLOCK_HEIGHT - tower_offet, block[1], BLOCK_HEIGHT, g_bufdc, 0, 0, PATCOPY);

	//Step25
	//�����Ļ�����ʾ�ڴ�����
	BitBlt(g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY);

	//Step26
	last_time = GetTickCount();
}

void New_Block()
{
	//Step27
	block[1] = tower[9][1];
	block[2] = tmp_color;

	//Step28
	direction = !direction;
	if (direction)
		block[0] = WINDOW_WIDTH;
	else
		block[0] = 0;

	//Step29
	tmp_color = (tmp_color + 1) % COLOR_NUM;
	BlockBursh = CreateSolidBrush(RGB(r[block[2]], g[block[2]], b[block[2]]));
} 