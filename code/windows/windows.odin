//+build windows
package windows_bindings

foreign import win { "system:kernel32.lib", "system:user32.lib", "system:Gdi32.lib" }

foreign win {
	SetCapture :: proc(hWnd: HWND) -> HWND ---
	ReleaseCapture :: proc() -> BOOL ---
	GetCursorPos :: proc(lpPoint: LPPOINT) -> BOOL ---
	ScreenToClient :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	TrackMouseEvent :: proc(lpEventTrack: LPTRACKMOUSEEVENT) -> BOOL ---
	GetLastError :: proc() -> DWORD ---
	GetFullPathNameA :: proc(filename: cstring, buffer_length: DWORD, buffer: cstring, file_part: rawptr) -> u32 ---
	VirtualAlloc :: proc(lpAddress: LPVOID, dwSize: SIZE_T, flAllocationType, flProtect: DWORD) -> LPVOID ---
	GetModuleHandleA :: proc(lpModuleName: LPCSTR) -> HMODULE ---
	LoadCursorA :: proc(hInstance: HINSTANCE, lpCursorName: LPCSTR) -> HCURSOR ---
	RegisterClassExA :: proc(^WNDCLASSEXA) -> ATOM ---
	CreateWindowExA :: proc(
		dwExStyle: DWORD,
		lpClassName: LPCSTR,
		lpWindowName: LPCSTR,
		dwStyle: DWORD,
		X: i32,
		Y: i32,
		nWidth: i32,
		nHeight: i32,
		hWndParent: HWND,
		hMenu: HMENU,
		hInstance: HINSTANCE,
		lpParam: LPVOID,
	) -> HWND ---
	SetWindowLongPtrA :: proc(hWnd: HWND, nIndex: i32, dwNewLong: LONG_PTR) -> LONG_PTR ---
	GetWindowLongPtrA :: proc(hWnd: HWND, nIndex: i32) -> LONG_PTR ---
	GetClientRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetWindowRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	SetWindowPos :: proc(hWnd, hWndInsertAfter: HWND, X, Y, cx, cy: i32, uFlags: UINT) -> BOOL ---
	ShowWindow :: proc(hWnd: HWND, nCmdSho: i32) -> BOOL ---
	GetDC :: proc(hWnd: HWND) -> HDC ---
	DefWindowProcA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	SetCursor :: proc(hCursor: HCURSOR) -> HCURSOR ---
	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---
	DispatchMessageA :: proc(lpMsg: ^MSG) -> LRESULT ---
	PeekMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---
	GetMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	StretchDIBits :: proc(
		hdc: HDC,
		xDest: i32,
		yDest: i32,
		DestWidth: i32,
		DestHeight: i32,
		xSrc: i32,
		ySrc: i32,
		SrcWidth: i32,
		SrcHeight: i32,
		lpBits: VOID,
		lpbmi: ^BITMAPINFO,
		iUsage: UINT,
		rop: DWORD,
	) -> i32 ---
	SetWindowPlacement :: proc(hWnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	GetWindowPlacement :: proc(hWnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	GetMonitorInfoA :: proc(hMonitor: HMONITOR, lpmi: LPMONITORINFO) -> BOOL ---
	MonitorFromWindow :: proc(hwind: HWND, dwFlags: DWORD) -> HMONITOR ---
	ReadFile :: proc(
		hFile: HANDLE,
		lpBuffer: LPVOID,
		nNumberOfBytesToRead: DWORD,
		lpNumberOfBytesRead: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
	) -> BOOL ---
	CreateFileA :: proc(
		lpFileName: LPCSTR,
		dwDesiredAccess: DWORD,
		dwShareMode: DWORD,
		lpSecurityAttributes: ^LPSECURITY_ATTRIBUTES,
		dwCreationDisposition: DWORD,
		dwFlagsAndAttributes: DWORD,
		hTemplateFil: HANDLE,
	) -> HANDLE ---
	GetFileSize :: proc(hFile: HANDLE, lpFileSizeHigh: LPDWORD) -> DWORD ---
	EnumFontFamiliesExA :: proc(
		hdc: HDC,
		lpLogfont: LPLOGFONTA,
		lpProc: FONTENUMPROCA,
		lParam: LPARAM,
		dwFlags: DWORD,
	) -> i32 ---
	FormatMessageW :: proc(
		dwFlags: DWORD,
		lpSource: LPCVOID,
		dwMessageId: DWORD,
		dwLanguageId: DWORD,
		lpBuffer: ^LPWSTR,
		nSize: DWORD,
		Argument: rawptr,
	) -> DWORD ---
	GetLogicalDrives :: proc() -> DWORD ---
	RegisterRawInputDevices :: proc(pRawInputDevices: PCRAWINPUTDEVICE, uiNumDevices: UINT, cbSize: UINT) -> BOOL ---
	ClipCursor :: proc(lpRect: ^RECT) -> BOOL ---
	ShowCursor :: proc(bShow: BOOL) -> i32 ---
	ClientToScreen :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	GetRawInputData :: proc(hRawInput: HRAWINPUT, uiCommand: UINT, pData: LPVOID, pcbSize: PUINT, cbSizeHeader: UINT, ) -> UINT ---
	}

LOWORD :: #force_inline proc "contextless" (x: DWORD) -> WORD {
	return WORD(x & 0xffff)
}

HIWORD :: #force_inline proc "contextless" (x: DWORD) -> WORD {
	return WORD(x >> 16)
}

