param($vCenterServerName)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}
 
$ScriptName = 'Community.VMware.Probe.VirtualMachineState.ps1'
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
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rvCenterServerName:$vCenterServerName")
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

Try {$VirtualMachines = Get-View -Server $connection -ViewType VirtualMachine -Property Summary | Select Summary,MoRef}
Catch {DefaultErrorLogging}

<#
If (!$VirtualMachines){
	LogScriptEvent 0 ("No virtual machines found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}
#>

ForEach ($VirtualMachine in $VirtualMachines){

	$bag = $api.CreatePropertyBag()
	$bag.AddValue('VirtualMachineId', [string]$VirtualMachine.MoRef)
	$bag.AddValue('vCenterServerName', $vCenterServerName)
	$bag.AddValue('PowerState',[string]$VirtualMachine.Summary.Runtime.PowerState)
	$bag
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}