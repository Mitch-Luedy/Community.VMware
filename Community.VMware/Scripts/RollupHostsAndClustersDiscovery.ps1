param($sourceId,$managedEntityId,$vCenterServerName)

$ScriptName = 'Community.VMware.Discovery.Rollup.HostsAndClusters.ps1'
$api = new-object -comObject 'MOM.ScriptAPI'

Set-PowerCLIConfiguration -ProxyPolicy NoProxy -InvalidCertificateAction Ignore -ParticipateInCeip $false -Scope Session -Confirm:$false

# <summary>
# 
# Input  :
# --------
#  It receives a *.ini file as Input parametrs.
#
# Output :
# --------
#    Section      Content                                                          
#    -------      -------                                                          
#    [owner]      {name,organization}
#    [database]   {server,port,file}                          
#    
#
# </summary>
 
 
 
function parseIniFile{
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String] $Inputfile
    )
 
    if ($Inputfile -eq ""){
        Write-Error "Ini File Parser: No file specified or selected to parse."
        Break
    }
    else{
 
        $ContentFile = Get-Content $Inputfile
        # commented Section
        $COMMENT_CHARACTERS = ";"
        # match section header
        $HEADER_REGEX = "\[+[A-Z0-9._ %<>/#+-]+\]" 
 
        $OccurenceOfComment = 0
        $ContentComment   = $ContentFile | Where { ($_ -match "^\s*$COMMENT_CHARACTERS") -or ($_ -match "^$COMMENT_CHARACTERS")  }  | % { 
            [PSCustomObject]@{ Comment= $_ ; 
                    Index = [Array]::IndexOf($ContentFile,$_) 
            }
            $OccurenceOfComment++
        }
 
        $COMMENT_INI = @()
        foreach ($COMMENT_ELEMENT in $ContentComment){
            $COMMENT_OBJ = New-Object PSObject
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Index -value $COMMENT_ELEMENT.Index
            $COMMENT_OBJ | Add-Member  -type NoteProperty -name Comment -value $COMMENT_ELEMENT.Comment
            $COMMENT_INI += $COMMENT_OBJ
        }
 
        $CONTENT_USEFUL = $ContentFile | Where { ($_ -notmatch "^\s*$COMMENT_CHARACTERS") -or ($_ -notmatch "^$COMMENT_CHARACTERS") } 
        $ALL_SECTION_HASHTABLE      = $CONTENT_USEFUL | Where { $_ -match $HEADER_REGEX  } | % { [PSCustomObject]@{ Section= $_ ; Index = [Array]::IndexOf($CONTENT_USEFUL,$_) }}
        #$ContentUncomment | Select-String -AllMatches $HEADER_REGEX | Select-Object -ExpandProperty Matches
 
        $SECTION_INI = @()
        foreach ($SECTION_ELEMENT in $ALL_SECTION_HASHTABLE){
            $SECTION_OBJ = New-Object PSObject
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Index -value $SECTION_ELEMENT.Index
            $SECTION_OBJ | Add-Member  -type NoteProperty -name Section -value $SECTION_ELEMENT.Section
            $SECTION_INI += $SECTION_OBJ
        }
 
        $INI_FILE_CONTENT = @()
        $NBR_OF_SECTION = $SECTION_INI.count
        $NBR_MAX_LINE   = $CONTENT_USEFUL.count
 
        #*********************************************
        # select each lines and value of each section 
        #*********************************************
        for ($i=1; $i -le $NBR_OF_SECTION ; $i++){
            if($i -ne $NBR_OF_SECTION){
                if(($SECTION_INI[$i-1].Index+1) -eq ($SECTION_INI[$i].Index )){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($SECTION_INI[$i].Index-1)) | Out-String
                    $CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                }
            }
            else{
                if(($SECTION_INI[$i-1].Index+1) -eq $NBR_MAX_LINE){        
                    $CONVERTED_OBJ = @() #There is nothing between the two section
                } 
                else{
                    $SECTION_STRING = $CONTENT_USEFUL | Select-Object -Index  (($SECTION_INI[$i-1].Index+1)..($NBR_MAX_LINE-1)) | Out-String
                    $CONVERTED_OBJ = convertfrom-stringdata -stringdata $SECTION_STRING
                }
            }
            $CURRENT_SECTION = New-Object PSObject
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Section -Value $SECTION_INI[$i-1].Section
            $CURRENT_SECTION | Add-Member -Type NoteProperty -Name Content -Value $CONVERTED_OBJ
            $INI_FILE_CONTENT += $CURRENT_SECTION
        }
        return $INI_FILE_CONTENT
    }
}

