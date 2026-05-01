// This module is intentionally excluded from flutter_rust_bridge code generation.
// It provides internal Rust networking primitives used by other Rust modules.
#![allow(dead_code)]

use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::time::Duration;
use std::thread;

/// Network configuration constants
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);
const MAX_RETRY_ATTEMPTS: u32 = 3;
const INITIAL_RETRY_DELAY_MS: u64 = 100;
const MAX_RETRY_DELAY_MS: u64 = 5000;

/// Network socket wrapper for TCP communication with retry mechanisms
#[flutter_rust_bridge::frb(ignore)]
pub struct NetworkSocket {
    stream: Option<TcpStream>,
    address: String,
    port: u16,
    retry_config: RetryConfig,
}

/// Retry configuration
#[derive(Debug, Clone)]
#[flutter_rust_bridge::frb(ignore)]
pub struct RetryConfig {
    pub max_attempts: u32,
    pub initial_delay_ms: u64,
    pub max_delay_ms: u64,
    pub backoff_multiplier: f64,
}

impl Default for RetryConfig {
    fn default() -> Self {
        Self {
            max_attempts: MAX_RETRY_ATTEMPTS,
            initial_delay_ms: INITIAL_RETRY_DELAY_MS,
            max_delay_ms: MAX_RETRY_DELAY_MS,
            backoff_multiplier: 2.0,
        }
    }
}

impl NetworkSocket {
    /// Create a new network socket with default retry configuration
    pub fn new(address: String, port: u16) -> Result<Self, String> {
        Ok(NetworkSocket {
            stream: None,
            address,
            port,
            retry_config: RetryConfig::default(),
        })
    }

    /// Create a new network socket with custom retry configuration
    pub fn with_retry_config(address: String, port: u16, retry_config: RetryConfig) -> Result<Self, String> {
        Ok(NetworkSocket {
            stream: None,
            address,
            port,
            retry_config,
        })
    }

    /// Connect to a remote address with retry mechanism
    pub fn connect(&mut self) -> Result<(), String> {
        let addr = format!("{}:{}", self.address, self.port);
        
        self.retry_operation(
            || {
                let stream = TcpStream::connect(&addr)
                    .map_err(|e| format!("Failed to connect: {}", e))?;

                stream
                    .set_read_timeout(Some(DEFAULT_TIMEOUT))
                    .map_err(|e| format!("Failed to set read timeout: {}", e))?;

                stream
                    .set_write_timeout(Some(DEFAULT_TIMEOUT))
                    .map_err(|e| format!("Failed to set write timeout: {}", e))?;

                Ok(stream)
            },
            "connection"
        ).map(|stream| {
            self.stream = Some(stream);
        })
    }

    /// Send data through the socket with retry mechanism
    pub fn send(&mut self, data: Vec<u8>) -> Result<(), String> {
        let stream = self.stream.as_mut()
            .ok_or_else(|| "Socket not connected".to_string())?;

        let retry_config = self.retry_config.clone();
        let mut attempt = 0;
        let mut delay_ms = retry_config.initial_delay_ms;

        loop {
            match stream.write_all(&data) {
                Ok(()) => return Ok(()),
                Err(error) => {
                    attempt += 1;
                    
                    if attempt >= retry_config.max_attempts {
                        return Err(format!(
                            "send failed after {} attempts: {}",
                            attempt, error
                        ));
                    }

                    eprintln!("[WARNING] send attempt {} failed: {}. Retrying in {}ms...",
                        attempt, error, delay_ms);

                    std::thread::sleep(std::time::Duration::from_millis(delay_ms));

                    // Exponential backoff with jitter
                    delay_ms = ((delay_ms as f64 * retry_config.backoff_multiplier) as u64)
                        .min(retry_config.max_delay_ms);
                    
                    // Add jitter to prevent thundering herd
                    let jitter = (delay_ms as f64 * 0.1 * (rand::random::<f64>() - 0.5)) as i64;
                    delay_ms = ((delay_ms as i64 + jitter) as u64).max(retry_config.initial_delay_ms);
                }
            }
        }
    }

