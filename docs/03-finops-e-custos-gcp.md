# FinOps e Estimativa de Custos — GCP

## 1. Premissas de Tráfego e Armazenamento

- **Ambiente:** laboratório acadêmico (`projeto-mensal-4`) na região `southamerica-east1` (São Paulo).
- **Tráfego estimado:** baixo volume (acessos de validação, testes E2E e demonstração em aula, < 20 GB/mês de saída).
- **Armazenamento:** discos de boot padronizados em `10 GiB` por VM (40 GiB no total) + discos persistentes externos para banco de dados e objetos SeaweedFS + snapshots diários (`daily_backup`).
- **Otimização de uso:** uso do workflow `power-schedule.yml` (`stop`/`start`) para desligar as VMs fora dos períodos de teste e aula, reduzindo o custo de computação em até ~70%.

## 2. Estimativa Mensal por Recurso

| Recurso | Especificação | Custo Mensal Estimado (USD) | Observação |
| :--- | :--- | :---: | :--- |
| Compute Engine (4 VMs) | 4x `e2-small` (`app-1`, `app-2`, `storage`, `db`) | ~$48.00 – $68.00 | ~$17/VM ligada 24x7; cai para ~$15–$20 com `power-schedule.yml` |
| Discos de Boot | 4x `10 GiB` (`pd-standard` / `pd-balanced`) | ~$2.00 – $4.00 | Padronizados em `10 GiB` no `compute.tf` |
| Discos Persistentes | `db-data-1` + `storage-data-1` | ~$3.00 – $6.00 | Dados do PostgreSQL 17 e SeaweedFS |
| Snapshots Diários | Política `daily_backup` | ~$1.00 – $2.00 | Aplicada aos discos de dados |
| Cloud Load Balancer | Forwarding rule + HTTPS (`sslip.io`) | ~$18.00 | Custo fixo de LB + tráfego baixo |
| Cloud NAT + VPC | 1x Cloud NAT para saída das VMs privadas | ~$3.00 – $5.00 | Tráfego de saída mínimo |
| Artifact Registry + GCS + Secret Manager | Imagens Docker, Terraform state e segredos | ~$0.50 – $1.50 | Uso dentro/próximo da faixa gratuita |
| **Total Estimado (24x7)** | — | **~$75.50 – $104.50** | — |
| **Total com `power-schedule.yml`** | — | **~$42.50 – $58.50** | Economia direta desligando VMs ociosas |

## 3. Alternativas Consideradas

- **Cloud SQL vs VM dedicada (`smart-construction-db`):** Cloud SQL traria gerenciamento automático, mas elevaria o custo fixo mensal; a VM `e2-small` com disco persistente e `backup-test.yml` atende ao laboratório com menor custo e controle total.
- **VM única vs 2 VMs de app + 1 VM de storage:** manter 2 VMs de aplicação valida o Load Balancer, enquanto isolar o SeaweedFS em `smart-construction-storage` elimina inconsistência de imagens sem depender de Cloud Storage pago por operação/egresso adicional.
