// Function-only PSP library (i.e. returns only methods,
// no actual object(s) created
local kube = (import "../lib/kube.libsonnet");

{
  PodSecurityPolicy(name):: kube._Object("policy/v1beta1", "PodSecurityPolicy", name) {
    metadata+: {
      assert !std.objectHas(self, "namespace") : "PSPs are not namespaced",
    },
    spec+: {
      // list of volume types considered safe to use
      safeVolumes_:: {
        configMap: true,
        emptyDir: true,
        persistentVolumeClaim: true,
        projected: true,
        secret: true,
        downwardAPI: true,
      },
      safeVolumes:: [key for key in std.objectFields(self.safeVolumes_) if self.safeVolumes_[key]],
    },
  },

  // Naming order matters: after collecting all PSPs for a Pod they'll get
  // alpha-sorted then 1st one will be applied.

  OrderedPSP(idx, plain_name):: $.PodSecurityPolicy(plain_name) {
    psp_meta:: { idx: idx, plain_name: plain_name },
    metadata+: { name: "%d-%s" % [idx, plain_name] },
  },

  // root/non-root helpers
  runAsAny:: { rule: "RunAsAny" },
  runAsNonRoot:: { rule: "MustRunAs", ranges: [{ min: 1, max: 65535 }] },

  // helper contructs and functions
  usePSP:: { apiGroups: ["policy"], resources: ["podsecuritypolicies"], verbs: ["use"] },
  crName(psp):: ("psp:%s" % psp.psp_meta.plain_name),
  rbName(pspName, ns):: ("psp:%s:%s" % [if ns != null then ns else "", pspName]),

  // Public methods
  ClusterRolePSP(psp):: kube.ClusterRole($.crName(psp)) {
    psp_meta:: psp.psp_meta,
    rules: [$.usePSP { resourceNames: [psp.metadata.name] }],
  },

  ClusterRoleBindingPSP(pspClusterRole, subjects):: kube.ClusterRoleBinding($.rbName(pspClusterRole.psp_meta.plain_name, null)) {
    roleRef_: pspClusterRole,
    subjects: subjects,
  },
  RoleBindingPSP(namespace, pspClusterRole, subjects):: kube.RoleBinding($.rbName(pspClusterRole.psp_meta.plain_name, namespace)) {
    assert pspClusterRole.kind == "ClusterRole" : "Passed pspClusterRole object must have `kind: 'ClusterRole', has: '%s'" % pspClusterRole.kind,
    metadata+: { namespace: namespace },
    roleRef_: pspClusterRole,
    subjects: subjects,
  },

  // Bind PSP ClusterRole to all SAs (Group) in namespace,
  // returns a RoleBinding object pointing to the passed ClusterRole,
  // with all fields and naming already set.
  RoleBindNamespacesToPSPRoles(namespaces, psp_cr):: {
    ["psp_rb_ns_%s_privileged" % ns]: $.RoleBindingPSP(
      ns,
      psp_cr,
      [kube.Group("system:serviceaccounts:%s" % ns)]
    )
    for ns in namespaces
  },
}
