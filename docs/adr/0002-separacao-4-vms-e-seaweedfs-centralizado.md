# ADR 0002 — Separação em 4 VMs e Centralização do SeaweedFS

## Contexto

A arquitetura inicial previa 2 VMs de aplicação (`app-1` e `app-2`) atrás do Load Balancer e 1 VM de banco (`db`). Manter o SeaweedFS replicado localmente dentro de cada VM de aplicação causava risco de *split-brain* no upload e leitura de imagens entre `app-1` e `app-2`.

## Decisão

Separar a infraestrutura em **4 VMs `e2-small`** com discos de boot padronizados em `10 GiB`:

1. `smart-construction-app-1` e `smart-construction-app-2`: camada *stateless* (`web` + `api` + `gateway`).
2. `smart-construction-storage`: VM dedicada ao **SeaweedFS** (`:8333` editorial, `:8334` privado) com disco persistente `smart-construction-storage-data-1`.
3. `smart-construction-db`: VM dedicada ao **PostgreSQL 17** com disco persistente `smart-construction-db-data-1`.

## Consequências

- **Positivas:** elimina inconsistência de arquivos entre `app-1` e `app-2`, permite escalar ou substituir VMs de aplicação sem perda de dados e possibilita backup/restore isolado de banco e imagens (`backup-test.yml`).
- **Negativas:** adiciona o custo de uma 4ª VM `e2-small` (~R\$ 118,45/mês 24x7 antes do `power-schedule.yml`).
