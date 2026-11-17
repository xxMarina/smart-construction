# Smart Construction — Infraestrutura Cloud, IaC & CI/CD (GCP)

Solução completa de automação de infraestrutura, segurança Zero-Trust e entrega contínua para a plataforma **Smart Construction** na **Google Cloud Platform (GCP)**, projetada com **Terraform**, **Ansible** e **GitHub Actions**.

---

## Visão Executiva e Proposta de Valor

* **Alta Disponibilidade na Camada de Aplicação:** Tráfego distribuído por um **Cloud Load Balancer** com IP estático e SSL gerenciado entre duas instâncias redundantes (`smart-construction-app-1` e `smart-construction-app-2`), eliminando ponto único de falha.
* **Isolamento de Dados e Rede Privada:** Camada de persistência (`smart-construction-db`) isolada de acessos externos, aceitando conexões exclusivamente da sub-rede interna da aplicação.
* **Segurança Zero-Trust (Sem Chaves Estáticas):** Autenticação federada via **Workload Identity Federation (OIDC)** entre GitHub Actions e GCP, segredos centralizados no **GCP Secret Manager** e acesso administrativo exclusivo via **Identity-Aware Proxy (IAP)** (zero portas SSH expostas à internet).
* **Governança FinOps e Operação Efêmera:** Pipelines automatizadas para pausar/retomar instâncias (`power-schedule.yml`) e destruir/recriar todo o ambiente sob demanda (`destroy.yml` / `deploy.yml`), reduzindo custos operacionais em até **48,7%**.

---

## Arquitetura da Solução

```mermaid
flowchart TB
    Dev([Engenharia / Git Push]) -->|OIDC Token Efêmero| GHA[GitHub Actions CI/CD]
    GHA -->|Push Imagens| AR[(Artifact Registry<br/>southamerica-east1)]
    GHA -->|Terraform State| GCS[(Cloud Storage<br/>tfstate)]
    GHA -->|Ansible via Túnel IAP| VPC

    Client([Usuários HTTPS]) --> LB[Cloud Load Balancer<br/>IP Estático + SSL]

    subgraph VPC [Google Cloud VPC - southamerica-east1]
        App1[smart-construction-app-1<br/>Next.js + FastAPI]
        App2[smart-construction-app-2<br/>Next.js + FastAPI]
        DB[(smart-construction-db<br/>Banco de Dados Isolado)]
    end

    LB --> App1
    LB --> App2
    App1 -->|Rede Interna| DB
    App2 -->|Rede Interna| DB

    AR -.->|Docker Pull| App1
    AR -.->|Docker Pull| App2
    SM[(GCP Secret Manager)] -.->|Runtime Secrets| App1
    SM -.->|Runtime Secrets| App2
    SM -.->|Runtime Secrets| DB