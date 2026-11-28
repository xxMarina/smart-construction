# ADR 0004 — Deploy Parametrizável via `workflow_dispatch` e `docker-compose.override.yml`

## Contexto

O repositório original usa um `docker-compose.yml` voltado para execução local (com `build` local e containers `db`/`storage` locais). Além disso, a entrega exige pipeline com execução manual parametrizável (`workflow_dispatch`) capaz de alterar infraestrutura (Terraform) e sistema/pacotes (Ansible) sem edições manuais nos servidores.

## Decisão

- Manter o `docker-compose.yml` base intacto e gerar dinamicamente o `/opt/smart-construction/docker-compose.override.yml` via Ansible (`playbook-app.yml`), desativando `build` local (`!reset null`), apontando para as imagens do Artifact Registry e injetando os IPs privados de `db` e `storage`.
- Adicionar inputs no `workflow_dispatch` de `deploy.yml` (`environment`, `instance_type`, `docker_tag`, `update_os`, `extra_packages`) conectados ao `terraform plan` (`app_machine_type` com `allow_stopping_for_update = true`) e ao `playbook-app.yml`.

## Consequências

- **Positivas:** zero divergência no `docker-compose.yml` de desenvolvimento local; atualizações de capacidade (`e2-small` ↔ `e2-medium`), pacotes e SO operadas 100% pela pipeline com idempotência e proteção de `concurrency`.
- **Negativas:** alterações de `instance_type` reiniciam brevemente as VMs de aplicação durante o `terraform apply`.
