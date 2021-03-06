﻿$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\Utils.psm1

$ENV:HOME = $ENV:USERPROFILE

if (Exec { .\minikube.exe status } | select-string "Running") {
    Exec { .\minikube.exe delete }
}

Exec { .\minikube.exe start --vm-driver=hyperv --hyperv-virtual-switch="$(GetVMSwitchName)" --cpus=4 --memory=4096 --disk-size=20g }
Exec { .\helm.exe init }
Exec { .\minikube.exe addons enable ingress }
Exec { .\minikube addons enable registry }
Exec { .\minikube addons enable heapster }

$minikubeIp = Exec { $(.\minikube ip) }

# Wait for tiller to become ready
Retry { .\helm.exe list 2>&1 | Out-Null }

Exec { .\draft.exe init --auto-accept --ingress-enabled }

$patches = @(
	('[{"op": "replace", "path": "/spec/template/spec/containers/0/args/3", "value": "--basedomain=' + ${minikubeIp} + '.nip.io"}]'),
	('[{"op": "replace", "path": "/spec/template/spec/containers/0/args/4", "value": "--ingress-enabled=true"}]'))

foreach ($patch in $patches) {
	Exec { .\kubectl.exe patch deployment/draftd --namespace=kube-system --type='json' "-p=$patch" }
}
