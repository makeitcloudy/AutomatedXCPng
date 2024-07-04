# Citrix Hypervisor API / XCP-ng API - 8.2.1

* 0. Get the XCP-ng or XenServer installed on one of your nodes.
* 1. Download the XenServer SDK

https://github.com/citrix/xenserver-sdk/blob/master/docs/index.md
https://developer-docs.citrix.com/projects/citrix-hypervisor-sdk/en/latest/

* 2. Once downloaded into your management node (in case it is windows based) extract zip file

```powershell
  $env:USERPROFILE\Documents\WindowsPowerShell\Modules
  $env:PROGRAMFILES\WindowsPowerShell\Modules
  $env:SystemRoot\system32\WindowsPowerShell\v1.0\Modules
```

* 3. Import the Module

```
  Import-Module XenServerPSModule
```
## AutomatedXCPng Module

* 4. Copy the AutomatedXCPng into the same location as the one mentioned for XenServerPSModule

```powershell
  Import-Module AutomatedXCPng
```

Module wraps the XenServerPS Module with a bunch of functions which brings the functionality towards VM's provisioning

* 5. List the commands available within the AutomatedXCPng

```powershell
  Get-Command -Module AutomatedXCPng
```

* 6. Start using the commandlets

* enumerate the iso available on your iso storage
* enumerte vm details like network IP and MAC, vcpu, storage etc
* create the VM skeletons, bios, uefi, uefi secure boot, equipped with disks and dvd drives
* add extra disk
* start, reboot, shutdown vms
* take a snapshot
* scrap the vms

* 7. It creates the VM from scratch without touching the xcp-ng Center / XEN Console GUI
* 8. Combined with an iso prepared as per SeguraOSD section, one will end up with unattended installation of running OS'es for your lab scenario.<br>