    /// Send data through the socket with custom retry configuration
    pub fn send_with_retry(&mut self, data: Vec<u8>, retry_config: RetryConfig) -> Result<(), String> {
        let original_config = self.retry_config.clone();
        self.retry_config = retry_config;
        let result = self.send(data);
        self.retry_config = original_config;
        result
    }

    /// Receive data from the socket with retry mechanism
    pub fn receive(&mut self, buffer_size: usize) -> Result<Vec<u8>, String> {
        let stream = self.stream.as_mut()
            .ok_or_else(|| "Socket not connected".to_string())?;

        let retry_config = self.retry_config.clone();
        let mut attempt = 0;
        let mut delay_ms = retry_config.initial_delay_ms;

        loop {
            let mut buffer = vec![0u8; buffer_size];
            match stream.read(&mut buffer) {
                Ok(n) => {
                    buffer.truncate(n);
                    return Ok(buffer);
                }
                Err(error) => {
                    attempt += 1;
                    
                    if attempt >= retry_config.max_attempts {
                        return Err(format!(
                            "receive failed after {} attempts: {}",
                            attempt, error
                        ));
                    }

                    eprintln!("[WARNING] receive attempt {} failed: {}. Retrying in {}ms...",
                        attempt, error, delay_ms);

                    std::thread::sleep(std::time::Duration::from_millis(delay_ms));

                    // Exponential backoff with jitter
                    delay_ms = ((delay_ms as f64 * retry_config.backoff_multiplier) as u64)
                        .min(retry_config.max_delay_ms);
                    
                    // Add jitter to prevent thundering herd
                    let jitter = (delay_ms as f64 * 0.1 * (rand::random::<f64>() - 0.5)) as i64;
                    delay_ms = ((delay_ms as i64 + jitter) as u64).max(retry_config.initial_delay_ms);
                }
            }
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

    /// Generic retry mechanism with exponential backoff
    fn retry_operation<T, F>(&self, mut operation: F, operation_name: &str) -> Result<T, String>
    where
        F: FnMut() -> Result<T, String>,
    {
        let mut attempt = 0;
        let mut delay_ms = self.retry_config.initial_delay_ms;

        loop {
            match operation() {
                Ok(result) => return Ok(result),
                Err(error) => {
                    attempt += 1;
                    
                    if attempt >= self.retry_config.max_attempts {
                        return Err(format!(
                            "{} failed after {} attempts: {}",
                            operation_name, attempt, error
                        ));
                    }

                    eprintln!("[WARNING] {} attempt {} failed: {}. Retrying in {}ms...",
                        operation_name, attempt, error, delay_ms);

                    thread::sleep(Duration::from_millis(delay_ms));

                    // Exponential backoff with jitter
                    delay_ms = ((delay_ms as f64 * self.retry_config.backoff_multiplier) as u64)
                        .min(self.retry_config.max_delay_ms);
                    
                    // Add jitter to prevent thundering herd
                    let jitter = (delay_ms as f64 * 0.1 * (rand::random::<f64>() - 0.5)) as i64;
                    delay_ms = ((delay_ms as i64 + jitter) as u64).max(self.retry_config.initial_delay_ms);
                }
            }
        }
    }
}

/// TCP Server for accepting connections with retry mechanisms
#[flutter_rust_bridge::frb(ignore)]
pub struct TcpServer {
    listener: Option<TcpListener>,
    port: u16,
    retry_config: RetryConfig,
}

impl TcpServer {
    /// Create a new TCP server with default retry configuration
    pub fn new(port: u16) -> Result<Self, String> {
        let addr = format!("0.0.0.0:{}", port);
        let listener = TcpListener::bind(&addr)
            .map_err(|e| format!("Failed to bind to {}: {}", addr, e))?;

        Ok(TcpServer {
            listener: Some(listener),
            port,
            retry_config: RetryConfig::default(),
        })
    }

    /// Accept a new connection with timeout and error handling
    pub fn accept(&self) -> Result<(TcpStream, String), String> {
        if let Some(ref listener) = self.listener {
            // Set non-blocking mode for accept with timeout
            listener
                .set_nonblocking(false)
                .map_err(|e| format!("Failed to set blocking mode: {}", e))?;

            let (stream, addr) = listener
                .accept()
                .map_err(|e| format!("Failed to accept connection: {}", e))?;

            stream
                .set_read_timeout(Some(DEFAULT_TIMEOUT))
                .map_err(|e| format!("Failed to set read timeout: {}", e))?;

            stream
                .set_write_timeout(Some(DEFAULT_TIMEOUT))
                .map_err(|e| format!("Failed to set write timeout: {}", e))?;

            Ok((stream, addr.to_string()))
        } else {
            Err("Server not initialized".to_string())
        }
    }

    /// Accept a new connection with retry mechanism
    pub fn accept_with_retry(&self) -> Result<(TcpStream, String), String> {
        let retry_config = RetryConfig {
            max_attempts: 5, // More attempts for server accept
            initial_delay_ms: 50,
            max_delay_ms: 1000,
            backoff_multiplier: 1.5,
        };

        let mut attempt = 0;
        let mut delay_ms = retry_config.initial_delay_ms;

        loop {
            match self.accept() {
                Ok(result) => return Ok(result),
                Err(error) => {
                    attempt += 1;
                    
                    if attempt >= retry_config.max_attempts {
                        return Err(format!(
                            "Accept failed after {} attempts: {}",
                            attempt, error
                        ));
                    }

                    eprintln!("[WARNING] Accept attempt {} failed: {}. Retrying in {}ms...",
                        attempt, error, delay_ms);

                    thread::sleep(Duration::from_millis(delay_ms));
                    
                    // Exponential backoff
                    delay_ms = ((delay_ms as f64 * retry_config.backoff_multiplier) as u64)
                        .min(retry_config.max_delay_ms);
                }
            }
        }
    }

    /// Close the server
    pub fn close(&mut self) -> Result<(), String> {
        self.listener = None;
        Ok(())
    }

    /// Get the port the server is listening on
    pub fn port(&self) -> u16 {
        self.port
    }
}

/// Network utilities
pub struct NetworkUtils {}

impl NetworkUtils {
    /// Check if a port is available
    pub fn is_port_available(port: u16) -> bool {
        std::net::TcpListener::bind(format!("0.0.0.0:{}", port)).is_ok()
    }

    /// Find an available port starting from the given port
    pub fn find_available_port(start_port: u16) -> Option<u16> {
        for port in start_port..=65535 {
            if Self::is_port_available(port) {
                return Some(port);
            }
        }
        None
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

    #[test]
    fn test_retry_config_default() {
        let config = RetryConfig::default();
        assert_eq!(config.max_attempts, 3);
        assert_eq!(config.initial_delay_ms, 100);
        assert_eq!(config.max_delay_ms, 5000);
        assert_eq!(config.backoff_multiplier, 2.0);
    }

    #[test]
    fn test_network_utils() {
        assert!(NetworkUtils::is_port_available(0)); // Port 0 should always be available
        
        if let Some(port) = NetworkUtils::find_available_port(30000) {
            assert!(NetworkUtils::is_port_available(port));
        }
    }

    #[test]
    fn test_retry_mechanism() {
        let socket = NetworkSocket::new("invalid.address".to_string(), 99999).unwrap();
        
        // This should fail after retries
        let result = socket.connect();
        assert!(result.is_err());
        
        // Verify error message contains retry information
        let error = result.unwrap_err();
        assert!(error.contains("failed after 3 attempts"));
    }
}