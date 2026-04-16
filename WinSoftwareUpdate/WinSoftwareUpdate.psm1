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

Function Get-rsLatestAppxPackageVersion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Packages,

        [Parameter(Mandatory = $true)]
        [string]$Architecture,

        [Parameter(Mandatory = $true)]
        [string]$PackageFamilyName
    )

    begin {
        [version]$DefaultVersion = "0.0.0.0"
    }

    process {
        try {
            $Version = $Packages |
                Where-Object { $_.Architecture -eq $Architecture -and $_.PackageFamilyName -eq $PackageFamilyName } |
                Sort-Object -Property Version -Descending |
                Select-Object -ExpandProperty Version -First 1

            if ($null -eq $Version -or [string]::IsNullOrWhiteSpace([string]$Version)) {
                return $DefaultVersion
            }

            return [version]$Version
        }
        catch {
            return $DefaultVersion
        }
    }

    end {
    }
}
Function Confirm-rsWinGet {
    <#
        .SYNOPSIS
        This function is connected and used of the main function for this module, Update-RSWinSoftware.
        So when you run the Update-RSWinSoftware function this function will be called during the process.

        .DESCRIPTION
        This function will connect to the GitHub API and check if there is a newer version of WinGet to download and install.

        .PARAMETER GitHubUrl
        Url to the GitHub API for the latest release of WinGet

        .PARAMETER GithubHeaders
        The headers and API version for the GitHub API, this is pasted from the main function for this module, Update-RSWinSoftware.
        This is pasted in from the main function for this module, Update-RSWinSoftware.

        .PARAMETER WinGet


        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md

        .NOTES
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
		YouTube:		https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Information about the installed version of WinGet")]
        $SysInfo
    )

    begin {
        [string]$WinGetUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        [hashtable]$GithubHeaders = @{
            "Accept"               = "application/vnd.github.v3+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        if ($null -eq $SysInfo) {
            $SysInfo = Get-rsSystemInfo
        }
    }

    process {
        try {
            $RestMethodParameters = @{
                Uri         = $WinGetUrl
                Method      = "Get"
                Headers     = $GithubHeaders
                TimeoutSec  = 10
                ErrorAction = "Stop"
            }

            if (-not [string]::IsNullOrWhiteSpace([string]$SysInfo.HTTPVersion)) {
                $RestMethodParameters.HttpVersion = $SysInfo.HTTPVersion
            }

            [System.Object]$GithubInfoRestData = Invoke-RestMethod @RestMethodParameters | Select-Object -Property assets, tag_name
            [string]$DownloadUrl = $GithubInfoRestData.assets |
                Where-Object { $_.name -like "*.msixbundle" } |
                Select-Object -ExpandProperty browser_download_url -First 1

            if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
                throw "Could not determine the latest WinGet download URL."
            }

            [string]$LatestWinGetTag = $GithubInfoRestData.tag_name -replace '^v'
            [System.Object]$GitHubInfo = [PSCustomObject]@{
                Tag         = $LatestWinGetTag
                DownloadUrl = $DownloadUrl
                OutFile     = Join-Path -Path $env:TEMP -ChildPath "WinGet_${LatestWinGetTag}.msixbundle"
            }
        }
        catch {
            throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        }

        $WinGetInfo = $SysInfo.Software["WinGet"]
        [version]$WinGetVersion = if ($null -ne $WinGetInfo -and $null -ne $WinGetInfo.Version) {
            $WinGetInfo.Version
        }
        else {
            "0.0.0.0"
        }
        [version]$GitHubVersion = $GitHubInfo.Tag
        if ($WinGetVersion -lt $GitHubVersion) {
            try {
                Write-Output "WinGet has a newer version $GitHubVersion, downloading and installing it..."
                Write-Verbose "Downloading WinGet..."
                Invoke-WebRequest -UseBasicParsing -Uri $GitHubInfo.DownloadUrl -OutFile $GitHubInfo.OutFile -ErrorAction Stop

                Write-Verbose "Installing version $GitHubVersion of WinGet..."
                Add-AppxPackage -Path $GitHubInfo.OutFile -ForceApplicationShutdown -ErrorAction Stop | Out-Null
            }
            catch {
                throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
            }
            finally {
                if (Test-Path -Path $GitHubInfo.OutFile) {
                    Write-Verbose "Deleting WinGet downloaded installation file..."
                    Remove-Item -Path $GitHubInfo.OutFile -Force -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            Write-Verbose "You're already on the latest version of WinGet $WinGetVersion, no need to update."
        }
    }

    end {
    }
}
Function Get-rsSystemInfo {
    <#
        .SYNOPSIS
        This function is connected and used of the main function for this module, Update-RSWinSoftware.
        So when you run the Update-RSWinSoftware function this function will be called during the process.

        .DESCRIPTION
        This function will collect the following data from the computer and store it in a PSCustomObject to make it easier for the main function for this module, Update-RSWinSoftware, to use the data.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md

        .NOTES
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
		YouTube:		https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding()]
    Param()

    begin {
        [hashtable]$ArchitectureMap = @{
            "x64-based PC"   = "x64"
            "ARM64-based PC" = "arm64"
            "x86-based PC"   = "x86"
        }
        [string]$PwshPath = Join-Path -Path "C:\Program Files" -ChildPath "PowerShell\7" -AdditionalChildPath "pwsh.exe"
    }

    process {
        try {
            [string]$Architecture = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object -ExpandProperty SystemType
        }
        catch {
            throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        }

        [string]$Arch = if ($ArchitectureMap.ContainsKey($Architecture)) {
            $ArchitectureMap[$Architecture]
        }
        else {
            "Unsupported"
        }

        if ($Arch -eq "Unsupported") {
            throw "Unsupported architecture detected."
        }

        try {
            [version]$CurrentPSVersion = if ($PSVersionTable.PSVersion.Major -lt 7) {
                if (Test-Path -Path $PwshPath) {
                    (Get-Command $PwshPath -ErrorAction Stop).Version
                }
                else {
                    $PSVersionTable.PSVersion
                }
            }
            else {
                $PSVersionTable.PSVersion
            }

            $AppxPackages = Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object { $_.Architecture -eq $Arch }
        }
        catch {
            throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        }

        $SysInfo = [ordered]@{
            Software    = [ordered]@{
                "Microsoft.VCLibs"  = [ordered]@{
                    Version  = Get-rsLatestAppxPackageVersion -Packages $AppxPackages -Architecture $Arch -PackageFamilyName "Microsoft.VCLibs.140.00_8wekyb3d8bbwe"
                    Url      = "https://aka.ms/Microsoft.VCLibs.$($Arch).14.00.Desktop.appx"
                    FileName = "Microsoft.VCLibs.$($Arch).14.00.Desktop.appx"
                }
                "Microsoft.UI.Xaml" = [ordered]@{
                    Version  = Get-rsLatestAppxPackageVersion -Packages $AppxPackages -Architecture $Arch -PackageFamilyName "Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe"
                    Url      = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.$($Arch).appx"
                    FileName = "Microsoft.UI.Xaml.2.8.$($Arch).appx"
                }
                "WinGet"            = [ordered]@{
                    Version  = Get-rsLatestAppxPackageVersion -Packages $AppxPackages -Architecture $Arch -PackageFamilyName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe"
                    Url      = ""
                    FileName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                }
                "vsRedist"          = [ordered]@{
                    Version  = ""
                    Url      = "https://aka.ms/vs/17/release/vc_redist.$($Arch).exe"
                    FileName = "vc_redist.$($Arch).exe"
                }
            }
            Arch        = $Arch
            VersionPS   = [version]$CurrentPSVersion
            Temp        = $env:TEMP
            HTTPVersion = Switch ($PSVersionTable.PSVersion.Major) {
                7 { "3.0" }
                default { "2.0" }
            }
        }

        return $SysInfo
    }

    end {
    }
}
Function Confirm-rsDependency {
    [CmdletBinding()]
    Param()

    begin {
    }

    process {
        $SysInfo = Get-rsSystemInfo

        foreach ($DependencyName in $SysInfo.Software.Keys | Where-Object { $_ -ne "WinGet" }) {
            $Software = $SysInfo.Software[$DependencyName]
            if ($null -eq $Software.Version -or $Software.Version -eq "0.0.0.0") {
                [string]$DepOutFile = Join-Path -Path $SysInfo.Temp -ChildPath $Software.FileName

                try {
                    Write-Output "$DependencyName is not installed, downloading and installing it now..."
                    Write-Verbose "Downloading $DependencyName..."
                    Invoke-RestMethod -Uri $Software.Url -OutFile $DepOutFile -HttpVersion $SysInfo.HTTPVersion -ErrorAction Stop

                    Write-Verbose "Installing $DependencyName..."
                    Add-AppxPackage -Path $DepOutFile -ErrorAction Stop | Out-Null
                }
                catch {
                    throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
                }
                finally {
                    if (Test-Path -Path $DepOutFile) {
                        Write-Verbose "Deleting $DependencyName downloaded installation file..."
                        Remove-Item -Path $DepOutFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        [version]$MinimumPwsh7Version = "7.0.0.0"
        if ($SysInfo.VersionPS -ge $MinimumPwsh7Version) {
            Confirm-rsPowerShell7 -SysInfo $SysInfo
        }

        Confirm-RSWinGet -SysInfo $SysInfo
    }

    end {
    }
}
Function Confirm-rsPowerShell7 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER SID
        .PARAMETER Trim
        .EXAMPLE
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        $SysInfo
    )

    begin {
        $MissingPWSH7 = $false
        [version]$MinimumPwsh7Version = "7.0.0.0"
        [string]$PwshPath = Join-Path -Path "C:\Program Files" -ChildPath "PowerShell\7" -AdditionalChildPath "pwsh.exe"
    }

    process {
        try {
            [version]$CurrentVersion = if ($PSVersionTable.PSVersion.Major -lt 7) {
                if (Test-Path -Path $PwshPath) {
                    (Get-Command $PwshPath -ErrorAction Stop).Version
                }
                else {
                    $MissingPWSH7 = $true
                    $PSVersionTable.PSVersion
                }
            }
            else {
                $PSVersionTable.PSVersion
            }

            $MetadataParameters = @{
                Uri         = "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
                ErrorAction = "Stop"
            }

            if ($null -ne $SysInfo -and -not [string]::IsNullOrWhiteSpace([string]$SysInfo.HTTPVersion)) {
                $MetadataParameters.HttpVersion = $SysInfo.HTTPVersion
            }
            elseif ($CurrentVersion -ge $MinimumPwsh7Version) {
                $MetadataParameters.HttpVersion = "3.0"
            }

            $GetMetaData = Invoke-RestMethod @MetadataParameters
            [version]$Release = $GetMetaData.StableReleaseTag -replace '^v'
        }
        catch {
            throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        }

        $PackageName = "PowerShell-${Release}-win-x64.msi"
        $PackagePath = Join-Path -Path $env:TEMP -ChildPath $PackageName
        $downloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v${Release}/${PackageName}"
        $ArgumentList = @("/i", $PackagePath, "/quiet")

        if ($CurrentVersion -lt $MinimumPwsh7Version) {
            $ArgumentList += "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1"
            $ArgumentList += "ENABLE_PSREMOTING=1"
            $ArgumentList += "ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1"
            $ArgumentList += "REGISTER_MANIFEST=1"
            $ArgumentList += "ADD_PATH=1"
        }

        if ($CurrentVersion -lt $Release) {
            try {
                Invoke-RestMethod -Uri $downloadURL -OutFile $PackagePath -ErrorAction Stop
                $InstallProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $ArgumentList -Wait -PassThru -ErrorAction Stop
                if ($InstallProcess.exitcode -ne 0) {
                    throw "Quiet install failed, please ensure you have administrator rights"
                }

                if ($MissingPWSH7) {
                    Write-Output "PowerShell 7 was not installed on your system, PowerShell 7 have been installed and you need to restart PowerShell to use the new version"
                }
                else {
                    Write-Output "PowerShell 7 have been updated from $CurrentVersion to $Release, you need to restart PowerShell to use the new version"
                }
            }
            catch {
                throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
            }
            finally {
                if (Test-Path -Path $PackagePath) {
                    Remove-Item -Path $PackagePath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    end {
    }
}
Function Update-rsWinSoftware {
    <#
        .SYNOPSIS
        This module let users auto update their installed software on Windows 10, 11 with WinGet.

        .DESCRIPTION
        The module will check if WinGet is installed and up to date, if not it will install WinGet or update it.
        It will also if Microsoft.VCLibs is installed and if not it will install it.
        Besides that the module will check what aritecture the computer is running and download the correct version of Microsoft.VCLibs etc.
        Then it will check if there is any software that needs to be updated and if so it will update them.

        .EXAMPLE
        Update-RSWinSoftware
        # This command will run the module and check if WinGet and VCLibs are up to date.

        .LINK
        https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md

        .NOTES
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
		YouTube:		https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    Param()

    begin {
        [bool]$IsAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
        [string[]]$Arguments = @(
            "upgrade"
            "--all"
            "--include-unknown"
            "--accept-package-agreements"
            "--accept-source-agreements"
            "--uninstall-previous"
            "--silent"
        )
    }

    process {
        if (-not $IsAdministrator) {
            Write-Error ("{0} needs admin privileges, exiting now...." -f $MyInvocation.MyCommand)
            return
        }

        if (-not $PSCmdlet.ShouldProcess("Local computer", "Update installed software with WinGet")) {
            return
        }

        try {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Import-Module Appx -UseWindowsPowershell -ErrorAction Stop
                Write-Output "This message is expected if you are using PowerShell 7 or higher and can be ignored`n"
            }

            Confirm-RSDependency

            Write-Output "Updating Wingets source list..."
            $SourceUpdateProcess = Start-Process -FilePath "WinGet.exe" -ArgumentList "source update" -NoNewWindow -Wait -PassThru -ErrorAction Stop
            if ($SourceUpdateProcess.exitcode -ne 0) {
                throw "WinGet source update failed with exit code $($SourceUpdateProcess.exitcode)."
            }

            Write-Output "Checking if any software needs to be updated..."
            $UpgradeProcess = Start-Process -FilePath "WinGet.exe" -ArgumentList $Arguments -NoNewWindow -Wait -PassThru -ErrorAction Stop
            if ($UpgradeProcess.exitcode -ne 0) {
                throw "WinGet upgrade failed with exit code $($UpgradeProcess.exitcode)."
            }
        }
        catch {
            throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        }

        Write-Output "FINISH - All of your programs have been updated!"
    }

    end {
    }
}
