# 02. Operação, Pipelines, Backup e Encerramento

Este documento descreve os procedimentos operacionais, pipelines de CI/CD, tratamento de segredos, acessos, plano de backup/restauração e encerramento da infraestrutura do **Smart Construction** na **Google Cloud Platform (GCP)**.

---

## 1. Pipelines de Infraestrutura e Entrega (GitHub Actions)

Toda a infraestrutura e implantação são automatizadas via GitHub Actions, autenticadas na GCP por **Workload Identity Federation (OIDC)** — sem chaves JSON estáticas no repositório.

| Workflow | Arquivo | Gatilho | Responsabilidade |
| :--- | :--- | :--- | :--- |
| **Deploy** | `.github/workflows/deploy.yml` | Push em `main` / PR / `workflow_dispatch` | `terraform init/plan/apply`, build & push das imagens Docker para o Artifact Registry e configuração das VMs via Ansible (`playbook-db.yml` e `playbook-app.yml`) por túnel IAP. |
| **Destroy** | `.github/workflows/destroy.yml` | `workflow_dispatch` | Executa backup lógico pré-destroy do PostgreSQL (Artifact no GitHub Actions) e `terraform destroy` para remover VMs, rede/LB e recursos efêmeros, preservando discos persistentes e estado remoto. |
| **Backup Test** | `.github/workflows/backup-test.yml` | `workflow_dispatch` | Executa `pg_dump` do banco principal e valida `pg_restore` em banco isolado (`smart_construction_restore_test`) via túnel IAP. |
| **Power Schedule** | `.github/workflows/power-schedule.yml` | Agendamento / `workflow_dispatch` | Liga/desliga as VMs (`TERMINATED`) fora do horário operacional para redução de custos de computação. |

---

## 2. Etapas Manuais Justificadas e Segredos

Para manter o estado e as credenciais protegidos fora do controle de versão e evitar recriação acidental de dados críticos, os seguintes recursos são pré-provisionados manualmente uma única vez:

1. **Bucket de Estado Remoto (`smart-construction-tfstate-projeto-mensal-4`):** Armazena o `terraform.tfstate` com versionamento.
2. **Discos Persistentes (`smart-construction-backend-data`, `smart-construction-storage-data-1`, `smart-construction-storage-data-2`):** Mantêm o banco PostgreSQL 17 e os volumes do SeaweedFS independentes do ciclo de vida das VMs (`destroy` / `apply`).
3. **GCP Secret Manager:** Armazena os 5 segredos de runtime (`sc-db-password`, `sc-jwt-secret`, `sc-admin-password`, `sc-s3-access-key`, `sc-s3-secret-key`), lidos pelas VMs via Service Account (`smart-construction-app-sa`) sem exposição em logs ou repositório.
4. **Workload Identity Federation (OIDC) e Service Account de Deploy (`github-deployer`):** Permite que o GitHub Actions execute Terraform, Artifact Registry e túneis IAP sem chaves estáticas.

---

## 3. Acessos Administrativos, Rede e Logs

- **Sem SSH público:** Nenhuma VM possui porta 22 exposta à internet. Todo acesso administrativo (humano ou Ansible) ocorre via **Identity-Aware Proxy (IAP)** (`gcloud compute ssh ... --tunnel-through-iap`).
- **Isolamento do Banco:** A VM `smart-construction-db` não possui IP público; a porta `5432` aceita conexões exclusivamente da sub-rede interna das VMs de aplicação.
- **Logs de Aplicação:** Podem ser consultados nas VMs via `docker logs` (ex.: `smart-construction-api-1`, `smart-construction-web-1`, `smart-construction-gateway-1`) ou via Cloud Logging.

---

## 4. Atualização da Aplicação

1. Alterações em código ou infraestrutura são enviadas via Pull Request (`terraform plan` automático para validação).
2. Após merge em `main` (ou disparo manual de `deploy.yml`):
   - Novas imagens imutáveis são construídas e enviadas ao Artifact Registry.
   - O Terraform aplica eventuais mudanças de infraestrutura (pulando o `apply` automaticamente quando não há alterações).
   - O Ansible atualiza os containers nas VMs de aplicação e executa healthchecks antes de concluir.

---

## 5. Plano de Backup e Restauração

### 5.1. Estratégia
- **Banco de Dados (PostgreSQL 17):** Backups lógicos via `pg_dump` (formato customizado `.dump`) na VM `smart-construction-db`, além da persistência em disco dedicado (`smart-construction-backend-data`). O workflow `destroy.yml` também gera automaticamente um dump pré-destroy e o armazena como Artifact no GitHub Actions (retenção de 30 dias) antes de remover a VM.
- **Armazenamento de Arquivos (SeaweedFS):** Dados gravados nos discos persistentes dedicados (`smart-construction-storage-data-1` e `smart-construction-storage-data-2`).

### 5.2. Teste de Restauração em Ambiente Isolado
> **Status:** Validado via pipeline (`.github/workflows/backup-test.yml`) em **17/11/2026**.

Procedimento automatizado executado via túnel IAP na VM `smart-construction-db`:
1. Geração de dump customizado (`pg_dump -U smart_migrator -d smart_construction -Fc -f /tmp/sc_backup_test.dump`).
2. Criação do banco isolado `smart_construction_restore_test`.
3. Restauração com `pg_restore --no-owner --no-acl` no banco isolado.
4. Validação de integridade entre o banco principal e o banco restaurado:
   - `Tabelas no schema smart (principal): 20 | restaurado: 20`
   - `Profissoes no banco principal: 2 | restaurado: 2`
   - Todas as 20 tabelas do schema `smart` restauradas (`aceites`, `administradores`, `arquivos`, `auditoria`, `cadastros`, `comprovantes_encerramento`, `empresas`, `enderecos`, `historico_cadastros`, `idempotencias_cadastro`, `limites_cadastro`, `limites_login`, `preservacoes`, `profissionais`, `profissional_cursos`, `profissional_profissoes`, `profissoes`, `publicacoes_profissionais`, `sessoes_admin`, `uploads_journal`).
5. Limpeza automática do banco temporário `smart_construction_restore_test` e do arquivo `/tmp/sc_backup_test.dump`.

---

## 6. Encerramento de Recursos e Cobrança Residual

Ao executar o workflow `destroy.yml`:
- **Recursos removidos (custo zerado):** VMs (`app-1`, `app-2`, `db`), Cloud Load Balancer, regra de encaminhamento, IP estático e recursos de rede associados.
- **Recursos mantidos (cobrança residual mínima):**
  - Discos persistentes de dados e storage (para preservação dos dados entre ciclos).
  - Bucket GCS de estado remoto (`smart-construction-tfstate-projeto-mensal-4`) e imagens no Artifact Registry (~R$ 1,13/mês).
  - Segredos no Secret Manager (dentro do Free Tier — R$ 0,00/mês).
