
NAME
    Install-RSVCLib
    
SYNOPSIS
    This function is connected and used of the main function for this module, Update-RSWinSoftware.
    So when you run the Update-RSWinSoftware function this function will be called during the process.
    
    
SYNTAX
    Install-RSVCLib [-VCLibsOutFile] <String> [-VCLibsUrl] <String> [<CommonParameters>]
    
    
DESCRIPTION
    This function will install VCLibs if it's not installed on the computer.
    

PARAMETERS
    -VCLibsOutFile <String>
        The path to the output file for the VCLibs when downloaded, this is pasted from the main function for this module, Update-RSWinSoftware.
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -VCLibsUrl <String>
        The url path to where the VCLibs can be downloaded from, this is pasted from the main function for this module, Update-RSWinSoftware.
        
        Required?                    true
        Position?                    2
        Default value                
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
    
    
RELATED LINKS
    https://github.com/rwidmark/WinSoftwareUpdate/blob/main/README.md


