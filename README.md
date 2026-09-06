---
post_title: Contoso Sovereign Landing Zone - Azure Multi-Region Demo
author1: GitHub Copilot
post_slug: contoso-prod-slz-demo
microsoft_alias: ""
featured_image: ""
categories: []
tags: [Azure, ALZ, SLZ, Terraform, Multi-Region]
ai_note: AI-assisted documentation based on the configured demo and verified workflow results.
summary: Two-region hub-and-spoke SLZ demo using the ALZ Terraform Accelerator, AVM and GitHub OIDC, without a paid DDoS plan.
post_date: 2026-09-06
---

## Contoso Sovereign Landing Zone Demo

This repository contains the Contoso platform landing zone configuration generated
by the **Azure Landing Zones Terraform Accelerator** using **Azure Verified
Modules (AVM)**. It demonstrates an SLZ governance hierarchy and a two-region
hub-and-spoke network with Azure Firewall Premium.

**This is a demo.** The `prod` suffix is a naming choice, not a production-readiness
or compliance claim. The GitHub organization uses the Free plan, so these
repositories are public. Never commit credentials, Terraform state or saved plans.

**Documentation snapshot: 6 September 2026.** Bootstrap completed. The no-DDoS
platform plan passed, and its apply was approved; completed regional provisioning
and acceptance checks are not yet confirmed. Consult the
[current delivery run](https://github.com/janegilring-demo/contoso-prod/actions/runs/34014306810)
for the latest result. Architecture diagrams below describe the configured target,
not an assertion that every component is deployed or compliant.

## Configuration

| Setting | Demo choice |
| --- | --- |
| Primary region | Norway East (`norwayeast`) |
| Secondary region | Sweden Central (`swedencentral`) |
| Platform subscriptions | Management, Connectivity and Identity |
| Existing parent | Tenant Root Group |
| Intermediate root | `contoso-alz` |
| Naming | Service `contoso`, environment `prod`, postfix `1` |
| Connectivity | `hub_and_spoke_vnet` |
| Paid DDoS Protection Plan | Disabled; associated auto-enable policies removed |
| Runners | GitHub-hosted |
| Apply approval | `contoso-prod-approvers` team, containing `janegilring` |
| ALZ PowerShell / bootstrap / starter | `7.1.5` / `v7.3.0` / `v17.5.1` |
| Terraform | `1.14.9` for the reviewed plan/apply workflow |
| SLZ library dependency | `platform/slz/2026.08.0` |

Subscription mappings and configuration are in
[terraform.tfvars.json](https://github.com/janegilring-demo/contoso-prod/blob/main/terraform.tfvars.json)
and [platform-landing-zone.auto.tfvars](https://github.com/janegilring-demo/contoso-prod/blob/main/platform-landing-zone.auto.tfvars).
Library customizations are in [lib](https://github.com/janegilring-demo/contoso-prod/tree/main/lib).

## Management-Group Architecture

```mermaid
flowchart TB
  tenant["Existing Tenant Root Group"] --> root["contoso-alz | Contoso Sovereign Landing Zone"]
  root --> platform["contoso-platform"]
  platform --> management["contoso-management | Management subscription"]
  platform --> connectivity["contoso-connectivity | Connectivity subscription"]
  platform --> identity["contoso-identity | Identity subscription"]
  platform --> security["contoso-security | No subscription assigned"]
  root --> landingzones["contoso-landingzones"]
  landingzones --> public["contoso-public"]
  landingzones --> corp["contoso-corp"]
  landingzones --> online["contoso-online"]
  landingzones --> local["contoso-local"]
  landingzones --> confidentialcorp["contoso-confidential-corp"]
  landingzones --> confidentialonline["contoso-confidential-online"]
  root --> sandbox["contoso-sandbox"]
  root --> decommissioned["contoso-decommissioned"]
```

Bootstrap created `contoso-alz` and initially attached the three subscriptions
directly beneath it. The platform configuration defines their final child-group
placement. Security is a reserved group; no fourth subscription was invented.

The SLZ model uses preview built-in initiatives aligned with:

- **L1: Data residency**, including region and service-specific replication controls.
- **L2: Encryption at rest and in transit**, including CMK with Key Vault Premium
  or Managed HSM keys, HTTPS and TLS-version controls.
- **L3: Encryption in use**, including confidential-computing controls.

The older Global and Confidential Sovereignty Baseline initiatives are historical
and were replaced in the April 2026 library update. Verify the selected library's
actual assignment IDs, effects and parameters, not only names or group existence.
The configured allowed locations are exactly `norwayeast` and `swedencentral`.

Local is intended for Azure Local workloads and Azure-public workloads with an
exit requirement to Azure Local disconnected operations. It is not a central
bucket for all Azure Arc resources. Resource-type eligibility alone does not
prove application portability or a tested exit plan.

## Regional Network Architecture

```mermaid
flowchart LR
  subgraph connectivity["Connectivity subscription - target architecture"]
    subgraph norway["Norway East - primary"]
      hubno["Hub VNet 10.0.0.0/22"] --- fwno["Azure Firewall Premium + policy"]
      hubno --- gwno["VPN + ExpressRoute gateways"]
      hubno --- basno["Azure Bastion"]
      fwno -->|"DNS proxy"| dnsno["Private DNS Resolver"]
    end
    subgraph sweden["Sweden Central - secondary"]
      hubse["Hub VNet 10.1.0.0/22"] --- fwse["Azure Firewall Premium + policy"]
      hubse --- gwse["VPN + ExpressRoute gateways"]
      hubse --- basse["Azure Bastion"]
      fwse -->|"DNS proxy"| dnsse["Private DNS Resolver"]
    end
    hubno <-->|"Hub peering"| hubse
    zones["Private DNS zones and VNet links"] --- hubno
    zones --- hubse
  end
  spokefuture["Future workload spokes - not supplied by this demo"] -.-> hubno
  spokefuture -.-> hubse
```

Regional address allocations are `10.0.0.0/16` and `10.1.0.0/16`; the actual hub
VNets use the `/22` ranges shown above. Future spokes use the regional firewall
as DNS proxy and the generated user-subnet routes for traffic inspection.

The Management subscription hosts monitoring resources such as Log Analytics,
data collection rules and the AMA managed identity. No identity-service workload,
workload spoke, VPN connection or ExpressRoute circuit is provisioned by this
configuration. Multi-region hubs do not provide automatic application failover.

## Delivery and State Security

- [This repository](https://github.com/janegilring-demo/contoso-prod) owns platform configuration.
- [contoso-prod-templates](https://github.com/janegilring-demo/contoso-prod-templates)
  owns the reusable CI/CD workflows.
- CI formats/validates Terraform and produces a plan for pull requests.
- CD runs a plan, waits for the required apply environment reviewer, then applies
  that same saved plan. Both repositories have protected main branches.
- Separate managed identities authenticate using GitHub OIDC. Plan has Reader
  and apply has Owner at `contoso-alz`; both have blob data access to the state
  container. No Azure client secret is required by these workflows.
- Terraform state is in a Norway East ZRS storage account with TLS 1.2, shared
  keys disabled and anonymous blob access disabled.
- Saved plan bundles use the same access-controlled Azure container instead of
  public GitHub artifacts. The bundle includes the lockfile and excludes state,
  caches and Git metadata. It is deleted after a successful apply.

The initial run encountered a backend 403 because the inherited MCAPS policy
disabled storage public-network access. The user explicitly authorized the
policy's `SecurityControl=Ignore` tag exclusion **only on bootstrap state storage**.
Public-network access was then enabled, while blob authentication and RBAC remain
required. No resource-group or tenant-wide policy exemption was created. Review
other MCAPS controls that honor the same tag before reusing this demo exception.

### Running the Deployment

Check for an existing run before dispatching another deployment. In **Actions**,
select **02 Azure Landing Zones Continuous Delivery**, choose **Run workflow**,
use `terraform_action=apply` and `terraform_cli_version=1.14.9`, review the plan,
then approve `contoso-prod-apply`. The workflow also runs on pushes to main.

Do not substitute a local apply or remove protection rules to bypass approval.
For documentation-only commits, `[skip ci]` prevents an unnecessary CI/CD run;
it does not change branch-protection requirements.

## Recorded Changes and Validation

1. Bootstrap completed with 157 additions and no changes/deletions. This includes
   GitHub files and provider registrations, not just Azure infrastructure.
2. [Templates PR #1](https://github.com/janegilring-demo/contoso-prod-templates/pull/1)
   moved saved plan bundles to protected Azure storage.
3. The account-scoped storage exception restored backend access. CI and delivery
   plan jobs verified OIDC, state access and protected bundle upload.
4. [Platform PR #1](https://github.com/janegilring-demo/contoso-prod/pull/1) disabled
   the paid DDoS plan and removed `Enable-DDoS-VNET` from the connectivity and
   landing-zone archetypes. No replacement paid DDoS SKU was enabled.
5. [CI run 34014115414](https://github.com/janegilring-demo/contoso-prod/actions/runs/34014115414)
   passed. The reviewed delivery plan contains 1509 additions, no changes or
   deletions, and no paid DDoS resource. Apply completion remains to be verified.

Before declaring the demo complete, verify regional provisioning, hub peerings,
firewall policies, gateways, Bastion, DNS endpoints/zones/links, subscription
placement, L1/L2/L3 policy assignments and a subsequent no-unexpected-change plan.
Policy evaluation/propagation and workload compliance are separate checks.

## Cost and Cleanup

Reference fixed cost without the paid DDoS plan: **USD 5,333.72/month**, reduced
by **USD 2,944/month** from the source scenario's USD 8,277.72. These are westus
estimates dated 2 April 2026, not Norway/Sweden prices or the current bill. Usage,
Defender, logging, egress, circuits and bootstrap add cost. Built-in Azure DDoS
infrastructure protection remains, but is not equivalent to DDoS Network Protection.

Preserve pre-existing resources in all three subscriptions. Do not use
subscription-wide cleanup or delete Tenant Root Group. Review exact demo resource
scopes before destruction, and retain the state backend and deployment identities
until dependent resources have been removed. A previous bootstrap re-plan proposed
state-container/RBAC replacements and was rejected: investigate drift before
rerunning bootstrap, rather than recreating state infrastructure.

## Reference Material

- [ALZ Terraform Accelerator](https://github.com/Azure/alz-terraform-accelerator)
- [Multi-region hub-and-spoke scenario and cost source](https://azure.github.io/Azure-Landing-Zones/accelerator/starter-terraform/scenarios/multi-region-hub-and-spoke-vnet-with-azure-firewall/)
- [SLZ option](https://azure.github.io/Azure-Landing-Zones/accelerator/starter-terraform/options/slz/)
- [Disable DDoS option](https://azure.github.io/Azure-Landing-Zones/accelerator/starter-terraform/options/ddos/)
- [Local management group and updated sovereign policies](https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/new-local-management-group-for-alz--updated-sovereign-policies-for-slz/4515156)
- [ALZ's Azure Migrate maintenance handover](https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/azure-landing-zone-alz-enters-its-next-chapter/4533520)
- [Cleanup guidance](https://azure.github.io/Azure-Landing-Zones/accelerator/faq/cleanup/)

ALZ remains open source and community-driven under Azure Migrate maintenance.
The maintenance handover does not require switching deployment tools, nor does
this demo claim to have been deployed by the Azure Migrate agent.
