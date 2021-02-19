param($vCenterServerName,$IntervalSeconds)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}

$ScriptName = 'Community.VMware.Probe.ClusterPerf.ps1'
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

Try {$VMclusters = Get-Cluster -Server $connection}
Catch {DefaultErrorLogging}

If (!$VMclusters){
	LogScriptEvent 0 ("No clusters found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}

$Stats = ('cpu.usage.average','mem.usage.average')
Try {$VMclustersPerf = $VMclusters | Get-Stat -Stat $Stats -Start $(Get-Date).AddSeconds(-$IntervalSeconds) -MaxSamples 1}
Catch {DefaultErrorLogging}

If (!$VMclustersPerf){
	LogScriptEvent 0 ("No cluster performance counters in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}

ForEach ($VMcluster in $VMclusters){

	$CPU_Percent	= [math]::Round(($VMclustersPerf | Where {($_.Entity.Id -eq $VMcluster.Id) -and ($_.MetricId -eq 'cpu.usage.average')}).Value)
	$MEM_Percent	= [math]::Round(($VMclustersPerf | Where {($_.Entity.Id -eq $VMcluster.Id) -and ($_.MetricId -eq 'mem.usage.average')}).Value)

	$bag = $api.CreatePropertyBag()
	$bag.AddValue('ClusterId', $VMcluster.Id)
	$bag.AddValue('vCenterServerName',$vCenterServerName)
	$bag.AddValue('cpu.usage.average',$CPU_Percent)
	$bag.AddValue('mem.usage.average',$MEM_Percent)
	$bag
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}