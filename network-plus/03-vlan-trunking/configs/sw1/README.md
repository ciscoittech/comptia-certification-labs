# Switch 1 (Core Switch) Configuration

## Role
- Core switch with inter-VLAN routing capability
- Trunk port to sw2
- Access ports for client3 and client4
- Default gateway for all VLANs

## VLANs Configured
- VLAN 10 (Engineering): 10.10.10.0/24
- VLAN 20 (Sales): 10.10.20.0/24
- VLAN 30 (Management): 10.10.30.0/24

## Interfaces
- eth1: Trunk to sw2 (carries VLAN 10, 20, 30)
- eth1.10: VLAN 10 SVI (10.10.10.1/24)
- eth1.20: VLAN 20 SVI (10.10.20.1/24)
- eth1.30: VLAN 30 SVI (10.10.30.1/24)
- eth2: Access port VLAN 10 (client3)
- eth3: Access port VLAN 20 (client4)

## Key Concepts
- **Trunk Port**: Carries multiple VLANs using 802.1Q tagging
- **SVI (Switch Virtual Interface)**: Layer 3 interface for inter-VLAN routing
- **Access Port**: Untagged port assigned to single VLAN
