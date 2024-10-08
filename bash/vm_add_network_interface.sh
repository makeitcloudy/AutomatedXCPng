#!/bin/bash

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
	--VmName) VM_NAME="$2"; shift ;;
        --NetworkName) NETWORK_NAME="$2"; shift ;;
        --Mac) MAC_ADDRESS="$2"; shift ;;
        --Device) DEVICE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Get UUIDs
VM_UUID=$(xe vm-list name-label="$VM_NAME" --minimal)
NETWORK_UUID=$(xe network-list name-label="$NETWORK_NAME" --minimal)

# Add the network interface (VIF)
VIF_UUID=$(xe vif-create vm-uuid=$VM_UUID network-uuid=$NETWORK_UUID mac=$MAC_ADDRESS device=$DEVICE)

# Connect the network interface
xe vif-plug uuid=$VIF_UUID
