#!/bin/bash

BACKUPDIR="."

mkdir -p "$BACKUPDIR"

if [[ $EUID -ne 0 ]]; then
    echo "Must be run as root"
    exit 1
fi

# #Check if a resource type has been provided
# if [[ -z "$1" ]]; then
#  echo "Usage: $0 <resource-type>"
#  exit 2
# fi

RESOURCES=(pods services deployments secrets statefulset)

NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for NAMESPACE in $NAMESPACES; do
    mkdir -p "$BACKUPDIR"/"$NAMESPACE"
    echo "Processing namespace: $NAMESPACE"
    RESOURCES=$(kubectl get $RESOURCE_TYPE -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    for RESOURCE in $RESOURCES; do
        echo "Fetching YAML for $RESOURCE_TYPE $RESOURCE in namespace $NAMESPACE"
        kubectl get "$RESOURCE_TYPE" "$RESOURCE" -n "$NAMESPACE" -o yaml > "$BACKUPDIR"/"$NAMESPACE"/"$RESOURCE_TYPE"-"$RESOURCE"-$(date +%d_%H%M%S ).yaml
        echo "----------------------------------------------------------------------------------------------------------------------------------------------"
    done
done