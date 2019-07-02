// Deploy PodSecurityPolicy rules to this cluster
local psp = import "../../common/psp.jsonnet";

local extraPrivNamespaces = [
  // "jenkins-team-foo",
  // "jenkins-team-bar",
];

local extraRestrictedNamespaces = [
  // "restricted-testbed",
];

local extraOSRestrictedNamespaces = [
  // "restricted-os-testbed",
];

psp +
psp.lib.RoleBindNamespacesToPSPRoles( extraPrivNamespaces, psp.psp_cr_privileged) +
psp.lib.RoleBindNamespacesToPSPRoles( extraRestrictedNamespaces, psp.psp_cr_restricted) +
psp.lib.RoleBindNamespacesToPSPRoles( extraOSRestrictedNamespaces, psp.psp_cr_openshift_restricted)
