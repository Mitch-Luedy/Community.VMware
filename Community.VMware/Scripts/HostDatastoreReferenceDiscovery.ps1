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

$ScriptName = 'Community.VMware.Discovery.HostDatastoreReference.ps1'
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

#Get Already Discovered VM Hosts from SCOM
Try {$VMhostObjs = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Exit if no VMs are discovered, because there is no relationship to build
If (!$VMhostObjs){
	ExitPrematurely ("No VM Hosts found discovered in SCOM for vCenter " + $vCenterServerName)
}

#Get Already Discovered Datastores from SCOM
Try {$VMdatastoreObjs = Get-SCOMClass -Name 'Community.VMware.Class.Datastore' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

If (!$VMdatastoreObjs){
	ExitPrematurely ("No VM Datastores found discovered in SCOM for vCenter " + $vCenterServerName)
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
	}
}

If ($connection.IsConnected -ne $True){
	ExitPrematurely ("Unable to connect to vCenter server " + $vCenterServerName)
}

Try {$VMwareHosts = (Get-View -Server $connection -ViewType HostSystem -Property Datastore) | Select Datastore,MoRef}
Catch {DefaultErrorLogging}

If (!$VMwareHosts){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	ExitPrematurely ("No VMs found in vCenter " + $vCenterServerName)
}

ForEach ($VMhost in $VMwareHosts){

	If ($VMhostObjs | Where {$_.'[Community.VMware.Class.Host].HostId'.Value -eq [string]$VMhost.MoRef}){

		#VM Host Obj (already discovered)
		$VMhostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
		$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]$VMhost.MoRef )
		$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
		
		ForEach ($VMdatastore in $VMhost.Datastore){

			$MatchingDatastore = $VMdatastoreObjs | Where {$_.'[Community.VMware.Class.Datastore].DatastoreId'.Value -eq [string]$VMdatastore}
			If ($MatchingDatastore){

				#Datastore Obj (already discovered)
				$VMdatastoreInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Datastore']$")
				$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Datastore']/DatastoreId$", [string]$MatchingDatastore.'[Community.VMware.Class.Datastore].DatastoreId'.Value )
				$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
				
				#VM references Datastore
				$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.HostReferencesDatastore']$")
				$rel1.Source = $VMhostInstance
				$rel1.Target = $VMdatastoreInstance
				$discoveryData.AddInstance($rel1)
			}
		}
	}
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}
$discoveryData