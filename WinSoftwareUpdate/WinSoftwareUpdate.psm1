<#
MIT License

Copyright (C) 2025 Robin Widmark.
<https://widmark.dev>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Get-rsPlatformInfo {
    [CmdletBinding()]
    param()

    $platformName = if ($IsWindows) {
        'Windows'
    }
    elseif ($IsMacOS) {
        'macOS'
    }
    else {
        'Unsupported'
    }

    $architecture = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
        ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
        ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
        ([System.Runtime.InteropServices.Architecture]::Arm64) { 'arm64' }
        default { 'Unsupported' }
    }

    if ($platformName -eq 'Unsupported' -or $architecture -eq 'Unsupported') {
        throw 'This module supports Windows and macOS on x64, x86, and arm64 only.'
    }

    $tempPath = [System.IO.Path]::GetTempPath()
    if ([string]::IsNullOrWhiteSpace($tempPath)) {
        $tempPath = $env:TEMP
    }

    [PSCustomObject]@{
        PlatformName = $platformName
        IsWindows    = $platformName -eq 'Windows'
        IsMacOS      = $platformName -eq 'macOS'
        Architecture = $architecture
        Temp         = $tempPath
        HTTPVersion  = if ($PSVersionTable.PSVersion.Major -ge 7) { '3.0' } else { '2.0' }
    }
}

function Get-rsCommandPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Specify the command name to resolve on the current platform.')]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }

    return $command.Source
}

function Invoke-rsNativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Specify the full path or command name for the native executable to run.')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(HelpMessage = 'Specify the argument list to pass to the native executable.')]
        [string[]]$ArgumentList = @(),

        [Parameter(HelpMessage = 'Specify a friendly operation name for error messages.')]
        [ValidateNotNullOrEmpty()]
        [string]$OperationName = 'native command'
    )

    Write-Verbose ("Running {0}: {1} {2}" -f $OperationName, $FilePath, ($ArgumentList -join ' '))
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "{0} failed with exit code {1}." -f $OperationName, $LASTEXITCODE
    }
}

function Invoke-rsDownloadFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Specify the URI to download.')]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory = $true, HelpMessage = 'Specify the full path to the file that will receive the download.')]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter(HelpMessage = 'Specify the HTTP version to request when the current PowerShell version supports it.')]
        [string]$HttpVersion
    )

    $downloadParameters = @{
        Uri         = $Uri
        OutFile     = $OutFile
        ErrorAction = 'Stop'
    }

    if (-not [string]::IsNullOrWhiteSpace($HttpVersion)) {
        $downloadParameters.HttpVersion = $HttpVersion
    }

    Invoke-WebRequest @downloadParameters | Out-Null
}

function Get-rsLatestAppxPackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Specify the Appx package collection to inspect.')]
        [ValidateNotNull()]
        [System.Collections.IEnumerable]$Packages,

        [Parameter(Mandatory = $true, HelpMessage = 'Specify the processor architecture to filter on.')]
        [ValidateSet('x64', 'x86', 'arm64')]
        [string]$Architecture,

        [Parameter(Mandatory = $true, HelpMessage = 'Specify the package family name to match.')]
        [ValidateNotNullOrEmpty()]
        [string]$PackageFamilyName
    )

    [version]$defaultVersion = '0.0.0.0'
    [version]$latestVersion = $defaultVersion

    foreach ($package in $Packages) {
        if ($package.Architecture -ne $Architecture -or $package.PackageFamilyName -ne $PackageFamilyName) {
            continue
        }

        try {
            [version]$candidateVersion = $package.Version
            if ($candidateVersion -gt $latestVersion) {
                $latestVersion = $candidateVersion
            }
        }
        catch {
        }
    }

    return $latestVersion
}

