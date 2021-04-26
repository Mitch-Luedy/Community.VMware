param($vCenterServerName)

$ScriptName = 'Community.VMware.Probe.HostPerf.ps1'
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

$vCenter=$vCenterServerName

#if(($a -ne "WinvCenter") -and ($a.content.vCenterServerNames -ne ""  -and $a.content.vCenterServerNames -ne $null )){ 
#    $vCenterServerName=($a.content.vCenterServerNames).split(",")
#}else{$vCenter=$vCenterServerName}

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Date: $( Get-Date)" | Out-File $EnhancedLoggingPath -append }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" vCenterServerNames: $vCenter" | Out-File $EnhancedLoggingPath -append  }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }


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
}

Function DefaultErrorLogging {
Param ([string]$vCenter)
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rvCenterServerName:$vCenter")

	#Append Logs 
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rvCenterServerName:$vCenter"  | Out-File $EnhancedLoggingPath -append   }


}

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

#foreach($vCenter in $vCenterServerName | Where-Object {$_ -ne $null -and $_ -ne ""}){

    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append   }
     
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


    if($connection.IsConnected -ne $true){
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to connect to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
        DefaultErrorLogging -vCenter $vCenter
        ExitPrematurely ("Unable to disconnect from vCenter server " + $vCenter)
    }Else{
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connected to vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append} 
    }


    #Try {$VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Summary | Select Summary}
    Try {
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Trying to get host view from $vCenter" | Out-File $EnhancedLoggingPath -append }  

        $VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Summary | Select Summary
        
    }
    Catch {
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Failed to get view, will retry in 15 seconds" | Out-File $EnhancedLoggingPath -append}   

        Start-Sleep -Seconds 10
        Try{
                    
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Retrying to get the view again" | Out-File $EnhancedLoggingPath -append }  

            $VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Summary | Select Summary
        }
        Catch{
                            
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Failed again, giving up.." | Out-File $EnhancedLoggingPath -append}   
            DefaultErrorLogging -vCenter $vCenter
        }
        #DefaultErrorLogging -vCenter $vCenter
    }
    
    

    ForEach ($VMhost in $VMhosts){

        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM Host: $VMHost" | Out-File $EnhancedLoggingPath -append   }
	    $CPU_UsageMHz	= $VMhost.Summary.QuickStats.OverallCpuUsage
	    $CPU_MaxMHz		= $VMhost.Summary.Hardware.CpuMhz * $VMhost.Summary.Hardware.NumCpuCores
	    $CPU_FreeMHz	= $CPU_MaxMHz - $CPU_UsageMHz
	    $CPU_Percent	= [math]::Round($CPU_UsageMHz*100/$CPU_MaxMHz)
	
	    $MEM_UsageMB	= $VMhost.Summary.QuickStats.OverallMemoryUsage
	    $MEM_MaxMB		= [math]::Round($VMhost.Summary.Hardware.MemorySize/1048576)
	    $MEM_FreeMB		= $MEM_MaxMB - $MEM_UsageMB
	    $MEM_Percent	= [math]::Round($MEM_UsageMB*100/$MEM_MaxMB)

	    $bag = $api.CreatePropertyBag()
	    $bag.AddValue('HostId',[string]$VMhost.Summary.Host)
	    $bag.AddValue('vCenterServerName',$vCenter)
	    $bag.AddValue('CPU_UsageMHz',$CPU_UsageMHz)
	    $bag.AddValue('CPU_MaxMHz',$CPU_MaxMHz)
	    $bag.AddValue('CPU_FreeMHz',$CPU_FreeMHz)
	    $bag.AddValue('CPU_Percent',$CPU_Percent)
	    $bag.AddValue('MEM_UsageMB',$MEM_UsageMB)
	    $bag.AddValue('MEM_MaxMB',$MEM_MaxMB)
	    $bag.AddValue('MEM_FreeMB',$MEM_FreeMB)
	    $bag.AddValue('MEM_Percent',$MEM_Percent)
	    $bag
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

#}