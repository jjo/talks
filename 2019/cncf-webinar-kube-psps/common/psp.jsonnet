// Create all objects needed for PSP:
// PSPs <- ClusterRoles <- (Cluster)RoleBindings

local kube = import "../lib/kube.libsonnet";

// Default extra namespaces needing psp_privileged (kubeprod, nginx-ingress),
local extraPrivNamespaces = ["kubeprod", "nginx-ingress"];

local psp = {
  lib:: import "../common/libpsp.jsonnet",
  // psp_FOO policies below are "chained" to further restrict what they can do,
  // their name must be also sorted from restrictive to permissive
  // to be able to use "override" cluster-wide default, below we'll create:
  //
  //   PSP                     ClusterRole
  //   20-restricted           restricted
  //   30-pks-restricted       pks-restricted
  //   32-openshift-restricted openshift-restricted
  //   40-nonroot              nonroot
  //   60-mayroot              mayroot     (cluster-wide default)
  //   70-mayroot_w_privesc    mayroot
  //   80-privileged           privileged

  // psp_privileged: allow all: privileged, root ok, linux host namespaces (net, PID, etc)
  // use-case: workloads requiring host mounts, networking (e.g. CNI pods), etc
  psp_privileged: $.lib.OrderedPSP(80, "privileged") {
    spec+: {
      allowedCapabilities: ["*"],
      privileged: true,
      allowPrivilegeEscalation: true,
      hostNetwork: true,
      hostIPC: true,
      hostPID: true,
      hostPorts: [{ min: 0, max: 65535 }],
      runAsUser: $.lib.runAsAny,
      fsGroup: $.lib.runAsAny,
      supplementalGroups: $.lib.runAsAny,
      seLinux: $.lib.runAsAny,
      volumes: ["*"],
    },
  },

  // psp_mayroot: allow root but void using/modifying host resources
  // use-case: most typical root containers
  psp_mayroot: $.psp_privileged + $.lib.OrderedPSP(60, "mayroot") {
    spec+: {
      privileged: false,
      allowPrivilegeEscalation: false,
      hostNetwork: false,
      hostIPC: false,
      hostPID: false,
      forbiddenSysctls: ["*"],
      // void hostPath for volumes
      volumes: self.safeVolumes,
      // don't allow packet-level inspection
      allowedCapabilities: [],
      requiredDropCapabilities: ["NET_RAW"],
      hostPorts: [],
    },
  },

  // psp_mayroot_w_privesc: allow root and privilege escalation but void using/modifying host resources
  // use-case: most typical root containers
  psp_mayroot_w_privesc: $.psp_mayroot + $.lib.OrderedPSP(70, "mayroot-w-privesc") {
    spec+: {
      // Restore `allowedCapabilities: *` (needing to also drop NET_RAW), else
      // Pods intended to rolebind to 70-mayroot-w-privesc (e.g. vtracker in k.dev release-automations NS)
      // would end binding to 60-mayroot
      // TODO(SRE): debug why is that happening ^
      allowedCapabilities: ["*"],
      requiredDropCapabilities: [],
      allowPrivilegeEscalation: true,
    },
  },

  // psp_nonroot: additionally forcing non root
  // use-case: non-root, similar to openshift restrictions
  psp_nonroot: $.psp_mayroot + $.lib.OrderedPSP(40, "nonroot") {
    spec+: {
      runAsUser: { rule: "MustRunAsNonRoot" },
      fsGroup: $.lib.runAsNonRoot,
      supplementalGroups: $.lib.runAsNonRoot,
    },
  },

  // psp_restricted: additionally forcing no linux caps
  // Most restrictive, forcing all capabilities drop

  psp_restricted: self.psp_nonroot + $.lib.OrderedPSP(20, "restricted") {
    spec+: {
      readOnlyRootFilesystem: true,
      requiredDropCapabilities: ["ALL"],
      allowedCapabilities: [],
    },
  },

  // NOTE: it's not possible to further restrict automountServiceAccountToken
  // via PSPs as it's handled as a "normal" Secret Volume, would need to be
  // policed via other means like OPA (Open Policy Agent).
  // See https://github.com/sysdiglabs/kube-psp-advisor/blob/a17acbc531ac47ba2313112e2cda03b520038fa9/generator/generator.go#L50
  //
  // Voiding this mount can be achieved by adding below to the ServiceAccount itself:
  //   apiVersion: v1
  //   automountServiceAccountToken: false
  //   kind: ServiceAccount


  // Two additional different "flavors" for privileged
  // NB: as these are less restrictive than above, use a higher order than psp_restricted
  //     in case e.g. a namespace default "30-pks-restricted" wants to be overridden
  //     by a serviceAccount bound to "20-restricted"

  // pks-restricted: following https://docs.pivotal.io/runtimes/pks/1-4/pod-security-policy.html#psp-admin
  psp_pks_restricted: self.psp_restricted + $.lib.OrderedPSP(30, "pks-restricted") {
    spec+: {
      readOnlyRootFilesystem: false,
    },
  },

  // openshift-restricted: trying to mimic openshift as much as possible
  psp_openshift_restricted: self.psp_restricted + $.lib.OrderedPSP(32, "openshift-restricted") {
    spec+: {
      readOnlyRootFilesystem: false,
      fsGroup: $.lib.runAsAny,
      supplementalGroups: $.lib.runAsAny,
    },
  },

  // respective ClusterRoles for each PSP above
  psp_cr_privileged: $.lib.ClusterRolePSP($.psp_privileged),
  psp_cr_mayroot_w_privesc: $.lib.ClusterRolePSP($.psp_mayroot_w_privesc),
  psp_cr_mayroot: $.lib.ClusterRolePSP($.psp_mayroot),
  psp_cr_nonroot: $.lib.ClusterRolePSP($.psp_nonroot),
  psp_cr_restricted: $.lib.ClusterRolePSP($.psp_restricted),
  psp_cr_pks_restricted: $.lib.ClusterRolePSP($.psp_pks_restricted),
  psp_cr_openshift_restricted: $.lib.ClusterRolePSP($.psp_openshift_restricted),

  // Cluster-wide default PSP
  psp_crb_clusterwide: $.lib.ClusterRoleBindingPSP($.psp_cr_mayroot, [
    kube.Group("system:authenticated"),
    kube.Group("system:serviceaccounts"),
  ]),

  // kube-system specific
  psp_rb_ns_kube_system_privileged: $.lib.RoleBindingPSP("kube-system", $.psp_cr_privileged, [
    kube.Group("system:masters"),
    kube.Group("system:serviceaccounts:kube-system"),
    kube.Group("system:nodes"),
    // Legacy node ID
    kube.User("kubelet"),
  ]),

};

psp +
psp.lib.RoleBindNamespacesToPSPRoles(
  extraPrivNamespaces,
  psp.psp_cr_privileged
)
