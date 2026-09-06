## Contoso Governance Compatibility Patch

Vendored from Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm
version 0.17.2, upstream commit a7da6e9bf6ae7a4be49ccbe47e57ce6e8efc2fb6.
The upstream MIT license is retained. This is a locally maintained derivative,
not a newly published or certified AVM release. Only runtime Terraform sources
and documentation are distributed; upstream development metadata is excluded.

### Changes

- `required_public_ip_tags`: map, empty by default. Passed to the nested mesh for
  firewall data/management IPs and merged into Bastion and gateway IP settings.
  Required values take precedence over per-IP values. The Contoso caller sets
  `FirstPartyUsage=/Unprivileged` to match the enforced tenant-root append policy.
- `subnet_network_security_group_ids`: nested map keyed by hub and generated
  subnet key. References existing external NSGs for Bastion and DNS-resolver
  subnets, without taking ownership of the NSGs or their rules.

Resource names, module labels, for_each keys, provider requirements, and registry
dependency versions are unchanged. No lifecycle ignore, state edit, provider
fork, policy exception, or resource deletion is used to conceal drift.

The caller currently supplies verified NSG IDs for primary/secondary hubs only.
Do not guess references to nonexistent NSGs for a future hub. Onboarding another
region must account for that region's policy-created NSG associations separately.

### Verification

Run root `terraform validate`, TFLint with both input files, and the consumer's
configuration-preservation checks. Review the complete CI/CD plan before apply:
no public-IP replacements and no removal of existing subnet NSG associations.
Recreating the already-absent Bastion hosts is expected. Registry-module scanner
findings and unavailable contributor tooling must be reported, not suppressed.

Replace this derivative with an upstream version only after equivalent tag/NSG
inputs are available and a reviewed plan proves existing addresses are retained.