function Get-rsPowerShellReleaseVersion {
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = 'Specify precomputed system information to reuse HTTP settings.')]
        [ValidateNotNull()]
        $SysInfo
    )

    $metadataParameters = @{
        Uri         = 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json'
        ErrorAction = 'Stop'
    }

    if ($null -ne $SysInfo -and -not [string]::IsNullOrWhiteSpace([string]$SysInfo.HTTPVersion)) {
        $metadataParameters.HttpVersion = $SysInfo.HTTPVersion
    }

    $metadata = Invoke-RestMethod @metadataParameters
    return [version]($metadata.StableReleaseTag -replace '^v')
}

function Get-rsSystemInfo {
    <#
        .SYNOPSIS
        Collect system and package-manager metadata for the current platform.

        .DESCRIPTION
        This helper gathers reusable information for the public update commands so the
        module only resolves platform details once per execution.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
    #>

    [CmdletBinding()]
    param()

    $platform = Get-rsPlatformInfo
    $sysInfo = [ordered]@{
        Platform    = $platform.PlatformName
        IsWindows   = $platform.IsWindows
        IsMacOS     = $platform.IsMacOS
        Arch        = $platform.Architecture
        VersionPS   = [version]$PSVersionTable.PSVersion
        Temp        = $platform.Temp
        HTTPVersion = $platform.HTTPVersion
        Software    = [ordered]@{}
    }

    if ($platform.IsWindows) {
        if ($PSVersionTable.PSVersion.Major -ge 7 -and -not (Get-Command -Name Get-AppxPackage -ErrorAction SilentlyContinue)) {
            Import-Module Appx -UseWindowsPowerShell -ErrorAction Stop
        }

        $appxPackages = Get-AppxPackage -AllUsers -ErrorAction Stop
        $pwshCommand = Get-rsCommandPath -CommandName 'pwsh'
        [version]$currentPwshVersion = if ($null -ne $pwshCommand) {
            (Get-Command -Name $pwshCommand -ErrorAction Stop).Version
        }
        else {
            $PSVersionTable.PSVersion
        }

        $sysInfo.Software['Microsoft.VCLibs'] = [ordered]@{
            Version  = Get-rsLatestAppxPackageVersion -Packages $appxPackages -Architecture $platform.Architecture -PackageFamilyName 'Microsoft.VCLibs.140.00_8wekyb3d8bbwe'
            Url      = "https://aka.ms/Microsoft.VCLibs.$($platform.Architecture).14.00.Desktop.appx"
            FileName = "Microsoft.VCLibs.$($platform.Architecture).14.00.Desktop.appx"
        }
        $sysInfo.Software['Microsoft.UI.Xaml'] = [ordered]@{
            Version  = Get-rsLatestAppxPackageVersion -Packages $appxPackages -Architecture $platform.Architecture -PackageFamilyName 'Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe'
            Url      = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.$($platform.Architecture).appx"
            FileName = "Microsoft.UI.Xaml.2.8.$($platform.Architecture).appx"
        }
        $sysInfo.Software['WinGet'] = [ordered]@{
            Version  = Get-rsLatestAppxPackageVersion -Packages $appxPackages -Architecture $platform.Architecture -PackageFamilyName 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
            Url      = ''
            FileName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
        }
        $sysInfo.Software['PowerShell'] = [ordered]@{
            Version  = [version]$currentPwshVersion
            FileName = "PowerShell-$($currentPwshVersion)-win-$($platform.Architecture).msi"
        }
        $sysInfo.VersionPS = [version]$currentPwshVersion
    }
    elseif ($platform.IsMacOS) {
        $brewPath = Get-rsCommandPath -CommandName 'brew'
        $sysInfo.Software['Homebrew'] = [ordered]@{
            Version = ''
            Path    = $brewPath
        }

        if ($null -ne $brewPath) {
            $brewVersion = & $brewPath --version 2>$null | Select-Object -First 1
            if ($brewVersion) {
                $sysInfo.Software['Homebrew'].Version = $brewVersion
            }
        }
    }

    return [PSCustomObject]$sysInfo
}