$vCenterINI="C:\vCenter\vCenter.ini"
if (Test-Path $vCenterINI){$a=parseIniFile -Inputfile $vCenterINI}Else{$a="WinvCenter"}

$EnhancedLogging=$a.content.EnhancedLogging
$EnhancedLoggingPath=$a.content.EnhancedLoggingPath
$EnhancedLoggingPath="$EnhancedLoggingPath\$ScriptName.log"

# if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {Start-Transcript -Path $EnhancedLoggingPath -Append -Verbose -NoClobber -Force}

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"vCenterServerName passed to script: $vCenterServerName " | Out-File $EnhancedLoggingPath -append   }

#if(($a -ne "WinvCenter") -and ($a.content.vCenterServerNames -ne ""  -and $a.content.vCenterServerNames -ne $null )){ 
#    $vCenterServerName=($a.content.vCenterServerNames).split(",")
#}else{$vCenter=$vCenterServerName}
$vCenter=$vCenterServerName

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Date: $( Get-Date)" | Out-File $EnhancedLoggingPath -append }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" Source Id: $sourceId,  Managed Entity Id: $managedEntityId,  vCenterServerNames: $vCenter" | Out-File $EnhancedLoggingPath -append  }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ==============================================================" | Out-File $EnhancedLoggingPath -append   }


 
Function ExitPrematurely ($Message) {
	$discoveryData.IsSnapshot = $false
	$api.LogScriptEvent($ScriptName,1985,2,$Message)
	do {
        if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Forcing disconnect from vCenter Server Name: $vCenter" | Out-File $EnhancedLoggingPath -append   }

        $connection=Get-VIServer -Server $vCenter -NotDefault  
	    Disconnect-VIServer -Server $connection -Confirm:$false -force:$true
        $connection=Get-VIServer -Server $vCenter -NotDefault
        if($connection.IsConnected -eq $true){
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Unable to disconnect from vCenter Server Name: $vCenter, will retry in 10 Seconds" | Out-File $EnhancedLoggingPath -append   }
		    DefaultErrorLogging -vCenter $vCenter
		    Start-Sleep -Seconds 15
   	    }
        $Now=Get-Date
    }While($Now -lt $date.AddMinutes(1) -and $connection.IsConnected -eq $true)
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"PID: $PID" | Out-File $EnhancedLoggingPath -append   }
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }
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

Function DefaultErrorLogging ($vCenter) {
	LogScriptEvent -EventLevel 1 -Message ("$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter")

	#Appned Logs 
	if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"$_`rType:$($_.Exception.GetType().FullName)`r$($_.InvocationInfo.PositionMessage)`rReceivedParam:`rsourceId:$sourceId`rmanagedEntityId:$managedEntityId`rvCenterServerName:$vCenter" | Out-File $EnhancedLoggingPath -append   }

}


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

if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Connecting to vCenter" + $vCenter   | Out-File $EnhancedLoggingPath -append   }
#Get Already Discovered Datacenters from this vCenter
Try {$VMdatacenterObjs = Get-SCOMClass -Name 'Community.VMware.Class.Datacenter' | Get-SCOMClassInstance | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenter}}
Catch {DefaultErrorLogging -vCenter $vCenter}

If (!$VMdatacenterObjs){
	ExitPrematurely ("No VM Datacenters found discovered in SCOM for vCenter " + $vCenter)
}

