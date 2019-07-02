#!/bin/sh -v
kubectl get ns -oname |egrep -o ns-.+ | xargs -tI@ -P0 kubectl delete pod -n @ --all
