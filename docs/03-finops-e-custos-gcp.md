# FinOps e Estimativa de Custos — GCP

## 1. Premissas de Tráfego e Armazenamento

- **Ambiente:** laboratório acadêmico (`projeto-mensal-4`) na região `southamerica-east1` (São Paulo).
- **Tráfego estimado:** baixo volume (acessos de validação, testes E2E e demonstração em aula, < 20 GB/mês de saída).
- **Armazenamento:** discos de boot padronizados em `10 GiB` por VM (40 GiB no total) + discos persistentes externos para banco de dados e objetos SeaweedFS + snapshots diários (`daily_backup`).
- **Otimização de uso:** uso do workflow `power-schedule.yml` (`stop`/`start`) para desligar as VMs fora dos períodos de teste e aula, reduzindo o custo de computação em até ~70%.

## 2. Estimativa Mensal por Recurso (Calculadora GCP)

Valores obtidos na **Calculadora de Preços da GCP** ([link da estimativa](https://cloud.google.com/products/calculator?dl=CjhDaVEwWVRsbE56UXdNQzFsTm1FMUxUUTFZV0l0T1RoaFpDMHhOV1ZqWlRjd09HVTJaRGtRQVE9PRAzGiQ5QkE2Q0FGRi0wQTY1LTRDM0UtQjlGQi00QTIyREQ5MUQ1NjE)) em **BRL**, exportados em [GCP-CUSTOS.csv](./custos/GCP-CUSTOS.csv) e [Google Cloud Estimate Summary.pdf](./custos/Google%20Cloud%20Estimate%20Summary.pdf):

| Recurso | Especificação | Custo Mensal (BRL) | Observação |
| :--- | :--- | :---: | :--- |
| Compute Engine (4 VMs) | 4x `e2-small` (`app-1`, `app-2`, `storage`, `db`) — 2.920h | R$ 473,81 | Ligadas 24x7; reduz até ~70% com `power-schedule.yml` |
| Discos de Boot | 4x `10 GiB` (`Balanced PD`) | R$ 36,61 | Padronizados em `10 GiB` no `compute.tf` |
| Discos Persistentes | `20 GiB` (`Zonal Balanced PD` — `db-data` + `storage-data`) | R$ 18,31 | Dados do PostgreSQL 17 e SeaweedFS |
| Snapshots Diários | `20 GiB` (`Storage PD Snapshot`, política `daily_backup`) | R$ 9,76 | Retenção de 7 dias em `southamerica-east1` |
| Cloud Load Balancer | Regional/External ALB (2 forwarding rules + 1 GiB in/out) | R$ 169,41 | Custo fixo mínimo de forwarding rule + tráfego baixo |
| Cloud NAT | `Public NAT` (4 VMs, 5 GiB, 1 IP) | R$ 48,59 | Saída das VMs sem IP público |
| Artifact Registry | `10 GiB` de armazenamento Docker | R$ 5,80 | Imagens `web`, `api` e `gateway` |
| Cloud Storage (GCS) | `3 GiB` Standard (`southamerica-east1`) | R$ 0,64 | Armazenamento do `.tfstate` |
| Secret Manager | 5 versões ativas, 10.000 acessos, 3 rotações | R$ 0,00 | Dentro da faixa gratuita |
| **Total Estimado (24x7)** | — | **R$ 762,92** | **R$ 9.155,07 / ano** |
| **Total com `power-schedule.yml`** | — | **~R$ 431,25** | Redução de ~70% no custo das VMs (~R$ 331,67 de economia) |

## 3. Alternativas Consideradas

- **Cloud SQL vs VM dedicada (`smart-construction-db`):** Cloud SQL traria gerenciamento automático, mas elevaria o custo fixo mensal; a VM `e2-small` com disco persistente e `backup-test.yml` atende ao laboratório com menor custo e controle total.
- **VM única vs 2 VMs de app + 1 VM de storage:** manter 2 VMs de aplicação valida o Load Balancer, enquanto isolar o SeaweedFS em `smart-construction-storage` elimina inconsistência de imagens sem depender de Cloud Storage pago por operação/egresso adicional.
