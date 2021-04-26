param($sourceId,$managedEntityId,$vCenterServerName)
$ScriptName = 'Community.VMware.Discovery.ClusterHostContainment.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'

Set-PowerCLIConfiguration -ProxyPolicy NoProxy -InvalidCertificateAction Ignore -ParticipateInCeip $false -Scope Session -Confirm:$false

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

# if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {Start-Transcript -Path $EnhancedLoggingPath -Append -Verbose -NoClobber -Force}

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"vCenterServerName passed to script: $vCenterServerName " | Out-File $EnhancedLoggingPath -append   }

#
#if( ($a -ne "WinvCenter" -and $a.content.vCenterServerNames -ne ""  -and $a.content.vCenterServerNames -ne $null )){ 
#    $vCenterServerName=($a.content.vCenterServerNames).split(",")
#}else{$vCenter=$vCenterServerName}
#

$vCenter=$vCenterServerName

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Date: $( Get-Date)" | Out-File $EnhancedLoggingPath -append}
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"SorceID: $sourceId,  Managed Entity ID: $managedEntityId,  vCenter Server Name: $vCenterServerName" | Out-File $EnhancedLoggingPath -append  }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }


Function ExitPrematurely ($Message){
	$discoveryData.IsSnapshot = $false
	$api.LogScriptEvent($ScriptName,1985,2,$Message)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$ScriptName,1985,$EventLevel,$Message" | Out-File $EnhancedLoggingPath -append }
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Discovery Data: $discoveryData" | Out-File $EnhancedLoggingPath -append }

	$discoveryData
    # if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {Stop-Transcript -Verbose}
    do {
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Forcing disconnect from vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append   }

        $connection=Get-VIServer -Server $vCenter -NotDefault  
	    Disconnect-VIServer -Server $connection -Confirm:$false -force:$true
        $connection=Get-VIServer -Server $vCenter -NotDefault
        if($connection.IsConnected -eq $true){
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to disconnect from vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
		    DefaultErrorLogging -vCenter $vCenter
		    Start-Sleep -Seconds 15
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -eq $true)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"PID: $PID" | Out-File $EnhancedLoggingPath -append   }
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }
	exit
}

Function LogScriptEvent {
	Param (
		
		#0 = Informational
		#1 = Error
		#2 = Warning
		[parameter(Mandatory=$true)]
		[ValidateRange(0,2)]
		[int]$EventLevel,		
		[parameter(Mandatory=$true)]
		[string]$Message
	)

	$api.LogScriptEvent($ScriptName,1985,$EventLevel,$Message)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$ScriptName,1985,$EventLevel,$Message" | Out-File $EnhancedLoggingPath -append }

}

Function DefaultErrorLogging {
Param ([string]$vCenter)
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter")
	
	#Append LogFIle
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter" | Out-File $EnhancedLoggingPath -append }

}

$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

Try {Import-Module OperationsManager}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging}

Try {New-SCOMManagementGroupConnection 'localhost'}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging}

Try {$MGconn = Get-SCOMManagementGroupConnection | Where {$_.IsActive -eq $true}}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging}

If(!$MGconn){
	ExitPrematurely ("Unable to connect to the local management group")
}


$ExistingConnection=$null
$date=Get-Date
if($vCenter -ne $null -and $vcenter -ne ""){
    
    do {
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connecting to vCenter Server Name: $vCenter, Opening new session" | Out-File $EnhancedLoggingPath -append   }
        $connection = Connect-VIServer -Server $vCenter -Force:$true -NotDefault
        if($connection.IsConnected -ne $true){
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
	        DefaultErrorLogging -vCenter $vCenter
            #Disconnect-VIServer -Server $vCenter -force:$true -confirm:$false
	        Start-Sleep -Seconds 10
            
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -ne $true)

    if($connection.IsConnected -ne $true){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
        DefaultErrorLogging -vCenter $vCenter
        ExitPrematurely ("Unable to disconnect from vCenter server " + $vCenter)
    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connected to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
    }
}Else{
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"No vCenter Server Name passes, Exiting" | Out-File $EnhancedLoggingPath -append} 

    ExitPrematurely ("No vCenter Server Name passes, Exiting")
}

