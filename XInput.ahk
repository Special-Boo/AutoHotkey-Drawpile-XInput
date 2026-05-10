
pi := 3.1415926535897932384626433832795
ThumbToAngle(this,Y, X) {
    if this.state['InDeadZone'] = 1
        return 0
    if X = 0
        angle := Y > 0 ? 90 : 270
    else{
        angle := ATan(Y / X) * 180 / pi
        if (X < 0)
            angle += 180
        else if (Y < 0)
            angle += 360
        else if (X = 0)
            angle := 90
    }
    return round(angle)
}


class XInput
{
    static _XInput_hm := DllCall("LoadLibrary", "str", "xinput1_3.dll")
    static _XInput_GetState := DllCall("GetProcAddress", "Ptr", XInput._XInput_hm, "uint", 100)    ; guide/home button works with this. __stdcall int secret_get_gamepad (int, XINPUT_GAMEPAD_SECRET*)
    static _XInput_SetState := DllCall("GetProcAddress", "Ptr", XInput._XInput_hm, "AStr", "XInputSetState")
    static _XInput_GetKeystroke := DllCall("GetProcAddress", "Ptr", XInput._XInput_hm, "AStr", "XInputGetKeystroke")
    static _XInput_GetCapabilities := DllCall("GetProcAddress", "Ptr", XInput._XInput_hm, "AStr", "XInputGetCapabilities")
    static _XInput_GetBatteryInformation := DllCall("GetProcAddress", "Ptr", XInput._XInput_hm, "AStr", "XInputGetBatteryInformation")
    static instances := 0
    static XINPUT_GAMEPAD_DPAD_UP := 0x0001
    static XINPUT_GAMEPAD_DPAD_DOWN := 0x0002
    static XINPUT_GAMEPAD_DPAD_LEFT := 0x0004
    static XINPUT_GAMEPAD_DPAD_RIGHT := 0x0008
    static XINPUT_GAMEPAD_START := 0x0010
    static XINPUT_GAMEPAD_BACK := 0x0020
    static XINPUT_GAMEPAD_THUMB := 0x0040
    static XINPUT_GAMEPAD_RIGHT_THUMB := 0x0080
    static XINPUT_GAMEPAD_SHOULDER := 0x0100
    static XINPUT_GAMEPAD_RIGHT_SHOULDER := 0x0200
    static XINPUT_GAMEPAD_GUIDE := 0x0400
    static XINPUT_GAMEPAD_A := 0x1000
    static XINPUT_GAMEPAD_B := 0x2000
    static XINPUT_GAMEPAD_X := 0x4000
    static XINPUT_GAMEPAD_Y := 0x8000

    __new(UserIndex)
    {
        ;OnExit, XInput_Term__
        if !(XInput._XInput_GetState && XInput._XInput_SetState && XInput._XInput_GetKeystroke && XInput._XInput_GetCapabilities && XInput._XInput_GetBatteryInformation) {
            MsgBox "Failed to initialize XInput: function not found."
            return
        }

        this.state := Map()
        this.last_visit := Map()
        this.button_flag_sequence := Map()

        this.state['UserIndex'] := UserIndex
        this.state['DeadZone'] := 30
        this.state['InDeadZone'] := 1
        this.state['TestMenu'] := 0

        button_list := ["DPAD_UP","DPAD_DOWN",'DPAD_LEFT','DPAD_RIGHT'
                        ,'START','BACK','THUMB','SHOULDER'
                        ,'GUIDE','A','B']

        for button in button_list
        {
            this.state[button] := False
            this.last_visit[button] := A_TickCount
            this.button_flag_sequence[button] := [0,0]
        }


        stick_list := ['TRIGGER','RIGHT_TRIGGER','ThumbX','ThumbY', 'Angle'
                        ,'UP','DOWN','LEFT','RIGHT','InDeadZone']
        for stick in stick_list
        {
            this.state[stick] := 0
        }


        XInput.instances++
        return this
    }


    /*
    *   Unloads XInput library/dll if it has been previously loaded.
    */
    __delete() {
        if !(--XInput.instances) {
            DllCall("FreeLibrary", "uint", XInput._XInput_hm)
            XInput._XInput_hm := XInput._XInput_GetState := XInput._XInput_SetState := XInput._XInput_GetKeystroke := XInput._XInput_GetCapabilities := XInput._XInput_GetBatteryInformation := 0
        }
    }

    XInput_GetStateRepeat() {
        func := objBindMethod(this, "XInput_GetState")
        SetTimer(func, 10)
    }

    XInput_TestMenu(value)
    {
        this.state['TestMenu'] := value
    }

    _XInput_TestMenu() {
        ListLines(0)
        str := ""
        list := ["DPAD_UP","DPAD_DOWN",'DPAD_LEFT','DPAD_RIGHT'
                ,'START','BACK','THUMB','SHOULDER',
                'GUIDE','A','B'
                ,'TRIGGER','ThumbX','ThumbY','InDeadZone', 'Angle', 'BatteryType', 'BatteryLevel']

        for input in list
        {
            if this.last_visit.has(input)
                {
                    time := Round((A_TickCount - this.last_visit[input])/1000, 2)
                    time := time < 1 ? time : 1
                }
            else
                time := "None"
            str.= input ' : ' this.state[input] ', ' time '`n'
        }

        ToolTip(str)
    }

