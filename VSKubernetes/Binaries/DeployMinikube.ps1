﻿$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\Utils.psm1

if (Exec { .\minikube.exe status } | select-string "Running") {
    Exec { .\minikube.exe delete }
}

Exec { .\minikube.exe start --vm-driver=hyperv --hyperv-virtual-switch="$(GetVMSwitchName)" --cpus=4 --memory=2048 --disk-size=20g }
Exec { .\helm.exe init }
Exec { .\minikube.exe addons enable ingress }
Exec { .\minikube addons enable registry }

$minikubeIp = Exec { $(.\minikube ip) }

# Wait for tiller to become ready
Retry { .\helm.exe list 2>&1 | Out-Null }

$ENV:DRAFT_BASE_DOMAIN="${minikubeIp}.xip.io"
Exec { .\draft.exe init --yes }