#Get Already Discovered Hosts from SCOM
Try {$VMhostbjs = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenter}}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLoggingr}

If (!$VMhostbjs){
	ExitPrematurely ("No VM Hosts found discovered in SCOM for vCenter " + $vCenter)
}

Try {
	Import-Module VMware.VimAutomation.Core
} Catch {
	Start-Sleep -Seconds 10
	Try {
		Import-Module VMware.VimAutomation.Core
	} Catch {
		DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging
		ExitPrematurely("Unable to import VMware Module")
	}
}

$ExistingConnection=$null
$date=Get-Date
if($vCenter -ne $null -and $vcenter -ne ""){
    
    do {
        $ExistingConnection=Get-VIServer -Server $vCenter -NotDefault  
        if($ExistingConnection.IsConnected -eq $true){
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"attempting to connet to existing session $a.SessionId on vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append   }
		    $connection = Connect-VIServer -Server $vCenter -Force:$true -session $ExistingConnection.SessionId -NotDefault 

    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"No existing session on vCenter Server Name: $vCenter, Opening new session" | Out-File $EnhancedLoggingPath -append   }
        $connection = Connect-VIServer -Server $vCenter -Force:$true -NotDefault
    }

        if($connection.IsConnected -ne $true){
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
	        DefaultErrorLogging -vCenter $vCenter
	        Start-Sleep -Seconds 10
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -ne $true)


    if($connection.IsConnected -ne $true){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
        DefaultErrorLogging -vCenter $vCenter
        ExitPrematurely ("Unable to disconnect from vCenter server " + $vCenter)
    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connected to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
    }
}Else{
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"No vCenter Server Name passed, Exiting" | Out-File $EnhancedLoggingPath -append} 

    ExitPrematurely("No vCenter passed to script")
}

Try {$VMwareClusters = (Get-View -Server $connection -ViewType ClusterComputeResource -Property Host) | Select Host,MoRef}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging}

If (!$VMwareClusters){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging $EnhancedLogging}
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"No VM Clusters found in vCenter " + $vCenter | Out-File $EnhancedLoggingPath -append  }
	ExitPrematurely ("No VM Clusters found in vCenter " + $vCenter)
}

ForEach ($VMcluster in $VMwareClusters){
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM Cluster: $VVMcluster" | Out-File $EnhancedLoggingPath -append }

	If ($VMclusterObjs | Where {$_.'[Community.VMware.Class.Cluster].ClusterId'.Value -eq [string]$VMcluster.MoRef}){

		#VM Host Obj (already discovered)
		$VMclusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Cluster']$")
		$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Cluster']/ClusterId$", [string]$VMcluster.MoRef )
		$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter )
		
		ForEach ($VMhost in $VMcluster.Host){

			$MatchingHost = $VMhostbjs | Where {$_.'[Community.VMware.Class.Host].HostId'.Value -eq [string]$VMHost}
			If ($MatchingHost){

				#Host Obj (already discovered)
				$VMhostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
				$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]$MatchingHost.'[Community.VMware.Class.Host].HostId'.Value )
				$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter )
				
				#Cluster Contains Host
				$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.ClusterContainsHost']$")
				$rel1.Source = $VMclusterInstance
				$rel1.Target = $VMhostInstance
				$discoveryData.AddInstance($rel1)
			}
		}
	}
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

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Discovery Data: $discoveryData" | Out-File $EnhancedLoggingPath -append }

$discoveryData

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ============  vCenter $vCenter finnished  ====================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
# if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {Stop-Transcript -Verbose}
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"PID: $PID" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }

Exit