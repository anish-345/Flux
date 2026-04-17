use tokio::net::TcpListener;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use std::path::Path;
use std::fs;
use crate::api::network::NetworkUtils;

pub struct WebShareConfig {
    pub port: u16,
    pub share_path: String,
}

/// Start a simple web server for file sharing
pub async fn start_web_sharing(config: WebShareConfig) -> Result<String, String> {
    let port = if config.port == 0 {
        NetworkUtils::find_available_port(8080).ok_or("No available ports")?
    } else {
        config.port
    };

    let addr = format!("0.0.0.0:{}", port);
    let listener = TcpListener::bind(&addr).await
        .map_err(|e| format!("Failed to bind web server to {}: {}", addr, e))?;

    let local_ip = get_local_ip()?;
    let web_url = format!("http://{}:{}", local_ip, port);

    // Spawn the server task
    tokio::spawn(async move {
        while let Ok((mut socket, _)) = listener.accept().await {
            let share_path = config.share_path.clone();
            tokio::spawn(async move {
                let mut buffer = [0; 1024];
                if let Ok(n) = socket.read(&mut buffer).await {
                    let request = String::from_utf8_lossy(&buffer[..n]);
                    
                    // Simple HTTP/1.1 response
                    if request.starts_with("GET / ") {
                        let response = build_file_list_html(&share_path);
                        let http_response = format!(
                            "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: {}\r\n\r\n{}",
                            response.len(),
                            response
                        );
                        let _ = socket.write_all(http_response.as_bytes()).await;
                    } else if request.starts_with("GET /download/") {
                        // Handle file download
                        let file_name = request.split_whitespace().nth(1)
                            .unwrap_or("")
                            .trim_start_matches("/download/");
                        
                        let file_path = Path::new(&share_path).join(file_name);
                        if file_path.exists() && file_path.is_file() {
                            if let Ok(mut file) = tokio::fs::File::open(&file_path).await {
                                let file_size = file.metadata().await.map(|m| m.len()).unwrap_or(0);
                                let header = format!(
                                    "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: {}\r\nContent-Disposition: attachment; filename=\"{}\"\r\n\r\n",
                                    file_size,
                                    file_name
                                );
                                let _ = socket.write_all(header.as_bytes()).await;
                                let mut file_buffer = [0; 8192];
                                while let Ok(n) = file.read(&mut file_buffer).await {
                                    if n == 0 { break; }
                                    if socket.write_all(&file_buffer[..n]).await.is_err() { break; }
                                }
                            }
                        }
                    }
                }
            });
        }
    });

    Ok(web_url)
}

fn get_local_ip() -> Result<String, String> {
    use std::net::UdpSocket;
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|e| e.to_string())?;
    socket.connect("8.8.8.8:80").map_err(|e| e.to_string())?;
    socket.local_addr().map(|addr| addr.ip().to_string()).map_err(|e| e.to_string())
}

fn build_file_list_html(path: &str) -> String {
    let mut html = String::from("<html><head><title>Flux Web Share</title><style>body{font-family:sans-serif;padding:20px;} .file-item{margin:10px 0;padding:10px;border:1px solid #ddd;border-radius:5px;}</style></head><body>");
    html.push_str("<h1>Available Files</h1>");
    
    if let Ok(entries) = fs::read_dir(path) {
        for entry in entries.flatten() {
            if let Ok(name) = entry.file_name().into_string() {
                html.push_str(&format!(
                    "<div class='file-item'><a href='/download/{}'>{}</a></div>",
                    name, name
                ));
            }
        }
    }
    
    html.push_str("</body></html>");
    html
}
