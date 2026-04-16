NAME
    Confirm-rsWinGet

SYNOPSIS
    Updates WinGet on Windows when a newer release is available.

SYNTAX
    Confirm-rsWinGet [[-SysInfo] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]

DESCRIPTION
    The command checks the latest GitHub release metadata for WinGet and installs
    the newest msixbundle package when the installed version is older.

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
