![GitHub](https://img.shields.io/github/license/rstolpe/WinSoftwareUpdate?style=plastic)  
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/rstolpe/WinSoftwareUpdate?sort=semver&style=plastic)  ![Last release](https://img.shields.io/github/release-date/rstolpe/WinSoftwareUpdate?style=plastic)
![GitHub last commit](https://img.shields.io/github/last-commit/rstolpe/WinSoftwareUpdate?style=plastic)  
![PSGallery downloads](https://img.shields.io/powershellgallery/dt/WinSoftwareUpdate?style=plastic)
  
# WinSoftwareUpdate
This module will let you update your installed software with WinGet, many of them but not all. The complete list is published here: [WinGet Repo](https://github.com/microsoft/winget-cli)  
This module is perfect for people like me that are to lazy to update every singel software all the time, it's much easier to just run a PowerShell Script.  
I have added the result from PSScriptAnalyzer in [test folder](https://github.com/rstolpe/WinSoftwareUpdate/tree/main/test) I have some ShouldProcess warnings in this module but that's nothing to worry about really.

## This module can do the following
- Check what platform your currently running and adapt the downloads for that, if your running x86, amd64, arm64.
- Make sure that you have WinGet installed and up to date, if it's not the module will install / update it for you to the latest version.
- Make sure that you have Microsoft.VCLibs installed, if not the module will install it for you.
- If your running this module with PowerShell 7 this module will check if PowerShell 7 have any newer versions, and if it's any newer version it will download and update PowerShell 7
- Update all your softwares with WinGet

# Links
* [My PowerShell Collection](https://github.com/rstolpe/PSCollection)
* [Webpage/Blog](https://www.stolpe.io)
* [Twitter](https://twitter.com/rstolpes)
* [LinkedIn](https://www.linkedin.com/in/rstolpe/)
* [PowerShell Gallery](https://www.powershellgallery.com/profiles/rstolpe)

# Help
Below I have specified things that I think will help people with this module.  
You can also see the API for each function in the [help folder](https://github.com/rstolpe/WinSoftwareUpdate/tree/main/help)

## Install
Install for current user
```
Install-Module -Name WinSoftwareUpdate -Scope CurrentUser -Force
```
  
Install for all users
```
Install-Module -Name WinSoftwareUpdate -Scope AllUsers -Force
```

# Update-RSWinSoftware
Run the complete update
````
Update-RSWinSoftware
````
  
Only checks if your softwares are up to date with WinGet. This will not verify if WinGet or Microsoft.VCLibs is up to date.
````
Update-RSWinSoftware -SkipVersionCheck
````


