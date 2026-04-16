![GitHub](https://img.shields.io/github/license/rwidmark/WinSoftwareUpdate?style=plastic)  
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/rwidmark/WinSoftwareUpdate?sort=semver&style=plastic) ![Last release](https://img.shields.io/github/release-date/rwidmark/WinSoftwareUpdate?style=plastic)  
![GitHub last commit](https://img.shields.io/github/last-commit/rwidmark/WinSoftwareUpdate?style=plastic)  
![PSGallery downloads](https://img.shields.io/powershellgallery/dt/WinSoftwareUpdate?style=plastic)

# WinSoftwareUpdate

WinSoftwareUpdate updates supported software on:

- **Windows** by validating required Appx dependencies, keeping WinGet current, and running `winget upgrade --all`
- **macOS** by using Homebrew to refresh metadata and upgrade installed formulae and casks

The module now supports `-Verbose`, `-WhatIf`, and `-Confirm` on all mutating commands.

## Requirements

### Windows
- Windows 10 or Windows 11
- Administrator privileges when running `Update-RSWinSoftware`

### macOS
- Homebrew installed and available on `PATH`

## Install

Install for the current user:

```powershell
Install-Module -Name WinSoftwareUpdate -Scope CurrentUser -Force
```

Install for all users:

```powershell
Install-Module -Name WinSoftwareUpdate -Scope AllUsers -Force
```

## Usage

Run the full update flow on the current platform:

```powershell
Update-RSWinSoftware
```

Preview the work without making changes:

```powershell
Update-RSWinSoftware -WhatIf -Verbose
```

Inspect the cached platform information used by the module:

```powershell
Get-rsSystemInfo
```

## Exported commands

- `Update-RSWinSoftware`
- `Get-rsSystemInfo`
- `Confirm-rsDependency`
- `Confirm-rsPowerShell7`
- `Confirm-rsWinGet`

## Help

Command help is stored in the [`Help`](./Help) directory.

## Links

- [My PowerShell Collection](https://github.com/rwidmark/PSCollection)
- [Webpage/Blog](https://widmark.dev)
- [X](https://twitter.com/widmark_robin)
- [Mastodon](https://mastodon.social/@rwidmark)
- [YouTube](https://www.youtube.com/@rwidmark)
- [LinkedIn](https://www.linkedin.com/in/rwidmark/)
- [GitHub](https://github.com/rwidmark)
