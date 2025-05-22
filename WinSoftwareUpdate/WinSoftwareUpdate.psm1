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

    # =================================
    #         Static Variables
    # =================================
    #
    # GitHub url for the latest release of WinGet
    [string]$WinGetUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    #
    # The headers and API version for the GitHub API
    [hashtable]$GithubHeaders = @{
        "Accept"               = "application/vnd.github.v3+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    # Collecting information from GitHub regarding latest version of WinGet.
    try {
        # If the computer is running PowerShell 7 or higher, use HTTP/3.0 for the GitHub API in other cases use HTTP/2.0
        [System.Object]$GithubInfoRestData = Invoke-RestMethod -Uri $WinGetUrl -Method Get -Headers $GithubHeaders -TimeoutSec 10 -HttpVersion $SysInfo.HTTPVersion | Select-Object -Property assets, tag_name

        [System.Object]$GitHubInfo = [PSCustomObject]@{
            Tag         = $($GithubInfoRestData.tag_name.Substring(1))
            DownloadUrl = $GithubInfoRestData.assets | where-object { $_.name -like "*.msixbundle" } | Select-Object -ExpandProperty browser_download_url
            OutFile     = "$($env:TEMP)\WinGet_$($GithubInfoRestData.tag_name.Substring(1)).msixbundle"
        }
    }
    catch {
        Throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
        break
    }

    # Checking if the installed version of WinGet are the same as the latest version of WinGet
    [version]$vWinGet = $SysInfo.Software.WinGet
    [version]$vGitHub = $GitHubInfo.Tag
    if ([Version]$vWinGet -lt [Version]$vGitHub) {
        Write-Output "WinGet has a newer version $($vGitHub | Out-String), downloading and installing it..."
        Write-Verbose "Downloading WinGet..."
        Invoke-WebRequest -UseBasicParsing -Uri $GitHubInfo.DownloadUrl -OutFile $GitHubInfo.OutFile

        Write-Verbose "Installing version $($vGitHub | Out-String) of WinGet..."
        [void](Add-AppxPackage $($GitHubInfo.OutFile) -ForceApplicationShutdown)
        
        Write-Verbose "Deleting WinGet downloaded installation file..."
        [void](Remove-Item -Path $($GitHubInfo.OutFile) -Force)
    }
    else {
        Write-Verbose "Your already on the latest version of WinGet $($vWinGet | Out-String), no need to update."
        Continue
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

    # Getting architecture of the computer and adapting it after the right download links
    [string]$Architecture = $(Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty SystemType)
    
    [string]$Arch = Switch ($Architecture) {
        "x64-based PC" { "x64" }
        "ARM64-based PC" { "arm64" }
        "x86-based PC" { "x86" }
        default { "Unsupported" }
    }

    if ($Arch -eq "Unsupported") {
        Throw "Your running a unsupported architecture, exiting now..."
        Break
    }
    else {
        # Verify verifying what ps version that's running and checks if pwsh7 is installed
        [version]$CurrentPSVersion = if ($PSVersionTable.PSVersion.Major -lt 7) {
            $pwshPath = Join-Path -Path "C:\Program Files" -ChildPath "PowerShell\7" -AdditionalChildPath "pwsh.exe"

            if ($pwshPath -eq $true) {
                (Get-Command "$($pwshPath)").Version
            }
            else {
                $PSVersionTable.PSVersion
            }
        }
        else {
            $PSVersionTable.PSVersion
        }

        # Collects everything in pscustomobject to get easier access to the information
        # Need to redothis to hashtable
        $SysInfo = [ordered]@{
            Software    = [ordered]@{
                "Microsoft.VCLibs"  = [ordered]@{
                    Version  = $(try { (Get-AppxPackage -AllUsers | Where-Object { $_.Architecture -eq $Arch -and $_.PackageFamilyName -like "Microsoft.VCLibs.140.00_8wekyb3d8bbwe" } | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version -First 1).version } catch { "0.0.0.0" }) -as [version]
                    Url      = "https://aka.ms/Microsoft.VCLibs.$($Arch).14.00.Desktop.appx"
                    FileName = "Microsoft.VCLibs.$($Arch).14.00.Desktop.appx"
                }
                "Microsoft.UI.Xaml" = [ordered]@{
                    Version  = $(try { (Get-AppxPackage -AllUsers | Where-Object { $_.Architecture -eq $Arch -and $_.PackageFamilyName -like "Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe" } | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version -First 1).version } catch { "0.0.0.0" }) -as [version]
                    Url      = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.$($Arch).appx"
                    FileName = "Microsoft.UI.Xaml.2.8.$($Arch).appx"
                }
                "WinGet"            = [ordered]@{
                    Version  = $(try { (Get-AppxPackage -AllUsers | Where-Object { $_.Architecture -eq $Arch -and $_.PackageFamilyName -like "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" } | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version -First 1).version } catch { "0.0.0.0" }) -as [version]
                    Url      = ""
                    FileName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                }
                "vsRedist"          = [ordered]@{
                    Version  = ""
                    Url      = "https://aka.ms/vs/17/release/vc_redist.$($Architecture).exe"
                    FileName = "vc_redist.$($Architecture).exe"
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
}
Function Confirm-rsDependency {
    # Collecting systeminformation
    $SysInfo = Get-rsSystemInfo

    # If any dependencies are missing it will install them
    foreach ($_info in $SysInfo.Software.keys) {
        if ($_info -notlike "WinGet") {
            $Software = $SysInfo.Software.$_info
            if ($null -eq $Software.version -or $Software.version -eq "0.0.0.0") {
                try {
                    Write-Output "$($_info) is not installed, downloading and installing it now..."
                    [string]$DepOutFile = Join-Path -Path $SysInfo.Temp -ChildPath $Software.FileName
                    Write-Verbose "Downloading $($_info)..."
                    Invoke-RestMethod -Uri $Software.url -OutFile $DepOutFile -HttpVersion $SysInfo.HTTPVersion

                    Write-Verbose "Installing $($_info)..."
                    [void](Add-AppxPackage -Path $DepOutFile)
                    
                    Write-Verbose "Deleting $($_info) downloaded installation file..."
                    [void](Remove-Item -Path $DepOutFile -Force)
                }
                catch {
                    Throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
                    break
                }
            }
        }
    }

    # Install VisualCRedist
    # To Install visualcredist use vc_redist.x64.exe /install /quiet /norestart

    # If PowerShell 7 is installed on the system then it will check if it's the latest version and if not it will update it
    [version]$pwsh7 = "7.0.0.0"
    if ($SysInfo.VersionPS -ge $pwsh7) {
        Confirm-rsPowerShell7 -SysInfo $SysInfo
    }
    
    # If WinGet is not installed it will be installed and if it's any updates it will be updated
    Confirm-RSWinGet -SysInfo $SysInfo
}
Function Confirm-rsPowerShell7 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER SID
        .PARAMETER Trim
        .EXAMPLE
    #>

    $MissingPWSH7 = $false

    [version]$CurrentVersion = if ($PSVersionTable.PSVersion.Major -lt 7) {
        $CheckpwshVersion = Test-Path -Path "C:\Program Files\PowerShell\7\pwsh.exe"

        if ($CheckpwshVersion -eq $true) {
            (Get-Command "C:\Program Files\PowerShell\7\pwsh.exe").Version
        }
        else {
            [version]$CurrentVersion = $PSVersionTable.PSVersion
            $true
        }
    }
    else {
        $PSVersionTable.PSVersion
    }

    [version]$pwshV7 = "7.0.0.0"
    if ($CurrentVersion -lt $pwshV7) {
        $GetMetaData = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json"
    }
    else {
        $GetMetaData = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json" -HttpVersion 3.0
    }

    [version]$Release = $GetMetaData.StableReleaseTag -replace '^v'
    $PackageName = "PowerShell-${Release}-win-x64.msi"
    $PackagePath = Join-Path -Path $env:TEMP -ChildPath $PackageName
    $downloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v${Release}/${PackageName}"

    if ($CurrentVersion -lt $pwshV7) {
        $MSIArguments = @()
        $MSIArguments = @("/i", $packagePath, "/quiet")
        $MSIArguments += "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1"
        $MSIArguments += "ENABLE_PSREMOTING=1"
        $MSIArguments += "ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1"
        $MSIArguments += "REGISTER_MANIFEST=1"
        $MSIArguments += "ADD_PATH=1"
    }

    # Check if powershell needs to update or not
    if ($CurrentVersion -lt $Release) {
        # Download latest MSI installer for PowerShell
        Invoke-RestMethod -Uri $downloadURL -OutFile $PackagePath

        # Setting arguments
        if ($null -ne $MSIArguments) {
            $ArgumentList = $MSIArguments
        }
        else {
            $ArgumentList = @("/i", $packagePath, "/quiet")
        }

        $InstallProcess = Start-Process msiexec -ArgumentList $ArgumentList -Wait -PassThru
        if ($InstallProcess.exitcode -ne 0) {
            throw "Quiet install failed, please ensure you have administrator rights"
        }
        else {
            if ($MissingPWSH7 -eq $true) {
                Write-Output "PowerShell 7 was not installed on your system, PowerShell 7 have been installed and you need to restart PowerShell to use the new version"
            } 
            else {
                Write-Output "PowerShell 7 have been updated from $($CurrentVersion) to $($Release), you need to restart PowerShell to use the new version"
            }
        }
        # Removes the installation file
        Remove-Item -Path $PackagePath -Force -ErrorAction SilentlyContinue
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

    #Check if script was started as Administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Error ("{0} needs admin privileges, exiting now...." -f $MyInvocation.MyCommand)
        break
    }

    # Importing appx with -usewindowspowershell if your using PowerShell 7 or higher
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Import-Module appx -UseWindowsPowershell
        Write-Output "This messages is expected if you are using PowerShell 7 or higher and can be ignored`n"
    }

    # Register WinGet
    # Add-AppxPackage -RegisterByFamilyName -MainPackage "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe"

    # Check if something needs to be installed or updated
    Confirm-RSDependency

    # Checking if it's any softwares to update and if so it will update them
    Write-Output "Updating Wingets source list..."
    Start-Process -FilePath "WinGet.exe" -ArgumentList "source update" -NoNewWindow -Wait

    Write-OutPut "Checks if any softwares needs to be updated..."
    try {
        $Arguments = @()
        $Arguments += "upgrade"
        $Arguments += "--all"
        $Arguments += "--include-unknown"
        $Arguments += "--accept-package-agreements"
        $Arguments += "--accept-source-agreements"
        $Arguments += "--uninstall-previous"
        $Arguments += "--silent"

        Start-Process -FilePath "WinGet.exe" -ArgumentList $Arguments -NoNewWindow -Wait
    }
    catch {
        Throw "Message: $($_.Exception.Message)`nError Line: $($_.InvocationInfo.Line)`n"
    }

    Write-OutPut "FINISH - All of your programs have been updated!"
}