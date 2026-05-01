use flutter_rust_bridge::frb;
use mdns_sd::{ServiceDaemon, ServiceInfo};
use std::sync::Mutex;
use lazy_static::lazy_static;

// ─────────────────────────────────────────────────────────────────────────────
// Global daemon — one per process, reused across register/unregister calls.
// ─────────────────────────────────────────────────────────────────────────────
lazy_static! {
    #[frb(ignore)]
    static ref MDNS_DAEMON: Mutex<Option<ServiceDaemon>> = Mutex::new(None);

    #[frb(ignore)]
    static ref ACTIVE_SERVICE_NAME: Mutex<Option<String>> = Mutex::new(None);
}

/// Result returned after mDNS registration succeeds.
#[frb]
pub struct MdnsRegistration {
    /// The unique `.local` hostname for this device, e.g. `anish-phone.local`.
    pub hostname: String,
    /// Full URL the user types in a browser, e.g. `http://anish-phone.local:8080`.
    pub url: String,
    /// The display label shown in the UI, e.g. `anish-phone.local`.
    pub display_name: String,
}

/// Register the Flux web-share server as a unique mDNS/DNS-SD service.
///
/// Each device on the same WiFi gets its own hostname derived from
/// [device_name], so multiple Flux instances can coexist:
///
/// ```
/// Device 1 → anish-phone.local:8080
/// Device 2 → ravi-tablet.local:8080
/// Device 3 → sara-laptop.local:8080
/// Device 4 → flux-4a2b.local:8080   (fallback when name is empty)
/// ```
///
/// The hostname is sanitised to RFC 1123 label rules (lowercase, hyphens only,
/// max 15 chars before `.local`) and a 4-char hex suffix from the IP is
/// appended to guarantee uniqueness even when two devices share the same name.
#[frb]
pub fn register_mdns_service(
    port: u16,
    ip_address: String,
    device_name: String,
) -> Result<MdnsRegistration, String> {
    // ── 1. Build a unique, RFC-1123-safe hostname ────────────────────────────
    let label = build_hostname_label(&device_name, &ip_address);
    // mDNS hostnames MUST end with `.local.` (trailing dot required by RFC 6762)
    let hostname_fqdn = format!("{}.local.", label);
    let hostname_display = format!("{}.local", label);

    // ── 2. Get or create the daemon ──────────────────────────────────────────
    let mut guard = MDNS_DAEMON
        .lock()
        .map_err(|e| format!("Failed to lock mDNS daemon: {}", e))?;

    if guard.is_none() {
        let daemon = ServiceDaemon::new()
            .map_err(|e| format!("Failed to create mDNS daemon: {}", e))?;
        *guard = Some(daemon);
    }

    let daemon = guard.as_ref().unwrap();

    // ── 3. Unregister any previous service ───────────────────────────────────
    {
        let mut name_guard = ACTIVE_SERVICE_NAME
            .lock()
            .map_err(|e| format!("Failed to lock service name: {}", e))?;

        if let Some(ref name) = *name_guard {
            let _ = daemon.unregister(name); // best-effort
        }
        *name_guard = None;
    }

    // ── 4. Build ServiceInfo ─────────────────────────────────────────────────
    // Service type _http._tcp is the standard for HTTP servers.
    // The instance name is what shows up in Bonjour browsers / network panels.
    let service_type = "_http._tcp.local.";
    let instance_name = format!("Flux Share ({})", label);

    let properties = [
        ("path", "/"),
        ("app", "flux"),
        ("version", "1"),
        ("device", label.as_str()),
    ];

    let service_info = ServiceInfo::new(
        service_type,
        &instance_name,
        &hostname_fqdn,
        ip_address.as_str(),
        port,
        &properties[..],
    )
    .map_err(|e| format!("Failed to create ServiceInfo: {}", e))?;

    // ── 5. Register ──────────────────────────────────────────────────────────
    let full_name = service_info.get_fullname().to_string();

    daemon
        .register(service_info)
        .map_err(|e| format!("Failed to register mDNS service: {}", e))?;

    {
        let mut name_guard = ACTIVE_SERVICE_NAME
            .lock()
            .map_err(|e| format!("Failed to lock service name: {}", e))?;
        *name_guard = Some(full_name);
    }

    let url = format!("http://{}:{}", hostname_display, port);

    Ok(MdnsRegistration {
        hostname: hostname_display.clone(),
        url,
        display_name: hostname_display,
    })
}

