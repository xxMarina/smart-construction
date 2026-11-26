# Evidências de Execução — Smart Construction (GCP)

Prints organizados em ordem sequencial dos cenários de teste do **PM-04 | Projeto Final**:

1. **`01-deploy.png`** — Cenário 1: execução da pipeline `deploy.yml` (Terraform + Ansible + Smoke Test HTTPS).
2. **`02-antes-depois-mudanca-VM.png`** — Cenário 2: verificação na GCP (antes/depois da alteração de `e2-small` → `e2-medium`).
3. **`03-antes-depois-mudanca-VM-ACTIONS.png`** — Cenário 2: log do GitHub Actions (`terraform-apply`) mostrando a mudança aplicada no tipo das VMs.
4. **`04-cenario3-idempotencia.png`** — Cenário 3: reexecução da pipeline sem alterações (`No changes` no Terraform e idempotência no Ansible).
5. **`05-aplicacao-profissionais-publico.png`** — Validação da demanda: página pública `/profissionais` exibindo o profissional sintético aprovado com foto.
6. **`06-backup-restore-postgres.png`** — Validação de backup e restauração isolada do **PostgreSQL** (`backup-test.yml`).
7. **`07-backup-restore-storage.png`** — Validação de backup e restauração isolada do **SeaweedFS** (`backup-test.yml`).
8. **`08-load-balancer-health.png`** — Saúde das instâncias `app-1` e `app-2` (`HEALTHY`) atrás do Cloud Load Balancer.
9. **`09-snapshot-antes.png`** — Estado antes da janela automática de snapshot (`Listed 0 items`).
10. **`10-snapshot-depois.png`** — Snapshots automáticos criados pela política `daily_backup` (`READY`).
11. **`11-snapshot.png`** — Detalhe dos snapshots automáticos na GCP.
