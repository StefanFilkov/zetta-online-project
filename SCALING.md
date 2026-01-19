## Infrastructure & Capacity

**Network Layer (Connectivity & Performance):**
- **Ingress Strategy:** Google Cloud Global HTTPS Load Balancer.
  - *Mechanism:* Anycast IP routes traffic to the nearest Google Edge, then over the private fiber backbone.
  - *Scaling:* Offloads SSL/TLS termination at the edge, saving CPU cycles on application pods.
- **Cluster Networking:** VPC-Native (Alias IPs).
  - *Performance:* Pods communicate directly via the VPC network without route hops or SNAT, improving throughput.
  - *Capacity:* Secondary CIDR ranges (`10.20.0.0/16`) allow for up to ~65,000 pods, preventing IP exhaustion during scale-up.
- **Egress:** Cloud NAT configured for the `ha-subnet`.
  - *Function:* Allows private nodes to access external APIs (like Docker Hub) without exposing public IPs.
- **Database Connectivity:** Private Service Access (VPC Peering).
  - *Security:* Traffic between GKE and Cloud SQL stays entirely within Google's private network (no public internet exposure).

**Compute Layer (Horizontal Scaling):**
- **Frontend:** 3-10 replicas (100m CPU / 128Mi RAM requests)
- **Order Service:** 3-10 replicas (100m CPU / 384Mi RAM requests)
- **Inventory Service:** 3-10 replicas (100m CPU / 384Mi RAM requests)

**Physical Layer (GKE Regional):**
- **Topology:** Regional Cluster (europe-west3) spread across 3 zones for High Availability.
- **Node Capacity:** Autoscaling set to 1-3 nodes per zone.
  - *Total Min:* 3 Nodes (1 per zone)
  - *Total Max:* 9 Nodes (3 per zone)
  - *Instance Type:* e2-standard-2 (2 vCPU, 8GB RAM each)

**Data Layer (Vertical Scaling):**
- **Cloud SQL:** PostgreSQL 15 (Regional HA)
- **Tier:** db-custom-2-8192 (2 vCPU, 8GB RAM)
- *Note:* Database scales vertically (tier upgrade) rather than horizontally.

## Bottleneck Assumptions & Triggers

- **CPU-Bound:** Scaling triggers at 70% average utilization.
- **Memory-Bound:** Scaling triggers at 80% average utilization.
- **Memory Profile:** Backend services are memory-intensive (~3x frontend requirement).

## Autoscaling Mechanism

**HPA Configuration (Applied to all services):**
```yaml
minReplicas: 3
maxReplicas: 10
metrics:
  - cpu: 70% target
  - memory: 80% target
behavior:
  scaleUp: Aggressive (100% or 2 pods per 30s) to handle traffic spikes immediately.
  scaleDown: Conservative (Max 1 pod per 60s) with 5-minute stabilization to prevent thrashing.
```
## Global Delivery Strategy
**Current Architecture:**
    Anycast IP: Traffic enters via a Google Cloud Global Load Balancer (Premium Tier).
    Edge Routing: Users connect to the nearest Google Edge Point of Presence (PoP) globally.
    Traffic Flow: Traffic rides Google's private fiber backbone to the europe-west3 region.
**Zero-Downtime Reliability:**
    ReadinessProbes: Traffic is not sent to pods until they pass health checks (configured in deployment.yaml).
    Rolling Updates: Deployments replace pods gradually to ensure service continuity.
    PDB (Implicit): Regional distribution ensures service survives single-zone failures.
## Observability & Guardrails
**Visibility:**
    Metrics: Managed Prometheus enabled for HPA custom metrics.
    Logging: Cloud Logging enabled for System and Workload components.
    Database: Query Insights enabled to detect slow queries and lock contention.
**Cost Safety:**
    Pod Limit: Hard cap of 10 replicas prevents runaway billing during DDoS or infinite loops.
    Infrastructure Cap: Node autoscaling is capped at 9 nodes total (approx. $225/mo max compute cost).
    **Data Safety:**
        Automated Daily Backups (7-day retention).
        Point-in-Time Recovery (PITR) enabled for second-level restoration granularity.