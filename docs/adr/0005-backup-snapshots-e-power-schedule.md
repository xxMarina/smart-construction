# ADR 0005 — Estratégia de Backup, Snapshots Automáticos e Controle de Energia

## Contexto

O projeto exige proteção contra perda de dados (banco PostgreSQL 17 e objetos no SeaweedFS), validação automatizada de restauração e controle de custos acadêmicos na GCP (onde 4 VMs `e2-small` ligadas 24x7 custam cerca de R\$ 473,81/mês só em computação).

## Decisão

- **Snapshots diários (`daily_backup`):** política regional no Terraform aplicada aos discos persistentes `smart-construction-db-data-1` e `smart-construction-storage-data-1` com janela a partir das `03:00` UTC (`00:00` BRT), retenção de `7` dias e `on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"`.
- **Teste isolado de backup/restore (`backup-test.yml`):** workflow dedicado no GitHub Actions que extrai dumps do PostgreSQL e arquivos do SeaweedFS via IAP SCP e valida a restauração em containers temporários isolados.
- **Controle de energia (`power-schedule.yml`):** workflow manual (`workflow_dispatch` com `stop`/`start`) para desligar as 4 VMs fora dos horários de aula/teste, mantendo discos e snapshots ativos.

## Consequências

- **Positivas:** backups automáticos continuam rodando mesmo com VMs desligadas; restauração validada ponta a ponta; economia estimada de ~70% no custo de VMs (reduzindo o total mensal de R\$ 762,92 para ~R\$ 431,25).
- **Negativas:** snapshots existentes permanecem por até 7 dias após um `terraform destroy`, exigindo remoção manual se o objetivo for zerar 100% dos recursos imediatamente.
