NAME
    Get-rsSystemInfo

SYNOPSIS
    Collects reusable platform metadata for the module.

SYNTAX
    Get-rsSystemInfo [<CommonParameters>]

DESCRIPTION
    Returns platform, architecture, temporary-path, HTTP-version, and package-manager
    metadata so the module can reuse that information across multiple operations.

    On Windows the result includes Appx dependency and WinGet details.
    On macOS the result includes Homebrew availability details.

PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable.

RELATED LINKS
    https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
