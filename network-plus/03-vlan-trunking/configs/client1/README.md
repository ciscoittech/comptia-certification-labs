# Client 1 Configuration

## Role
Engineering department workstation

## Network Details
- VLAN: 10 (Engineering)
- IP Address: 10.10.10.10/24
- Default Gateway: 10.10.10.1 (sw1)
- Connected to: sw2 eth2 (access port)

## Testing Capabilities
- Ping other VLAN 10 devices (client3)
- Cannot ping VLAN 20 devices directly (VLAN isolation)
- Can ping VLAN 20 through inter-VLAN routing on sw1
