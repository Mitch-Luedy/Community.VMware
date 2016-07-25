Community.VMware
================

Community developed Operations Manager monitoring for VMware

### Description ###

This project was created to provide a free VMware monitoring option to the Operations Manager community. The workflows in this Management Pack utilize PowerShell and VMware vSphere PowerCLI to connect to vCenter to perform monitoring.

## Getting Started ##

### Warning ###

There is a bug that will cause MonitoringHost.exe to crash on the Management Server that manages the VMware discovered objects. Have a plan to mitigate this bug if you plan on testing this MP out.

### Basic Requirements ###

* Operations Manager 2012
* VMware vCenter Server
* VMware vSphere PowerCLI (Installed on Management Servers)

### Setup ###

1. Install the Operations Manager agent on each VMware vCenter server
1. Download [VMware vSphere PowerCLI](https://www.vmware.com/support/developer/PowerCLI/)
1. Install vSphere PowerCLI on each Management Server
1. Grant vCenter Read-only access for SCOM
	* Management Server **Default Action Account**  accounts.
	* OR use a new service account and configure it with the following:
		* Local Administrator access on each Management Server
		* SCOM Read-only access
		* Add the account to the **Community - VMware Monitoring Profile** after importing the Management Pack
1. Import the Management Pack files
	* Community.VMware.mpb
	* Community.VMware.Unsealed.xml
1. (optional) Configure the members of the **Community - VMware Monitoring Resource Pool**

## Monitoring ##

### VMware vCenter Inventory Objects ###

* Datacenters
	* Monitors
		* VMware Datacenter Datastore Space Free Percent
	* Rules
		* VMware Datacenter Datastore Space Capacity TB Collection
		* VMware Datacenter Datastore Space Used TB Collection
		* VMware Datacenter Datastore Space Free TB Collection
* Clusters
	* Monitors
		* VMware Cluster Current Failover Level
		* Host Availability
		* Host Performance
		* VMware Cluster Memory Usage Average
		* VMware Cluster Datastore Space Free Percent
		* VMware Cluster CPU Usage Average
	* Rules
		* VMware Cluster Memory Usage Average Percent Collection
		* VMware Cluster Datastore Space Used Percent Collection
		* VMware Cluster Datastore Space Used GB Collection
		* VMware Cluster Datastore Space Free Percent Collection
		* VMware Cluster Datastore Space Free GB Collection
		* VMware Cluster Datastore Space Capacity GB Collection
		* VMware Cluster CPU Usage Average Percent Collection
* Hosts
 	* Monitors
	 	* VMware Host Power State
	 	* VMware Host Memory Usage Percent
	 	* VMware Host Datastore Space Free Percent
	 	* VMware Host CPU Usage Percent
	* Rules
		* VMware Host Memory Usage Percent Collection
		* VMware Host Memory Usage MB Collection
		* VMware Host Memory Usage Free Collection
		* VMware Host Memory Usage Capacity Collection
		* VMware Host Datastore Space Used Percent Collection
		* VMware Host Datastore Space Used GB Collection
		* VMware Host Datastore Space Free Percent Collection
		* VMware Host Datastore Space Capacity GB Collection
		* VMware Host CPU Usage Percent Collection
		* VMware Host CPU Usage MHz Collection
		* VMware Host CPU Free MHz Collection
		* VMware Host CPU Capacity MHz Collection
* Datastores
 	* Monitors
	 	* VMware Datastore State
	 	* VMware Datastore Space Free Percent
	 	* VMware Datastore Space Free GB
	* Rules
		* VMware Datastore Space Used Percent Collection
		* VMware Datastore Space Used GB Collection
		* VMware Datastore Space Free Percent Collection
		* VMware Datastore Space Free GB Collection
		* VMware Datastore Space Capacity GB Collection
* Networks
	* Monitors
		* VMware Network Overall Status
* vApps
	* Monitors
		* VMware vApp Started State

### VMware Rollup Objects ###

The VMware Rollup objects are discovered separately for a rollup of the vCenter objects to the top of their hosting vCenter instance. This is displayed in the **vCenter Topology Rollup** Diagram View.

## Views ##

The views contained in this management pack are included in the **VMware** view folder.

* **1. Active Alerts** - Presents all active alerts for all of the discovered VMware vCenter Inventory objects
* **2. vCenter Topology Rollup** - Presents all vCenter instances with a **Hosts and Clusters** like drill down
* **3. vCenter Object States** - Presents each vCenter Server and their hosted vCenter object states. Click on each column to see the state of each objects
* **1. Inventory Objects** - Folder that includes state views for the discovered vCenter inventory objects.
* **2. Custom Views** - Folder for adding custom views

## Known Issues ##

* **Event 300 PowerShell Warning Exception** - Provider Health: Attempting to perform the NewDrive operation on the 'VimInventory' provider failed for the drive with root '\'. The specified mount name 'vis' is already in use.. 

	Multiple monitoring scripts running to collect and monitor using the VMware PowerCLI providers causes this contention. This can lead to MonitoringHost.exe crashes and memory leakage. **I don't have the time to address this issue**



