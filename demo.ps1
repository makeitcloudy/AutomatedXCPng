#nodeName: DNS or IP address of Xen mgmt interface
$nodeName = 'nodeNameDNS'
#nodeHypervisorUserName: username to login to the Xen mgmt interface
$nodeHypervisorUserName = 'userName'
#isoSR: name of the storage repository with the ISO's used to provision vm's
$isoSR = 'isoStorageRepositoryName'

#xenCred: credentials to login to Xen
$xenCred = Get-Credential -UserName $nodeHypervisorUserName -Message 'password for the $nodeHypervisorUserName on Xen'
Connect-PLXen -XenHost $nodeName -Credential $xenCred -Verbose

#Xen Automation - Xen - DISCONNECT
Disconnect-PLXen -Verbose

#region Xen - Inventory
#Xen Storage Repositories - Available Labels
Get-PLXenSR -Verbose
#Xen List of default templates - those can be used for VM provisioning
Get-PLXenTemplate -Type default -Verbose
#Xen List Custom templates
Get-PLXenTemplate -Type custom -Verbose
#Xen RAM Total
Get-PLXenRam -Type Total -Verbose
#Xen RAM Free
Get-PLXenRam -Type Free -Verbose
#Xen Storage Repositories - getting details about all SR
Get-PLXenStorage -Verbose | Select-Object * -ExcludeProperty SROtherConfig | Sort-Object SRNameLabel | Out-GridView
#Xen Storage Repositories - dedicated for VMs, total, used and free space
Get-PLXenStorage | Where-Object { $_.SRNameLabel -match "ssd|hdd|nvme"}

#Xen Cpu Threads
Get-PLXenCPUCount -Verbose
#Xen Iso Repositories - Available Labels
Get-PLXenISORepository -Verbose
#Xen Iso Repositories - Details about availability, type and path
Get-PLXenISOLibrary -Verbose

Get-PLXenISOLibrary | Where-Object { $_.SRIsoOtherConfig.Keys -notmatch "dirty" } | Out-GridView  #show those which needs to be fixed
Get-PLXenISOLibrary | Where-Object { $_.SRIsoOtherconfig.Values -match "true" } #show those which are available for Xen
#($(Get-PLXenISOLibrary).SRIsoOtherconfig).Keys
#Get-PLXenISOLibrary | Where-Object {$_.SRIsoOtherconfig.Values -match "true"} | Select-Object SRIsoNameLabel | Get-PLXenIso -Verbose | Select-Object IsoLabel 
Get-PLXenISOLibrary | Where-Object { $_.SRIsoOtherconfig.Values -match "true" } #list available ISO Libraries
#for the available ISO Libraries list all iso files which are available for your disposal
Get-PLXenISOLibrary | Where-Object { $_.SRIsoOtherconfig.Values -match "true" } | Select-Object SRIsoNameLabel | Get-PLXenIso -Verbose | Select-Object IsoLabel,IsoDescription,IsoVirtualSize,IsoPhysicalUtilization,IsoIsToolsIso,SRNameLabel,SRNameDescription,SRUUID | Sort-Object IsoLabel | Out-GridView

#Xen ISO Storage Repositories
Get-PLXenIso -SRName $isoSR -Verbose
Get-PLXenIso -SRName $isoSR -Verbose | Select-Object IsoLabel | Where-Object {$_.IsoLabel -notmatch 'Citrix|debian|SQL'}
Get-PLXenIso -SRName $isoSR -Verbose | Select-Object IsoLabel | Where-Object {$_.IsoLabel -match 'w2k22_eval'}

#Xen network
Get-PLXenNetwork -Verbose | Sort-Object NetworkBridge | Select-Object NetworkLabel

#Xen Automation - VM - INVENTORY - NETWORK IPv4 addresses get the IP address of all hosts running on node
Get-XenVM | Where-Object {$_.is_a_template -eq $False -and $_.is_a_snapshot -eq $False -and $_.power_state -eq "running"} | Select-Object name_label,uuid,vCPUs_max,@{Name='ipv4';Expression={((Get-XenVMGuestMetrics -Uuid (Get-XenVMProperty -vm (Get-XenVM -Uuid $_.uuid) -XenProperty GuestMetrics).uuid).Networks)['0/ipv4/0']}},@{Name='ipv6';Expression={((Get-XenVMGuestMetrics -Uuid (Get-XenVMProperty -vm (Get-XenVM -Uuid $_.uuid) -XenProperty GuestMetrics).uuid).Networks)['0/ipv6/0']}} | Format-Table -AutoSize

#Xen Automation - VM - INVENTORY - Network details
Get-PLXenVMNetwork | Out-GridView

