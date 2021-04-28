param($vCenterServerName)

$ScriptName = 'Community.VMware.Probe.DatacenterDatastorePerf.ps1'
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

#if(($a -ne "WinvCenter" -and $a.content.vCenterServerNames -ne ""  -and $a.content.vCenterServerNames -ne $null )){ 
#    $vCenterServerName=($a.content.vCenterServerNames).split(",")
#}else{$vCenter=$vCenterServerName}
$vCenter=$vCenterServerName

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Date: $( Get-Date)" | Out-File $EnhancedLoggingPath -append }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" vCenterServerName: $vCenterServerName" | Out-File $EnhancedLoggingPath -append  }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }

Function ExitPrematurely ($Message) {
	$api.LogScriptEvent($ScriptName,1985,2,$Message)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$ScriptName,1985,$EventLevel,$Message" | Out-File $EnhancedLoggingPath -append }
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
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rvCenterServerName:$vCenter")

	#Append Logs
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rvCenterServerName:$vCenter" | Out-File $EnhancedLoggingPath -append }

}

Try {
	Import-Module VMware.VimAutomation.Core
} Catch {
	Start-Sleep -Seconds 10
	Try {
		Import-Module VMware.VimAutomation.Core
	} Catch {
		DefaultErrorLogging -EnhancedLogging  $EnhancedLogging 
		ExitPrematurely("Unable to load VMware Module")
	}
}

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "Connecting to vCenter Server: $vCenter" | Out-File $EnhancedLoggingPath -append }

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
Try {
    $VMdatacentersView = Get-View -Server $connection -ViewType Datacenter -Property Datastore | Select Datastore,MoRef
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "VM Datacenter View returned: $VMdatacentersView"| Out-File $EnhancedLoggingPath -append }
}
Catch {
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM  Datastore View: $VMdatastores" | Out-File $EnhancedLoggingPath  -append}
    DefaultErrorLogging -vCenter $vCenter -EnhancedLogging  $EnhancedLogging
}

If (!$VMdatacentersView){
	LogScriptEvent 0 ("No datacenters found in vCenter server " + $vCenter)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "No VM Datacenter View availible"| Out-File $EnhancedLoggingPath -append }
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging  $EnhancedLogging}
	#ExitPrematurely("No Datacenter found in vCenter server")
}

Try {
    $VMdatastores = Get-View -Server $connection -ViewType Datastore -Property Summary | Select Summary
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "VM Datasore View returned: $VMdatastores"| Out-File $EnhancedLoggingPath -append }    
}
Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging  $EnhancedLogging}

If (!$VMdatastores){
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "No VM Datastores View availible"| Out-File $EnhancedLoggingPath -append }
    LogScriptEvent 0 ("No datastores found in vCenter server " + $vCenter)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging -vCenter $vCenter -EnhancedLogging  $EnhancedLogging}
	#ExitPrematurely("No Datastore found in vCenter Server")
}

ForEach ($VMdatacenter in $VMdatacentersView){
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "Current Datacenter: $VMdatacenter "| Out-File $EnhancedLoggingPath -append }

	$CAPACITY_GB	= 0
	$FREE_GB		= 0
	$USED_GB		= 0
	$CAPACITY_TB	= 0
	$FREE_TB		= 0
	$USED_TB		= 0

	ForEach ($VMdatastore in $VMdatacenter.Datastore){

        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "Current Datastore: $VMdatastores "| Out-File $EnhancedLoggingPath -append }
		    
        $VMdatastoreView = $VMdatastores | Where {$_.Summary.Datastore -eq [string]$VMdatastore}
		if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") { "Current Datastore View: $VMdatastoreView "| Out-File $EnhancedLoggingPath -append }

		If ($VMdatastoreView){
			
			$Store_CAPACITY_GB	= $VMdatastoreView.Summary.Capacity * (9.31323e-10)
			$Store_FREE_GB		= $VMdatastoreView.Summary.FreeSpace * (9.31323e-10)
			$Store_USED_GB		= ($VMdatastoreView.Summary.Capacity - $VMdatastoreView.Summary.FreeSpace)*(9.31323e-10)
			$Store_CAPACITY_TB	= $VMdatastoreView.Summary.Capacity * (9.09495e-13)
			$Store_FREE_TB		= $VMdatastoreView.Summary.FreeSpace * (9.09495e-13)
			$Store_USED_TB		= ($VMdatastoreView.Summary.Capacity - $VMdatastoreView.Summary.FreeSpace)*(9.09495e-13)
			
			$CAPACITY_GB	= $CAPACITY_GB + $Store_CAPACITY_GB
			$FREE_GB		= $FREE_GB + $Store_FREE_GB
			$USED_GB		= $USED_GB + $Store_USED_GB
			$CAPACITY_TB	= $CAPACITY_TB + $Store_CAPACITY_TB
			$FREE_TB		= $FREE_TB + $Store_FREE_TB
			$USED_TB		= $USED_TB + $Store_USED_TB
		}
	}
	
	If ($CAPACITY_GB -ne 0){
		$FREE_Percent	= [math]::Round((($FREE_GB * 100)/$CAPACITY_GB) , 2)
		$USED_Percent	= [math]::Round((($USED_GB * 100)/$CAPACITY_GB) , 2)
	}
	$CAPACITY_GB	= [math]::Round($CAPACITY_GB, 2)
	$FREE_GB		= [math]::Round($FREE_GB, 2)
	$USED_GB		= [math]::Round($USED_GB, 2)
	$CAPACITY_TB	= [math]::Round($CAPACITY_TB, 2)
	$FREE_TB		= [math]::Round($FREE_TB, 2)
	$USED_TB		= [math]::Round($USED_TB, 2)
	
	$bag = $api.CreatePropertyBag()
	$bag.AddValue('DatacenterId', [string]$VMdatacenter.MoRef)
	$bag.AddValue('vCenterServerName',$vCenter)
	$bag.AddValue('CAPACITY_GB',$CAPACITY_GB)
	$bag.AddValue('FREE_GB',$FREE_GB)
	$bag.AddValue('USED_GB',$USED_GB)
	$bag.AddValue('FREE_Percent',$FREE_Percent)
	$bag.AddValue('CAPACITY_TB',$CAPACITY_TB)
	$bag.AddValue('FREE_TB',$FREE_TB)
	$bag.AddValue('USED_TB',$USED_TB)
	$bag
}
    
$date=Get-Date
do {
	Disconnect-VIServer -Server $connection -Confirm:$false  
    if($connection.IsConnected -eq $true){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to disconnect from vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
		DefaultErrorLogging -vCenter $vCenter
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

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ============  vCenter $vCenter finnished  ====================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
# if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {Stop-Transcript -Verbose}
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"PID: $PID" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }

Exit