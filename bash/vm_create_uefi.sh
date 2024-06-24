#!/bin/bash

# TESTED - 2024.06.17 - it works

# Function to print usage
usage() {
  echo "Usage: $0 --VmName VM_Name --VCpu [2|4|8] --CoresPerSocket [2,4] 
  --MemoryGB [2|4|8|16] 
  --DiskGB [16,40,64] 
  --ActivationExpiration [90|180] 
  --TemplateName TEMPLATE_Name --IsoName ISO_Name --IsoSRName ISO_SR_NAME 
  --NetworkName Network_Name --Mac 'XY:XX:XX:XX:XX:XX' 
  --StorageName SR_Name --VmDescription 'purpose of the machine'"
  exit 1
}

# Parse parameters
while [ "$1" != "" ]; do
  case $1 in
    --VmName )  shift
                VM_NAME=$1
                ;;
    --VCpu )  shift
                VCPU=$1
                ;;
    --CoresPerSocket )  shift
                CORESPERSOCKET=$1
                ;;
    --MemoryGB )  shift
                MEMORY=$1
                ;;
    --DiskGB ) shift
                DISK_SIZE=$1
                ;;
    --ActivationExpiration )  shift
                ACTIVATIONEXPIRATIONDAYS=$1
                ;;
    --TemplateName )  shift
                TEMPLATE_NAME=$1
                ;;
    --IsoName ) shift
                ISO_NAME=$1
                ;;
    --IsoSRName ) shift
                ISO_SR_NAME=$1
                ;;                
    --NetworkName ) shift
                NETWORK_NAME=$1
                ;;
    --Mac ) shift
                MAC=$1
                ;;
    --StorageName ) shift
                SR_NAME=$1
                ;;
    --VmDescription )  shift
                VM_DESCRIPTION=$1
                ;;
    * )         usage
                ;;
  esac
  shift
done

# Check mandatory parameters
if [ -z "$VM_NAME" ] || [ -z "$VCPU" ] || [ -z "$CORESPERSOCKET" ] || [ -z "$MEMORY" ] || [ -z "$DISK_SIZE" ] || [ -z "$ACTIVATIONEXPIRATIONDAYS" ] || [ -z "$TEMPLATE_NAME" ] || [ -z "$ISO_NAME" ] || [ -z "$ISO_SR_NAME" ] || [ -z "$NETWORK_NAME" ] || [ -z "$MAC" ] || [ -z "$SR_NAME" ] || [ -z "$VM_DESCRIPTION" ]; then
  usage
fi

# Default expiration days to 90 if not provided
ACTIVATIONEXPIRATIONDAYS=${ACTIVATIONEXPIRATIONDAYS:-90}

# Calculate the date based on the expiration days parameter
EXPIRATION_DATE=$(date -d "+${ACTIVATIONEXPIRATIONDAYS} days" +"%Y-%m-%d")

# Convert memory and disk size to bytes
MEMORY_GIGABYTES="${MEMORY}GiB"
DISK_SIZE_BYTES=$((DISK_SIZE * 1024 * 1024 * 1024))
DISK_OS_NAME="${VM_NAME}_OS_Disk"

# Get GUIDs
SR_UUID=$(xe sr-list name-label="$SR_NAME" --minimal)
ISOSR_UUID=$(xe sr-list name-label="$ISO_SR_NAME" --minimal)
NETWORK_UUID=$(xe network-list name-label="$NETWORK_NAME" --minimal)
TEMPLATE_UUID=$(xe template-list name-label="$TEMPLATE_NAME" --minimal)
ISO_UUID=$(xe vdi-list name-label="$ISO_NAME" sr-uuid="$ISOSR_UUID" --minimal)


# Create VM
#VM_UUID=$(xe vm-install template="$TEMPLATE_UUID" new-name-label="$VM_NAME" sr-uuid="$SR_UUID")
#VM_UUID=$(xe vm-create template="$TEMPLATE_UUID" name-label=$VM_NAME new-name-label=$VM_NAME name-description=$VM_DESCRIPTION other-config:{descirption="Expiration Date: $EXPIRATION_DATE"})
VM_UUID=$(xe vm-install template="$TEMPLATE_UUID" name-label=$VM_NAME new-name-label=$VM_NAME sr-uuid="$SR_UUID" name-description=$VM_DESCRIPTION)

# Set VM description with expiration date
xe vm-param-set uuid=$VM_UUID name-description="Exp Date: $EXPIRATION_DATE - $VM_DESCRIPTION"

# Set VM parameters
#xe vm-param-set uuid=$VM_UUID memory-static-max=$MEMORY_GIGABYTES memory-dynamic-max=$MEMORY_GIGABYTES memory-dynamic-min=$MEMORY_GIGABYTES memory-static-min=$MEMORY_GIGABYTES

xe vm-param-set uuid=$VM_UUID memory-static-max=$MEMORY_GIGABYTES memory-dynamic-max=$MEMORY_GIGABYTES memory-dynamic-min=$MEMORY_GIGABYTES memory-static-min=$MEMORY_GIGABYTES
xe vm-param-set uuid=$VM_UUID HVM-boot-params:{order="cd"; firmware="uefi"}
xe vm-param-set uuid=$VM_UUID other-config:{secureboot="false"; hpet="true"; pae="true"; vga="std"; nx="true"; viridian_time_ref_count="true"; apic="true"; viridian_reference_tsc="true"; viridian="true"; acpi="1"}

xe vm-param-set uuid=$VM_UUID VCPUs-max=$VCPU VCPUs-at-startup=$VCPU
xe vm-param-set uuid=$VM_UUID platform:cores-per-socket=$CORESPERSOCKET


#xe vm-disk-add vm=$VM_UUID sr-uuid=$SR_UUID device=0 disk-size=$DISK_SIZE_BYTES
#CREATE DISK and bind it with VM
## VDI_UUID=$(xe vdi-create sr-uuid=$SR_UUID name-label=$DISK_OS_NAME virtual-size=$DISK_SIZE_BYTES type=user name-description="testing")
#xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$VDI_UUID type=disk mode=rw device=0
##xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$VDI_UUID type=disk mode=rw device=0 bootable=true unpluggable=true

# CREATE CD
#xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$VDI_UUID type=cd mode=ro device=3 bootable=false unpluggable=true empty=true
#xe vm-cd-add vm=$VM_UUID cd-name=$ISO_NAME device=3

### Create ISO

# Step 2: Find the ISO SR and the ISO VDI
#ISOSR_UUID=$(xe sr-list name-label=ISO_Repository --minimal)
#ISO_UUID=$(xe vdi-list sr-uuid=$ISOSR_UUID name-label=example.iso --minimal)

# Step 3: Create a CD VBD and attach it to the VM
xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$ISO_UUID device=3 type=cd mode=ro bootable=true unpluggable=true empty=false

### Create Network
# Enter an address in the form XY:XX:XX:XX:XX:XX where 
#                  X is any hexadecimal digit, and 
#                  Y is one of 2, 6, A or E.

xe vif-create vm-uuid=$VM_UUID network-uuid=$NETWORK_UUID device=0 mac=$MAC ipv4-allowed=true ipv6-allowed=false

# resize the disk
output=$(xe vm-disk-list vm=$VM_NAME --multiple)
VDI_UUID_SR=$(echo "$output" | grep -A 3 "Disk 0 VDI:" | grep "uuid ( RO)" | awk '{print $5}')
xe vdi-resize uuid=$VDI_UUID_SR disk-size=$DISK_SIZE_BYTES

# Start VM
xe vm-start uuid=$VM_UUID