NAME
    Update-RSWinSoftware

SYNOPSIS
    Updates supported software on Windows with WinGet or on macOS with Homebrew.

SYNTAX
    Update-RSWinSoftware [-WhatIf] [-Confirm] [<CommonParameters>]

DESCRIPTION
    On Windows, the command validates required Appx dependencies, updates WinGet when
    needed, and then upgrades installed software with WinGet.

    On macOS, the command requires Homebrew, refreshes Homebrew metadata, and upgrades
    installed formulae and casks.

PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. Because the command
        supports ShouldProcess, it also supports WhatIf and Confirm.

EXAMPLE
    PS> Update-RSWinSoftware

    Updates supported software on the current platform.

EXAMPLE
    PS> Update-RSWinSoftware -WhatIf -Verbose

    Shows each update action without applying changes.

RELATED LINKS
    https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