VOID :: rawptr
PVOID :: rawptr
LPVOID :: rawptr
LPCVOID :: rawptr
HANDLE :: PVOID
HWND :: HANDLE
HINSTANCE :: HANDLE
HMODULE :: HINSTANCE
HCURSOR :: HICON
HICON :: HANDLE
HBRUSH :: HANDLE
HRAWINPUT :: HANDLE
HMENU :: HANDLE
HDC :: HANDLE
HMONITOR :: HANDLE
WCHAR :: u16
LPWSTR :: [^]WCHAR

TRUE :: 1
FALSE :: 0

BOOL :: i32
LONG :: i32
UINT :: u32
ULONG :: u32
ULONG_PTR :: ^ULONG
WORD :: u16
DWORD :: u32
LPDWORD :: ^DWORD
SIZE_T :: uint
LPCSTR :: cstring
LONG_PTR :: int
UINT_PTR :: uint
LRESULT :: LONG_PTR
LPARAM :: LONG_PTR
WPARAM :: UINT_PTR
ATOM :: WORD
BYTE :: u8
CHAR :: u8
USHORT :: u16

PUINT :: ^UINT

POINT :: struct { x, y: LONG }
LPPOINT :: ^POINT
LPTRACKMOUSEEVENT :: ^TRACKMOUSEEVENT
TRACKMOUSEEVENT :: struct { cbSize, dwFlags: DWORD, hwndTrack: HWND, dwHoverTime: DWORD }
WNDCLASSEXA :: struct {
	cbSize: UINT,
	style: UINT,
	lpfnWndProc: WNDPROC,
	cbClsExtra: i32,
	cbWndExtra: i32,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName: LPCSTR,
	lpszClassName: LPCSTR,
	hIconSm: HICON,
}
WNDPROC :: #type proc "stdcall" (HWND, UINT, WPARAM, LPARAM) -> LRESULT
RECT :: struct {left, top, right, bottom: LONG}
LPRECT :: ^RECT
BITMAPINFO :: struct {bmiHeader: BITMAPINFOHEADER, bmiColors: [1]RGBQUAD}
BITMAPINFOHEADER :: struct {
	biSize: DWORD,
	biWidth: LONG,
	biHeight: LONG,
	biPlanes: WORD,
	biBitCount: WORD,
	biCompression: DWORD,
	biSizeImage: DWORD,
	biXPelsPerMeter: LONG,
	biYPelsPerMeter: LONG,
	biClrUsed: DWORD,
	biClrImportant: DWORD,
}
RGBQUAD :: struct {rgbBlue, rgbGreen, rgbRed, rgbReserved: BYTE}
WINDOWPLACEMENT :: struct {
	length: UINT,
	flags: UINT,
	showCmd: UINT,
	ptMinPosition: POINT,
	ptMaxPosition: POINT,
	rcNormalPosition: RECT,
	rcDevice: RECT,
}
MSG :: struct {
	hwnd: HWND,
	message: UINT,
	wParam: WPARAM,
	lParam: LPARAM,
	time: DWORD,
	pt: POINT,
}
MONITORINFO :: struct {cbSize: DWORD, rcMonitor, rcWork: RECT, dwFlags: DWORD}
LPMONITORINFO :: ^MONITORINFO
OVERLAPPED :: struct {
	Internal: ULONG_PTR,
	InternalHigh: ULONG_PTR,
	DUMMYUNIONNAME: struct #raw_union {
		DUMMYSTRUCTNAME: struct {Offset, OffsetHigh: DWORD},
		pointer: PVOID,
	},
	hEvent: HANDLE,
}
LPOVERLAPPED :: ^OVERLAPPED
SECURITY_ATTRIBUTES :: struct {
	nLength: DWORD,
	lpSecurityDescriptor: LPVOID,
	bInheritHandle: BOOL,
}
LPSECURITY_ATTRIBUTES :: ^SECURITY_ATTRIBUTES
LOGFONTA :: struct {
	lfHeight: LONG,
	lfWidth: LONG,
	lfEscapement: LONG,
	lfOrientation: LONG,
	lfWeight: LONG,
	lfItalic: BYTE,
	lfUnderline: BYTE,
	lfStrikeOut: BYTE,
	lfCharSet: BYTE,
	lfOutPrecision: BYTE,
	lfClipPrecision: BYTE,
	lfQuality: BYTE,
	lfPitchAndFamily: BYTE,
	lfFaceName: [LF_FACESIZE]CHAR,
}
LPLOGFONTA :: ^LOGFONTA
FONTENUMPROCA :: #type proc "c" (lpelfe: ^LOGFONTA, lpntme: ^TEXTMETRICA, FontType: DWORD, lParam: LPARAM) -> i32
TEXTMETRICA :: struct {
	tmHeight: LONG,
	tmAscent: LONG,
	tmDescent: LONG,
	tmInternalLeading: LONG,
	tmExternalLeading: LONG,
	tmAveCharWidth: LONG,
	tmMaxCharWidth: LONG,
	tmWeight: LONG,
	tmOverhang: LONG,
	tmDigitizedAspectX: LONG,
	tmDigitizedAspectY: LONG,
	tmFirstChar: BYTE,
	tmLastChar: BYTE,
	tmDefaultChar: BYTE,
	tmBreakChar: BYTE,
	tmItalic: BYTE,
	tmUnderlined: BYTE,
	tmStruckOut: BYTE,
	tmPitchAndFamily: BYTE,
	tmCharSet: BYTE,
}
NEWTEXTMETRICEXA :: struct {
	ntmTm: NEWTEXTMETRICA,
	ntmFontSig: FONTSIGNATURE,
}
NEWTEXTMETRICA :: struct {
	tmHeight: LONG,
	tmAscent: LONG,
	tmDescent: LONG,
	tmInternalLeading: LONG,
	tmExternalLeading: LONG,
	tmAveCharWidth: LONG,
	tmMaxCharWidth: LONG,
	tmWeight: LONG,
	tmOverhang: LONG,
	tmDigitizedAspectX: LONG,
	tmDigitizedAspectY: LONG,
	tmFirstChar: BYTE,
	tmLastChar: BYTE,
	tmDefaultChar: BYTE,
	tmBreakChar: BYTE,
	tmItalic: BYTE,
	tmUnderlined: BYTE,
	tmStruckOut: BYTE,
	tmPitchAndFamily: BYTE,
	tmCharSet: BYTE,
	ntmFlags: DWORD,
	ntmSizeEM: UINT,
	ntmCellHeight: UINT,
	ntmAvgWidth: UINT,
}
FONTSIGNATURE :: struct {
	fsUsb: [4]DWORD,
	fsCsb: [2]DWORD,
}
RAWINPUTDEVICE :: struct {
	usUsagePage: USHORT,
	usUsage: USHORT,
	dwFlags: DWORD,
	hwndTarget: HWND,
}
PRAWINPUTDEVICE :: ^RAWINPUTDEVICE
PCRAWINPUTDEVICE :: ^RAWINPUTDEVICE
RAWINPUT :: struct {
	header: RAWINPUTHEADER,
 	data: struct #raw_union {
		mouse: RAWMOUSE,
		keyboard: RAWKEYBOARD,
		hid: RAWHID,
	},
}
PRAWINPUT :: ^RAWINPUT
LPRAWINPUT :: ^RAWINPUT
RAWINPUTHEADER :: struct {
	dwType: DWORD,
	dwSize: DWORD,
	hDevice: HANDLE,
	wParam: WPARAM,
}
PRAWINPUTHEADER :: ^RAWINPUTHEADER
LPRAWINPUTHEADER :: ^RAWINPUTHEADER
RAWMOUSE :: struct {
	usFlags: USHORT,
	DUMMYUNIONNAME: struct #raw_union {
		ulButtons: ULONG,
		DUMMYSTRUCTNAME: struct {
			usButtonFlags: USHORT,
			usButtonData: USHORT,
		},
	},
	ulRawButtons: ULONG,
	lLastX: LONG,
	lLastY: LONG,
	ulExtraInformation: ULONG,
}
PRAWMOUSE :: ^RAWMOUSE
LPRAWMOUSE :: ^RAWMOUSE
RAWKEYBOARD :: struct {
	MakeCode: USHORT,
	Flags: USHORT,
	Reserved: USHORT,
	VKey: USHORT,
	Message: UINT,
	ExtraInformation: ULONG,
}
PRAWKEYBOARD :: ^RAWKEYBOARD
LPRAWKEYBOARD :: ^RAWKEYBOARD
RAWHID :: struct {
	dwSizeHid: DWORD,
	dwCount: DWORD,
	bRawData: [1]BYTE,
}
PRAWHID :: ^RAWHID
LPRAWHID :: ^RAWHID

