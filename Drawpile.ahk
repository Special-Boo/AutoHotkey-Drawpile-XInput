DetectHiddenWindows True

#include "%A_ScriptDir%\ClassMemory.ahk"
#include "%A_ScriptDir%\XInput.ahk"
#include "%A_ScriptDir%\VirtualDesktop.ahk"
InstallKeybdHook 1

global coordinfo
coordinfo := Map(
	"Saturation", ["Sliders", "X160 Y70"]
	, "Brightness", ["Sliders", "X160 Y100"]
	, "Red", ["Sliders", "X200 Y150"]
	, "Green", ["Sliders", "X200 Y180"]
	, "Blue", ["Sliders", "X200 Y210"]
	, "Drawpile", ["ahk_class Qt5158QWindowIcon", "X0 Y0"]
	, "Chrome", ["ahk_class Chrome_WidgetWin_1", "X0 Y0"]
	, "Layer1", ["Layer", "X66 Y66"]
	, "Layer2", ["Layer", "X66 Y90"]
	, "Radius", ["Tool", "X130 Y140"]
	, "Opacity", ["Tool", "X130 Y165"]
	, "Stabilizer", ["Tool", "X130 Y233"]
	, "Brush2", ["Tool", "X110 Y10"]
	, "Eraser", ["Tool", "X200 Y10"]
)

global _xpadder, _drawpile
global XButtons
global Zoom_Toggle_Switch
global NowSet

; global LButton_Hotkey
global Mouse_Hold, Processing


global now_Layer 

Now_Layer := 1

NowSet := 1

Zoom_Toggle_Switch := 0

; LButton_Hotkey := 0
Mouse_Hold := 0
Processing := 0

global Saturation, Brightness
Saturation := 0
Brightness := 0
+^d::VirtualDesktopRight()
+^a::VirtualDesktopLeft()

; if WinExist("Slider")
; {
; 	_drawpile := _ClassMemory("Slider")

; 	_drawpile.addAddress('Saturation',_drawpile.getAddressFromOffsets("UChar"
; 																	, _drawpile.GetModuleBaseAddress("Qt5Gui.dll")
; 																	, [0x4E7460, 0x20, 0x30, 0x30, 0x40, 0x28, 0x120]))

; 	_drawpile.addAddress('Brightness',_drawpile.getAddressFromOffsets("UChar"
; 																	, _drawpile.GetModuleBaseAddress("Qt5Gui.dll")
; 																	, [0x4E7460, 0x30, 0x30, 0x68, 0x30, 0x48, 0x28, 0x120])) 
; }
; else
; 	MsgBox("Failed to load memory -- Drawpile")

; if WinExist("Slider")
; {
; 	_drawpile := _ClassMemory("Brushes",True)

; 	_drawpile.addAddress('Brush Angle',_drawpile.getAddressFromOffsets(_drawpile.getModuleBaseAddress("Qt5Gui.dll") + 0x68DB20
; 																	,[0x0,0x30,0x30,0x1F0,0x30,0x1128,0x58794]))
; 	_drawpile.addAddress('Brush Angle2',_drawpile.getAddressFromOffsets(_drawpile.getModuleBaseAddress("Qt5Gui.dll") + 0x68DB20
; 																	,[0x0,0x18,0x30,0x30,0x238,0x1128,0x58794]))
; }
; else
; 	MsgBox("Failed to load memory -- Drawpile")

; Xpadder(set := -1)
; {
; 	if set = -1
; 		return _xpadder.read("UChar", _xpadder.address["XpadderSet"],[]) + 1
; 	else if (1 <= set and set <= 8) {
; 		_xpadder.write("UChar", set - 1, _xpadder.address["XpadderSet"],[])
; 	}

; }

PS_NAVI := XInput(0)
PS_NAVI.XInput_GetStateRepeat()
; PS_NAVI.XInput_TestMenu(1)

SetTimer(xpadder_mini, 30)

UpdateCoordInfo(name,xpos,ypos)
{
	global coordinfo
	CoordInfo[name][2] := "X" String(xpos) " Y" String(ypos)
}

PS_NAVI_ButtonState(input_expression) {
	split_str_arr := StrSplit(input_expression, A_Space)

	input := split_str_arr[1]
	expression := split_str_arr[2]
	value := split_str_arr[3]

	return expression = "<" ? PS_NAVI.state[input] < value
		: expression = ">" ? PS_NAVI.state[input] > value
		: expression = "=" ? PS_NAVI.state[input] = value
		: PS_NAVI.state[input] != value
}

click_1(name)
{
	ControlClick(coordinfo[name][2], coordinfo[name][1])
	ControlClick("X0 Y0", "ahk_class Qt5158QWindowIcon")
}
click_2(name)
{
	ControlClick(coordinfo[name][2], coordinfo[name][1], , , 2)
}

