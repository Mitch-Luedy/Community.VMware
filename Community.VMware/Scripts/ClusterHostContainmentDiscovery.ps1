param($sourceId,$managedEntityId,$vCenterServerName)

Function ExitPrematurely ($Message){
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

$ScriptName = 'Community.VMware.Discovery.ClusterHostContainment.ps1'
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

#Get Already Discovered Clusters from SCOM
Try {$VMclusterObjs = Get-SCOMClass -Name 'Community.VMware.Class.Cluster' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Exit if no VMs are discovered, because there is no relationship to build
If (!$VMclusterObjs){
	ExitPrematurely ("No VM Clusters found discovered in SCOM for vCenter " + $vCenterServerName)
}

#Get Already Discovered Hosts from SCOM
Try {$VMhostbjs = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

If (!$VMhostbjs){
	ExitPrematurely ("No VM Hosts found discovered in SCOM for vCenter " + $vCenterServerName)
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

Try {$VMwareClusters = (Get-View -Server $connection -ViewType ClusterComputeResource -Property Host) | Select Host,MoRef}
Catch {DefaultErrorLogging}

If (!$VMwareClusters){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	ExitPrematurely ("No VM Clusters found in vCenter " + $vCenterServerName)
}

ForEach ($VMcluster in $VMwareClusters){

	If ($VMclusterObjs | Where {$_.'[Community.VMware.Class.Cluster].ClusterId'.Value -eq [string]$VMcluster.MoRef}){

		#VM Host Obj (already discovered)
		$VMclusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Cluster']$")
		$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Cluster']/ClusterId$", [string]$VMcluster.MoRef )
		$VMclusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
		
		ForEach ($VMhost in $VMcluster.Host){

			$MatchingHost = $VMhostbjs | Where {$_.'[Community.VMware.Class.Host].HostId'.Value -eq [string]$VMHost}
			If ($MatchingHost){

				#Host Obj (already discovered)
				$VMhostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
				$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]$MatchingHost.'[Community.VMware.Class.Host].HostId'.Value )
				$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
				
				#Cluster Contains Host
				$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.ClusterContainsHost']$")
				$rel1.Source = $VMclusterInstance
				$rel1.Target = $VMhostInstance
				$discoveryData.AddInstance($rel1)
			}
		}
	}
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}
$discoveryData