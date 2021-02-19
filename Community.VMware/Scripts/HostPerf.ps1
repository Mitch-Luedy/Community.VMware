param($vCenterServerName)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}
 
$ScriptName = 'Community.VMware.Probe.HostPerf.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'

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
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rvCenterServerName:$vCenterServerName")
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

Try {
	$connection = Connect-VIServer -Server $vCenterServerName -Force:$true -NotDefault
} Catch {
	Start-Sleep -Seconds 10
	Try {
		$connection = Connect-VIServer -Server $vCenterServerName -Force:$true -NotDefault
	} Catch {
		DefaultErrorLogging
		Exit
	}
}

Try {$VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Summary | Select Summary}
Catch {DefaultErrorLogging}

ForEach ($VMhost in $VMhosts){

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
	$bag.AddValue('vCenterServerName',$vCenterServerName)
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
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}