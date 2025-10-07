# Switch 2 (Access Switch) Configuration

## Role
- Access layer switch
- Trunk port to sw1
- Access ports for client1 and client2
- No inter-VLAN routing (Layer 2 only)

## VLANs Configured
- VLAN 10 (Engineering)
- VLAN 20 (Sales)

## Interfaces
- eth1: Trunk to sw1 (carries VLAN 10, 20)
- eth1.10: VLAN 10 subinterface
- eth1.20: VLAN 20 subinterface
- eth2: Access port VLAN 10 (client1)
- eth3: Access port VLAN 20 (client2)

## Key Concepts
- **Access Switch**: Provides end-user connectivity
- **VLAN Segmentation**: Isolates traffic between departments
- **Trunk Uplink**: Connects to core switch for inter-VLAN routing