setText(name, input, LR)
{

	if LR = "RIGHT"
	{
		SetControlDelay 25
		ControlClick(coordinfo[name][2], coordinfo[name][1], ,"RIGHT" , 1)
	}
	else if LR = "LEFT"
	{
		SetControlDelay 0
		ControlClick(coordinfo[name][2], coordinfo[name][1], ,"LEFT" , 2)
	}
	ControlSendText(input, , coordinfo[name][1])
}

getText(name)
{
	A_Clipboard := ""
	click_2(name)
	SendInput "{CtrlDown}c{CtrlUp}"
	ClipWait 0.5
	return A_Clipboard
}

; getRecentRGB()
; {
; 	WinGetPos(&x,&y,&w,&h,"Slider")
; 	MsgBox("x:" x "Y : " y)
; 	RGBInt := Integer(PixelGetColor(x + 37, y + 15))
; 	Blue := RGBint & 255
; 	Green := (RGBint >> 8) & 255
; 	Red := (RGBint >> 16) & 255
; 	return [Red, Green, Blue]
; }

getMousePosRGB()
{
	MouseGetPos &X, &Y
	RGBInt := Integer(PixelGetColor(X, Y))
	Blue := RGBint & 255
	Green := (RGBint >> 8) & 255
	Red := (RGBint >> 16) & 255
	return [Red, Green, Blue]
}

Turbo_Sleep(On := True, start := 0.15, min := 0.03, decay := 0.9)
{
	static t_min := min	; fastsest repeat rate allowed (seconds)
	static t_decay := decay
	static t := start	; init delay (seconds)

	(On = True)
	? (Sleep(t * 1000), t := Max(t *= t_decay, t_min))
	: (t := start)
	return t <= t_min ? 1 : 0
}

StartMoveColorV2()
{
	SetControlDelay -1
	stride := 3
	global brightness

	WinGetPos(&x, &y, &w, &h, "Sliders")
	BrightnessXpos := w - 40
	BrightnessYpos := 115
	UpdateCoordInfo("Brightness",BrightnessXpos,BrightnessYpos)

	while PS_NAVI_ButtonState("InDeadZone = 0") | PS_NAVI_ButtonState("TRIGGER > 10") 
	{
		if PS_NAVI_ButtonState("UP = 1")
			|| PS_NAVI_ButtonState("DOWN = 1")
		{
			PS_NAVI_ButtonState("UP = 1") ? SendInput("{]}") : SendInput("{[}")
			Sleep(20)
		}
		else if PS_NAVI_ButtonState("InDeadZone = 0")
		{

			brightness := PS_NAVI_ButtonState("RIGHT = 1") ? MIN(brightness + stride, 255) : MAX(brightness - stride, 0)
			setText("Brightness", brightness, "LEFT")

			if not PS_NAVI_ButtonState("TRIGGER > 10")
				Sleep(75)
			else
				Sleep(10)
			; Turbo_Sleep(True) ? stride++ : stride	
		}
		else {
			Sleep(10)
		}
	}
	; Turbo_Sleep(False)
	click_Drawpile()
}

StartMoveSize()
{
	while PS_NAVI_ButtonState("InDeadZone = 0")
		{
			if PS_NAVI_ButtonState("UP = 1")
				|| PS_NAVI_ButtonState("DOWN = 1")
			{
				PS_NAVI_ButtonState("UP = 1") ? SendInput(']') : SendInput('[')
			}
			else
			{
				Do_Nothing()
				
			}
			Sleep(25)
		}
}

atan2(y,x) {
	Return atan(y/x)+4*atan((x<0)*((y>0)-(y<0)))
}

GetAngle(x1, y1, x2, y2)
{
	; 두 점 사이의 거리를 계산합니다.
	d := sqrt(abs(x2 - x1) ^ 2 + abs(y2 - y1) ^ 2)
	
	; y축의 양의 방향으로의 선의 기울기를 계산합니다.
	m := (y2 - y1) / (x2 - x1)
	
	; 두 점 사이의 각도를 계산합니다.
	angle := atan2(y2 - y1, x2 - x1)
	
	; 각도를 라디안에서 도 단위로 변환합니다.
	angle := angle * 180 / 3.141592653589793
	
	; 각도를 반올림합니다.
	angle := Round(angle)
	
	; 각도를 반환합니다.
	Return angle
}


; Set_Brush_Angle(XInputState)
; {
	
; 		MouseGetPos(&x_start, &y_start)

; 		while PS_NAVI_ButtonState(XInputState)
; 			Sleep(20)
; 		MouseGetPos(&x_end, &y_end)

; 		Angle := GetAngle(x_start, y_start, x_end, y_end)
; 		Angle := Angle + 90 > 360 ? Angle - 360 : Angle + 90
; 		_drawpile.write("Float", Angle, _drawpile.address["Brush Angle"],[])
; 		_drawpile.write("Float", Angle, _drawpile.address["Brush Angle2"],[])
	
; }

