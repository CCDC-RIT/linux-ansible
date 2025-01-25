#!/bin/bash

if  [ "$EUID" -ne 0 ];
then
    echo "User must be root to run this script."
    exit 1
fi

/bin/bash /var/tmp/get_helm.sh
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install --replace falco --namespace falco --create-namespace --set tty=true --set-file config=/etc/falco-config.yaml --set-file rules=/etc/falco-rules.yaml falcosecurity/falco