# Operação e Pipelines CI/CD — Smart Construction

## 1. Pipelines no GitHub Actions

Os workflows em `.github/workflows/` automatizam validação, build, deploy, testes de backup, controle de energia e destruição do ambiente:

- **`ci.yaml`:** executa lint, typecheck, testes unitários (frontend e backend com Ruff, mypy e pytest).
- **`pr-check.yml`:** valida `terraform fmt`, `terraform validate`, `ansible-playbook --syntax-check` (incluindo `playbook-storage.yml`) e checagens de Pull Request.
- **`deploy.yml`:**
  - Possui `concurrency` configurada (`cancel-in-progress` ativo apenas para `pull_request`), evitando conflitos de *state lock* na `main`.
  - Suporta execução manual via `workflow_dispatch` com parâmetros configuráveis: `environment`, `instance_type` (`e2-small`/`e2-medium`/`e2-micro`, repassado ao Terraform com `allow_stopping_for_update = true`), `docker_tag`, `update_os` (`apt upgrade`) e `extra_packages`.
  - Constrói e publica imagens no Artifact Registry (`build-web` com `NEXT_PUBLIC_ASSETS_BASE_URL=/assets`, `ASSETS_PROXY_URL=http://storage:8333/smart-assets` e `API_PROXY_URL=http://api:8000`).
  - Executa Terraform e playbooks Ansible em ordem: `playbook-db.yml`, `playbook-storage.yml` e `playbook-app.yml` (que gera o `docker-compose.override.yml` de produção).
  - Finaliza com o job **`5. Smoke Test HTTPS`** validando a resposta pública em `https://<IP_LB>.sslip.io` (ex.: `https://34.107.193.113.sslip.io`).
- **`backup-test.yml`:** executa testes isolados de backup e restauração via IAP SCP em containers temporários para:
  - **PostgreSQL** (`pg_dump` / `pg_restore` isolado).
  - **SeaweedFS** (`tar` com `--warning=no-file-changed` + container isolado `chrislusf/seaweedfs:4.48` + upload de artifact).
- **`power-schedule.yml`:** acionado manualmente via `workflow_dispatch` com parâmetro `action` (`stop` ou `start`) para desligar ou religar as 4 VMs (`app-1`, `app-2`, `storage`, `db`) e economizar custos fora do horário de uso.
- **`destroy.yml`:** destrói a infraestrutura provisionada pelo Terraform quando o laboratório for encerrado.

## 2. Bootstrap Inicial do Ambiente

Após o primeiro deploy, o administrador deve:

1. Garantir os segredos no **Google Secret Manager** (`smart-construction-db-password`, credenciais S3/SeaweedFS e chaves de sessão/CSRF).
2. Acessar uma VM de aplicação via **IAP SSH** (`gcloud compute ssh smart-construction-app-1 --tunnel-through-iap --zone=southamerica-east1-a`) e criar a conta administrativa manualmente via CLI com prompt oculto (o setup idempotente preserva credenciais existentes).
3. Carregar as **25 profissões** iniciais no banco via CLI de seed editorial.

## 3. Acesso, Logs e Troubleshooting

- **SSH seguro:** sempre via IAP (`--tunnel-through-iap`), sem exposição de porta 22 na internet.
- **Logs de containers:** `docker compose logs -f api web` nas VMs `app-1`/`app-2`, `docker compose logs -f seaweedfs` em `smart-construction-storage` e `docker compose logs -f db` em `smart-construction-db`.
- **Atualização:** merges na branch `main` disparam automaticamente o `deploy.yml`.