    XInput_GetState() {
        ListLines(0)

        xiState := Buffer(16)
        DllCall(XInput._XInput_GetState, "uint", this.state['UserIndex'], "Ptr", xiState)
        PacketNumber := NumGet(xiState, 0, "UInt")
        wButtons := NumGet(xiState, 4, "UShort")
        LeftTrigger := NumGet(xiState, 6, "UChar")
        RightTrigger := NumGet(xiState, 7, "UChar")
        ThumbLX := NumGet(xiState, 8, "Short")
        ThumbLY := NumGet(xiState, 10, "Short")
        ThumbRX := NumGet(xiState, 12, "Short")
        ThumbRY := NumGet(xiState, 14, "Short")

        button_list := ["DPAD_UP","DPAD_DOWN",'DPAD_LEFT','DPAD_RIGHT'
                        ,'START','BACK','THUMB','SHOULDER'
                        ,'A','B','GUIDE']
        for button in button_list
        {
            if wButtons & XInput.XINPUT_GAMEPAD_%button%
            {   
                if this.state[button] = 0
                    and (A_TickCount - this.last_visit[button])/1000 < 0.2
                    this.state[button] := 2
                else if this.state[button] = 0
                    this.state[button] := 1
                else
                    this.state[button] = 0
            }
            else
            {
                this.state[button] := 0
            }
            
            this.button_flag_sequence[button][2] := this.button_flag_sequence[button][1]
            this.button_flag_sequence[button][1] := this.state[button]
            
            if this.button_flag_sequence[button][2] = 0
            and this.button_flag_sequence[button][1] = 1
                this.last_visit[button] := A_TickCount
        }

        this.state['TRIGGER'] := round(LeftTrigger / 255 * 100)
        this.state['ThumbX'] := ThumbLX >= 0 ? round(ThumbLX / 32767 * 100) : round(ThumbLX / 32766 * 100)
        this.state['ThumbY'] := ThumbLY >= 0 ? round(ThumbLY / 32767 * 100) : round(ThumbLY / 32766 * 100)
        this.state['Angle'] := ThumbToAngle(this,ThumbLX,ThumbLY)

        flag := ""

        if this.state['ThumbX']**2 + this.state['ThumbY']**2 < this.state['DeadZone']**2
            flag := "InDeadZone"
        else {
            if this.state['ThumbY'] < this.state['ThumbX'] {
                if this.state['ThumbY'] > -this.state['ThumbX'] 
                    flag := "RIGHT"
                else 
                    flag := "DOWN"
            }
            else {
                if this.state['ThumbY'] < -this.state['ThumbX']
                    flag := "LEFT"
                else
                    flag := "UP"
            }
        }

        for stick in ['InDeadZone','UP','DOWN','LEFT','RIGHT']
            if stick = flag
                this.state[stick] := 1
            else
                this.state[stick] := 0

        this.XInput_GetBatteryInformation(0,1)

        if this.state['TestMenu'] = True
            this._XInput_TestMenu()
    }

    Xinput_SetDeadzone(DeadZone)
    {
        this.state['DeadZone'] := DeadZone
    }


    XInput_GetKeystroke() {
        xiKeystroke := Buffer(8)

        ;Unicode : NumGet(xiKeystroke, 2, "UShort")
        return {
            (Join,
                VirtualKey: NumGet(xiKeystroke, 0, "UShort")
                Flags: NumGet(xiKeystroke, 4, "UShort")
                UserIndex: NumGet(xiKeystroke, 6, "UChar")
                HidCode: NumGet(xiKeystroke, 7, "UChar")
            )
        }
    }

    XInput_SetState(LeftMotorSpeed, RightMotorSpeed) {
        return DllCall(XInput._XInput_SetState, "uint", this.state['UserIndex'], "uint*", LeftMotorSpeed | RightMotorSpeed << 16) = 0
    }

    XInput_GetCapabilities(Flags := 0) {
        xiCaps := Buffer(20)

        return {
            (Join,
                UserIndex: this.state['UserIndex']
                Type: NumGet(xiCaps, 0 "UChar")
                SubType: NumGet(xiCaps, 1, "UChar")
                Flags: NumGet(xiCaps, 2, "UShort")
                Buttons: NumGet(xiCaps, 4, "UShort")
                LeftTrigger: NumGet(xiCaps, 6, "UChar")
                RightTrigger: NumGet(xiCaps, 7, "UChar")
                ThumbLX: NumGet(xiCaps, 8, "UShort")
                ThumbLY: NumGet(xiCaps, 10, "UShort")
                ThumbRX: NumGet(xiCaps, 12, "UShort")
                ThumbRY: NumGet(xiCaps, 14, "UShort")
                LeftMotorSpeed: NumGet(xiCaps, 16, "UShort")
                RightMotorSpeed: NumGet(xiCaps, 18, "UShort")
            )
        }
    }

    XInput_GetBatteryInformation(UserIndex := 0, DevType := 1) {
        xiBattery := Buffer(8)    ; actually 7 but 8 may have better performance
        DllCall(XInput._XInput_GetBatteryInformation, "uint", UserIndex, "uchar", DevType, "Ptr", xiBattery)
        BatteryType := NumGet(xiBattery, 0, "UChar")
        BatteryLevel := NumGet(xiBattery, 1, "UChar")
        this.state['BatteryType'] := BatteryType
        this.state['BatteryLevel'] := BatteryLevel
        }
}