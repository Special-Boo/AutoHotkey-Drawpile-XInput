class _ClassMemory
{
    ; List of useful accessible values. Some of these inherited values (the non objects) are set when the new operator is used.

    __new(program, is64bit := False)
    {
        ;variables:
        ;   aTypeSize
        ;   aRights
        ;   PID
        ;   hProcess
        ;   currentProgram
        ;   ptrType
        ;   BaseAddress
        ;
        this.currentProgram := program
        this.aTypeSize := Map("UChar", 1, "Char", 1
            , "UShort", 2, "Short", 2
            , "UInt", 4, "Int", 4
            , "UFloat", 4, "Float", 4
            , "Int64", 8, "Double", 8)
        this.aRights := Map("PROCESS_ALL_ACCESS", 0x001F0FFF
            , "PROCESS_CREATE_PROCESS", 0x0080
            , "PROCESS_CREATE_THREAD", 0x0002
            , "PROCESS_DUP_HANDLE", 0x0040
            , "PROCESS_QUERY_INFORMATION", 0x0400
            , "PROCESS_QUERY_LIMITED_INFORMATION", 0x1000
            , "PROCESS_SET_INFORMATION", 0x0200
            , "PROCESS_SET_QUOTA", 0x0100
            , "PROCESS_SUSPEND_RESUME", 0x0800
            , "PROCESS_TERMINATE", 0x0001
            , "PROCESS_VM_OPERATION", 0x0008
            , "PROCESS_VM_READ", 0x0010
            , "PROCESS_VM_WRITE", 0x0020
            , "SYNCHRONIZE", 0x00100000)
        if !this.PID := this.findPID(program)    ; set handle to 0 if program not found
        {
            MsgBox("Failed to get PID")
            return
        }
        if !this.hProcess := this.openProcess(this.PID)    ; NULL/Blank if failed to open process for some reason
        {
            MsgBox("Failed to get HANDLE")
            return    
        }
        this.currentProgram := program
        this.ptrType := ((this.isTarget64bit := is64bit) ? "Int64" : "UInt")
        this.BaseAddress := this.getProcessBaseAddress(program)
        this.address := Map()
        return this
    }


    __delete()
    {
        if !this.PID
            return
        this.closeHandle(this.hProcess)
        ; if this.pNumberOfBytesRead
        ;     DllCall("GlobalFree", "Ptr", this.pNumberOfBytesRead)
        ; if this.pNumberOfBytesWritten
        ;     DllCall("GlobalFree", "Ptr", this.pNumberOfBytesWritten)
        return
    }
    addAddress(name,address)
    {
        this.address[name] := address
        return
    }
    
    getBaseAddress()
    {
        return this.baseAddress
    }

    findPID(program)
    {
        pid := WinGetPID(program)
        return pid ? pid : 0    ; PID is null on fail, return 0
    }

    openProcess(PID)
    {
        dwDesiredAccess := this.aRights["PROCESS_QUERY_INFORMATION"]
        | this.aRights["PROCESS_ALL_ACCESS"]
        | this.aRights["PROCESS_VM_OPERATION"]
        | this.aRights["PROCESS_VM_READ"]
        | this.aRights["PROCESS_VM_WRITE"]
        | this.aRights["SYNCHRONIZE"]
        r := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", pid)
        return r ? r : ""
    }
    
    getAddressFromOffsets(start_address, array_offsets)
    {
        ; If invalid type RPM() returns success (as bytes to read resolves to null in dllCall())
        ; so set errorlevel to invalid parameter for DLLCall() i.e. -2
        ptrType := A_Is64bitOS ? "Int64" : "UInt"
        buf := Buffer(A_PtrSize)
        NumPut(ptrType, start_address, buf)    ;put start address in buf

        if array_offsets.Length
        {
            last_offset := array_offsets.Pop()
            
            for index, offset in array_offsets
            {
                    DllCall("ReadProcessMemory"
                    , "Ptr", this.hProcess
                    , "Ptr", NumGet(buf, 0, ptrType) + offset    ; 버퍼 안에는 next_address 값이 들어있다.
                    , "Ptr", buf    ;write in buf
                    , "UInt", A_PtrSize    ; 마지막에는 주소가 담겨있게 된다.
                    , "UInt", 0)
            }
                
            final_address := NumGet(buf, 0, ptrType) + last_offset
        }
        else final_address := start_address

        return final_address
    }

    read(type, start_address, array_offsets)
    {
        buf := Buffer(this.aTypeSize[type])
        DllCall("ReadProcessMemory"
            , "Ptr", this.hProcess
            , "Ptr", this.getAddressFromOffsets(start_address, array_offsets)
            , "Ptr", buf    ;write in buf
            , "UInt", this.aTypeSize[type]
            , "UInt", 0)
        return NumGet(buf, 0, type)
    }

    write(type, input, start_address, array_offsets)
    {
        buf := Buffer(this.aTypeSize[type])
        NumPut(type, input, buf)
        whathappened := DllCall("WriteProcessMemory"
            , "Ptr", this.hProcess
            , "Ptr", this.getAddressFromOffsets(start_address, array_offsets)
            , "Ptr", buf    ;write from buf
            , "UInt", this.aTypeSize[type]
            , "UInt", 0)
        return whathappened
    }

    getProcessBaseAddress(windowTitle)
    {
        hwnd := WinExist(windowTitle)
        ; GetWindowLong returns a Long (Int) and GetWindowLongPtr return a Long_Ptr
        baseaddress := DllCall(A_PtrSize = 4    ; If DLL call fails, returned value will = 0
            ? "GetWindowLong"
            : "GetWindowLongPtr"
            , "Ptr", hwnd, "Int", -6, A_Is64bitOS ? "Int64" : "UInt")
        return baseaddress

        ; For the returned value when the OS is 64 bit use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
        ; however if the OS is 32 bit, must use UInt, otherwise the number will be huge (however it will still work as the lower 4 bytes are correct)
        ; Note - it's the OS bitness which matters here, not the scripts/AHKs
    }


    ; Method:            getModuleBaseAddress(module := "", byRef aModuleInfo := "")
    ; Parameters:
    ;   moduleName -    The file name of the module/dll to find e.g. "calc.exe", "GDI32.dll", "Bass.dll" etc
    ;                   If no module (null) is specified, the address of the base module - main()/process will be returned
    ;                   e.g. for calc.exe the following two method calls are equivalent getModuleBaseAddress() and getModuleBaseAddress("calc.exe")
    ;   aModuleInfo -   (Optional) A module Info object is returned in this variable. If method fails this variable is made blank.
    ;                   This object contains the keys: name, fileName, lpBaseOfDll, SizeOfImage, and EntryPoint

    getModuleBaseAddress(moduleName := "")
    {
        if !moduleName
            moduleName := this.GetModuleFileNameEx(0, True)    ; 모듈 이름이 없으면 메인 exe파일 이름으로. calc.exe

        if r := this.getModules(&Modules) < 0
            return r    ; -4, -3

        this.Modules := Modules

        if this.Modules.Has(moduleName)
            return this.Modules[moduleName].lpBaseOfDll
        return
        ; no longer returns -5 for failed to get module info
    }


    ; Method:               getModules(byRef aModules, useFileNameAsKey := False)
    ;                       Stores the process's loaded modules as an array of (object) modules in the aModules parameter.
    ; Parameters:
    ;   aModules            An unquoted variable name. The loaded modules of the process are stored in this variable as an array of objects.
    ;                       Each object in this array has the following keys: name, fileName, lpBaseOfDll, SizeOfImage, and EntryPoint.
    ;   useFileNameAsKey    When true, the file name e.g. GDI32.dll is used as the lookup key for each module object.
    ; Return Values:
    ;   Positive integer    The size of the aModules array. (Success)
    ;   -3                  EnumProcessModulesEx failed.
    ;   -4                  The AHK script is 32 bit and you are trying to access the modules of a 64 bit target process.

    getModules(&Modules, useFileNameAsKey := False)    ; Modules 는 출력이다.
    {
        if (A_PtrSize = 4 && this.IsTarget64bit)
            return -4    ; AHK is 32bit and target process is 64 bit, this function wont work

        Modules := Map()
        ModuleInfo := Object()

        moduleCount := this.EnumProcessModulesEx(&lphModule)
        if !moduleCount
            return -3

        loop moduleCount
        {
            hModule := NumGet(lphModule, (A_index - 1) * A_PtrSize, "Int64")    ;hModule is handler Module (pointer to Module)
            this.GetModuleInformation(hModule, &ModuleInfo)

            ModuleInfo.Path := this.GetModuleFileNameEx(hModule)    ;A\B\C\D.dll

            SplitPath(ModuleInfo.Path, &fileName)    ; D.dll
            ModuleInfo.FileName := fileName    ; D.dll

            Modules[fileName] := ModuleInfo
        }
        return moduleCount
    }

    ; lpFilename [out]
    ; A pointer to a buffer that receives the fully qualified path to the module.
    ; If the size of the file name is larger than the value of the nSize parameter, the function succeeds
    ; but the file name is truncated and null-terminated.
    ; If the buffer is adequate the string is still null terminated.


    GetModuleFileNameEx(hModule := 0, fileNameNoPath := False)
    {
        ; ANSI MAX_PATH = 260 (includes null) - unicode can be ~32K.... but no one would ever have one that size
        ; So just give it a massive size and don't bother checking. Most coders just give it MAX_PATH size anyway
        lpFilename := Buffer(2048 * 2)
        DllCall("psapi\GetModuleFileNameEx"
            , "Ptr", this.hProcess
            , "Ptr", hModule
            , "Ptr", lpFilename
            , "Uint", 2048 / 2)
        file := StrGet(lpFilename, "UTF-16")
        if fileNameNoPath
            SplitPath(file, &file)    ; strips the path so = GDI32.dll

        return file
    }

    ; dwFilterFlag
    ;   LIST_MODULES_DEFAULT    0x0
    ;   LIST_MODULES_32BIT      0x01
    ;   LIST_MODULES_64BIT      0x02
    ;   LIST_MODULES_ALL        0x03

    EnumProcessModulesEx(&lphModule, dwFilterFlag := 0x03)
    {
        lastError := A_LastError
        lphModule := Buffer(4)
        reqSize := Buffer(4)
        size := 4
        loop
        {
            DllCall("psapi\EnumProcessModulesEx"
                , "Ptr", this.hProcess
                , "Ptr", lphModule
                , "Uint", size
                , "Ptr", reqSize
                , "Uint", dwFilterFlag)
            if (size >= NumGet(reqSize, "UInt"))
                break
            else
            {
                size := NumGet(reqSize, "UInt")
                lphModule := Buffer(size)
            }
        }
        ; On first loop it fails with A_lastError = 0x299 as its meant to
        ; might as well reset it to its previous version
        DllCall("SetLastError", "UInt", lastError)
        return NumGet(reqSize, 0, "UInt") // A_PtrSize    ; module count  ; sizeof(HMODULE) - enumerate the array of HMODULEs
    }

    GetModuleInformation(hModule, &ModuleInfo)
    {
        MODULEINFO := Buffer(A_PtrSize * 3)
        DllCall("psapi\GetModuleInformation"
            , "Ptr", this.hProcess
            , "Ptr", hModule
            , "Ptr", MODULEINFO
            , "UInt", A_PtrSize * 3)
        ModuleInfo := {
            lpBaseOfDll: NumGet(MODULEINFO, 0, "Ptr")
            , SizeOfImage: NumGet(MODULEINFO, A_PtrSize, "UInt")
            , EntryPoint: NumGet(MODULEINFO, A_PtrSize * 2, "Ptr")
        }
        return ModuleInfo

    }


    closeHandle(hProcess)
    {
        return DllCall("CloseHandle", "Ptr", hProcess)
    }
}