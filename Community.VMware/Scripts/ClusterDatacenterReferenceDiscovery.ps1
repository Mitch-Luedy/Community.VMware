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

$ScriptName = 'Community.VMware.Discovery.ClusterDatacenterReference.ps1'
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

#Get Already Discovered Datacenters from SCOM
Try {$VMdatacenterObjs = Get-SCOMClass -Name 'Community.VMware.Class.Datacenter' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

If (!$VMdatacenterObjs){
	ExitPrematurely ("No VM Datacenters found discovered in SCOM for vCenter " + $vCenterServerName)
}

#Get Already Discovered VM Clusters from SCOM
Try {$VMclusterObjs = Get-SCOMClass -Name 'Community.VMware.Class.Cluster' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Exit if no VM Clusters were discovered, because there is no relationship to build
If (!$VMclusterObjs){
	ExitPrematurely ("No VM Clusters found discovered in SCOM for vCenter " + $vCenterServerName)
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

Try {$VMwareDatacenters = Get-Datacenter -Server $connection}
Catch {DefaultErrorLogging}

If (!$VMwareDatacenters){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	ExitPrematurely ("No VM Datacenters found in vCenter " + $vCenterServerName)
}

ForEach ($VMdatacenter in $VMwareDatacenters){

	#Verify VMdatacenter is in SCOM
	If ($VMdatacenterObjs | Where {$_.'[Community.VMware.Class.Datacenter].DatacenterId'.Value -eq [string]$VMdatacenter.Id}){

		#Get VM Clusters in this datacenter
		$VMclustersInDatacenter = $VMdatacenter | Get-Cluster | Get-View -Property Name | Select Name,MoRef

		If ($VMclustersInDatacenter){
		
			#VM datacenter Obj (already discovered)
			$VMdatacenterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Datacenter']$")
			$VMdatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Datacenter']/DatacenterId$", [string]$VMdatacenter.Id )
			$VMdatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
		
			ForEach ($VMcluster in $VMclustersInDatacenter){
			
				#Verify Cluster is in SCOM
				If ($VMclusterObjs | Where {$_.'[Community.VMware.Class.Cluster].ClusterId'.Value -eq [string]$VMcluster.MoRef}){

					#VM Cluster Obj (already discovered)
					$VMclusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Cluster']$")
					$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Cluster']/ClusterId$", [string]$VMcluster.MoRef )
					$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
					
					#Cluster references Datacenter
					$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.ClusterReferencesDatacenter']$")
					$rel1.Source = $VMclusterInstance
					$rel1.Target = $VMdatacenterInstance
					$discoveryData.AddInstance($rel1)
				}
			}
		}
	}
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}
$discoveryData