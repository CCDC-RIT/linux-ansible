#!/bin/bash

BACKUPDIR="."

mkdir -p "$BACKUPDIR"

export KUBECONFIG=/etc/kubernetes/admin.conf

if [[ $EUID -ne 0 ]]; then
    echo "Must be run as root"
    exit 1
fi

# #Check if a resource type has been provided
# if [[ -z "$1" ]]; then
#  echo "Usage: $0 <resource-type>"
#  exit 2
# fi

RESOURCE_TYPES=(pods services deployments secrets statefulset)

NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for NAMESPACE in $NAMESPACES; do
    mkdir -p "$BACKUPDIR"/"$NAMESPACE"
    echo "Processing namespace: $NAMESPACE"
    for RESOURCE_TYPE in "${RESOURCE_TYPES[@]}"; do
        echo "  Fetching $RESOURCE_TYPE..."
        RESOURCE_NAMES=$(kubectl get "$RESOURCE_TYPE" -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        # Skip if the resource type doesn't exist in this namespace
        if [[ -z "$RESOURCE_NAMES" ]]; then
            echo "    No $RESOURCE_TYPE found in $NAMESPACE"
            continue
        fi
        for NAME in $RESOURCE_NAMES; do
            OUTFILE="$BACKUPDIR/$NAMESPACE/${RESOURCE_TYPE}-${NAME}.yaml"
            echo "    Saving $RESOURCE_TYPE/$NAME → $OUTFILE"
            kubectl get "$RESOURCE_TYPE" "$NAME" -n "$NAMESPACE" -o yaml > "$OUTFILE"
        done
    done

    echo "--------------------------------------------------------------------------"
done