function Confirm-rsWinGet {
    <#
        .SYNOPSIS
        Ensure WinGet is installed and current on Windows.

        .DESCRIPTION
        This helper checks the latest WinGet release metadata and installs a newer
        Windows package when needed.

        .PARAMETER SysInfo
        Provide system information from Get-rsSystemInfo to avoid recalculating it.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(HelpMessage = 'Provide system information from Get-rsSystemInfo to reuse platform and package metadata.')]
        [ValidateNotNull()]
        $SysInfo
    )

    if ($null -eq $SysInfo) {
        $SysInfo = Get-rsSystemInfo
    }

    if (-not $SysInfo.IsWindows) {
        Write-Verbose 'Skipping WinGet validation because the current platform is not Windows.'
        return
    }

    $restMethodParameters = @{
        Uri         = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
        Method      = 'Get'
        Headers     = @{
            Accept                = 'application/vnd.github.v3+json'
            'X-GitHub-Api-Version' = '2022-11-28'
        }
        TimeoutSec  = 10
        ErrorAction = 'Stop'
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$SysInfo.HTTPVersion)) {
        $restMethodParameters.HttpVersion = $SysInfo.HTTPVersion
    }

    $githubInfoRestData = Invoke-RestMethod @restMethodParameters | Select-Object -Property assets, tag_name
    [string]$downloadUrl = $githubInfoRestData.assets |
        Where-Object { $_.name -like '*.msixbundle' } |
        Select-Object -ExpandProperty browser_download_url -First 1

    if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
        throw 'Could not determine the latest WinGet download URL.'
    }

    [version]$latestWinGetVersion = $githubInfoRestData.tag_name -replace '^v'
    [version]$installedVersion = if ($null -ne $SysInfo.Software['WinGet']) {
        $SysInfo.Software['WinGet'].Version
    }
    else {
        '0.0.0.0'
    }

    if ($installedVersion -ge $latestWinGetVersion) {
        Write-Verbose "WinGet $installedVersion is already current."
        return
    }

    $outFile = Join-Path -Path $SysInfo.Temp -ChildPath "WinGet_$($latestWinGetVersion).msixbundle"
    if (-not $PSCmdlet.ShouldProcess("WinGet $latestWinGetVersion", 'Download and install updated WinGet package')) {
        return
    }

    try {
        Write-Verbose "Downloading WinGet $latestWinGetVersion from GitHub."
        Invoke-rsDownloadFile -Uri $downloadUrl -OutFile $outFile -HttpVersion $SysInfo.HTTPVersion

        Write-Verbose "Installing WinGet $latestWinGetVersion."
        Add-AppxPackage -Path $outFile -ForceApplicationShutdown -ErrorAction Stop | Out-Null
        Write-Output "WinGet has been updated to $latestWinGetVersion."
    }
    finally {
        if (Test-Path -Path $outFile) {
            Remove-Item -Path $outFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Confirm-rsPowerShell7 {
    <#
        .SYNOPSIS
        Ensure PowerShell 7 is current on supported platforms.

        .DESCRIPTION
        On Windows the module installs the latest MSI release. On macOS the module
        updates the Homebrew PowerShell formula when Homebrew is available.

        .PARAMETER SysInfo
        Provide system information from Get-rsSystemInfo to avoid recalculating it.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(HelpMessage = 'Provide system information from Get-rsSystemInfo to reuse platform and package metadata.')]
        [ValidateNotNull()]
        $SysInfo
    )

    if ($null -eq $SysInfo) {
        $SysInfo = Get-rsSystemInfo
    }

    [version]$releaseVersion = Get-rsPowerShellReleaseVersion -SysInfo $SysInfo
    [version]$currentVersion = $SysInfo.VersionPS

    if ($currentVersion -ge $releaseVersion) {
        Write-Verbose "PowerShell $currentVersion is already current."
        return
    }

    if ($SysInfo.IsWindows) {
        $packageName = "PowerShell-$($releaseVersion)-win-$($SysInfo.Arch).msi"
        $packagePath = Join-Path -Path $SysInfo.Temp -ChildPath $packageName
        $downloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$($releaseVersion)/$packageName"
        $argumentList = @('/i', $packagePath, '/quiet')

        if ($currentVersion -lt [version]'7.0.0') {
            $argumentList += @(
                'ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1'
                'ENABLE_PSREMOTING=1'
                'ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1'
                'REGISTER_MANIFEST=1'
                'ADD_PATH=1'
            )
        }

        if (-not $PSCmdlet.ShouldProcess("PowerShell $releaseVersion", 'Download and install the latest Windows PowerShell MSI')) {
            return
        }

        try {
            Write-Verbose "Downloading PowerShell $releaseVersion."
            Invoke-rsDownloadFile -Uri $downloadUrl -OutFile $packagePath -HttpVersion $SysInfo.HTTPVersion
            Write-Verbose "Installing PowerShell $releaseVersion."
            Invoke-rsNativeCommand -FilePath 'msiexec.exe' -ArgumentList $argumentList -OperationName 'PowerShell installer'
            Write-Output "PowerShell has been updated from $currentVersion to $releaseVersion. Restart PowerShell to use the new version."
        }
        finally {
            if (Test-Path -Path $packagePath) {
                Remove-Item -Path $packagePath -Force -ErrorAction SilentlyContinue
            }
        }

        return
    }

    if ($SysInfo.IsMacOS) {
        $brewPath = $SysInfo.Software['Homebrew'].Path
        if ([string]::IsNullOrWhiteSpace($brewPath)) {
            Write-Verbose 'Skipping PowerShell update because Homebrew is not installed.'
            return
        }

        $formulaInstalled = (& $brewPath list --formula powershell 2>$null | Measure-Object).Count -gt 0
        if (-not $formulaInstalled) {
            Write-Verbose 'Skipping PowerShell update because the Homebrew powershell formula is not installed.'
            return
        }

        if (-not $PSCmdlet.ShouldProcess('Homebrew powershell formula', 'Upgrade PowerShell with Homebrew')) {
            return
        }

        Invoke-rsNativeCommand -FilePath $brewPath -ArgumentList @('upgrade', 'powershell') -OperationName 'brew upgrade powershell'
        Write-Output "PowerShell has been updated from $currentVersion to the latest Homebrew release."
    }
}

