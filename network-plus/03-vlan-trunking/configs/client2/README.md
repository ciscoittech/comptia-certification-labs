# Client 2 Configuration

## Role
Sales department workstation

## Network Details
- VLAN: 20 (Sales)
- IP Address: 10.10.20.10/24
- Default Gateway: 10.10.20.1 (sw1)
- Connected to: sw2 eth3 (access port)

## Testing Capabilities
- Ping other VLAN 20 devices (client4)
- Cannot ping VLAN 10 devices directly (VLAN isolation)
- Can ping VLAN 10 through inter-VLAN routing on sw1
