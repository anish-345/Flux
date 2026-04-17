# Rust Essential Libraries Guide

**Last Updated:** April 12, 2026  
**Status:** Active Learning Document  
**Use Case:** Reference for proper libraries and frameworks for Rust development

---

## 🌐 HTTP & Networking

### reqwest - HTTP Client
```toml
[dependencies]
reqwest = { version = "0.11", features = ["json"] }
tokio = { version = "1", features = ["full"] }
```

**When to use:** HTTP requests, REST APIs, async operations
**Pros:** Async-first, easy to use, built-in JSON support
**Cons:** Requires tokio runtime

```rust
use reqwest::Client;

#[tokio::main]
async fn main() {
    let client = Client::new();
    let response = client
        .get("https://api.example.com/users")
        .send()
        .await
        .unwrap();
    
    let body = response.text().await.unwrap();
    println!("{}", body);
}
```

### hyper - Low-level HTTP
```toml
[dependencies]
hyper = "0.14"
```

**When to use:** Custom HTTP implementations, servers
**Pros:** Low-level control, fast
**Cons:** More complex API

### axum - Web Framework
```toml
[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
```

**When to use:** Building REST APIs, web servers
**Pros:** Type-safe routing, middleware support
**Cons:** Requires tokio

```rust
use axum::{routing::get, Router};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(handler));
    
    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn handler() -> &'static str {
    "Hello, World!"
}
```

---

## 📄 JSON Serialization

### serde - Serialization Framework
```toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

**When to use:** JSON serialization/deserialization
**Pros:** Type-safe, efficient, widely used
**Cons:** Requires derive macros

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
struct User {
    name: String,
    age: u32,
}

fn main() {
    let user = User {
        name: "John".to_string(),
        age: 30,
    };
    
    let json = serde_json::to_string(&user).unwrap();
    let parsed: User = serde_json::from_str(&json).unwrap();
}
```

### toml - TOML Parsing
```toml
[dependencies]
toml = "0.8"
```

**When to use:** Configuration files
**Pros:** Human-readable, type-safe
**Cons:** Limited to TOML format

### ron - Rust Object Notation
```toml
[dependencies]
ron = "0.8"
```

**When to use:** Rust-native serialization
**Pros:** Rust-like syntax, efficient
**Cons:** Less widely used

---

## 🔄 Async Runtime

### tokio - Async Runtime
```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
```

**When to use:** Async operations, concurrent tasks
**Pros:** Production-ready, feature-rich, widely used
**Cons:** Heavier than alternatives

```rust
use tokio::time::{sleep, Duration};

#[tokio::main]
async fn main() {
    let task1 = tokio::spawn(async {
        sleep(Duration::from_secs(1)).await;
        "Task 1"
    });
    
    let task2 = tokio::spawn(async {
        sleep(Duration::from_secs(2)).await;
        "Task 2"
    });
    
    let (r1, r2) = tokio::join!(task1, task2);
    println!("{:?}, {:?}", r1, r2);
}
```

### async-std - Alternative Runtime
```toml
[dependencies]
async-std = "1.12"
```

**When to use:** Alternative to tokio
**Pros:** Lighter weight, similar API
**Cons:** Smaller ecosystem

### futures - Async Utilities
```toml
[dependencies]
futures = "0.3"
```

**When to use:** Working with futures, combinators
**Pros:** Powerful combinators, well-designed
**Cons:** Requires understanding of futures

```rust
use futures::future;

async fn fetch_multiple(urls: Vec<&str>) {
    let futures = urls.iter().map(|url| fetch(url));
    let results = future::join_all(futures).await;
}
```

---

## 🔐 Error Handling

### thiserror - Custom Errors
```toml
[dependencies]
thiserror = "1.0"
```

**When to use:** Library error types
**Pros:** Minimal boilerplate, derives Display and Error
**Cons:** Limited to simple cases

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum MyError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Parse error: {0}")]
    Parse(String),
}

fn main() -> Result<(), MyError> {
    Ok(())
}
```

### anyhow - Flexible Error Handling
```toml
[dependencies]
anyhow = "1.0"
```

**When to use:** Application-level error handling
**Pros:** Flexible, easy context, no custom types needed
**Cons:** Less type-safe

```rust
use anyhow::{Result, Context};

