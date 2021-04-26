﻿param($sourceId,$managedEntityId,$vCenterServerName)

$ScriptName = 'Community.VMware.Discovery.Host.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'

# <summary>
# 
# Input  :
# --------
#  It receives a *.ini file as Input parametrs.
#
# Output :
# --------
#    Section      Content                                                          
#    -------      -------                                                          
#    [owner]      {name,organization}
#    [database]   {server,port,file}                          
#    
#
# </summary>
 
 
 
function parseIniFile{
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String] $Inputfile
    )
 
    if ($Inputfile -eq ""){
        Write-Error "Ini File Parser: No file specified or selected to parse."
        Break
    }
    else{
 
        $ContentFile = Get-Content $Inputfile
        # commented Section
        $COMMENT_CHARACTERS = ";"
        # match section header
        $HEADER_REGEX = "\[+[A-Z0-9._ %<>/#+-]+\]" 
 
        $OccurenceOfComment = 0
        $ContentComment   = $ContentFile | Where { ($_ -match "^\s*$COMMENT_CHARACTERS") -or ($_ -match "^$COMMENT_CHARACTERS")  }  | % { 
            [PSCustomObject]@{ Comment= $_ ; 
                    Index = [Array]::IndexOf($ContentFile,$_) 
            }
            $OccurenceOfComment++
        }
 
        $COMMENT_INI = @()
        foreach ($COMMENT_ELEMENT in $ContentComment){
            $COMMENT_OBJ = New-Object PSObject
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Index -value $COMMENT_ELEMENT.Index
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Comment -value $COMMENT_ELEMENT.Comment
            $COMMENT_INI += $COMMENT_OBJ
        }
 
        $CONTENT_USEFUL = $ContentFile | Where { ($_ -notmatch "^\s*$COMMENT_CHARACTERS") -or ($_ -notmatch "^$COMMENT_CHARACTERS") } 
        $ALL_SECTION_HASHTABLE      = $CONTENT_USEFUL | Where { $_ -match $HEADER_REGEX  } | % { [PSCustomObject]@{ Section= $_ ; Index = [Array]::IndexOf($CONTENT_USEFUL,$_) }}
        #$ContentUncomment | Select-String -AllMatches $HEADER_REGEX | Select-Object -ExpandProperty Matches
 
        $SECTION_INI = @()
        foreach ($SECTION_ELEMENT in $ALL_SECTION_HASHTABLE){
            $SECTION_OBJ = New-Object PSObject
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Index -value $SECTION_ELEMENT.Index
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Section -value $SECTION_ELEMENT.Section
            $SECTION_INI += $SECTION_OBJ
        }
 
        $INI_FILE_CONTENT = @()
        $NBR_OF_SECTION = $SECTION_INI.count
        $NBR_MAX_LINE   = $CONTENT_USEFUL.count
 
        #*********************************************
        # select each lines and value of each section 
        #*********************************************
        for ($i=1; $i -le $NBR_OF_SECTION ; $i++){
            if($i -ne $NBR_OF_SECTION){
                if(($SECTION_INI[$i-1].Index+1) -eq ($SECTION_INI[$i].Index )){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($SECTION_INI[$i].Index-1)) | Out-String
                    $CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                }
            }
            else{
                if(($SECTION_INI[$i-1].Index+1) -eq $NBR_MAX_LINE){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($NBR_MAX_LINE-1)) | Out-String
                    $CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                }
            }
            $CURRENT_SECTION = New-Object PSObject
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Section -Value $SECTION_INI[$i-1].Section
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Content -Value $CONVERTED_OBJ
            $INI_FILE_CONTENT += $CURRENT_SECTION
        }
        return $INI_FILE_CONTENT
    }
}

$vCenterINI="C:\vCenter\vCenter.ini"
if (Test-Path $vCenterINI){$a=parseIniFile -Inputfile $vCenterINI}Else{$a="WinvCenter"}

$EnhancedLogging=$a.content.EnhancedLogging
$EnhancedLoggingPath=$a.content.EnhancedLoggingPath
$EnhancedLoggingPath="$EnhancedLoggingPath\$ScriptName.log"

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"vCenterServerName passed to script: $vCenterServerName " | Out-File $EnhancedLoggingPath -append   }

