# Playing with sealed-secrets

See <https://github.com/bitnami-labs/sealed-secrets>

## Installation
### Client side: `kubeseal` CLI tool

* Linux

~~~~bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.3/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
~~~~

* MacOS

~~~~bash
brew install kubeseal
~~~~

### Server side: sealed-secrets `controller` in kube-system NS

~~~~bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.3/controller.yaml
~~~~

## Example usage

1. Deploy a MariaDB image without `MARIADB_ROOT_PASSWORD`, it will
   CrashLoop because of lacking it

~~~~bash
cd manifests
kubectl apply -f mydb.deploy.yaml
~~~~

2. Add missing secret, push sealedsecret

~~~~bash
./create-sealedsecret.sh
kubectl apply -f mydb.sealedsecret.yaml
~~~~
