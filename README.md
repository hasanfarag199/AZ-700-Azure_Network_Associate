# lab1
## Azure resources Connectivity to Internet (egress)
1. RT is Associated to App Subnet for directing the outbound traffic from the VM1 first to the FW before reaching any address (e.g the internet).
2. NSG is Associated to App Subnet for restricting the outbound traffic from the VM1 since Egress is allowed by default [e.g 10.40.0.10 0.0.0.0 * Deny]
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
