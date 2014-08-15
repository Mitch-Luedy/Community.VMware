param($vCenterServerName)

$ScriptName = 'Community.VMware.Probe.DatacenterDatastorePerf.ps1'
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

Try {$VMdatacentersView = Get-View -Server $connection -ViewType Datacenter -Property Datastore | Select Datastore,MoRef}
Catch {DefaultErrorLogging}

If (!$VMdatacentersView){
	LogScriptEvent 0 ("No datacenters found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}

Try {$VMdatastores = Get-View -Server $connection -ViewType Datastore -Property Summary | Select Summary}
Catch {DefaultErrorLogging}

If (!$VMdatastores){
	LogScriptEvent 0 ("No datastores found in vCenter server " + $vCenterServerName)
	Try {Disconnect-VIServer -Server $connection -Confirm:$false}
	Catch {DefaultErrorLogging}
	exit
}

ForEach ($VMdatacenter in $VMdatacentersView){

	$CAPACITY_GB	= 0
	$FREE_GB		= 0
	$USED_GB		= 0
	$CAPACITY_TB	= 0
	$FREE_TB		= 0
	$USED_TB		= 0

	ForEach ($VMdatastore in $VMdatacenter.Datastore){

		$VMdatastoreView = $VMdatastores | Where {$_.Summary.Datastore -eq [string]$VMdatastore}
		
		If ($VMdatastoreView){
			
			$Store_CAPACITY_GB	= $VMdatastoreView.Summary.Capacity * (9.31323e-10)
			$Store_FREE_GB		= $VMdatastoreView.Summary.FreeSpace * (9.31323e-10)
			$Store_USED_GB		= ($VMdatastoreView.Summary.Capacity - $VMdatastoreView.Summary.FreeSpace)*(9.31323e-10)
			$Store_CAPACITY_TB	= $VMdatastoreView.Summary.Capacity * (9.09495e-13)
			$Store_FREE_TB		= $VMdatastoreView.Summary.FreeSpace * (9.09495e-13)
			$Store_USED_TB		= ($VMdatastoreView.Summary.Capacity - $VMdatastoreView.Summary.FreeSpace)*(9.09495e-13)
			
			$CAPACITY_GB	= $CAPACITY_GB + $Store_CAPACITY_GB
			$FREE_GB		= $FREE_GB + $Store_FREE_GB
			$USED_GB		= $USED_GB + $Store_USED_GB
			$CAPACITY_TB	= $CAPACITY_TB + $Store_CAPACITY_TB
			$FREE_TB		= $FREE_TB + $Store_FREE_TB
			$USED_TB		= $USED_TB + $Store_USED_TB
		}
	}
	
	If ($CAPACITY_GB -ne 0){
		$FREE_Percent	= [math]::Round((($FREE_GB * 100)/$CAPACITY_GB) , 2)
		$USED_Percent	= [math]::Round((($USED_GB * 100)/$CAPACITY_GB) , 2)
	}
	$CAPACITY_GB	= [math]::Round($CAPACITY_GB, 2)
	$FREE_GB		= [math]::Round($FREE_GB, 2)
	$USED_GB		= [math]::Round($USED_GB, 2)
	$CAPACITY_TB	= [math]::Round($CAPACITY_TB, 2)
	$FREE_TB		= [math]::Round($FREE_TB, 2)
	$USED_TB		= [math]::Round($USED_TB, 2)
	
	$bag = $api.CreatePropertyBag()
	$bag.AddValue('DatacenterId', [string]$VMdatacenter.MoRef)
	$bag.AddValue('vCenterServerName',$vCenterServerName)
	$bag.AddValue('CAPACITY_GB',$CAPACITY_GB)
	$bag.AddValue('FREE_GB',$FREE_GB)
	$bag.AddValue('USED_GB',$USED_GB)
	$bag.AddValue('FREE_Percent',$FREE_Percent)
	$bag.AddValue('CAPACITY_TB',$CAPACITY_TB)
	$bag.AddValue('FREE_TB',$FREE_TB)
	$bag.AddValue('USED_TB',$USED_TB)
	$bag
}
Try {Disconnect-VIServer -Server $connection -Confirm:$false}
Catch {DefaultErrorLogging}