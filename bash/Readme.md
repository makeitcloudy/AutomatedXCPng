# XCP-ng - scripts

Follow this rules

```code
# you are logged in as root user via ssh to the xcp-ng
mkdir -p /opt/scripts
chmod 700 scriptName.sh
```

## XCP-ng - scripts - manual execution - debugging

### /opt/scripts/vm_create_bios.sh

### /opt/scripts/vm_add_disk.sh

/opt/scripts/vm_add_disk_test.sh 
--vmName "test_vm"
--storageName "node4_hdd_sdc_lsi" 
--diskGB 200 
--diskName "test_vm_dataDrive" 
description "test_vm_dataDrive"


VM_NAME="test_vm"
SR_NAME="node4_hdd_sdc_lsi"
DISK_NAME="test_vm_dataDrive"
DEVICE_ID=4
DISK_SIZE=200
DISK_DESCRIPTION="test_vm_dataDrive"

```bash
SR_UUID=$(xe sr-list name-label=$SR_NAME --minimal)
VM_UUID=$(xe vm-list name-label=$VM_NAME --minimal)
VDI_UUID=$(xe vdi-create sr-uuid=$SR_UUID name-label=$DISK_NAME type=user virtual-size=200GiB)
xe vdi-param-set uuid=$VDI_UUID name-label=$DISK_NAME name-description=$DISK_DESCRIPTION
VBD_UUID=$(xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$VDI_UUID device=4 bootable=false mode=RW type=Disk)
xe vbd-plug uuid=$VBD_UUID
```

## XCP-ng for the test_vm provisioning 

```bash
# TESTED - succesfull execution - 2024.VI.14

# node4 - authoringD - provisiong authoringD VM
/opt/scripts/vm_create.sh --VmName 'test_vm' --VCpu 4 --CoresPerSocket 2 --MemoryGB 8 --DiskGB 40 --ActivationExpiration 90 --TemplateName 'Windows 10 (64-bit)' --IsoName 'w10ent_21H2_updt_2302.iso' --IsoSRName 'node4_nfs' --NetworkName '[NetworkName]' --Mac '5E:16:3e:33:33:33' --StorageName 'node4_ssd_sdf' --VmDescription 'test_vm_21H2_updt_2302_untd'

#node4 - authoringD - add extra disk to authoringBox
/opt/scripts/vm_add_disk.sh --vmName "test_vm" --storageName "node4_hdd_sdc_lsi" --diskName "test_vm_dataDrive" --deviceId 4 --diskGB 200  --description "test_vm_dataDrive"