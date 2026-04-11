use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::time::Duration;

/// Network socket wrapper for TCP communication
pub struct NetworkSocket {
    stream: Option<TcpStream>,
    address: String,
    port: u16,
}

impl NetworkSocket {
    /// Create a new network socket
    pub fn new(address: String, port: u16) -> Result<Self, String> {
        Ok(NetworkSocket {
            stream: None,
            address,
            port,
        })
    }

    /// Connect to a remote address
    pub fn connect(&mut self) -> Result<(), String> {
        let addr = format!("{}:{}", self.address, self.port);
        let stream = TcpStream::connect(&addr)
            .map_err(|e| format!("Failed to connect: {}", e))?;

        stream
            .set_read_timeout(Some(Duration::from_secs(30)))
            .map_err(|e| format!("Failed to set read timeout: {}", e))?;

        stream
            .set_write_timeout(Some(Duration::from_secs(30)))
            .map_err(|e| format!("Failed to set write timeout: {}", e))?;

        self.stream = Some(stream);
        Ok(())
    }

    /// Send data through the socket
    pub fn send(&mut self, data: Vec<u8>) -> Result<(), String> {
        if let Some(ref mut stream) = self.stream {
            stream
                .write_all(&data)
                .map_err(|e| format!("Failed to send data: {}", e))?;
            Ok(())
        } else {
            Err("Socket not connected".to_string())
        }
    }

    /// Receive data from the socket
    pub fn receive(&mut self, buffer_size: usize) -> Result<Vec<u8>, String> {
        if let Some(ref mut stream) = self.stream {
            let mut buffer = vec![0u8; buffer_size];
            match stream.read(&mut buffer) {
                Ok(n) => {
                    buffer.truncate(n);
                    Ok(buffer)
                }
                Err(e) => Err(format!("Failed to receive data: {}", e)),
            }
        } else {
            Err("Socket not connected".to_string())
        }
    }

    /// Close the socket connection
    pub fn close(&mut self) -> Result<(), String> {
        self.stream = None;
        Ok(())
    }

    /// Check if socket is connected
    pub fn is_connected(&self) -> bool {
        self.stream.is_some()
    }
}

/// TCP Server for accepting connections
pub struct TcpServer {
    listener: Option<TcpListener>,
    port: u16,
}

impl TcpServer {
    /// Create a new TCP server
    pub fn new(port: u16) -> Result<Self, String> {
        let addr = format!("0.0.0.0:{}", port);
        let listener = TcpListener::bind(&addr)
            .map_err(|e| format!("Failed to bind to {}: {}", addr, e))?;

        Ok(TcpServer {
            listener: Some(listener),
            port,
        })
    }

    /// Accept a new connection
    pub fn accept(&self) -> Result<(TcpStream, String), String> {
        if let Some(ref listener) = self.listener {
            let (stream, addr) = listener
                .accept()
                .map_err(|e| format!("Failed to accept connection: {}", e))?;

            stream
                .set_read_timeout(Some(Duration::from_secs(30)))
                .map_err(|e| format!("Failed to set read timeout: {}", e))?;

            stream
                .set_write_timeout(Some(Duration::from_secs(30)))
                .map_err(|e| format!("Failed to set write timeout: {}", e))?;

            Ok((stream, addr.to_string()))
        } else {
            Err("Server not initialized".to_string())
        }
    }

    /// Close the server
    pub fn close(&mut self) -> Result<(), String> {
        self.listener = None;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_socket_creation() {
        let socket = NetworkSocket::new("127.0.0.1".to_string(), 8080);
        assert!(socket.is_ok());
    }

    #[test]
    fn test_server_creation() {
        let server = TcpServer::new(0); // Use port 0 for automatic assignment
        assert!(server.is_ok());
    }
}
