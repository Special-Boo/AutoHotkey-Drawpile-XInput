hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", A_ScriptDir . "\virtual-desktop-accessor.dll", "Ptr")
global IsWindowOnDesktopNumberProc
:= DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
global MoveWindowToDesktopNumberProc
:= DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
global GoToDesktopNumberProc
:= DllCall("GetProcAddress","Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
global GetCurrentDesktopNumberProc
:= DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
global GetDesktopCountProc
:= DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")

GetCurrentDesktop() {
    return DllCall(GetCurrentDesktopNumberProc)
}

GetDesktopCount() {
    return DllCall(GetDesktopCountProc)
}

GoToDesktop(Right_or_Left)
{
    if Right_or_Left = "Right"
        SendInput("{Ctrl Down}{LWin Down}{Right}{Ctrl Up}{LWin Up}")
    else if Right_or_Left = "Left"
        SendInput("{Ctrl Down}{LWin Down}{Left}{Ctrl Up}{LWin Up}")
    else
        throw "Got nor 'Right' or 'Left'"
}

MoveCurrentWindowTo(Right_or_Left)
{
    id := WinGetId("A")
    CurrentDesktop := GetCurrentDesktop()

    if Right_or_Left = "Right"
        index := Min(CurrentDesktop + 1, GetDesktopCount() - 1)
    else if Right_or_Left = "Left"
        index := Max(0, CurrentDesktop - 1)
    else
        throw "Got nor 'Right' or 'Left'"

    DllCall(MoveWindowToDesktopNumberProc, "UInt", id, "UInt", index)
}
