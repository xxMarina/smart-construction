# ADR 0001 — Escolha da Google Cloud Platform e Região `southamerica-east1`

## Contexto

A aplicação Smart Construction precisava sair do ambiente local Docker Compose para uma infraestrutura em nuvem provisionada via Terraform e configurada via Ansible, atendendo aos requisitos do laboratório acadêmico (`projeto-mensal-4`) com baixa latência para usuários no Brasil e controle de custos.

## Decisão

Adotar a **Google Cloud Platform (GCP)** na região **`southamerica-east1`** (São Paulo, zona `southamerica-east1-a`), utilizando Compute Engine (`e2-small`), Cloud Load Balancer, VPC privada, Cloud NAT, Identity-Aware Proxy (IAP), Artifact Registry, Secret Manager e Cloud Storage (para o `.tfstate`).

## Consequências

- **Positivas:** baixa latência no Brasil, integração nativa entre IAP, Secret Manager, Artifact Registry e inventário dinâmico do Ansible (`google.cloud.gcp_compute`), além de créditos acadêmicos disponíveis no projeto.
- **Negativas:** custo fixo do Cloud Load Balancer e Cloud NAT mesmo em baixo tráfego, mitigado parcialmente pelo desligamento programado das VMs via `power-schedule.yml`.