/// Unregister the mDNS service.  Call this when the web-share server stops.
#[frb]
pub fn unregister_mdns_service() -> Result<(), String> {
    let guard = MDNS_DAEMON
        .lock()
        .map_err(|e| format!("Failed to lock mDNS daemon: {}", e))?;

    if let Some(ref daemon) = *guard {
        let mut name_guard = ACTIVE_SERVICE_NAME
            .lock()
            .map_err(|e| format!("Failed to lock service name: {}", e))?;

        if let Some(ref name) = *name_guard {
            daemon
                .unregister(name)
                .map_err(|e| format!("Failed to unregister mDNS service: {}", e))?;
            *name_guard = None;
        }
    }

    Ok(())
}

/// Returns `true` — mdns-sd works on all platforms we target.
/// On Android, CHANGE_WIFI_MULTICAST_STATE permission is required (declared in
/// AndroidManifest.xml).
#[frb]
pub fn is_mdns_supported() -> bool {
    true
}

/// Shutdown the global mDNS daemon. Call this when the app is exiting.
#[frb]
pub fn shutdown_mdns_daemon() -> Result<(), String> {
    let mut guard = MDNS_DAEMON
        .lock()
        .map_err(|e| format!("Failed to lock mDNS daemon: {}", e))?;

    if let Some(daemon) = guard.take() {
        daemon.shutdown()
            .map_err(|e| format!("Failed to shutdown mDNS daemon: {}", e))?;
    }

    // Also clear the active service name
    let mut name_guard = ACTIVE_SERVICE_NAME
        .lock()
        .map_err(|e| format!("Failed to lock service name: {}", e))?;
    *name_guard = None;

    Ok(())
}

