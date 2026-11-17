**04. Estudo de Custos e Governança FinOps (GCP)**  
**Premissas da Estimativa**  
Os valores abaixo refletem o dimensionamento exato provisionado no projeto projeto-mensal-4 na região **southamerica-east1** ** (São Paulo)**, cotados via  **Google Cloud Pricing Calculator** em  **16/11/2026** (moeda:  **BRL**).  
- **Link da Simulação Oficial:**https://cloud.google.com/products/calculator/estimate-preview/CiQwY2VhNDk2Ny0zMzU1LTQzNzctYTYzOC0wNjg2NGNlODM2MWEQAQ%3D%3D  
- **Região Alvo:**southamerica-east1 (São Paulo, Brasil)  
- **Cenário 24/7:** Operação ininterrupta (2.190 horas/mês somadas nas 3 instâncias, equivalente a 730h/mês por VM).  
- **Cenário Otimizado (Sob Demanda):** Operação em janela comercial/homologação (~528 horas/mês somadas via automação power-schedule.yml, mantendo discos persistentes e Load Balancer ativos).  
**Detalhamento de Recursos e Custos Estimados (BRL)**  
| | | | | |  
|-|-|-|-|-|  
| **Serviço GCP** | **Especificação Provisionada** | **Quantidade** | **Custo Mensal (24/7)** | **Custo Otimizado (Sob Demanda)** |   
| **Compute Engine (Computação)** | e2-small (0.5 vCPU, 2 GB RAM) — 3 VMs (app-1, app-2, db) | 3 VMs | R$ 355,36 | R$ 85,68 |   
| **Compute Engine (Armazenamento)** | Boot Disk pd-balanced (10 GiB por instância = 30 GiB total) | 3 Discos | R$ 27,46 | R$ 27,46 |   
| **Cloud Load Balancing** | External/Regional HTTP(S) Load Balancer (1 Forwarding Rule + IP atrelado) | 1 LB | R$ 169,26 | R$ 169,26 |   
| **Artifact Registry** | Repositório smart-construction (~2 GiB de imagens Docker) | 2 GiB | R$ 0,92 | R$ 0,92 |   
| **Cloud Storage** | Bucket smart-construction-tfstate-projeto-mensal-4 (Standard) | 1 GiB | R$ 0,21 | R$ 0,21 |   
| **Secret Manager** | 5 versões ativas de segredos + 1.000 operações de acesso/mês | 5 segredos | R$ 0,00*(Free Tier)* | R$ 0,00*(Free Tier)* |   
| **TOTAL ESTIMADO MENSAL** | — | — | **R$ 553,21 / mês** | **R$ 283,53 / mês** |   
| **PROJEÇÃO ANUAL (x12)** | — | — | **R$ 6.638,48 / ano** | **R$ 3.402,36 / ano** |   
   
**Estratégias de Otimização FinOps Implementadas na Arquitetura**  
1. **Automação de Desligamento Programado (** **power-schedule.yml** **):**  
- Instâncias Compute Engine desligadas (TERMINATED) zeram a cobrança de vCPU e memória — apenas o armazenamento dos discos persistentes (30 GiB = R$ 27,46/mês) permanece ativo.  
- Ao operar o ambiente sob demanda (~8h/dia em dias úteis), a economia mensal chega a **R$ 269,68/mês** ( **~48,7% de redução na fatura total** e  **~75,9% na computação**), preservando o IP estático e o certificado SSL gerenciado ativo.  
2. **Prevenção de Cobrança por IP Ocioso:**  
- O endereço IP externo estático permanece vinculado diretamente à *Forwarding Rule* do Load Balancer, evitando a tarifa extra de IP reservado sem uso (~R$ 66,72/mês economizados).  
3. **Infraestrutura Efêmera via IaC (** **destroy.yml** ** + ** **deploy.yml** **):**  
- Em períodos sem operação, o workflow destroy.yml remove instâncias e Load Balancer, mantendo apenas o estado remoto do Terraform e as imagens no Artifact Registry (**R$ 1,13/mês**).  
4. **Aproveitamento do Free Tier Gerenciado (Secret Manager):**  
- Com 5 segredos ativos e ~1.000 leituras mensais durante os deploys automatizados, o gerenciamento de credenciais opera com custo zero (R$ 0,00/mês).  