xpadder_mini()
{
	ListLines(0)
	global NowSet
	PS_NAVI.Xinput_SetDeadzone(65)
	; if Xpadder() != 3
	; 	MAP_PS_NAVI("SHOULDER = 1"
	; 		, [SetDeadzone_30]
	; 		, [THUMB_Brightness, LEFT_DestopLeft, Right_DesktopRight])
	MAP_PS_NAVI("B = 1"	; Temporary Switch Virtual Desktop
		, [VirtualDesktopRight,Top_Chrome], [TRIGGER_ColorFilter], [VirtualDesktopLeft])

	if !Drawpile() and !CSP() {
		MAP_PS_NAVI("RIGHT = 1"
			, [], [Volume_Up, TurboSleepOn], [TurboSleepOff])
		MAP_PS_NAVI("LEFT = 1"
			, [], [Volume_DOWN, TurboSleepOn], [TurboSleepOff])
		MAP_PS_NAVI("THUMB = 1", [SendInput.Bind("{LWIN Down}{Shift Down}{s}{LWIN Up}{Shift Up}")])

	}

	; if CSP() {
	; 	MAP_PS_NAVI("DPAD_LEFT = 1"
	; 		, [SendInput.Bind("{Ctrl Down}{z}{Ctrl Up}")])

	; 	MAP_PS_NAVI("A = 1"
	; 		, [SendInput.Bind("{Ctrl Down}{Shift Down}{z}{Shift Up}{Ctrl Up}")])

	; 	if NowSet = 1 || NowSet = 2 {
	; 		; MoveToDirection(65, 100)

	; 			; if Xpadder() != 3
	; 		MAP_PS_NAVI("SHOULDER = 1"
	; 		, [Set_8,AirBrush]
	; 		, [StartMoveSize]
	; 		, [Set_1,Pen])

	; 		MAP_PS_NAVI("TRIGGER > 10"	; Darkpen
	; 			, [DarkPen], [], [Pen])

	; 		; MAP_PS_NAVI("THUMB = 1"
	; 		; 	, [], [StartMove], []) ; Temporary Brush

	; 		; MAP_PS_NAVI("GUIDE = 1"	; AirBrush
	; 		; 	, [Set_8,AirBrushEraser]
	; 		; 	, [StartMoveSize]	;should Block other buttonPress in this state
	; 		; 	, [Set_1, Pen])


	; 		MAP_PS_NAVI("DPAD_UP = 1"	; Select Tool
	; 			, [Select], [TRIGGER_Del], [Pen])


	; 		; MAP_PS_NAVI("DPAD_RIGHT = 1"
	; 			; , [Replace_LButton.Bind(1), Eraser], [Mouse_Lock], [Pen,Replace_LButton.Bind(0)])


	; 		MAP_PS_NAVI("DPAD_DOWN = 1"	; To Brush
	; 			, [])
	; 	}
	; }

	if Drawpile() {

		MAP_PS_NAVI("DPAD_LEFT != 0"
			, [Undo])

		MAP_PS_NAVI("A != 0"
			, [Redo])

		if NowSet = 1 || NowSet = 2 {
			; MoveToDirection(65, 100)

			MAP_PS_NAVI("InDeadZone = 0",[StartMoveCanvas])

			MAP_PS_NAVI("SHOULDER = 1"
				, [Smudge],[],[Pen])

			MAP_PS_NAVI("THUMB = 1"
				, [Zoom_Toggle])

			MAP_PS_NAVI("THUMB = 2"
				, [Save])

			MAP_PS_NAVI("TRIGGER > 5"	; Darkpen
				, [DarkPen], [Shoulder_Expand], [Pen])

			; MAP_PS_NAVI("THUMB = 1"
			; 	, [], [StartMove], []) ; Temporary Brush

			; MAP_PS_NAVI("GUIDE = 1"	; AirBrush
			; 	, [Set_8,AirBrushEraser]
			; 	, [StartMoveSize]	;should Block other buttonPress in this state
			; 	, [Set_1, Pen])

			if NowSet != 3
				MAP_PS_NAVI("GUIDE = 1"
				, [Set_8, Layer2, AirBrush]
				, [StartMoveSize]
				, [Set_1, Layer1, Pen])

			MAP_PS_NAVI("DPAD_UP = 1"	; Select Tool
				, [Select], [TRIGGER_Del, CopyPaste.Bind("SHOULDER = 1"), StartMoveCanvas], [Pen])
				

			MAP_PS_NAVI("DPAD_RIGHT != 0"
				, [click_Layer1, Eraser], [TRIGGER_Opacity, DOWN_Size_Down, UP_Size_Up], [Eraser, Pen])


			MAP_PS_NAVI("DPAD_DOWN = 1"	; To Brush
				, [Brush, click_Layer2, Set_3])

			
		}
		if NowSet = 3 {
			MAP_PS_NAVI("InDeadZone = 0",[StartMoveColorV2])
				

			; MAP_PS_NAVI("SHOULDER = 1"
			; , [SHOULDER_Brush_Angle])

			MAP_PS_NAVI("GUIDE = 1"	; AirBrush
				, [AirBrush]
				, [SHOULDER_BrushSize]
				, [Set_3, Brush])

			MAP_PS_NAVI("DPAD_UP = 1"	; Select Tool
				, [Select], [TRIGGER_Del], [Brush])

			MAP_PS_NAVI("DPAD_RIGHT = 1",
				[Eraser], [TRIGGER_Opacity, DOWN_Size_Down, UP_Size_Up], [Eraser, click_Drawpile, Brush])

			MAP_PS_NAVI("DPAD_DOWN = 1"	; To Pen
				, [Pen, click_Layer1, Set_1])
				
			MAP_PS_NAVI("TRIGGER > 10", [ColorPicker])

			MAP_PS_NAVI("SHOULDER = 1", [AirBrush]
										, [TRIGGER_ColorPicker, StartMoveColorV2]
										, [Brush])
										
			; MAP_PS_NAVI("SHOULDER = 2", [DotPen, Flood], [TRIGGER_ColorPicker, B_AutoClicker],[click_Drawpile, Brush])

		}
	}


	; if Drawpile() {
	; 	MAP_PS_NAVI("DPAD_LEFT = 1"
	; 		, [Undo])

	; 	MAP_PS_NAVI("A = 1"
	; 		, [Redo])

	; 	if Xpadder() = 1 || Xpadder() = 2 {
	; 		; MoveToDirection(65, 100)

	; 			; if Xpadder() != 3
	; 		MAP_PS_NAVI("SHOULDER = 1"
	; 		, [Set_8,AirBrush]
	; 		, [StartMoveSize]
	; 		, [Set_1,Pen])

	; 		MAP_PS_NAVI("TRIGGER > 10"	; Darkpen
	; 			, [DarkPen,draw_start], [], [draw_stop,Pen])

	; 		MAP_PS_NAVI("THUMB = 1"
	; 			, [Eraser,draw_start], [], [Pen,draw_stop]) ; Temporary Brush

	; 		MAP_PS_NAVI("GUIDE = 1"	; AirBrush
	; 			, [Set_8,AirBrushEraser]
	; 			, [StartMoveSize]	;should Block other buttonPress in this state
	; 			, [Set_1, Pen])


	; 		MAP_PS_NAVI("DPAD_UP = 1"	; Select Tool
	; 			, [Select], [], [Eraser, Pen])


	; 		MAP_PS_NAVI("DPAD_RIGHT = 1"
	; 			, [draw_start], [], [draw_stop])


	; 		MAP_PS_NAVI("DPAD_DOWN = 1"	; To Brush
	; 			, [Brush, click_Layer2, Set_3])
	; 	}
	; 	if Xpadder() = 3 {
	; 		if PS_NAVI_ButtonState("InDeadZone = 0")
	; 			StartMoveColorV2()

	; 		MAP_PS_NAVI("SHOULDER = 1"
	; 		, [size_adjust_start], [], [size_adjust_stop])

	; 		MAP_PS_NAVI("GUIDE = 1"	; AirBrush
	; 			, [AirBrush]
	; 			, [TRIGGER_AirBrushEraser, SHOULDER_BrushSize]
	; 			, [Set_3, Brush])

	; 		MAP_PS_NAVI("DPAD_UP = 1"	; Select Tool
	; 			, [Select], [], [Eraser, Brush])

	; 		MAP_PS_NAVI("DPAD_RIGHT = 1",
	; 			[Eraser], [TRIGGER_AirBrushEraser], [click_Drawpile, Brush])

	; 		MAP_PS_NAVI("DPAD_DOWN = 1"	; To Pen
	; 			, [Pen, click_Layer1, Set_1]
	; 		)
	; 	}
	; }
}

