use std::net::{IpAddr, UdpSocket};
use std::time::Duration;

/// Device information for discovery
#[derive(Debug, Clone)]
pub struct DeviceInfo {
    pub id: String,
    pub name: String,
    pub ip_address: String,
    pub port: u16,
    pub device_type: String,
}

/// Discover devices on the local network
pub fn discover_devices(timeout_ms: u64) -> Result<Vec<DeviceInfo>, String> {
    let socket = UdpSocket::bind("0.0.0.0:0")
        .map_err(|e| format!("Failed to bind UDP socket: {}", e))?;

    socket
        .set_read_timeout(Some(Duration::from_millis(timeout_ms)))
        .map_err(|e| format!("Failed to set timeout: {}", e))?;

    socket
        .set_broadcast(true)
        .map_err(|e| format!("Failed to enable broadcast: {}", e))?;

    // Send discovery broadcast
    let discovery_message = b"FLUX_DISCOVERY_REQUEST";
    socket
        .send_to(discovery_message, "255.255.255.255:5353")
        .map_err(|e| format!("Failed to send broadcast: {}", e))?;

    let mut devices = Vec::new();
    let mut buffer = [0u8; 1024];

    loop {
        match socket.recv_from(&mut buffer) {
            Ok((size, addr)) => {
                if let Ok(message) = std::str::from_utf8(&buffer[..size]) {
                    if message.starts_with("FLUX_DISCOVERY_RESPONSE:") {
                        if let Some(device) = parse_device_info(message, addr.ip()) {
                            devices.push(device);
                        }
                    }
                }
            }
            Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                break; // Timeout reached
            }
            Err(e) => return Err(format!("Failed to receive: {}", e)),
        }
    }

    Ok(devices)
}

/// Broadcast device presence on the network
pub fn broadcast_presence(device_name: String, port: u16) -> Result<(), String> {
    let socket = UdpSocket::bind("0.0.0.0:5353")
        .map_err(|e| format!("Failed to bind UDP socket: {}", e))?;

    socket
        .set_broadcast(true)
        .map_err(|e| format!("Failed to enable broadcast: {}", e))?;

    let local_ip = get_local_ip()?;
    let response = format!(
        "FLUX_DISCOVERY_RESPONSE:{}|{}|{}",
        device_name, local_ip, port
    );

    socket
        .send_to(response.as_bytes(), "255.255.255.255:5353")
        .map_err(|e| format!("Failed to send response: {}", e))?;

    Ok(())
}

/// Get local IP address
fn get_local_ip() -> Result<String, String> {
    let socket = UdpSocket::bind("0.0.0.0:0")
        .map_err(|e| format!("Failed to bind socket: {}", e))?;

    socket
        .connect("8.8.8.8:80")
        .map_err(|e| format!("Failed to connect: {}", e))?;

    socket
        .local_addr()
        .map(|addr| addr.ip().to_string())
        .map_err(|e| format!("Failed to get local address: {}", e))
}

/// Parse device information from discovery response
fn parse_device_info(message: &str, ip: IpAddr) -> Option<DeviceInfo> {
    let parts: Vec<&str> = message.split(':').collect();
    if parts.len() < 2 {
        return None;
    }

    let info_parts: Vec<&str> = parts[1].split('|').collect();
    if info_parts.len() < 3 {
        return None;
    }

    Some(DeviceInfo {
        id: format!("{}", ip),
        name: info_parts[0].to_string(),
        ip_address: info_parts[1].to_string(),
        port: info_parts[2].parse().unwrap_or(5353),
        device_type: "unknown".to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_device_info() {
        let message = "FLUX_DISCOVERY_RESPONSE:TestDevice|192.168.1.100|5353";
        let ip = "192.168.1.100".parse().unwrap();
        let device = parse_device_info(message, ip);
        assert!(device.is_some());
        let device = device.unwrap();
        assert_eq!(device.name, "TestDevice");
        assert_eq!(device.port, 5353);
    }
}
