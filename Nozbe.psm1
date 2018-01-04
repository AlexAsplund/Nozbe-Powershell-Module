<#
.SYNOPSIS
    Powershell module for Nozbe
.DESCRIPTION
    Powershell module for Nozbe using the old API because of simplicity.
    Remember to either initiate with Set-NozbeAPIKey or specify the API key for every function with -APIKey xxxxxxx
    AUTHOR: Alex Asplund (https://github.com/AlexAsplund)
.NOTES
    No warranties yadaydayada
    MIT License
#>

<#
.SYNOPSIS
    Gets your nozbe API key

.EXAMPLE
    Get-NozbeAPIKey -Username somemail@example.com -Password hunter5
    Returns the API key.
#>
function Get-NozbeAPIKey{
    [cmdletbinding()]

    param(
        # Username to Nozbe (email)
        [Parameter(Mandatory=$true)]
        [string]
        $Username,
        # Password to nozbe 
        [Parameter(Mandatory=$true)]
        [string]
        $Password
    )
    try{
        $Request = invoke-webrequest -uri "https://webapp.nozbe.com/api/login/email-$username/password-$password" -Verbose:$Verbose
    }
    catch{
        Write-Error "Error getting API-key"
        Write-Error "$_"
    }
    
    return ($Request.content | ConvertFrom-Json).key

}

<#
.SYNOPSIS
    Sets the API-key as a global variable thats used in all functions for easier handling.
.EXAMPLE
    Set-NozbeAPIKey -APIKey 1234567890
    Sets the variable GLOBAL:APIKey to the -APIKey value
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Set-NozbeAPIKey{
    [cmdletbinding()]

    param(
        [string]$APIKey
    )
    Write-Verbose "Setting Global:NozbeAPIKey"
    $Global:NozbeAPIKey = $APIKey

}

<#
.SYNOPSIS
    Gets all nozbe projects
.DESCRIPTION
    Gets all nozbe projects. Converts from json and returns it.
.EXAMPLE
    Get-NozbeProjects
    Returns all projects
.EXAMPLE
    Get-NozbeProjects -APIKey 1234567890
    Returns all projects with the specified API-key
#>
function Get-NozbeProjects{
    [cmdletbinding()]

    param(
        $APIKey = $Global:NozbeApiKey
    )
    Write-Verbose "Sending request"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/projects/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)
}

<#
.SYNOPSIS
    Returns all contexts
    You can also use -APIKey for using another API-key
.EXAMPLE
    Get-NozbeContexts
    Returns all contexts
#>
function Get-NozbeContexts{
    [cmdletbinding()]
    param(
        $APIKey = $Global:NozbeApiKey
    )
    Write-Verbose "Sending request"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/contexts/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)

}
<#
.SYNOPSIS
    Returns all actions for specified project or context
    You can also use -APIKey for using another API-key
.EXAMPLE
    Get-NozbeActions -What project -ID <project_id> -ShowDone
    Returns all actions in project project_id and includes actions marked as done.
#>
function Get-NozbeActions{
    [cmdletbinding()]
    param(
        $APIKey = $Global:NozbeApiKey,
        # What action do you want to fetch?
        [Parameter(Mandatory=$true)]
        [ValidateSet('next','project','context')]
        [string]
        $What,
        [string]
        $ID,
        [switch]$ShowDone
    )

    $ShowDoneString = "0"

    if($ShowDone){
        $ShowDoneString = "1"
    }

    if($What -eq 'next') {
        Write-Verbose "What: Next selected"
        $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/actions/showdone-$ShowDoneString/what-$what/key-$APIKey"
        return ($Response.content | ConvertFrom-Json)
    }
    else {
        if([string]::IsNullOrEmpty($ID)) {
            Write-Error "$ID is empty or null! to use -What Project/context you must supply and ID"
        }
        Write-Verbose "What: Project or Context selected"
        $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/actions/showdone-$ShowDoneString/what-$what/id-$ID/key-$APIKey"
        return ($Response.content | ConvertFrom-Json)

    }

}

function Get-NozbeNotes{
    [cmdletbinding()]
    param(
        $APIKey = $Global:NozbeApiKey,
        [Parameter(Mandatory=$true)]
        [ValidateSet('next','project','context')]
        [string]
        $What,
        [Parameter(Mandatory=$true)]
        [string]
        $ID
    )
    Write-Verbose "Fetching notes for $What - ID: $ID"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/notes/showdone-$ShowDoneString/what-$what/id-$ID/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)

}

Function Set-NozbeActionAsCompleted{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]
        $IDs,
        $APIKey = $Global:NozbeApiKey
    )
    Write-Verbose "Marking $IDs as completed"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/check/ids-$($IDs -join ";")/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)

}

Function New-NozbeAction{
    param(
        
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        # No projectID = put in inbox
        [string]
        $ProjectID,
        
        [string]
        $ContextID,
        
        [switch]
        $next,
        
        [ValidateSet('5','15','30','60','90','120','180')]
        [string]
        $Time,

        $APIKey = $Global:NozbeApiKey
    )

    if(![string]::IsNullOrEmpty($ContextID)){
        $ContextString = "context_id-$ContextID/"
    }
    else {
        $ContextString = ""
    }

    if(![string]::IsNullOrEmpty($Time)) {
        $TimeString = "time-$time/"
    }
    else{
        $TimeString = ""
    }

    $NextString = "next-false"

    if($next){
        $NextString = "next-true"
    }

    # URLEncode the name
    $Name = [System.Web.HttpUtility]::UrlEncode($Name) 
    Write-Verbose "Creating action $Name in project $ProjectID with context: $ContextID, Time $time. $NextString"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/newaction/name-$Name/project_id-$ProjectID/$ContextString$TimeString/$NextString/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)

}



Function Get-NozbeInfo {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('context','project')]
        [string]
        $What,
        [Parameter(Mandatory=$true)]
        [string]
        $ID,
        $APIKey = $Global:NozbeApiKey
    )
    Write-Verbose "Getting info about $What with ID $ID"
    $Response = Invoke-WebRequest -Uri "https://webapp.nozbe.com/api/info/what-$what/id-$ID/key-$APIKey"
    return ($Response.content | ConvertFrom-Json)
}