#Get Already Discovered Cluster Objects from this vCenter
Try {$DiscoveredClusters = Get-SCOMClass -Name 'Community.VMware.Class.Cluster' | Get-SCOMClassInstance  | Where {$_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenter}}
Catch {DefaultErrorLogging -vCenter $vCenter}

#Get Already Discovered Standalone Hosts from this vCenter
Try {$DiscoveredStandaloneHosts = Get-SCOMClass -Name 'Community.VMware.Class.Host' | Get-SCOMClassInstance  | Where {($_.'[Community.VMware.Class.vCenter].vCenterServerName'.Value -eq $vCenter) -and ($_.'[Community.VMware.Class.Host].IsStandalone'.Value -eq 'True')}}
Catch {DefaultErrorLogging -vCenter $vCenter}

#Create RollupvCenter Object
$vCenterRootInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']$")
$vCenterRootInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
$vCenterRootInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $vCenter)
$discoveryData.AddInstance($vCenterRootInstance)

#Create RollupHostsAndClusters for THIS RollupvCenter instance
$RollupHostsAndClustersInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']$")
$RollupHostsAndClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", 'Hosts and Clusters')
$RollupHostsAndClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
$RollupHostsAndClustersInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Hosts and Clusters')
$discoveryData.AddInstance($RollupHostsAndClustersInstance)

#RollupvCenterRoot Hosts RollupHostsAndClusters
$rel1 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.vCenterHostsHostsAndClusters']$")
$rel1.Source = $vCenterRootInstance
$rel1.Target = $RollupHostsAndClustersInstance
$discoveryData.AddInstance($rel1)

