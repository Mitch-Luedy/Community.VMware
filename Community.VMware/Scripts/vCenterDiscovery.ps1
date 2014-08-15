param($sourceId,$managedEntityId)

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

$api = new-object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

Try {Import-Module OperationsManager}
Catch {DefaultErrorLogging}

Try {New-SCOMManagementGroupConnection -ComputerName 'localhost'}
Catch {DefaultErrorLogging}

Try {$vCenterServerServices = Get-SCOMClass -Name 'Community.VMware.Class.vCenterServerService' | Get-SCOMClassInstance}
Catch {DefaultErrorLogging}

If (!$vCenterServerServices){

	$discoveryData.IsSnapshot = $false

}	Else {
	
	#VMware Monitoring Resource Pool Obj
	$Pool = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.ResourcePool']$")
	
	#Discover vCenter Instances
	ForEach ($vCenterServer in $vCenterServerServices){
		
		#vCenter Obj
		$vCenter = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vCenter']$")
		$vCenter.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", ($vCenterServer.'[Microsoft.Windows.Computer].PrincipalName'.Value))
		$vCenter.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", ($vCenterServer.'[Microsoft.Windows.Computer].PrincipalName'.Value))
		$discoveryData.AddInstance($vCenter)
		
		#Resource Pool Hosts vSphere
		$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.ResourcePoolHostsvCenter']$")
		$rel1.Source = $Pool
		$rel1.Target = $vCenter
		$discoveryData.AddInstance($rel1)
	}
}

#Return Discovery Data
$discoveryData