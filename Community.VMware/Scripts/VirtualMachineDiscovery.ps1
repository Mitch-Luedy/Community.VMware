param($sourceId,$managedEntityId,$vCenterServerName)

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
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenterServerName")
}

$ScriptName = 'Community.VMware.Discovery.VirtualMachines.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

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
	}
}

If ($connection.IsConnected -ne $True){
	ExitPrematurely ("Unable to connect to vCenter server " + $vCenterServerName)
}

Try {$VMwareVirtualMachines = (Get-View -Server $connection -ViewType VirtualMachine -Property Name,Summary -Filter @{"Config.Template"="false"}) | Select Name,Summary}
Catch {DefaultErrorLogging}

If (!$VMwareVirtualMachines){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	ExitPrematurely ("No VMs found in vCenter " + $vCenterServerName)
}

ForEach ($VM in $VMwareVirtualMachines){

	#Virtual Machine Obj
	$VMInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.VirtualMachine']$")
	$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineName$", [string]$VM.Name )
	$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineHostName$", [string]$VM.Summary.Guest.HostName )
	$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineId$", [string]$VM.Summary.Vm )
	$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
	$VMInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$",  [string]$VM.Name )
	$discoveryData.AddInstance($VMInstance)
	
	#vCenter Obj (already discovered)
	$vCenterObj = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vCenter']$")
	$vCenterObj.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )

	#vCenter Hosts Virtual Machine
	$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.vCenterHostsVirtualMachine']$")
	$rel1.Source = $vCenterObj
	$rel1.Target = $VMInstance
	$discoveryData.AddInstance($rel1)
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}
$discoveryData