param($sourceId,$managedEntityId)

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

$ScriptName = 'Community.VMware.Discovery.VirtualMachineComputerRelationship.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

Try {Import-Module OperationsManager}
Catch {DefaultErrorLogging}

Try {New-SCOMManagementGroupConnection 'localhost'}
Catch {DefaultErrorLogging}

Try {$MGconn = Get-SCOMManagementGroupConnection | Where {$_.IsActive -eq $true}}
Catch {DefaultErrorLogging}

If(!$MGconn){
	ExitPrematurely ("Unable to connect to the local management group")
}

Try {$VMobjs = Get-SCOMClass -Name 'Community.VMware.Class.VirtualMachine' | Get-SCOMClassInstance}
Catch {DefaultErrorLogging}

Try {$ComputerObjs = Get-SCOMClass -Name 'System.Computer' | Get-SCOMClassInstance}
Catch {DefaultErrorLogging}

ForEach ($VM in $VMobjs){
	
	Try {$MatchingComputerObj = $ComputerObjs | Where {$_.DisplayName -eq ($VM.'[Community.VMware.Class.VirtualMachine].VirtualMachineHostName'.Value)}}
	Catch {DefaultErrorLogging}
	If ($MatchingComputerObj){

		#Get Computer Class Type
		Try {$ClassType = Get-SCOMClass -Id ($MatchingComputerObj.LeastDerivedNonAbstractMonitoringClassId) | Select Name}
		Catch {DefaultErrorLogging}
		
		#If a Winodows Computer
		If ($ClassType.Name -eq 'Microsoft.Windows.Computer'){

			#Create Windows Computer Object for discovery
			$WindowsInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Windows!Microsoft.Windows.Computer']$")
			$WindowsInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", [string]$MatchingComputerObj.'[Microsoft.Windows.Computer].PrincipalName'.Value )
			
			#Create Virtual Machine object for discovery
			$VMinstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.VirtualMachine']$")
			$VMinstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineId$", [string]$VM.'[Community.VMware.Class.VirtualMachine].VirtualMachineId'.Value )
			$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$",  [string]$VM.'[Community.VMware.Class.vCenter].vCenterServerName'.value )
			
			#Create Relationship (Virtual Machine Contains Computer)
			$rel1 =  $discoveryData.CreateRelationshipInstance("$MPElement[Name='SVL!System.VirtualMachineContainsComputer']$")
			$rel1.source = $VMinstance
			$rel1.target = $WindowsInstance
			$discoveryData.AddInstance($rel1)
		}
		ElseIf ($ClassType.Name -eq 'Microsoft.Unix.Computer'){

			#Create Unix Computer Object for discovery
			$WindowsInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Unix!Microsoft.Unix.Computer']$")
			$WindowsInstance.AddProperty("$MPElement[Name='Unix!Microsoft.Unix.Computer']/PrincipalName$", [string]$MatchingComputerObj.'[Microsoft.Unix.Computer].PrincipalName'.Value )
			
			#Create Virtual Machine object for discovery
			$VMinstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.VirtualMachine']$")
			$VMinstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineId$", [string]$VM.'[Community.VMware.Class.VirtualMachine].VirtualMachineId'.Value )
			$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$",  [string]$VM.'[Community.VMware.Class.vCenter].vCenterServerName'.value )
			
			#Create Relationship (Virtual Machine Contains Computer)
			$rel1 =  $discoveryData.CreateRelationshipInstance("$MPElement[Name='SVL!System.VirtualMachineContainsComputer']$")
			$rel1.source = $VMinstance
			$rel1.target = $WindowsInstance
			$discoveryData.AddInstance($rel1)
		}
		     
		#Can't determine Computer Class Type
		Else {
			$api.LogScriptEvent($ScriptName,1985,2,('Unable to map '+ $MatchingComputerObj.DisplayName +' to class '+ $ClassType.Name))
		}
	}
}
$discoveryData