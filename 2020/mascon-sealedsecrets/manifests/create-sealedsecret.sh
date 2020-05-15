#!/bin/bash
kubectl create secret generic mydb-secret --from-literal=db-password=$(read -s -p "pass: " pass; echo $^Css) -oyaml --dry-run=client |\
   kubeseal > mydb.sealedsecret.yaml
