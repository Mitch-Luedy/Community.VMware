param($sourceId,$managedEntityId,$vCenterServerName)

if (Test-path C:\vCenter\Server.txt){
    $Server=(Get-content C:\vCenter\Server.txt).Trim()
    $vCenterServerName=$Server
}
 
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

$ScriptName = 'Community.VMware.Discovery.vAppHostAndClusterReferenceRelationship.ps1'
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

#Get Already Discovered vApps from SCOM
Try {$vAppObjs = Get-SCOMClass -Name 'Community.VMware.Class.vApp' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Exit if no VMs are discovered, because there is no relationship to build
If (!$vAppObjs){
	ExitPrematurely ("No vApps found discovered in SCOM for vCenter " + $vCenterServerName)
}

#Get Already Discovered Clusters from SCOM
Try {$VMclusterObjs = Get-SCOMClass -Name 'Community.VMware.Class.Cluster' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Get Already Discovered Clusters from SCOM
Try {$VMhostObjs = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

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
	}
}

If ($connection.IsConnected -ne $True){
	ExitPrematurely ("Unable to connect to vCenter server " + $vCenterServerName)
}

Try {$VMwarevApps = Get-View -Server $connection -ViewType VirtualApp -Property Owner | Select Owner,MoRef}
Catch {DefaultErrorLogging}

If (!$VMwarevApps){
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	ExitPrematurely ("No vApps found in vCenter " + $vCenterServerName)
}

ForEach ($vApp in $VMwarevApps){

	#Only move forward with already discovered vApps
	If ($vAppObjs | Where {$_.'[Community.VMware.Class.vApp].vAppId'.Value -eq [string]$vApp.MoRef}){
		
		$vAppInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vApp']$")
		$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vApp']/vAppId$", [string]$vApp.MoRef)
		$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
	
		If ($VMclusterObjs | Where {$_.'[Community.VMware.Class.Cluster].ClusterId'.Value -eq [string]$vApp.Owner}){
		
			$ClusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Cluster']$")
			$ClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Cluster']/ClusterId$", [string]$vApp.Owner )
			$ClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
			
			#vApp reference Cluster
			$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.vAppReferencesCluster']$")
			$rel1.Source = $vAppInstance
			$rel1.Target = $ClusterInstance
			$discoveryData.AddInstance($rel1)
		}
		ElseIf ($VMhostObjs | Where {$_.'[Community.VMware.Class.Host].HostId'.Value -eq [string]$vApp.Owner}){
				
			$HostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
			$HostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]$vApp.Owner )
			$HostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )

			#VM reference Host
			$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.vAppReferencesHost']$")
			$rel1.Source = $vAppInstance
			$rel1.Target = $HostInstance
			$discoveryData.AddInstance($rel1)
		}
	}
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}
$discoveryData