VirtualDesktopRight() {
	if GetKeyState("LButton")
		MoveCurrentWindowTo("Right")
	GoToDesktop("Right")
}
VirtualDesktopLeft() {
	if GetKeyState("LButton")
		MoveCurrentWindowTo("Left")
	GoToDesktop("Left")
}
click_Layer1()
{
	global Now_Layer
	if Now_Layer = 1
		return

	CoordMode("Pixel", "Screen")
	WinGetPos(&x, &y, &w, &h, "Layer")
	ImageSearch(&xpos, &ypos, x, y, w, h, "*100 Layer 1.png")
	if !xpos
		ImageSearch(&xpos, &ypos, x, y, w, h, "*100 Layer 1 Selected.png")
	; Click(xpos,ypos)
	ControlClick("X" xpos " Y" ypos, "Layer")

	click_Drawpile()

	Now_Layer := 1
}
click_Layer2()
{
	global Now_Layer
	if Now_Layer = 2
		return
	CoordMode("Pixel", "Screen")
	WinGetPos(&x, &y, &w, &h, "Layer")


	ImageSearch(&xpos, &ypos, x, y, w, h,"*100 Layer 2.png")
	if !xpos
		ImageSearch(&xpos, &ypos, x, y, w, h, "*100 Layer 2 Selected.png")


	if xpos
		; Click(xpos,ypos)
		ControlClick("X" xpos " Y" ypos, "Layer")
	else
	{
		ImageSearch(&xpos, &ypos, x, y, w, h, "*100 Add Layer.png")
		ControlClick("X" xpos - 20 " Y" ypos, "Layer")
		ImageSearch(&xpos, &ypos, x, y, w, h, "*100 Layer 2 Selected.png")
		SendInput("{Click " xpos " " ypos " Down}{click " xpos " " (ypos + 40) " Up}")

	}
	click_Drawpile()
	Now_Layer := 2
}

