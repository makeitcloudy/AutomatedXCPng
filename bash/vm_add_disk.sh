#!/bin/bash

# Function to print usage
usage() {
  echo "Usage: $0 --vmName VM_NAME --storageName SR_NAME --diskName DISK_NAME --deviceId DEVICE_ID --diskGB DISK_SIZE --description DISK_DESCRIPTION"
  exit 1
}

# Parse parameters
while [ "$1" != "" ]; do
  case $1 in
    --vmName ) shift
               VM_NAME=$1
               ;;
    --storageName ) shift
                SR_NAME=$1
                ;;
    --diskName ) shift
                DISK_NAME=$1
                ;;
    --deviceId ) shift
                DEVICE_ID=$1
                ;;
    --diskGB ) shift
                 DISK_SIZE=$1
                 ;;
    --description ) shift
                DISK_DESCRIPTION=$1
                ;;
    * )         usage
                ;;
  esac
  shift
done

# Check mandatory parameters
if [ -z "$VM_NAME" ] || [ -z "$SR_NAME" ] || [ -z "$DISK_NAME" ] || [ -z "$DEVICE_ID" ] || [ -z "$DISK_SIZE" ] || [ -z "$DISK_DESCRIPTION" ]; then
  usage
fi

# Get UUIDs
#VM_UUID=$(xe vm-list name-label="$VM_NAME" --minimal)
#SR_UUID=$(xe sr-list name-label="$SR_NAME" --minimal)

# Get the UUID of the VM
VM_UUID=$(xe vm-list name-label=$VM_NAME --minimal)

# Get the UUID of fthe Storage Repository
SR_UUID=$(xe sr-list name-label=$SR_NAME --minimal)

# Convert Disk Size to Bytes
DISK_SIZE_BYTES=$((DISK_SIZE * 1024 * 1024 * 1024))

# Crete the Virtual Disk (VDI)
VDI_UUID=$(xe vdi-create sr-uuid=$SR_UUID name-label=$DISK_NAME type=user virtual-size=$DISK_SIZE_BYTES)

# Set the description and name-label for the VDI
xe vdi-param-set uuid=$VDI_UUID name-label=$DISK_NAME name-description=$DISK_DESCRIPTION

# Create the Virtual Block Device (VBD) that connects the VDI to the VM
VBD_UUID=$(xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$VDI_UUID device=$DEVICE_ID bootable=false mode=RW type=Disk)

# Plug the VD into the VM / activate disk
xe vbd-plug uuid=$VBD_UUID

# At this point you can see the disk being added

echo "Disk of size ${DISK_SIZE}GB added to VM '$VM_NAME' successfully with name '$DISK_NAME' and description '$DISK_DESCRIPTION'."