function Confirm-rsDependency {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(HelpMessage = 'Provide system information from Get-rsSystemInfo to reuse platform and package metadata.')]
        [ValidateNotNull()]
        $SysInfo
    )

    if ($null -eq $SysInfo) {
        $SysInfo = Get-rsSystemInfo
    }

    if ($SysInfo.IsWindows) {
        foreach ($dependencyName in @('Microsoft.VCLibs', 'Microsoft.UI.Xaml')) {
            $software = $SysInfo.Software[$dependencyName]
            if ($null -ne $software.Version -and $software.Version -ne [version]'0.0.0.0') {
                Write-Verbose "$dependencyName is already installed."
                continue
            }

            $outFile = Join-Path -Path $SysInfo.Temp -ChildPath $software.FileName
            if (-not $PSCmdlet.ShouldProcess($dependencyName, 'Download and install missing dependency')) {
                continue
            }

            try {
                Write-Verbose "Downloading $dependencyName."
                Invoke-rsDownloadFile -Uri $software.Url -OutFile $outFile -HttpVersion $SysInfo.HTTPVersion
                Write-Verbose "Installing $dependencyName."
                Add-AppxPackage -Path $outFile -ErrorAction Stop | Out-Null
                Write-Output "$dependencyName has been installed."
            }
            finally {
                if (Test-Path -Path $outFile) {
                    Remove-Item -Path $outFile -Force -ErrorAction SilentlyContinue
                }
            }
        }

        if ($SysInfo.VersionPS -ge [version]'7.0.0') {
            Confirm-rsPowerShell7 -SysInfo $SysInfo -WhatIf:$WhatIfPreference -Verbose:$($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)
        }

        Confirm-rsWinGet -SysInfo $SysInfo -WhatIf:$WhatIfPreference -Verbose:$($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)
        return
    }

    if ($SysInfo.IsMacOS) {
        if ([string]::IsNullOrWhiteSpace([string]$SysInfo.Software['Homebrew'].Path)) {
            throw 'Homebrew is required on macOS. Install Homebrew first and then rerun Update-RSWinSoftware.'
        }

        Write-Verbose 'Homebrew is available on macOS.'
        Confirm-rsPowerShell7 -SysInfo $SysInfo -WhatIf:$WhatIfPreference -Verbose:$($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)
    }
}