Top_Chrome()
{
	if WinExist("Chrome")
	{
		state := WinGetMinMax("Chrome")
		if state = 0 {
			WinSetAlwaysOnTop(1, "Chrome")
			WinSetAlwaysOnTop(0, "Chrome")
		}
		else
		{ }
	
	}
	

}

StartMoveCanvas()
{
	MAP_PS_NAVI("InDeadZone = 0",[],[Scroll_Up_Repeat,Scroll_Down_Repeat,Scroll_Left_Repeat,Scroll_Right_Repeat],[])
}

Scroll_Up_Repeat()
{
	while PS_NAVI_ButtonState("UP = 1")
	{
		SendInput("{Up}")
		if PS_NAVI_ButtonState("TRIGGER > 10")
			Sleep(15)
		else
			Sleep(50)
	}
}
Scroll_Down_Repeat()
{
	while PS_NAVI_ButtonState("DOWN = 1")
	{
		SendInput("{Down}")
		if PS_NAVI_ButtonState("TRIGGER > 10")
			Sleep(15)
		else
			Sleep(50)
	}
}
Scroll_Left_Repeat()
{
	while PS_NAVI_ButtonState("LEFT = 1")
	{		
		SendInput("{LEFT}")	
		if PS_NAVI_ButtonState("TRIGGER > 10")
			Sleep(25)
		else
			Sleep(150)
	}
}
Scroll_Right_Repeat()
{
	while PS_NAVI_ButtonState("RIGHT = 1")
	{
		SendInput("{RIGHT}")
		if PS_NAVI_ButtonState("TRIGGER > 10")
			Sleep(25)
		else
			Sleep(150)
	}
}
Scroll_Nothing()
{
	while PS_NAVI_ButtonState("InDeadZone = 1")
		Sleep(30)
}

Shoulder_Expand()
{
		while PS_NAVI_ButtonState('SHOULDER = 1')
			{
				SendInput("{Ctrl Down}{k}{Ctrl Up}")
				Sleep(150)
			}
}

Zoom_Toggle()
{
	global Zoom_Toggle_Switch
	start := A_TickCount

	if Zoom_Toggle_Switch = 0
	{
		SendInput("{Ctrl Down}{+}{Ctrl Up}")
		Zoom_Toggle_Switch := 1
		
		while PS_NAVI_ButtonState("THUMB = 1")
		{
			Sleep(20)
			if (A_TickCount - start)/1000 > 0.3 and Zoom_Toggle_Switch = 1
			{
				SendInput("{Ctrl Down}{+}{Ctrl Up}")
				Zoom_Toggle_Switch := 2
			}
		}
	}
	else
	{
		Zoom_Toggle_Switch = 1
		? SendInput("{Ctrl Down}{-}{Ctrl Up}")
		: SendInput("{Ctrl Down}{-}{-}{Ctrl Up}")
		Zoom_Toggle_Switch := 0
	}



}

CopyPaste(XInput)
{
	if PS_NAVI_ButtonState(XInput)
	{
		SendInput("{Ctrl Down}{c}{Ctrl Up}")
		Sleep(30)
		SendInput("{Ctrl Down}{v}{Ctrl Up}")
		Sleep(30)
		
		while PS_NAVI_ButtonState(XInput)
			Sleep(30)
	}

}

MoveLayer(XInput)
{
	if PS_NAVI_ButtonState(XInput)
	{
		SendInput("{Ctrl Down}{x}{Ctrl Up}")
		Sleep(30)
		click_Layer2()
		Sleep(30)
		click_Drawpile()
		Sleep(30)
		SendInput("{Ctrl Down}{v}{Ctrl Up}")
		Sleep(30)
		SendInput("{Enter}")
		Sleep(30)
		click_Layer1()
		Sleep(30)
		click_Drawpile()
	}
	while PS_NAVI_ButtonState(XInput)
		Sleep(30)
}

AutoClicker(XInput)
{
	While PS_NAVI_ButtonState(XInput)
	{
		SendInput("{Click}")
		Sleep(50)
	}
}