TME_LEAVE :: 0x00000002
MEM_COMMIT :: 0x00001000
MEM_RESERVE :: 0x00002000
PAGE_READWRITE :: 0x04
CS_VREDRAW :: 0x0001
CS_HREDRAW :: 0x0002
WS_OVERLAPPED :: 0x00000000
WS_CAPTION :: 0x00C00000
WS_SYSMENU :: 0x00080000
WS_THICKFRAME :: 0x00040000
WS_MINIMIZEBOX :: 0x00020000
WS_MAXIMIZEBOX :: 0x00010000
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
GWLP_USERDATA :: -21
GWL_STYLE   :: -16
SW_SHOWNORMAL :: 1
SW_SHOWMINIMIZED :: 2
BI_RGB :: 0x0000
PM_NOREMOVE :: 0x0000
PM_REMOVE :: 0x0001
PM_NOYIELD :: 0x0002
DIB_RGB_COLORS :: 0
SRCCOPY :: 0x00CC0020
SWP_NOSIZE :: 0x0001
SWP_NOMOVE :: 0x0002
SWP_NOZORDER :: 0x0004
SWP_NOREDRAW :: 0x0008
SWP_NOACTIVATE :: 0x0010
SWP_FRAMECHANGED :: 0x0020
SWP_SHOWWINDOW :: 0x0040
SWP_HIDEWINDOW :: 0x0080
SWP_NOCOPYBITS :: 0x0100
SWP_NOOWNERZORDER :: 0x0200
SWP_NOSENDCHANGING :: 0x0400
MONITOR_DEFAULTTONULL :: 0x00000000
MONITOR_DEFAULTTOPRIMARY :: 0x00000001
MONITOR_DEFAULTTONEAREST :: 0x00000002
GENERIC_READ :: 0x80000000
FILE_SHARE_READ :: 0x00000001
OPEN_EXISTING :: 3
FILE_ATTRIBUTE_NORMAL :: 0x00000080
LF_FACESIZE :: 32
DEFAULT_PITCH :: 0
FIXED_PITCH :: 1
VARIABLE_PITCH :: 2
RASTER_FONTTYPE :: 0x0001
DEVICE_FONTTYPE :: 0x0002
TRUETYPE_FONTTYPE :: 0x0004
ANSI_CHARSET :: 0
DEFAULT_CHARSET :: 1
SYMBOL_CHARSET :: 2
SHIFTJIS_CHARSET :: 128
HANGEUL_CHARSET :: 129
HANGUL_CHARSET :: 129
GB2312_CHARSET :: 134
CHINESEBIG5_CHARSET :: 136
OEM_CHARSET :: 255
FORMAT_MESSAGE_ALLOCATE_BUFFER :: 0x00000100
FORMAT_MESSAGE_FROM_SYSTEM :: 0x00001000
FORMAT_MESSAGE_IGNORE_INSERTS :: 0x00000200

HID_USAGE_PAGE_GENERIC :: 0x01
HID_USAGE_GENERIC_MOUSE :: 0x02
RIDEV_INPUTSINK :: 0x00000100

RID_INPUT :: 0x10000003
RIM_TYPEMOUSE :: 0x00000000
RIM_TYPEKEYBOARD :: 0x00000001
RIM_TYPEHID :: 0x00000002

_CW_USEDEFAULT := 0x80000000
CW_USEDEFAULT := i32(_CW_USEDEFAULT)

_IDC_ARROW := rawptr(uintptr(32512))
_IDC_SIZENS := rawptr(uintptr(32645))
_IDC_SIZEWE := rawptr(uintptr(32644))
_IDC_HAND := rawptr(uintptr(32649))

IDC_ARROW := cstring(_IDC_ARROW)
IDC_SIZENS := cstring(_IDC_SIZENS)
IDC_SIZEWE := cstring(_IDC_SIZEWE)
IDC_HAND := cstring(_IDC_HAND)

INVALID_HANDLE :: HANDLE(~uintptr(0))
INVALID_HANDLE_VALUE :: INVALID_HANDLE
