#!/bin/bash
kubectl get pod --all-namespaces \
  -ojsonpath="{range .items[*]}ns/{@.metadata.namespace} \
    pod/{@.metadata.name} sa/{@.spec.serviceAccount} \
    psp/{@.metadata.annotations['kubernetes\.io/psp']} \
    state/{@.status.phase}{@.status.containerStatuses..state..reason}{'\n'}" |\
  column -t