function Update-rsWinSoftware {
    <#
        .SYNOPSIS
        Update supported software by using WinGet on Windows or Homebrew on macOS.

        .DESCRIPTION
        On Windows the module validates required dependencies, updates WinGet when
        necessary, and then upgrades installed software. On macOS the module uses
        Homebrew to refresh metadata and upgrade installed formulae and casks.

        .EXAMPLE
        Update-RSWinSoftware
        Updates supported software on the current platform.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param()

    $platform = Get-rsPlatformInfo

    if ($platform.IsWindows) {
        if ($PSVersionTable.PSVersion.Major -ge 7 -and -not (Get-Command -Name Get-AppxPackage -ErrorAction SilentlyContinue)) {
            Write-Verbose 'Importing the Appx module through Windows PowerShell compatibility.'
            Import-Module Appx -UseWindowsPowerShell -ErrorAction Stop
        }

        $sysInfo = Get-rsSystemInfo
        $isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdministrator) {
            throw 'Update-RSWinSoftware requires administrator rights on Windows.'
        }

        Confirm-rsDependency -SysInfo $sysInfo -WhatIf:$WhatIfPreference -Verbose:$($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)

        $wingetPath = Get-rsCommandPath -CommandName 'winget'
        if ([string]::IsNullOrWhiteSpace($wingetPath)) {
            throw 'WinGet is not available after dependency validation.'
        }

        if ($PSCmdlet.ShouldProcess('WinGet sources', 'Refresh WinGet sources')) {
            Invoke-rsNativeCommand -FilePath $wingetPath -ArgumentList @('source', 'update') -OperationName 'winget source update'
        }

        if ($PSCmdlet.ShouldProcess('Installed software', 'Upgrade software with WinGet')) {
            Invoke-rsNativeCommand -FilePath $wingetPath -ArgumentList @(
                'upgrade'
                '--all'
                '--include-unknown'
                '--accept-package-agreements'
                '--accept-source-agreements'
                '--uninstall-previous'
                '--silent'
            ) -OperationName 'winget upgrade'
        }

        Write-Output 'FINISH - All supported Windows software updates have been processed.'
        return
    }

    if ($platform.IsMacOS) {
        $sysInfo = Get-rsSystemInfo
        Confirm-rsDependency -SysInfo $sysInfo -WhatIf:$WhatIfPreference -Verbose:$($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue)
        $brewPath = $sysInfo.Software['Homebrew'].Path

        if ($PSCmdlet.ShouldProcess('Homebrew metadata', 'Refresh Homebrew formula and cask metadata')) {
            Invoke-rsNativeCommand -FilePath $brewPath -ArgumentList @('update') -OperationName 'brew update'
        }

        if ($PSCmdlet.ShouldProcess('Installed software', 'Upgrade software with Homebrew')) {
            # --greedy updates auto-updating casks as well to match the Windows all-software intent.
            Invoke-rsNativeCommand -FilePath $brewPath -ArgumentList @('upgrade', '--greedy') -OperationName 'brew upgrade'
        }

        Write-Output 'FINISH - All supported macOS software updates have been processed.'
        return
    }

    throw 'This module supports Windows and macOS only.'
}

Export-ModuleMember -Function @(
    'Confirm-rsDependency'
    'Confirm-rsPowerShell7'
    'Confirm-rsWinGet'
    'Get-rsSystemInfo'
    'Update-rsWinSoftware'
)