; ColorPicker2 := SendInput.Bind("{Alt Down}{Click}{Alt Up}")
ColorPicker()	; color picker or Brush size adjust
{
	global Saturation, Brightness
	
	SetControlDelay -1
	SendInput("{Ctrl Down}{Alt Down}{Click}{Ctrl Up}{Alt Up}")
	; Sleep(30)
	; rgb_value := getMousePosRGB()

	Red := getText("Red")
	Green := getText("Green")
	Blue := getText("Blue")

	Brightness := Max(Red, Green, Blue)
	Saturation := (Brightness - Min(Red, Green, Blue))

	click_1("Drawpile")
}


; Start_Move_Layer_Together(XInput, XInput_For_Drag)
; {
; 	flag := False
; 	SendInput("{s}")
; 	ToolTip("Recording Drag...")
; 	while PS_NAVI_ButtonState(XInput)
; 	{
; 		if PS_NAVI_ButtonState(XInput_For_Drag)
; 		{
; 			flag := True
; 			break
; 		}
; 	}
	
; 	if flag = False
; 	{
; 		ToolTip("")
; 		SendInput("{r}")
; 		return
; 	}

; 	MouseGetPos(&x_start, &y_start)
; 	SendInput("{LButton Down}")


; 	while PS_NAVI_ButtonState(XInput_For_Drag)
; 		{}
; 	MouseGetPos(&x_end, &y_end)
; 	SendInput("{Lbutton Up}")


; 	ToolTip("Waiting Next Drag...")

; 	flag := False
; 	while PS_NAVI_ButtonState(XInput)
; 		{
; 			if PS_NAVI_ButtonState(XInput_For_Drag)
; 			{
; 				flag := True
; 				break
; 			}
; 		}
	
; 	if flag = False
; 	{
; 		ToolTip("")
; 		SendInput("{r}")
; 		return
; 	}

; 	MouseGetPos(&x_start_2, &y_start_2)
; 	SendInput("{LButton Down}")

; 	while PS_NAVI_ButtonState(XInput_For_Drag)
; 		{}
; 	MouseGetPos(&x_end_2, &y_end_2)
; 	SendInput("{Lbutton Up}")

; 	click_Layer2()
; 	Sleep(50)

; 	Send("{Click " x_start " " y_start " Down}{Click " x_end " " y_end " Down}")
; 	Send("{Click Up}")
; 	Sleep(50)

; 	Send("{Click " x_start_2 " " y_start_2 " Down}{Click " x_end_2 " " y_end_2 " Down}")
; 	Send("{Click Up}")
; 	Sleep(50)
; 	SendInput("{Enter}")
; 	Sleep(50)
; 	SendInput("{r}")
	
; 	click_Layer1()
; 	ToolTip("")
; }


draw_start := SendInput.Bind("{LButton Down}")
draw_stop := SendInput.Bind("{LButton Up}")

SetDeadzone_30 := ObjBindMethod(PS_NAVI, "Xinput_SetDeadzone", 30)
Drawpile := WinActive.Bind("Drawpile",,"ahk")
Chrome := WinActive.Bind("ahk_exe chrome.exe")
CSP := WinActive.Bind("CLIP STUDIO PAINT")
click_Drawpile := ControlClick.Bind("X0 Y0", "ahk_class Qt5158QWindowIcon")

Desktop_Right := GoToDesktop.Bind("Right")
Desktop_Left := GoToDesktop.Bind("Left")

size_adjust_start := SendInput.Bind("{Ctrl Down}{Space Down}")
size_adjust_stop := SendInput.Bind("{Ctrl Up}{Space Up}")

Select := SendInput.Bind("{d}")
DarkPen := SendInput.Bind("{1}")
Pen := SendInput.Bind("{s}")
Brush := SendInput.Bind("{3}")
AirBrush := SendInput.Bind("{4}")
Smudge := SendInput.Bind("{5}")
Flood := SendInput.Bind("{f}")
Eraser := SendInput.Bind("{e}")

Undo := _Undo.Bind("DPAD_LEFT != 0")
Redo := _Redo.Bind("A != 0")
Save := SendInput.Bind("{Ctrl Down}{s}{Ctrl Up}")


Layer1 := click_1.Bind("Layer1")
Layer2 := click_1.Bind("Layer2")
Opacity_70 := setText.Bind("Opacity", 70, "RIGHT")
Opacity_100 := setText.Bind("Opacity", 100, "RIGHT")
Stabilizer_30 := setText.Bind("Stabilizer", 30, "RIGHT")
Stabilizer_60 := setText.Bind("Stabilizer", 60, "RIGHT")

Slot1()
{
	ControlClick("X10 Y140","Tool")
	click_Drawpile()
	while PS_NAVI_ButtonState("TRIGGER > 10")
	{
		SendInput("{]}")
		Sleep(25)
	}
}

Brush_Size_Up(XInputState)
{
	while PS_NAVI_BUTTONSTATE(XinputState){
		SendInput("{]}")
		Sleep(30)
	}
}

Brush_Size_Down(XInputState)
{
	while PS_NAVI_BUTTONSTATE(XinputState){
		SendInput("{[}")
		Sleep(30)

	}
}

