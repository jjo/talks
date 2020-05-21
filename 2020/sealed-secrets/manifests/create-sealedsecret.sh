#!/bin/bash
set -v
kubectl create secret generic mydb-secret --from-literal=db_password=$(read -s -p "pass: " pass; echo $pass) -oyaml --dry-run=client |\
   kubeseal "${@}" > mydb.sealedsecret.yaml
