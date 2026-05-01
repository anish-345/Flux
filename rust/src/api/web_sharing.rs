use flutter_rust_bridge::frb;
use std::fs;
use std::path::Path;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;

// ─────────────────────────────────────────────────────────────────────────────
// Public types bridged to Dart
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for the embedded web-share server.
#[frb]
pub struct WebShareConfig {
    /// Port to listen on. Pass 0 to auto-select an available port.
    pub port: u16,
    /// Directory whose files will be listed and served for download.
    pub share_path: String,
}

/// Result returned after the server starts successfully.
#[frb]
pub struct WebShareResult {
    /// The URL clients should open in a browser (e.g. `http://192.168.1.5:8080`).
    pub url: String,
    /// The actual port the server is listening on (useful when port 0 was requested).
    pub port: u16,
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Start an embedded HTTP server that lists and serves files for download.
///
/// The server runs in a background Tokio task and keeps running until the
/// process exits or [stop_web_sharing] is called with the returned port.
/// Returns the URL and port on success.
#[frb]
pub async fn start_web_sharing(config: WebShareConfig) -> Result<WebShareResult, String> {
    let port = if config.port == 0 {
        find_available_port(8080).ok_or_else(|| "No available ports found".to_string())?
    } else {
        config.port
    };

    let addr = format!("0.0.0.0:{}", port);
    let listener = TcpListener::bind(&addr)
        .await
        .map_err(|e| format!("Failed to bind web server to {}: {}", addr, e))?;

    let actual_port = listener
        .local_addr()
        .map(|a| a.port())
        .unwrap_or(port);

    let local_ip = get_local_ip()?;
    let url = format!("http://{}:{}", local_ip, actual_port);

    let share_path = config.share_path.clone();

    // Spawn the accept loop as a background task.
    tokio::spawn(async move {
        while let Ok((mut socket, _)) = listener.accept().await {
            let path = share_path.clone();
            tokio::spawn(async move {
                handle_connection(&mut socket, &path).await;
            });
        }
    });

    Ok(WebShareResult {
        url,
        port: actual_port,
    })
}

/// List the files available in a directory (used by the web UI and Dart UI).
#[frb]
pub fn list_shared_files(share_path: String) -> Result<Vec<String>, String> {
    let entries = fs::read_dir(&share_path)
        .map_err(|e| format!("Failed to read directory '{}': {}", share_path, e))?;

    let mut names = Vec::new();
    for entry in entries.flatten() {
        if let Ok(name) = entry.file_name().into_string() {
            if entry.path().is_file() {
                names.push(name);
            }
        }
    }

    names.sort();
    Ok(names)
}

/// Get the device's local IP address (the one reachable on the LAN).
#[frb]
pub fn get_local_ip_address() -> Result<String, String> {
    get_local_ip()
}

/// Check whether a TCP port is free on this device.
#[frb]
pub fn is_port_available(port: u16) -> bool {
    std::net::TcpListener::bind(format!("0.0.0.0:{}", port)).is_ok()
}

/// Find the first available port starting from `start_port`.
/// Returns `None` if no port is free in the range `start_port..=65535`.
#[frb]
pub fn find_free_port(start_port: u16) -> Option<u16> {
    find_available_port(start_port)
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers  (not exposed to Dart)
// ─────────────────────────────────────────────────────────────────────────────

#[frb(ignore)]
async fn handle_connection(socket: &mut tokio::net::TcpStream, share_path: &str) {
    let mut buffer = [0u8; 2048];
    let n = match socket.read(&mut buffer).await {
        Ok(n) if n > 0 => n,
        _ => return,
    };

    let request = String::from_utf8_lossy(&buffer[..n]);
    let first_line = request.lines().next().unwrap_or("");

    if first_line.starts_with("GET /download/") {
        // ── File download ──────────────────────────────────────────────────
        let encoded_name = first_line
            .split_whitespace()
            .nth(1)
            .unwrap_or("")
            .trim_start_matches("/download/");

        let file_name = percent_decode(encoded_name);
        let file_path = Path::new(share_path).join(&file_name);

        if file_path.exists() && file_path.is_file() {
            if let Ok(mut file) = tokio::fs::File::open(&file_path).await {
                let file_size = file
                    .metadata()
                    .await
                    .map(|m| m.len())
                    .unwrap_or(0);

                let header = format!(
                    "HTTP/1.1 200 OK\r\n\
                     Content-Type: application/octet-stream\r\n\
                     Content-Length: {}\r\n\
                     Content-Disposition: attachment; filename=\"{}\"\r\n\
                     Access-Control-Allow-Origin: *\r\n\
                     \r\n",
                    file_size, file_name
                );
                let _ = socket.write_all(header.as_bytes()).await;

                let mut buf = [0u8; 65536]; // 64 KB streaming buffer
                loop {
                    match file.read(&mut buf).await {
                        Ok(0) => break,
                        Ok(n) => {
                            if socket.write_all(&buf[..n]).await.is_err() {
                                break;
                            }
                        }
                        Err(_) => break,
                    }
                }
            }
        } else {
            let body = "404 Not Found";
            let _ = socket
                .write_all(
                    format!(
                        "HTTP/1.1 404 Not Found\r\nContent-Length: {}\r\n\r\n{}",
                        body.len(),
                        body
                    )
                    .as_bytes(),
                )
                .await;
        }
    } else if first_line.starts_with("GET / ") || first_line.starts_with("GET / HTTP") || first_line == "GET /" {
        // ── File list page ─────────────────────────────────────────────────
        let html = build_file_list_html(share_path);
        let response = format!(
            "HTTP/1.1 200 OK\r\n\
             Content-Type: text/html; charset=utf-8\r\n\
             Content-Length: {}\r\n\
             Access-Control-Allow-Origin: *\r\n\
             \r\n{}",
            html.len(),
            html
        );
        let _ = socket.write_all(response.as_bytes()).await;
    } else {
        // ── 404 for anything else ──────────────────────────────────────────
        let body = "404 Not Found";
        let _ = socket
            .write_all(
                format!(
                    "HTTP/1.1 404 Not Found\r\nContent-Length: {}\r\n\r\n{}",
                    body.len(),
                    body
                )
                .as_bytes(),
            )
            .await;
    }
}

#[frb(ignore)]
fn build_file_list_html(path: &str) -> String {
    let mut rows = String::new();

    if let Ok(entries) = fs::read_dir(path) {
        let mut names: Vec<String> = entries
            .flatten()
            .filter(|e| e.path().is_file())
            .filter_map(|e| e.file_name().into_string().ok())
            .collect();
        names.sort();

        for name in &names {
            let size = fs::metadata(Path::new(path).join(name))
                .map(|m| format_size(m.len()))
                .unwrap_or_else(|_| "?".to_string());

            rows.push_str(&format!(
                "<tr>\
                   <td><a href='/download/{enc}'>{name}</a></td>\
                   <td style='color:#888;padding-left:16px'>{size}</td>\
                 </tr>",
                enc = percent_encode(name),
                name = html_escape(name),
                size = size,
            ));
        }
    }

    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Flux — Shared Files</title>
  <style>
    body{{font-family:system-ui,sans-serif;max-width:640px;margin:40px auto;padding:0 16px;background:#f9f9f9;color:#222}}
    h1{{font-size:1.4rem;margin-bottom:24px}}
    table{{width:100%;border-collapse:collapse}}
    tr:hover{{background:#f0f0f0}}
    td{{padding:10px 8px;border-bottom:1px solid #e0e0e0}}
    a{{color:#1a73e8;text-decoration:none}}
    a:hover{{text-decoration:underline}}
  </style>
</head>
<body>
  <h1>📁 Shared Files</h1>
  <table><tbody>{rows}</tbody></table>
</body>
</html>"#,
        rows = rows
    )
}

#[frb(ignore)]
fn get_local_ip() -> Result<String, String> {
    use std::net::UdpSocket;
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|e| e.to_string())?;
    socket.connect("8.8.8.8:80").map_err(|e| e.to_string())?;
    socket
        .local_addr()
        .map(|addr| addr.ip().to_string())
        .map_err(|e| e.to_string())
}

#[frb(ignore)]
fn find_available_port(start_port: u16) -> Option<u16> {
    for port in start_port..=65535 {
        if std::net::TcpListener::bind(format!("0.0.0.0:{}", port)).is_ok() {
            return Some(port);
        }
    }
    None
}

/// Minimal percent-encoder for file names in URLs.
#[frb(ignore)]
fn percent_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9'
            | b'-' | b'_' | b'.' | b'~' => out.push(b as char),
            _ => out.push_str(&format!("%{:02X}", b)),
        }
    }
    out
}

/// Minimal percent-decoder for incoming URL paths.
#[frb(ignore)]
fn percent_decode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let bytes = s.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(hex) = std::str::from_utf8(&bytes[i + 1..i + 3]) {
                if let Ok(byte) = u8::from_str_radix(hex, 16) {
                    out.push(byte as char);
                    i += 3;
                    continue;
                }
            }
        }
        out.push(bytes[i] as char);
        i += 1;
    }
    out
}

/// Escape HTML special characters to prevent XSS in the file list page.
#[frb(ignore)]
fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

/// Human-readable file size (B / KB / MB / GB).
#[frb(ignore)]
fn format_size(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;
    if bytes >= GB {
        format!("{:.1} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.1} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.1} KB", bytes as f64 / KB as f64)
    } else {
        format!("{} B", bytes)
    }
}
