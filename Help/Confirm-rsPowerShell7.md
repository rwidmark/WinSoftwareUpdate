NAME
    Confirm-rsPowerShell7

SYNOPSIS
    Updates PowerShell 7 on supported platforms when a newer release is available.

SYNTAX
    Confirm-rsPowerShell7 [[-SysInfo] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]

DESCRIPTION
    On Windows, the command downloads the latest PowerShell MSI and installs it.
    On macOS, the command upgrades the Homebrew powershell formula when it exists.

PARAMETERS
    -SysInfo <Object>
        Optional cached system information returned by Get-rsSystemInfo.

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. Because the command
        supports ShouldProcess, it also supports WhatIf and Confirm.

RELATED LINKS
    https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
