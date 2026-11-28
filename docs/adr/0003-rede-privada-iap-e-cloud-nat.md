# ADR 0003 — Rede Privada, Acesso via IAP e Saída via Cloud NAT

## Contexto

As VMs de banco de dados, armazenamento e aplicação não devem ficar expostas diretamente na internet por portas administrativas (SSH/22, PostgreSQL/5432, SeaweedFS/8333-8334).

## Decisão

- Provisionar todas as VMs na sub-rede privada (`10.10.0.0/24`) **sem IPs públicos**.
- Restringir o tráfego externo HTTP/HTTPS exclusivamente ao **Cloud Load Balancer** (`<IP_LB>.sslip.io`).
- Utilizar **Cloud NAT** para saída controlada de internet (atualizações `apt` e pull de imagens no Artifact Registry).
- Utilizar **Identity-Aware Proxy (IAP)** para acesso SSH administrativo e execução do Ansible (`--tunnel-through-iap`).

## Consequências

- **Positivas:** superfície de ataque mínima; banco e storage inacessíveis externamente; auditoria de acesso via IAM da GCP.
- **Negativas:** dependência do Cloud NAT (~R\$ 48,59/mês) para saída das VMs e necessidade de configurar `iap` no `ansible.cfg` e workflows.
