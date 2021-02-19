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

$ScriptName = 'Community.VMware.Discovery.HostDatacenterReference.ps1'
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

#Get Already Discovered VM Hosts from SCOM
Try {$VMhostObjs = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenterServerName}}
Catch {DefaultErrorLogging}

#Exit if no VM Hosts were discovered, because there is no relationship to build
If (!$VMhostObjs){
	ExitPrematurely ("No VM Hosts found discovered in SCOM for vCenter " + $vCenterServerName)
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

		#Get VMhosts in this datacenter
		Try {$VMhostsInDatacenter = $VMdatacenter | Get-VMHost | Get-View -Property Name | Select Name,MoRef}
		Catch {DefaultErrorLogging}

		If ($VMhostsInDatacenter){
		
			#VM datacenter Obj (already discovered)
			$VMdatacenterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Datacenter']$")
			$VMdatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Datacenter']/DatacenterId$", [string]$VMdatacenter.Id )
			$VMdatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
		
			ForEach ($VMhost in $VMhostsInDatacenter){
			
				#Verify Host is in SCOM
				If ($VMhostObjs | Where {$_.'[Community.VMware.Class.Host].HostId'.Value -eq [string]$VMhost.MoRef}){

					#VM Host Obj (already discovered)
					$VMhostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
					$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", [string]$VMhost.MoRef )
					$VMhostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenterServerName )
					
					#Host references Datacenter
					$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.HostReferencesDatacenter']$")
					$rel1.Source = $VMhostInstance
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