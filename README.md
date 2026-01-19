# Setup Guide - Zetta Online Project

## Local Development Setup

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd zetta-online-project
```

### Step 2: Understand the Docker Compose Configuration

The project includes a `compose.yaml` file that orchestrates all services:

```yaml
services:
  db             # PostgreSQL database
  inventory      # Inventory microservice (Java)
  order          # Order microservice (Java)
  frontend       # React frontend (nginx)
  nginx          # To route traffic between the services
```

### Step 3: Start All Services

```bash
docker compose up -d
```

**What This Does:**
1. Creates a Docker network for service communication
2. Starts PostgreSQL database on port 5432
3. Initializes databases with schema from `apps/local-setup/init-local-db.sql`
4. Builds and starts Inventory Service on port 8081
5. Builds and starts Order Service on port 8082
6. Builds React frontend and starts nginx on port 3000

**Expected Output:**
```
[+] up 8/8
✔ Image zetta-online-project-order-service     Built        1.6s 
✔ Image zetta-online-project-frontend          Built        1.6s 
✔ Image zetta-online-project-inventory-service Built        1.6s 
✔ Container shop-postgres                      Healthy     11.1s 
✔ Container inventory-service                  Created      0.1s 
✔ Container order-service                      Created      0.1s 
✔ Container shop-frontend                      Created      0.1s 
✔ Container shop-nginx                         Created      0.1s
```

### Step 4: Check Service Status

```bash
docker compose ps
```

**Expected Output:**
```
NAME                IMAGE                                    COMMAND                  SERVICE             CREATED              STATUS                        PORTS
inventory-service   zetta-online-project-inventory-service   "sh -c 'java -jar ap…"   inventory-service   About a minute ago   Up About a minute             0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp
order-service       zetta-online-project-order-service       "sh -c 'java -jar ap…"   order-service       About a minute ago   Up About a minute             0.0.0.0:8082->8080/tcp, [::]:8082->8080/tcp
shop-frontend       zetta-online-project-frontend            "/docker-entrypoint.…"   frontend            About a minute ago   Up About a minute             80/tcp, 8080/tcp
shop-nginx          nginx:alpine                             "/docker-entrypoint.…"   nginx               About a minute ago   Up About a minute             0.0.0.0:3000->80/tcp, [::]:3000->80/tcp
shop-postgres       postgres:15-alpine                       "docker-entrypoint.s…"   postgres            About a minute ago   Up About a minute (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp

```

### Step 5: View Logs

**All Services:**
```bash
docker compose logs -f
```

**Specific Service:**
```bash
docker compose logs -f inventory
docker compose logs -f order
docker compose logs -f frontend
```

### Step 6: Access the Application

Open your browser and navigate to:

**Frontend:** http://localhost:3000

You should see:
- A header with "Browse our products and place your orders"
- Lorem Ipsum placeholder text
- A list of products with images
- "Buy" buttons for each product

### Step 7: Test API Endpoints

**Inventory Service (Direct):**
```bash
# List all products
curl http://localhost:8081/api/products

# Get specific product
curl http://localhost:8081/api/products/1
```

**Order Service (Direct):**
```bash
# Create an order
curl -X POST http://localhost:8082/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 1,
    "customerName": "Test User",
    "customerEmail": "test@example.com"
  }'

# List all orders
curl http://localhost:8082/api/orders
```

**Via Frontend Proxy (how the UI calls them):**
```bash
# Through nginx routing
curl http://localhost:3000/api/products
curl http://localhost:3000/api/orders
```

---

## Stopping and Cleaning Up

### Stop Services (Keep Data)
```bash
docker compose stop
```

### Stop and Remove Containers
```bash
docker compose down
```

### Remove Everything (Including Volumes)
```bash
docker compose down -v
```

---

## Cloud Deployment (GCP)

Make sure you have:

1. **GCP Account** with billing enabled
2. **GCP Project** created

### Step 1: Configure GCP CLI

```bash
# Authenticate
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Step 2: Enable Required APIs

```bash
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### Step 3: Configure Terraform Variables

Changes the values in `terraform/terraform.tfvars` to mach your setup so far

### Step 4: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 5: Review Infrastructure Plan

```bash
terraform plan
```

Review the resources that will be created

### Step 6: Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This can take a while.

### Step 7: Configure kubectl

```bash
gcloud container clusters get-credentials ha-gke \
  --region europe-west3 \
  --project YOUR_PROJECT_ID
```

**Verify:**
```bash
kubectl get nodes
```
### Step 8: Install and Configure argocd

1. Install argocd
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
2. Get the admin passworkd
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
3. Make it accessible on localhost
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
4. Open https://localhost:8080 and login as 'admin' with the password from step 2
5. Apply the applicationset
```bash
kubectl apply -f /k8s/apps/applicationset.yaml
```

### Step 9: Configure the ci/cd pipeline

#### How it works:
1. The pipeline checks for changes the paths of each app 
```
'apps/frontend/**'
'apps/inventory-service/**'
'apps/order-service/**'
```
2. The pipeline builds and pushes the images to the cr
3. Finally it changes the manifests of each app to the latest version

#### Add the secrets to GitHub

From the terraform output look for these lines:

```bash
github_service_account_email = "actualvalue"
github_workload_identity_provider = "actualvalue"
```

Then go to your repository, settings, secrets and variables, actions, new repository secret. 
Name the secret `GCP_SERVICE_ACCOUNT` and add the value of `github_service_account_email`
Repeat with `GCP_WORKLOAD_IDENTITY_PROVIDER` and `github_workload_identity_provider`

You will have a pipeline that builds the images and pushes them to the container registry and updates the manifest to the latest version

### Step 10: Create Kubernetes Secrets

```bash
# Install kubeseal
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

```
Steps to seal a secret:
1. Create an ordinary secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: name
  namespace: namespace
type: Opaque
data:
  key: <base64 encoded value>
```

2. Seal it using kubeseal into a new file:
```bash
# Make sure you dont push the normal secret to the repo
kubeseal -f secret.yaml -w sealed-secret.yaml
```

3. Argocd will apply it once the code reaches github or you can apply it manually like so
```bash
kubectl apply -f sealed-secret.yaml
```

### Step 14: Configure Domain (Optional)
#### Using cloudflare
1. Edit terraform/cert_manager.tf to suit your domain

2. From terraform output get store_dns_auth_cname should look like this
```bash
store_dns_auth_cname = tolist([
  {
    "data" = "longstring"
    "name" = "_acme-challenge.your.desired.domain.name"
    "type" = "CNAME"
  },
])
```
3. Add a CNAME record in your DNS provider with the respective values

4. Add an A record in your DNS provider:
   ```
   NAME                  CONTENT
   app.yourdomain.com    <Ingres-ip>
   ```

5. Update Ingress with your domain:
   ```yaml
   spec:
     rules:
     - host: app.yourdomain.com
       http:
         ...
   ```

---