if(($a -ne "WinvCenter") -and ($a.content.vCenterServerNames -ne ""  -and $a.content.vCenterServerNames -ne $null )){ 
    $vCenterServerName=($a.content.vCenterServerNames).split(",")
}else{$vCenter=$vCenterServerName}

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Date: $( Get-Date)" | Out-File $EnhancedLoggingPath -append }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Source Id: $sourceId,  Managed Entity Id: $managedEntityId,  vCenterServerNames: $vCenterServerName" | Out-File $EnhancedLoggingPath -append  }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }


 
Function ExitPrematurely ($Message) {
	$discoveryData.IsSnapshot = $false
	$api.LogScriptEvent($ScriptName,1985,2,$Message)
	$discoveryData
	exit
}

Function LogScriptEvent {
	Param (
		
		#0 = Informational
		#1 = Error
		#2 = Warning
		[parameter(Mandatory=$true)]
		[ValidateRange(0,2)]
		[int]$EventLevel
		,
		
		[parameter(Mandatory=$true)]
		[string]$Message
	)

	$api.LogScriptEvent($ScriptName,1985,$EventLevel,$Message)
}

Function DefaultErrorLogging {
Param ([string]$vCenter)
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter")

	#Append Logs 
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter" | Out-File $EnhancedLoggingPath -append   }

}


$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

Try {
	Import-Module VMware.VimAutomation.Core
} Catch {
	Start-Sleep -Seconds 10
	Try {
		Import-Module VMware.VimAutomation.Core
	} Catch {
		DefaultErrorLogging
		Exit
	}
}

foreach($vCenter in $vCenterServerName | Where-Object {$_ -ne $null -and $_ -ne ""}){

    $date=Get-Date
    do {
        Try {
		    $connection = Connect-VIServer -Server $vCenter -Force:$true -NotDefault

	    } Catch {
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
		    #DefaultErrorLogging -vCenter $vCenter
		    Start-Sleep -Seconds 10
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -ne $true)


    if($connection.IsConnected -ne $True){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
        DefaultErrorLogging -vCenter $vCenter
        ExitPrematurely ("Unable to connect to vCenter server " + $vCenter)
    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connected to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
    }



    Try {
        $VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Name,Parent | Select Name,Parent,MoRef
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM Hosts: $VMhosts " | Out-File $EnhancedLoggingPath -append   }
    }
    Catch {DefaultErrorLogging -vCenter $vCenter}

    If (!$VMhosts){
	    Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	    Catch {DefaultErrorLogging -vCenter $vCenter}
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"No Hosts found in vCenter " + $vCenter | Out-File $EnhancedLoggingPath -append   }
	    ExitPrematurely ("No Hosts found in vCenter " + $vCenter)
    
    }

    ForEach ($VMhost in $VMhosts){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$VM Host: $VMHost"| Out-File $EnhancedLoggingPath -append   }
	    If ($VMhost.Parent.Type -eq 'ClusterComputeResource'){
		    $IsStandalone = 'False'
	    }
	    Else {$IsStandalone = 'True'}

	    #Host Obj
	    $VMhostObj = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
	    $VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostName$", $VMhost.Name)
	    $VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]($VMhost.MoRef))
	    $VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/IsStandalone$", $IsStandalone)
	    $VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
	    $VMhostObj.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $VMhost.Name)
	    $discoveryData.AddInstance($VMhostObj)
	
	    #vCenter Obj (already discovered)
	    $vCenterObj = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vCenter']$")
	    $vCenterObj.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter )

	    #vCenter Hosts Host
	    $rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.vCenterHostsHost']$")
	    $rel1.Source = $vCenterObj
	    $rel1.Target = $VMhostObj
	    $discoveryData.AddInstance($rel1)
    }
    
    $date=Get-Date
    do {
        Try {
		    Disconnect-VIServer -Server $connection -Confirm:$false

	    } Catch {
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to disconnect from vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
		    #DefaultErrorLogging -vCenter $vCenter
		    Start-Sleep -Seconds 10
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -eq $true)


    if($connection.IsConnected -eq $true){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to disconnect from vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
        DefaultErrorLogging -vCenter $vCenter
        ExitPrematurely ("Unable to disconnect from vCenter server " + $vCenter)
    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Disconnected from to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
    }

}
$discoveryData