UP_Size_Up := Brush_Size_UP.Bind("UP = 1")
DOWN_Size_Down := Brush_Size_Down.Bind("DOWN = 1")

ChangeSet(num := -1)
{
	global NowSet
	if num = -1
		return NowSet
	else
		NowSet := num
}

Set_1 := ChangeSet.Bind(1)
Set_3 := ChangeSet.Bind(3)
Set_8 := ChangeSet.Bind(8)


B_AutoClicker := AutoClicker.Bind("B = 1")

SHOULDER_DrawLine := DrawLine.Bind("SHOULDER = 1")
; SHOULDER_Brush_Angle := Set_Brush_Angle.Bind("SHOULDER = 1")
SHOULDER_Layer := MAP_PS_NAVI.Bind("SHOULDER = 1", [click_Layer2], [], [click_Layer1])
SHOULDER_BrushSize := MAP_PS_NAVI.Bind("SHOULDER = 1", [size_adjust_start], [], [size_adjust_stop])

TRIGGER_ColorFilter := MAP_PS_NAVI.Bind("TRIGGER > 10", [ColorFilterOn], [], [ColorFilterOff])
TRIGGER_Opacity := MAP_PS_NAVI.Bind("TRIGGER > 10", [Opacity_70,click_Drawpile], [], [Opacity_100,click_Drawpile])
; TRIGGER_AirBrushEraser := MAP_PS_NAVI.Bind("TRIGGER > 10", [DotPen], [], [AirBrush])
TRIGGER_ColorPicker := MAP_PS_NAVI.Bind("TRIGGER > 10", [ColorPicker])
TRIGGER_Del := MAP_PS_NAVI.Bind("TRIGGER > 10", [SendInput.Bind("{Del}")])

; DPAD_UP_TRIGGER_Start_Move_Layer_Together := Start_Move_Layer_Together.Bind("DPAD_UP = 2","TRIGGER > 10")

THUMB_Brightness := MAP_PS_NAVI.Bind("THUMB = 1", [SendInput.Bind("{vkFFsc13B}")])
LEFT_DestopLeft := MAP_PS_NAVI.Bind("LEFT = 1", [VirtualDesktopLeft])
Right_DesktopRight := MAP_PS_NAVI.Bind("RIGHT = 1", [VirtualDesktopRight])

Volume_Up := SendInput.Bind("{Volume_Up}")
Volume_Down := SendInput.Bind("{Volume_Down}")

TurboSleepOn := Turbo_Sleep.Bind(True)
TurboSleepOff := Turbo_Sleep.Bind(False)

_Undo(XInput)
{
	start := A_TickCount

	SendInput("{Ctrl Down}{z}{Ctrl Up}")

	while PS_NAVI_ButtonState(XInput)
	{
		if (A_TickCount - start)/1000 > 0.2
			{
				SendInput("{Ctrl Down}{z}{Ctrl Up}")
				TurboSleepOn()
			}	
		else
		{ }
	}
	TurboSleepOff()
}

_Redo(XInput)
{
	start := A_TickCount

	SendInput("{Shift Down}{z}{Shift Up}")

	while PS_NAVI_ButtonState(XInput)
	{
		if (A_TickCount - start)/1000 > 0.2
			{
				SendInput("{Shift Down}{z}{Shift Up}")
				TurboSleepOn()
			}	
		else
		{ }
	}
	TurboSleepOff()
}

HoverDraw(Xinput_State)
{
	SendInput("{5}{LButton Down}")
	while PS_NAVI_ButtonState(Xinput_State)
		Sleep(10)
	SendInput("{LButton Up}{r}")
}

DrawLine(Xinput_State)
{
	SetDefaultMouseSpeed 0

	MouseGetPos(&x_start, &y_start)
	
	while PS_NAVI_ButtonState(Xinput_State)
		Sleep(20)
	MouseGetPos(&x_end, &y_end)


	setText("Stabilizer",0, "RIGHT")
	click_1("Drawpile")
	Send("{Click " x_start " " y_start " Down}{Click " x_end " " y_end " Down}")
	Send("{Click Up}")
	setText("Stabilizer",94, "RIGHT")	
	click_1("Drawpile")

}

ToggleColorFilter()
{
	SendInput("{Ctrl Down}{LWin Down}{c}{LWin Up}{Ctrl Up}")
}

ColorFilterOn()
{
	Enabled := ColorFilterCheck()
	if !Enabled
		ToggleColorFilter()
}
ColorFilterOff()
{
	Enabled := ColorFilterCheck()
	if Enabled
		ToggleColorFilter()
}