ForEach ($VMdatacenter in $VMdatacenterObjs){
    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM Datacenter " + $VMdatacenter   | Out-File $EnhancedLoggingPath -append   }
	#Create RollupDatacenter Obj
	$RollupDatacenterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']$")
	$RollupDatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterName$", $VMdatacenter.DisplayName)
	$RollupDatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
	$RollupDatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
	$RollupDatacenterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
	$RollupDatacenterInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$",  $VMdatacenter.DisplayName)
	$discoveryData.AddInstance($RollupDatacenterInstance)
	
	#RollupHostsAndClusters Hosts Datacenter
	$rel2 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClustersHostsDatacenter']$")
	$rel2.Source = $RollupHostsAndClustersInstance
	$rel2.Target = $RollupDatacenterInstance
	$discoveryData.AddInstance($rel2)
	
	#Create RollupAllClusters Obj
	$RollupAllClustersInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']$")
	$RollupAllClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
	$RollupAllClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
	$RollupAllClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
	$RollupAllClustersInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
	$RollupAllClustersInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Clusters')
	$discoveryData.AddInstance($RollupAllClustersInstance)
	
	#RollupDatacenter Hosts RollupAllClusters
	$rel3 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.DatacenterHostsAllClusters']$")
	$rel3.Source = $RollupDatacenterInstance
	$rel3.Target = $RollupAllClustersInstance
	$discoveryData.AddInstance($rel3)
	
	If ($DiscoveredClusters){
	
		#Get Discovered Cluster Objects in this Datacenter
		Try {$RelClusterReferencesDatacenter = Get-SCOMRelationship -Name 'Community.VMware.Relationship.ClusterReferencesDatacenter'}
		Catch {DefaultErrorLogging -vCenter $vCenter}
		
		Try {$DiscoveredClustersInThisDatacenter = Get-SCOMRelationshipInstance -TargetInstance $VMdatacenter | Where {$_.RelationshipId  -eq $RelClusterReferencesDatacenter.Id} | Select SourceObject}
		Catch {DefaultErrorLogging -vCenter $vCenter}

		ForEach ($Cluster in $DiscoveredClustersInThisDatacenter){
		    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Dicovered Cluster: " + $Cluster   | Out-File $EnhancedLoggingPath -append   }
			#Create RollupCluster Obj
			$RollupClusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']$")
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterName$", [string]$Cluster.SourceObject )
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterId$", $Cluster.SourceObject.Name )
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
			$RollupClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
			$RollupClusterInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", [string]$Cluster.SourceObject)
			$discoveryData.AddInstance($RollupClusterInstance)
			
			#RollupAllClusters Hosts RollupCluster
			$rel4 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.AllClustersHostsCluster']$")
			$rel4.Source = $RollupAllClustersInstance
			$rel4.Target = $RollupClusterInstance
			$discoveryData.AddInstance($rel4)
			
			#Already Discovered Cluster
			$ClusterInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Cluster']$")
			$ClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Cluster']/ClusterId$", [string]$Cluster.SourceObject.Name)
			$ClusterInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
			
			#RollupCluster Contains Cluster
			$rel5 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterContainsCluster']$")
			$rel5.Source = $RollupClusterInstance
			$rel5.Target = $ClusterInstance
			$discoveryData.AddInstance($rel5)
			
			#Get Discovered Hosts In This Cluster
			$RelClusterContainsHost = Get-SCOMRelationship -Name 'Community.VMware.Relationship.ClusterContainsHost'
			$DiscoveredHostsInThisCluster = Get-SCOMRelationshipInstance -SourceInstance $Cluster.SourceObject | Where {$_.RelationshipId  -eq $RelClusterContainsHost.Id} | Select TargetObject
			
			ForEach ($DiscoveredHostInThisCluster in $DiscoveredHostsInThisCluster){
				
				#Get Virtual Machines in this Cluster Host
				$RelVirtualMachineReferencesHost = Get-SCOMRelationship -Name 'Community.VMware.Relationship.VirtualMachineReferencesHost'
				$VirtualMachinesInThisClusterHost = Get-SCOMRelationshipInstance -TargetInstance $DiscoveredHostInThisCluster.TargetObject | Where {$_.RelationshipId  -eq $RelVirtualMachineReferencesHost.Id} | Select SourceObject
				
				If ($VirtualMachinesInThisClusterHost){
				
					#Create RollupClusterVirtualMachines Instance
					$RollupClusterVirtualMachinesInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterVirtualMachines']$")
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterVirtualMachines']/Name$", 'Virtual Machines')
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterId$", $Cluster.SourceObject.Name )
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupClusterVirtualMachinesInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Virtual Machines')
					$discoveryData.AddInstance($RollupClusterVirtualMachinesInstance)
								
					#RollupCluster Hosts RollupClusterVirtualMachines
					$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterHostsVirtualMachines']$")
					$rel6.Source = $RollupClusterInstance
					$rel6.Target = $RollupClusterVirtualMachinesInstance
					$discoveryData.AddInstance($rel6)
					
					#Add VM Object to VM Rollup
					ForEach ($VirtualMachineInThisClusterHost in $VirtualMachinesInThisClusterHost){
					
						#Already Discovered VM
						$VMinstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.VirtualMachine']$")
						$VMinstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineId$", $VirtualMachineInThisClusterHost.SourceObject.Name )
						$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupClusterVirtualMachines Contains VM
						$rel7 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterVirtualMachinesContainsVirtualMachine']$")
						$rel7.Source = $RollupClusterVirtualMachinesInstance
						$rel7.Target = $VMinstance
						$discoveryData.AddInstance($rel7)
					}
				}
			
				#Get Datastores in this Cluster Host
				$RelHostReferencesDatastore = Get-SCOMRelationship -Name 'Community.VMware.Relationship.HostReferencesDatastore'
				$VMdatastoresInThisClusterHost = Get-SCOMRelationshipInstance -SourceInstance $DiscoveredHostInThisCluster.TargetObject | Where {$_.RelationshipId  -eq $RelHostReferencesDatastore.Id} | Select TargetObject
				
				If ($VMdatastoresInThisClusterHost){
					
					#Create RollupDatastore
					$RollupClusterDatastoreInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterDatastores']$")
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterDatastores']/Name$", 'Datastores')
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterId$", $Cluster.SourceObject.Name )
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupClusterDatastoreInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Datastores')
					$discoveryData.AddInstance($RollupClusterDatastoreInstance)
								
					#RollupCluster Hosts RollupClusterDatastores
					$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterHostsDatastores']$")
					$rel6.Source = $RollupClusterInstance
					$rel6.Target = $RollupClusterDatastoreInstance
					$discoveryData.AddInstance($rel6)
					
					ForEach ($VMdatastoreInThisClusterHost in $VMdatastoresInThisClusterHost){
					
						#Already Discovered Datastore Obj
						$VMdatastoreInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Datastore']$")
						$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Datastore']/DatastoreId$", $VMdatastoreInThisClusterHost.TargetObject.Name )
						$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupClusterDatastores Contains VM
						$rel7 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterDatastoresContainsDatastore']$")
						$rel7.Source = $RollupClusterDatastoreInstance
						$rel7.Target = $VMdatastoreInstance
						$discoveryData.AddInstance($rel7)
					}
				}
				
				#Get Networks in this Cluster Host
				$RelHostReferencesNetwork = Get-SCOMRelationship -Name 'Community.VMware.Relationship.HostReferencesNetwork'
				$NetworksInThisClusterHost = Get-SCOMRelationshipInstance -SourceInstance $DiscoveredHostInThisCluster.TargetObject | Where {$_.RelationshipId  -eq $RelHostReferencesNetwork.Id} | Select TargetObject
				
				If ($NetworksInThisClusterHost){
					
					#Create RollupNetwork
					$RollupClusterNetworkInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterNetworks']$")
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClusterNetworks']/Name$", 'Networks')
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterId$", $Cluster.SourceObject.Name )
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupClusterNetworkInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Networks')
					$discoveryData.AddInstance($RollupClusterNetworkInstance)
								
					#RollupCluster Hosts RollupNetwork
					$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterHostsNetworks']$")
					$rel6.Source = $RollupClusterInstance
					$rel6.Target = $RollupClusterNetworkInstance
					$discoveryData.AddInstance($rel6)
					
					ForEach ($NetworkInThisClusterHost in $NetworksInThisClusterHost){
					
						#Already Discovered Network Obj
						$VMnetworkInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Network']$")
						$VMnetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Network']/NetworkId$", $NetworkInThisClusterHost.TargetObject.Name)
						$VMnetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupClusterDatastores Contains VM
						$rel7 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterNetworksContainsNetwork']$")
						$rel7.Source = $RollupClusterNetworkInstance
						$rel7.Target = $VMnetworkInstance
						$discoveryData.AddInstance($rel7)
					}
				}
			}
		
			#Get Discovered vApps In this Cluster
			$RelvAppReferencesCluster = Get-SCOMRelationship -Name 'Community.VMware.Relationship.vAppReferencesCluster'
			$DiscoveredvAppsReferencingCluster = Get-SCOMRelationshipInstance -TargetInstance $Cluster.SourceObject | Where {$_.RelationshipId  -eq $RelvAppReferencesCluster.Id} | Select SourceObject
			
			If ($DiscoveredvAppsReferencingCluster){
			
				#Create RollupClustervApps Instance
				$RollupvAppsInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClustervApps']$")
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.ClustervApps']/Name$", 'vApps')
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Cluster']/ClusterId$", $Cluster.SourceObject.Name )
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllClusters']/Name$", 'Clusters')
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
				$RollupvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
				$RollupvAppsInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'vApps')
				$discoveryData.AddInstance($RollupvAppsInstance)
							
				#RollupCluster Hosts RollupClustervApps
				$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClusterHostsvApps']$")
				$rel6.Source = $RollupClusterInstance
				$rel6.Target = $RollupvAppsInstance
				$discoveryData.AddInstance($rel6)
			
				ForEach ($DiscoveredvAppReferencingCluster in $DiscoveredvAppsReferencingCluster){
				
					#Already Discovered vApp
					$vAppInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vApp']$")
					$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vApp']/vAppId$", $DiscoveredvAppReferencingCluster.SourceObject.Name )
					$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
					
					#RollupClustervApps Contains vApps
					$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.ClustervAppsContainsvApp']$")
					$rel6.Source = $RollupvAppsInstance
					$rel6.Target = $vAppInstance
					$discoveryData.AddInstance($rel6)
				}
			}
		}
	}

	#Create AllStandaloneHosts Obj
	$RollupAllStandaloneHostsInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']$")
	$RollupAllStandaloneHostsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
	$RollupAllStandaloneHostsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
	$RollupAllStandaloneHostsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", 'Hosts and Clusters')
	$RollupAllStandaloneHostsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
	$RollupAllStandaloneHostsInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Standalone Hosts')
	$discoveryData.AddInstance($RollupAllStandaloneHostsInstance)
	
	#RollupDatacenter Hosts AllStandaloneHosts
	$rel8 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.DatacenterHostsAllStandaloneHosts']$")
	$rel8.Source = $RollupDatacenterInstance
	$rel8.Target = $RollupAllStandaloneHostsInstance
	$discoveryData.AddInstance($rel8)
	
	If ($DiscoveredStandaloneHosts){
	
		#Get Discovered Standalone Hosts in this Datacenter
		$RelHostReferencesDatacenter = Get-SCOMRelationship -Name 'Community.VMware.Relationship.HostReferencesDatacenter'
		$DiscoveredHostsInThisDatacenter = Get-SCOMRelationshipInstance -TargetInstance $VMdatacenter | Where {$_.RelationshipId  -eq $RelHostReferencesDatacenter.Id} | Select SourceObject
		
		ForEach ($DiscoveredHostInThisDatacenter in $DiscoveredHostsInThisDatacenter){
				    
            if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Discovered Stand alone Host: " + $DiscoveredHostInThisDatacenter   | Out-File $EnhancedLoggingPath -append }  
			    
			#Only Standalone Hosts
			If ($DiscoveredStandaloneHosts | Where {$_.Id -eq $DiscoveredHostInThisDatacenter.SourceObject.Id}){
				#Create RollupStandaloneHost Obj
				$RollupStandaloneHostInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']$")
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostName$", [string]$DiscoveredHostInThisDatacenter.SourceObject )
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name )
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
				$RollupStandaloneHostInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", [string]$DiscoveredHostInThisDatacenter.SourceObject)
				$discoveryData.AddInstance($RollupStandaloneHostInstance)
				
				#RollupAllStandaloneHosts Hosts RollupStandaloneHost
				$rel9 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.AllStandaloneHostsHostsStandaloneHost']$")
				$rel9.Source = $RollupAllStandaloneHostsInstance
				$rel9.Target = $RollupStandaloneHostInstance
				$discoveryData.AddInstance($rel9)
				
				#Already Discovered Host Obj
				$VMhostObj = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Host']$")
				$VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.Host']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name)
				$VMhostObj.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
				
				#RollupStandaloneHost Contains Host
				$rel10 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostContainsHost']$")
				$rel10.Source = $RollupStandaloneHostInstance
				$rel10.Target = $VMhostObj
				$discoveryData.AddInstance($rel10)
				
				#VMs in Standalone Host
				$RelVirtualMachineReferencesHost = Get-SCOMRelationship -Name 'Community.VMware.Relationship.VirtualMachineReferencesHost'
				$VirtualMachinesInThisStandaloneHost = Get-SCOMRelationshipInstance -TargetInstance $DiscoveredHostInThisDatacenter.SourceObject | Where {$_.RelationshipId  -eq $RelVirtualMachineReferencesHost.Id} | Select SourceObject
				
				If ($VirtualMachinesInThisStandaloneHost){
				
					#Create RollupStandaloneHostVirtualMachines Instance
					$RollupStandaloneHostVirtualMachinesInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostVirtualMachines']$")
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostVirtualMachines']/Name$", 'Virtual Machines')
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name)
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupStandaloneHostVirtualMachinesInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Virtual Machines')
					$discoveryData.AddInstance($RollupStandaloneHostVirtualMachinesInstance)
								
					#RollupStandaloneHost Hosts RollupStandaloneHostVirtualMachines
					$rel11 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostHostsVirtualMachines']$")
					$rel11.Source = $RollupStandaloneHostInstance
					$rel11.Target = $RollupStandaloneHostVirtualMachinesInstance
					$discoveryData.AddInstance($rel11)
					
					#Add VM Object to VM Rollup
					ForEach ($VirtualMachineInThisStandaloneHost in $VirtualMachinesInThisStandaloneHost){
					    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Virtual Machine In This Standalone Host ($DiscoveredHostInThisDatacenter):" + $VirtualMachineInThisStandaloneHost   | Out-File $EnhancedLoggingPath -append }
						#Already Discovered VM
						$VMinstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.VirtualMachine']$")
						$VMinstance.AddProperty("$MPElement[Name='Community.VMware.Class.VirtualMachine']/VirtualMachineId$", $VirtualMachineInThisStandaloneHost.SourceObject.Name )
						$VMInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupStandaloneHostVirtualMachines Contains VM
						$rel12 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostVirtualMachinesContainsVirtualMachine']$")
						$rel12.Source = $RollupStandaloneHostVirtualMachinesInstance
						$rel12.Target = $VMinstance
						$discoveryData.AddInstance($rel12)
					}
				}
			
				#Get Datastores in this Standalone Host
				$RelHostReferencesDatastore = Get-SCOMRelationship -Name 'Community.VMware.Relationship.HostReferencesDatastore'
				$VMdatastoresInThisStandaloneHost = Get-SCOMRelationshipInstance -SourceInstance $DiscoveredHostInThisDatacenter.SourceObject | Where {$_.RelationshipId  -eq $RelHostReferencesDatastore.Id} | Select TargetObject
				
				If ($VMdatastoresInThisStandaloneHost){
					
					#Create RollupDatastore
					$RollupStandaloneHostDatastoresInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostDatastores']$")
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostDatastores']/Name$", 'Datastores')
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name)
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupStandaloneHostDatastoresInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Datastores')
					$discoveryData.AddInstance($RollupStandaloneHostDatastoresInstance)
					
					#RollupStandaloneHost Contains RollupDatastore
					$rel11 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostHostsDatastores']$")
					$rel11.Source = $RollupStandaloneHostInstance
					$rel11.Target = $RollupStandaloneHostDatastoresInstance
					$discoveryData.AddInstance($rel11)
					
					ForEach ($VMdatastoreInThisStandaloneHost in $VMdatastoresInThisStandaloneHost){
						if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"VM datastore In This Standalone Host: " + $VMdatastoreInThisStandaloneHost   | Out-File $EnhancedLoggingPath -append }

						#Already Discovered Datastore Obj
						$VMdatastoreInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Datastore']$")
						$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Datastore']/DatastoreId$", $VMdatastoreInThisStandaloneHost.TargetObject.Name )
						$VMdatastoreInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupDatastore Contains Datastore
						$rel12 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostDatastoresContainsDatastore']$")
						$rel12.Source = $RollupStandaloneHostDatastoresInstance
						$rel12.Target = $VMdatastoreInstance
						$discoveryData.AddInstance($rel12)
					}
				}
				
				#Get Networks in this Standalone Host
				$RelHostReferencesNetwork = Get-SCOMRelationship -Name 'Community.VMware.Relationship.HostReferencesNetwork'
				$NetworksInThisStandaloneHost = Get-SCOMRelationshipInstance -SourceInstance $DiscoveredHostInThisDatacenter.SourceObject | Where {$_.RelationshipId  -eq $RelHostReferencesNetwork.Id} | Select TargetObject
				
				If ($NetworksInThisStandaloneHost){
					
					#Create RollupNetwork
					$RollupStandaloneHostNetworksInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostNetworks']$")
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostNetworks']/Name$", 'Networks')
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name)
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
					$RollupStandaloneHostNetworksInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'Networks')
					$discoveryData.AddInstance($RollupStandaloneHostNetworksInstance)
					
					#RollupStandaloneHost Contains RollupNetwork
					$rel11 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostHostsNetworks']$")
					$rel11.Source = $RollupStandaloneHostInstance
					$rel11.Target = $RollupStandaloneHostNetworksInstance
					$discoveryData.AddInstance($rel11)
					
					ForEach ($NetworkInThisStandaloneHost in $NetworksInThisStandaloneHost){
					    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Network In This Stand alone Host: " + $NetworkInThisStandaloneHost   | Out-File $EnhancedLoggingPath -append }
						#Already Discovered Network Obj
						$VMnetworkInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Network']$")
						$VMnetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Network']/NetworkId$", $NetworkInThisStandaloneHost.TargetObject.Name )
						$VMnetworkInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
						
						#RollupNetwork Contains Network
						$rel12 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostNetworksContainsNetwork']$")
						$rel12.Source = $RollupStandaloneHostNetworksInstance
						$rel12.Target = $VMnetworkInstance
						$discoveryData.AddInstance($rel12)
					}
				}
			}
				
			#Get Discovered vApps In this Host
			$RelvAppReferencesHost = Get-SCOMRelationship -Name 'Community.VMware.Relationship.vAppReferencesHost'
			$DiscoveredvAppsReferencingHost = Get-SCOMRelationshipInstance -TargetInstance $Host.SourceObject | Where {$_.RelationshipId  -eq $RelvAppReferencesHost.Id} | Select SourceObject
			
			If ($DiscoveredvAppsReferencingHost){
			
				#Create RollupHostvApps Instance
				$RollupStandaloneHostvAppsInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostvApps']$")
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHostvApps']/Name$", 'vApps')
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.StandaloneHost']/HostId$", $DiscoveredHostInThisDatacenter.SourceObject.Name)
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.AllStandaloneHosts']/Name$", 'Standalone Hosts')
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters.Datacenter']/DatacenterId$", $VMdatacenter.'[Community.VMware.Class.Datacenter].DatacenterId'.Value )
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.HostsAndClusters']/Name$", "Hosts and Clusters")
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='Community.VMware.Class.Rollup.vCenter']/vCenterServerName$", $vCenter)
				$RollupStandaloneHostvAppsInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", 'vApps')
				$discoveryData.AddInstance($RollupStandaloneHostvAppsInstance)
							
				#RollupHost Hosts RollupHostvApps
				$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostHostsvApps']$")
				$rel6.Source = $RollupStandaloneHostInstance
				$rel6.Target = $RollupStandaloneHostvAppsInstance
				$discoveryData.AddInstance($rel6)
			
				ForEach ($DiscoveredvAppReferencingHost in $DiscoveredvAppsReferencingHost){
				    if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"Discovered vApp Referencing Host: " + $DiscoveredvAppReferencingHost   | Out-File $EnhancedLoggingPath -append } 
					#Already Discovered vApp
					$vAppInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Community.VMware.Class.vApp']$")
					$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vApp']/vAppId$", $DiscoveredvAppReferencingHost.SourceObject.Name )
					$vAppInstance.AddProperty("$MPElement[Name='Community.VMware.Class.vCenter']/vCenterServerName$", $vCenter)
					
					#RollupHostvApps Contains vApps
					$rel6 = $discoveryData.CreateRelationshipInstance("$MPElement[Name='Community.VMware.Relationship.Rollup.HostsAndClusters.StandaloneHostvAppsContainsvApp']$")
					$rel6.Source = $RollupStandaloneHostvAppsInstance
					$rel6.Target = $vAppInstance
					$discoveryData.AddInstance($rel6)
				}
			}
		}
	}
}
$discoveryData
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" ============  vCenter $vCenter finnished  ====================" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" " | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {"PID: $PID" | Out-File $EnhancedLoggingPath -append   }
if($EnhancedLogging -eq "true" -or $EnhancedLogging -eq "yes") {" **********************$(Get-date)****************************************" | Out-File $EnhancedLoggingPath -append   }

Exit