
NAME
    Update-RSWinSoftware
    
SYNOPSIS
    This module let users auto update their installed software on Windows 10, 11 with WinGet.
    
    
SYNTAX
    Update-RSWinSoftware [-SkipVersionCheck] [<CommonParameters>]
    
    
DESCRIPTION
    The module will check if WinGet is installed and up to date, if not it will install WinGet or update it.
    It will also if Microsoft.VCLibs is installed and if not it will install it.
    Besides that the module will check what aritecture the computer is running and download the correct version of Microsoft.VCLibs etc.
    Then it will check if there is any software that needs to be updated and if so it will update them.
    

PARAMETERS
    -SkipVersionCheck [<SwitchParameter>]
        You can decide if you want to skip the WinGet version check, default it set to false. If you use the switch -SkipVersionCheck it will skip to check the version of WinGet.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
NOTES
    
    
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
		YouTube:		https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS > Update-RSWinSoftware
    # This command will run the module and check if WinGet and VCLibs are up to date.
    
    
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS > Update-RSWinSoftware -SkipVersionCheck
    # This command will run the module without checking if WinGet and VCLibs are up to date.
    
    
    
    
    
    
    
RELATED LINKS
    https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md