#endregion

#region Xen - Create VM from scratch

Get-PLXenIso -SRName $isoSR -Verbose | Select-Object IsoLabel | Where-Object {$_.IsoLabel -notmatch 'Citrix|debian|SQL'} #node1
Get-PLXenTemplate -Type default -Verbose
Get-PLXenSR -Verbose
Get-PLXenNetwork -Verbose | Sort-Object NetworkBridge | Select-Object NetworkLabel

        #Enter an address in the form XY:XX:XX:XX:XX:XX where 
        #                 X is any hexadecimal digit, and 
        #                 Y is one of 2, 6, A or E.

$vmArray = @()
$vmParam = @{
    VMName                  = 'w10_updated'       #VM Skel
    VMDescription           = 'w10_updated_unattended'
    VMSKU                   = 'Windows 10 (64-bit)' #VM Template
    VMBootISO               = 'w10ent_21H2_updt_2406_unattended_noprompt.iso'
    VMIsoSR                 = $isoSR
    #VMIsoSR                 = 'centos8Stream_nfs'   #ISO SR
    VMSR                    = 'node4_ssd_sde'        #VM disk
    VMDiskName              = 'w10_test_disk_name'
    VMDiskDescription       = 'w10_test_disk_description'
    VMDiskGB                = 32
    VMRAM                   = 8 * 1GB      #VM Skel
    VMCPU                   = 8            #VM Skel
    CoresPerSocket          = 4
    HVMBootPolicy           = 'BIOS order' #VM Skel
    HVMShadowMultiplier     = 1            #VM Skel
    UserVersion             = 1            #VM Skel
    ActionsAfterReboot      = 'restart'    #VM Skel
    ActionsAfterCrash       = 'restart'    #VM Skel
    HardwarePlatformVersion = 2            #VM Skel
    NetworkName             = 'eth1' #VM Network operations
    #Enter an address in the form XY:XX:XX:XX:XX:XX where 
    #                         X is any hexadecimal digit, and 
    #                         Y is one of 2, 6, A or E.

    MAC                     = 'XY:XX:XX:XX:XX:XX'
    MTU                     = 1500
}
$vmObject = [pscustomobject]$vmParam
$vmArray += $vmObject
#endregion

#Xen Automation - VM - CREATE FROM SCRATCH
foreach ($vm in ($vmArray | Where-Object {$_.VMName -match $vmNameRegex})){
    New-PLXenVM -VmParam $vm -Firmware uefi -SecureBoot False -Verbose # Variable initialization are within the begin section of New-PLXenVm
}

#Xen Automation - VM - modify parameters
$vmNameRegex = "_updated"
Set-PLXenVM -VMNameRegex $vmNameRegex -BootOrder cdn -Verbose

#c - hardDisk
#d - dvd
#n - network
$bootParams = @{order = 'cdn'}
#$bootParams = @{order = 'dcn'}
#$bootParams = @{order = 'c'}
#$bootParams = @{order = "dc"; firmware = "uefi"}
#$bootParams = @{order = "dc"; firmware = "bios"}
foreach($element in $xenVm){
    Set-XenVM -VM $element -HVMBootParams $bootParams -Verbose
    #xe vm-param-set uuid=<UUID> HVM-boot-params:order=ndc
}

#Xen Automation - CREATE VM - Unmount CD after sucesfull installation
foreach($element in ($vmArray | Where-Object {$_.VMName -match $vmNameRegex})){
    Write-Output "Performing the operation `"VBD.eject`" on target $($element.VMName)"
    Get-XenVm -Name $element.VMName | Select-Object -ExpandProperty VBDs | Get-XenVBD | Where-Object { $_.type -eq "CD" } | Invoke-XenVBD -XenAction Eject -Verbose #eject ISO
}

#Xen Automation - CREATE VM - Mount XenServer Tools
$xenServerToolsIso                     = 'Citrix_Hypervisor_82_tools.iso'
$nodeIsoSR                             = $isoSR #node4

foreach($element in ($vmArray | Where-Object {$_.VMName -match $vmNameRegex})){
    Write-Output "Performing the operation `"VBD.insert`" on target $($element.VMName)"
    Get-XenVM -Name $element.VMName | Select-Object -ExpandProperty VBDs | Get-XenVBD | Where-Object { $_.type -eq "CD" } | Invoke-XenVBD -XenAction Insert -VDI (Get-XenVDI -Uuid (Get-PLXenIso -SRName $nodeIsoSR | Where-Object { $_.IsoLabel -match $xenServerToolsIso }).IsoUUID | Select-Object -ExpandProperty opaque_ref) -Verbose
}