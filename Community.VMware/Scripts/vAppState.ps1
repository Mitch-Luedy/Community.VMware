param($vCenterServerName)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}
 
$ScriptName = 'Community.VMware.Probe.vAppState.ps1'
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

Try {$vApps = Get-View -Server $connection -ViewType VirtualApp -Property Summary | Select Summary,MoRef}
Catch {DefaultErrorLogging}

<#
If (!$vApps){
	LogScriptEvent 0 ("No vApps found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}
#>

ForEach ($vApp in $vApps){

	$bag = $api.CreatePropertyBag()
	$bag.AddValue('vAppId', [string]$vApp.MoRef)
	$bag.AddValue('vCenterServerName', $vCenterServerName)
	$bag.AddValue('State',[string]$vApp.Summary.VAppState)
	$bag
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}