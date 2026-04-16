NAME
    Confirm-rsDependency

SYNOPSIS
    Validates platform-specific prerequisites for Update-RSWinSoftware.

SYNTAX
    Confirm-rsDependency [[-SysInfo] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]

DESCRIPTION
    On Windows, the command installs missing Microsoft.VCLibs and Microsoft.UI.Xaml
    dependencies, updates PowerShell 7 when applicable, and validates WinGet.

    On macOS, the command verifies that Homebrew is available and updates the
    Homebrew PowerShell formula when it is installed.

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