/// Discover all Flux Share instances on the local network via mDNS.
///
/// Listens for `_http._tcp.local.` services with the `app=flux` TXT property
/// for [timeout_ms] milliseconds, then returns the list of found peers.
///
/// Each entry is a JSON string:
/// `{"name":"anish-phone","url":"http://anish-phone.local:8080","ip":"192.168.1.47","port":8080}`
#[frb]
pub fn discover_flux_peers(timeout_ms: u64) -> Result<Vec<String>, String> {
    use mdns_sd::{ServiceEvent};
    use std::time::{Duration, Instant};

    // ── 1. Get or create the global daemon (reuse instead of creating new) ────────
    let mut guard = MDNS_DAEMON
        .lock()
        .map_err(|e| format!("Failed to lock mDNS daemon: {}", e))?;

    if guard.is_none() {
        let daemon = ServiceDaemon::new()
            .map_err(|e| format!("Failed to create mDNS daemon: {}", e))?;
        *guard = Some(daemon);
    }

    let daemon = guard.as_ref().unwrap();

    let receiver = daemon
        .browse("_http._tcp.local.")
        .map_err(|e| format!("Failed to start mDNS browse: {}", e))?;

    let deadline = Instant::now() + Duration::from_millis(timeout_ms);
    let mut peers: Vec<String> = Vec::new();
    let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();

    while Instant::now() < deadline {
        // Non-blocking receive with a short timeout
        match receiver.recv_timeout(Duration::from_millis(100)) {
            Ok(ServiceEvent::ServiceResolved(info)) => {
                // Only include Flux services (identified by app=flux TXT property)
                let is_flux = info
                    .get_properties()
                    .get("app")
                    .map(|v| v.val_str() == "flux")
                    .unwrap_or(false);

                if !is_flux {
                    continue;
                }

                let fullname = info.get_fullname().to_string();
                if seen.contains(&fullname) {
                    continue;
                }
                seen.insert(fullname);

                let hostname = info.get_hostname().trim_end_matches('.').to_string();
                let port = info.get_port();
                let ip = info
                    .get_addresses()
                    .iter()
                    .next()
                    .map(|a| a.to_string())
                    .unwrap_or_default();

                // Extract device label from the "device" TXT property
                let device_label = info
                    .get_properties()
                    .get("device")
                    .map(|v| v.val_str().to_string())
                    .unwrap_or_else(|| hostname.clone());

                let url = format!("http://{}:{}", hostname, port);
                let entry = format!(
                    r#"{{"name":"{}","url":"{}","ip":"{}","port":{}}}"#,
                    device_label, url, ip, port
                );
                peers.push(entry);
            }
            Ok(_) => {} // Ignore other events (Added, Removed, etc.)
            Err(_) => {} // Timeout — keep looping until deadline
        }
    }

    // Don't shutdown the daemon - we reuse it for future discoveries
    Ok(peers)
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Build a unique, RFC-1123-safe hostname label from the device name and IP.
///
/// Rules:
/// - Lowercase, only `[a-z0-9-]`
/// - Must start and end with alphanumeric
/// - Max 15 chars (leaves room for `.local` within the 63-char label limit)
/// - A 4-char hex suffix derived from the last two octets of the IP is appended
///   to guarantee uniqueness when two devices share the same name
///
/// Examples:
///   ("Anish's Phone", "192.168.1.47") → "anish-phone-012f"
///   ("",              "192.168.1.47") → "flux-012f"
#[frb(ignore)]
fn build_hostname_label(device_name: &str, ip_address: &str) -> String {
    // 4-char hex suffix from last two IP octets for uniqueness
    let suffix = ip_suffix(ip_address);

    let base = if device_name.trim().is_empty() {
        "flux".to_string()
    } else {
        sanitise_label(device_name)
    };

    // Truncate base to leave room for "-xxxx" suffix (5 chars)
    let max_base = 10;
    let truncated = if base.len() > max_base {
        base[..max_base].trim_end_matches('-').to_string()
    } else {
        base
    };

    let label = format!("{}-{}", truncated, suffix);

    // Ensure it starts with a letter (RFC 1123 relaxes this but mDNS is safer)
    if label.starts_with(|c: char| c.is_ascii_digit()) {
        format!("flux-{}", label)
    } else {
        label
    }
}

/// Sanitise an arbitrary string into a valid DNS label segment.
/// Keeps only ASCII alphanumerics, converts spaces/underscores to hyphens,
/// collapses consecutive hyphens, strips leading/trailing hyphens.
#[frb(ignore)]
fn sanitise_label(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut prev_hyphen = false;

    for ch in s.chars() {
        if ch.is_ascii_alphanumeric() {
            out.push(ch.to_ascii_lowercase());
            prev_hyphen = false;
        } else if (ch == ' ' || ch == '_' || ch == '-') && !prev_hyphen && !out.is_empty() {
            out.push('-');
            prev_hyphen = true;
        }
        // drop everything else (apostrophes, emoji, etc.)
    }

    // Strip trailing hyphen
    let trimmed = out.trim_end_matches('-').to_string();
    if trimmed.is_empty() { "flux".to_string() } else { trimmed }
}

/// Derive a 4-char hex string from the last two octets of an IPv4 address.
/// Falls back to a fixed value if parsing fails.
#[frb(ignore)]
fn ip_suffix(ip: &str) -> String {
    let parts: Vec<&str> = ip.split('.').collect();
    if parts.len() == 4 {
        let a = parts[2].parse::<u16>().unwrap_or(0);
        let b = parts[3].parse::<u16>().unwrap_or(0);
        let combined = (a << 8) | b;
        format!("{:04x}", combined)
    } else {
        // IPv6 or unparseable — use last 4 chars of the string as hex-ish suffix
        let raw: String = ip.chars()
            .filter(|c| c.is_ascii_alphanumeric())
            .take(4)
            .collect();
        if raw.len() == 4 { raw } else { "0000".to_string() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitise_label() {
        assert_eq!(sanitise_label("Anish's Phone"), "anishs-phone");
        assert_eq!(sanitise_label("Ravi Tablet"), "ravi-tablet");
        assert_eq!(sanitise_label("Sara's Laptop 2"), "saras-laptop-2");
        assert_eq!(sanitise_label(""), "flux");
        assert_eq!(sanitise_label("!!!"), "flux");
    }

    #[test]
    fn test_ip_suffix() {
        assert_eq!(ip_suffix("192.168.1.47"), "012f");
        assert_eq!(ip_suffix("192.168.0.1"), "0001");
        assert_eq!(ip_suffix("10.0.0.255"), "00ff");
    }

    #[test]
    fn test_build_hostname_label() {
        let label = build_hostname_label("Anish's Phone", "192.168.1.47");
        assert!(label.ends_with("-012f"));
        assert!(label.chars().all(|c| c.is_ascii_alphanumeric() || c == '-'));

        // Empty name falls back to flux-xxxx
        let label2 = build_hostname_label("", "192.168.1.47");
        assert!(label2.starts_with("flux-"));
    }
}