MAP_PS_NAVI(Status, sequentialFunctionLists*)
{
	StartFuncs := []
	HoldFuncs := []
	EndFuncs := []

	queue := ['StartFuncs','HoldFuncs','EndFuncs']

	for index, functionList in sequentialFunctionLists
		%queue[index]% := functionList
	
	if PS_NAVI_ButtonState(Status) {
		for infunc in StartFuncs
			infunc()
		While PS_NAVI_ButtonState(status)
		{
			for holdfunc in HoldFuncs
				holdfunc()
		}
		for outfunc in EndFuncs
			outfunc()
	}
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; F1::	; Moving Color Pos
; {
; 	while !fKeyState(&F2, &F3, &F4, &F5) {
; 	}

; 	SetControlDelay -1
; 	StartMoveColor(F2, F3, F4, F5)
; }

; Format("{1:x}", )

; Replace_LButton(value)
; {
; 	global LButton_Hotkey
; 	LButton_Hotkey := value
; }

Mouse_Lock()
{
	global Mouse_Hold
	while Mouse_Hold = 1
		Sleep(10)
}

; #HotIf LButton_Hotkey
; {
; 	LButton::
; 	{
; 		global Mouse_Hold
; 		SendInput("{LButton Down}")
; 		Mouse_Hold := 1
; 	}
	
; 	LButton Up::
; 	{
; 		global Mouse_Hold
; 		SendInput("{LButton Up}")
; 		Mouse_Hold := 0
; 	}
; }
; #HotIf


; ^t::
; {
; 	; 0x250,0x8,0xD0,0x30,0x1128,0x58794
; 	msg := _drawpile.write("Float",100,_drawpile.address["Brush Angle"],[])
; 	msg := _drawpile.read("Float",_drawpile.address["Brush Angle"],[])
; 	ToolTip(msg)
; 	Sleep(500)
; 	ToolTip("")
; }

^g::
{
	global NowSet
	Set_1()
	MsgBox(NowSet)
}

F8::	;브러쉬 사이즈 변경
{
	SetControlDelay -1
	SendInput("{Ctrl Down}{Space Down}")
	while GetKeyState("F8", "P")
		Sleep(30)
	SendInput("{Ctrl Up}{Space Up}")

}


^1::
{
	If WinExist("Layer")
		WinMove 34,	3, 207, 159, "Layer"
	If WinExist("Sliders")
		WinMove 34 , 170	, 208	,243, "Sliders"
	If WinExist("Tool - ")
		WinMove 34,575	,295	,295, "Tool - "
	If WinExist("Brush")
		WinMove 34  ,872	,293	,181, "Brush"
	if WinExist("X0 Y0", "ahk_class Qt5158QWindowIcon")
		WinMove(305, 19, 1419, 1065, "X0 Y0", "ahk_class Qt5158QWindowIcon")
	if WinExist("Chrome")
		WinMove(682, 50, 1061, 961, "Chrome")
}



RButton::
{
	ListLines(0)
	RButton()
}

RButton(*)
{
	ListLines(0)
	global XButtons
	XButtons := 0
	if XButtons
		return
	else
	{
		SendInput("{RButton Down}")
		KeyWait("RButton")
		SendInput("{RButton Up}")
	}
}

XButton1::
{
	ListLines(0)

	global XButtons
	Xbuttons := True
	Hotkey("RButton", (*) => "", "On")
	while GetKeyState("XButton1", "P")
	{
		SendInput("{WheelDown}")
		GetKeyState("RButton", "P") ? Sleep(20) : Sleep(50)
	}
	Hotkey("RButton", RButton)
}

Xbutton2::
{
	ListLines(0)

	global XButtons
	Xbuttons := True
	Hotkey("RButton", (*) => "", "On")
	While GetKeyState("XButton2", "P")
	{
		SendInput("{WheelUp}")
		GetKeyState("RButton", "P") ? Sleep(20) : Sleep(50)
	}
	Hotkey("RButton", RButton)
}

^r::
{
	MsgBox("Reloading...", , "T0.3")
	Reload
}

; #c::
; {
; 	ColorFilterCheck()
; }

Volume_Mute::MButton



ColorFilterCheck()
{
	FilterEnabled := RegRead("HKEY_CURRENT_USER\Software\Microsoft\ColorFiltering", "Active")
Return FilterEnabled
}

Do_Nothing()
{
	
}

^T::
{
	A_Clipboard := FormatTime(,"ORA yyyy-MM-dd HH'시'")
}

MButton::
{
	MouseGetPos(&x1,&y1)
	while(GetKeyState("MButton","P")){
		Sleep(30)
	}
	MouseGetPos(&x2,&y2)
	if (x1 = x2) & (y1 = y2){
		SendInput("{MButton}")
	}

	if (x1 < x2) & (Abs(x2-x1) > 100)
		VirtualDesktopRight()
	else if (x1 > x2) & (Abs(x2-x1) > 100)
		VirtualDesktopLeft()
	else if (y2 < y1) & (Abs(y2-y1) > 100)
		SendInput("{LWin Down}{tab}{Lwin Up}")
	else if (y2 > y1) & (Abs(y2-y1) > 100)
		SendInput("{Lwin Down}{d}{LWin Up}")

}
		