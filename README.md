# lab1
## Azure resources Connectivity to Internet (egress)
1. Firewall (FW) is used by Associating the route table (RT) to App Subnet to let the outbound traffic from the VM1 on to any address (e.g the internet), pass first to the FW before reaching the internet
2. NSG is needed to restrict the outbound traffic since Egress is allowed by default [e.g 10.40.0.10 0.0.0.0 * Deny]
```mermaid
graph TD
    VNET["Az-UkSth-Vnet<br/>10.40.0.0/16"]

    APP["App Subnet<br/>10.40.0.0/24"]
    SEC["Sec Subnet<br/>10.40.1.0/24"]

    NSG["App-NSG"]
    RT["App-RT <br/> 0.0.0.0->10.40.1.10"]
    
    NIC1["App-Srv-Nic0<br/>10.40.0.10"]
    VM1["App-Srv-Vm"]

    NIC2["Fw-Nic1<br/>10.40.1.10"]
    FW["Fw"]


    VNET --> APP
    VNET --> SEC

    NSG -. Associated .-> APP
    RT -. Associated .-> APP

    APP --> NIC1
    NIC1 --> VM1

    SEC --> NIC2
    NIC2 --> FW

    NET["Internet<br/>0.0.0.0/0"]
    VM1 --> FW
    FW --> NET
```
## Azure resources Connectivity from Internet (Ingress)
