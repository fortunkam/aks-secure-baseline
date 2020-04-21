#!/bin/bash
RG="mfaks-spoke-rg"
AKS="mfaks-aks"
ACR="mfaksacr"

ACR_ID=$(az acr show -n $ACR -g $RG --query id -o tsv)

az aks update -g $RG -n $AKS --attach-acr $ACR_ID