param($vCenterServerName)

$ScriptName = 'Community.VMware.Probe.HostState.ps1'
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
	Add-PSSnapin VMware.VimAutomation.Core
} Catch {
	Start-Sleep -Seconds 10
	Try {
		Add-PSSnapin VMware.VimAutomation.Core
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

<#
If ($connection.IsConnected -ne $True){
	LogScriptEvent 0 ("Unable to connect to vCenter server " + $vCenterServerName)
	exit
}
#>

Try {$VMhosts = Get-View -Server $connection -ViewType HostSystem -Property Runtime | Select Runtime,MoRef}
Catch {DefaultErrorLogging}

<#
If (!$VMhosts){
	LogScriptEvent 0 ("No hosts found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}
#>

ForEach ($VMhost in $VMhosts){

	$bag = $api.CreatePropertyBag()
	$bag.AddValue('HostId', [string]$VMhost.MoRef)
	$bag.AddValue('vCenterServerName', $vCenterServerName)
	$bag.AddValue('PowerState',[string]$VMhost.Runtime.PowerState)
	$bag
}

Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}