fn read_file(path: &str) -> Result<String> {
    std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read {}", path))
}
```

---

## 🧪 Testing

### test - Built-in Testing
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_addition() {
        assert_eq!(2 + 2, 4);
    }
    
    #[test]
    #[should_panic]
    fn test_panic() {
        panic!("This should panic");
    }
}
```

### mockito - Mocking
```toml
[dev-dependencies]
mockito = "0.12"
```

```rust
#[cfg(test)]
mod tests {
    use mockito::mock;
    
    #[test]
    fn test_with_mock() {
        let _m = mock("GET", mockito::Matcher::Any)
            .with_status(200)
            .create();
    }
}
```

### criterion - Benchmarking
```toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "my_benchmark"
harness = false
```

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(black_box(20))));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
```

---

## 💾 Data Structures

### ndarray - Numerical Computing
```toml
[dependencies]
ndarray = "0.15"
```

**When to use:** Matrix operations, numerical computing
**Pros:** Efficient, NumPy-like API
**Cons:** Steep learning curve

```rust
use ndarray::Array2;

fn main() {
    let a = Array2::<f64>::zeros((3, 3));
    let b = Array2::<f64>::ones((3, 3));
    let c = &a + &b;
}
```

### hashbrown - Hash Maps
```toml
[dependencies]
hashbrown = "0.14"
```

**When to use:** High-performance hash maps
**Pros:** Faster than std HashMap
**Cons:** Nightly-only features

### parking_lot - Synchronization
```toml
[dependencies]
parking_lot = "0.12"
```

**When to use:** Faster mutexes and RwLocks
**Pros:** Faster than std, no poisoning
**Cons:** Different API

---

## 🔗 Serialization Formats

### bincode - Binary Encoding
```toml
[dependencies]
bincode = "1.3"
```

**When to use:** Efficient binary serialization
**Pros:** Fast, compact
**Cons:** Not human-readable

### protobuf - Protocol Buffers
```toml
[dependencies]
protobuf = "2.28"
```

**When to use:** Cross-language serialization
**Pros:** Efficient, widely supported
**Cons:** Requires .proto files

### capnp - Cap'n Proto
```toml
[dependencies]
capnp = "0.18"
```

**When to use:** Zero-copy serialization
**Pros:** Very fast, zero-copy
**Cons:** Complex schema language

---

## 📊 Library Selection Matrix

| Feature | reqwest | hyper | axum | tokio | async-std |
|---------|---------|-------|------|-------|-----------|
| Ease of use | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Performance | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Ecosystem | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Documentation | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎯 Recommended Stack

**CLI Application:**
- Async: tokio
- HTTP: reqwest
- JSON: serde_json
- Errors: anyhow
- Testing: criterion

**Web API:**
- Framework: axum
- Async: tokio
- JSON: serde_json
- Errors: thiserror
- Database: sqlx or diesel
- Testing: mockito + criterion

**Data Processing:**
- Async: tokio
- Numerics: ndarray
- Serialization: serde + bincode
- Errors: anyhow
- Testing: criterion

**Systems Programming:**
- Async: tokio (if needed)
- Errors: thiserror
- Synchronization: parking_lot
- Testing: built-in test
- Benchmarking: criterion

---

## 🔗 Common Patterns

### HTTP Client with Error Handling
```rust
use reqwest::Client;
use thiserror::Error;

#[derive(Error, Debug)]
enum ApiError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),
    
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}

async fn fetch_users() -> Result<Vec<User>, ApiError> {
    let client = Client::new();
    let response = client.get("https://api.example.com/users").send().await?;
    let users = response.json().await?;
    Ok(users)
}
```

### Async Server with Middleware
```rust
use axum::{middleware, Router, routing::get};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(handler))
        .layer(middleware::from_fn(logging_middleware));
    
    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn logging_middleware(req: Request, next: Next) -> Response {
    println!("{} {}", req.method(), req.uri());
    next.run(req).await
}
```

---

**Status:** ✅ Active Knowledge Base  
**Confidence Level:** High (Official Documentation)  
**Use:** Reference for selecting proper libraries in Rust projects