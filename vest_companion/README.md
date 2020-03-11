# Vaptic: Companion

Talks to vaptic over bluetooth.

Protocol:
- Vaptic enters pairing mode via button (clears saved key)
- App sends shared key via BLE write
- Vaptic rejects or accepts key and link is established
- Vaptic returns device details via BLE read
- App writes vibration matrix via BLE
- Vaptic notifies on device info update