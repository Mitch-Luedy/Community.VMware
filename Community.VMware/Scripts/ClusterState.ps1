param($vCenterServerName)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}

$ScriptName = 'Community.VMware.Probe.ClusterState.ps1'
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

Try {$VMclusters = Get-View -Server $connection -ViewType ClusterComputeResource -Property Summary | Select Summary, MoRef}
Catch {DefaultErrorLogging}

<#
If (!$VMclusters){
	LogScriptEvent 0 ("No clusters found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}
#>

ForEach ($VMcluster in $VMclusters){

	$bag = $api.CreatePropertyBag()
	$bag.AddValue('ClusterId', [string]$VMcluster.MoRef)
	$bag.AddValue('vCenterServerName',$vCenterServerName)
	$bag.AddValue('CurrentFailoverLevel', $VMcluster.Summary.CurrentFailoverLevel)
	$bag
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}