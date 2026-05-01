// HTML template for the Flux web share page.
// Files load immediately via fetch() on page load.
// SSE (/api/events) provides live updates when files are added/removed.

const String webShareHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Flux Share</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f8fafc;color:#0f172a;min-height:100vh;padding:clamp(1rem,4vw,2rem)}
    .container{max-width:860px;margin:0 auto}
    .header{text-align:center;padding:2rem 1rem 1.5rem}
    .logo{display:inline-flex;align-items:center;justify-content:center;width:52px;height:52px;background:linear-gradient(135deg,#6366f1,#0ea5e9);border-radius:14px;margin-bottom:1rem;box-shadow:0 8px 20px -4px rgba(99,102,241,.4)}
    .logo svg{width:26px;height:26px;color:#fff;stroke:currentColor;fill:none;stroke-width:2}
    h1{font-size:clamp(1.25rem,4vw,1.6rem);font-weight:700;letter-spacing:-.02em}
    .subtitle{color:#64748b;font-size:.9rem;margin-top:.25rem}
    .badge{display:inline-flex;align-items:center;gap:.5rem;background:#f1f5f9;padding:.4rem 1rem;border-radius:20px;font-size:.8rem;color:#475569;margin-top:.75rem}
    .dot{width:8px;height:8px;background:#22c55e;border-radius:50%;animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
    .card{background:#fff;border-radius:16px;padding:clamp(1rem,3vw,1.5rem);box-shadow:0 1px 3px rgba(0,0,0,.06),0 4px 12px rgba(0,0,0,.04);margin-bottom:1.25rem;border:1px solid #f1f5f9}
    .section-title{font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#94a3b8;margin-bottom:.75rem}
    .btn-all{display:flex;align-items:center;justify-content:center;gap:.5rem;width:100%;padding:.75rem;background:linear-gradient(135deg,#10b981,#059669);color:#fff;border:none;border-radius:10px;font-weight:600;font-size:.95rem;cursor:pointer;margin-bottom:1rem;transition:opacity .15s}
    .btn-all:hover{opacity:.9}
    .btn-all:disabled{background:#94a3b8;cursor:default}
    .file-list{display:flex;flex-direction:column;gap:.6rem}
    .file-item{display:flex;align-items:center;gap:.75rem;padding:.75rem 1rem;background:#f8fafc;border-radius:10px;border:1px solid #e2e8f0;transition:border-color .15s}
    .file-item:hover{border-color:#6366f1}
    .file-icon{width:36px;height:36px;background:linear-gradient(135deg,#6366f1,#8b5cf6);border-radius:8px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:1.1rem;flex-shrink:0}
    .file-info{flex:1;min-width:0}
    .file-name{font-weight:600;font-size:.9rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .file-size{font-size:.75rem;color:#94a3b8;margin-top:.1rem}
    .dl-btn{background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;border:none;padding:.5rem .9rem;border-radius:8px;font-size:.8rem;font-weight:600;cursor:pointer;text-decoration:none;white-space:nowrap;transition:opacity .15s;display:inline-block}
    .dl-btn:hover{opacity:.85}
    .empty{text-align:center;padding:2.5rem 1rem;color:#94a3b8}
    .upload-zone{border:2px dashed #cbd5e1;border-radius:12px;padding:2rem;text-align:center;cursor:pointer;transition:border-color .2s,background .2s;position:relative}
    .upload-zone.drag{border-color:#6366f1;background:#eef2ff}
    .upload-zone input{position:absolute;inset:0;opacity:0;cursor:pointer;width:100%;height:100%}
    .upload-icon{font-size:2rem;margin-bottom:.5rem}
    .upload-text{font-weight:600;color:#475569}
    .upload-sub{font-size:.8rem;color:#94a3b8;margin-top:.25rem}
    .upload-progress{margin-top:.75rem;display:none}
    .progress-bar{height:6px;background:#e2e8f0;border-radius:3px;overflow:hidden;margin-top:.4rem}
    .progress-fill{height:100%;background:linear-gradient(90deg,#6366f1,#0ea5e9);border-radius:3px;transition:width .2s;width:0%}
    .upload-status{font-size:.8rem;color:#6366f1;margin-top:.3rem}
    .received-list{display:flex;flex-direction:column;gap:.4rem;margin-top:.75rem}
    .received-item{display:flex;align-items:center;gap:.5rem;font-size:.85rem;color:#22c55e}
    @media(min-width:640px){.file-list{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr))}.file-item{flex-direction:column;align-items:flex-start}.dl-btn{width:100%;margin-top:.5rem;text-align:center}}
  </style>
</head>
<body>
<div class="container">
  <div class="header">
    <div class="logo">
      <svg viewBox="0 0 24 24"><path d="M12 4v12M12 4l-5 5M12 4l5 5M4 20h16" stroke-linecap="round" stroke-linejoin="round"/></svg>
    </div>
    <h1>Flux Share</h1>
    <p class="subtitle">Download or upload files directly in your browser</p>
    <div class="badge"><span class="dot"></span><span id="statusText">Loading…</span></div>
  </div>

  <div class="card">
    <div class="section-title">📥 Files to Download</div>
    <button class="btn-all" id="dlAllBtn" onclick="downloadAll()" disabled>⬇ Download All as ZIP</button>
    <div class="file-list" id="fileList"><div class="empty">Loading files…</div></div>
  </div>

  <div class="card" id="uploadCard" style="display:none">
    <div class="section-title">📤 Send Files to Device</div>
    <div class="upload-zone" id="dropZone">
      <input type="file" id="fileInput" multiple onchange="handleFiles(this.files)">
      <div class="upload-icon">📁</div>
      <div class="upload-text">Tap to choose files or drag & drop</div>
      <div class="upload-sub">Files will be saved to the device</div>
    </div>
    <div class="upload-progress" id="uploadProgress">
      <div class="progress-bar"><div class="progress-fill" id="progressFill"></div></div>
      <div class="upload-status" id="uploadStatus">Uploading…</div>
    </div>
    <div class="received-list" id="receivedList"></div>
  </div>
</div>

<script>
  // ── Helpers ───────────────────────────────────────────────────────────────
  function formatSize(b) {
    if (b >= 1073741824) return (b/1073741824).toFixed(1)+' GB';
    if (b >= 1048576)    return (b/1048576).toFixed(1)+' MB';
    if (b >= 1024)       return (b/1024).toFixed(1)+' KB';
    return b+' B';
  }
  function fileIcon(name) {
    const ext = (name.split('.').pop()||'').toLowerCase();
    return {jpg:'🖼',jpeg:'🖼',png:'🖼',gif:'🖼',webp:'🖼',svg:'🖼',
            mp4:'🎬',mov:'🎬',avi:'🎬',mkv:'🎬',
            mp3:'🎵',wav:'🎵',flac:'🎵',
            pdf:'📄',doc:'📝',docx:'📝',txt:'📝',
            zip:'📦',rar:'📦','7z':'📦',apk:'📱',exe:'💻'}[ext] || '📄';
  }
  function renderFiles(files) {
    const list = document.getElementById('fileList');
    const btn  = document.getElementById('dlAllBtn');
    if (!files || !files.length) {
      list.innerHTML = '<div class="empty">No files shared yet</div>';
      btn.disabled = true;
      document.getElementById('statusText').textContent = '0 files';
      return;
    }
    btn.disabled = false;
    document.getElementById('statusText').textContent =
      files.length + ' file' + (files.length !== 1 ? 's' : '') + ' available';
    list.innerHTML = files.map(f => `
      <div class="file-item">
        <div class="file-icon">${fileIcon(f.name)}</div>
        <div class="file-info">
          <div class="file-name" title="${f.name}">${f.name}</div>
          <div class="file-size">${formatSize(f.size)}${f.downloadCount > 0 ? ' · '+f.downloadCount+' dl' : ''}</div>
        </div>
        <a href="/download/${f.id}" class="dl-btn" download="${f.name}">⬇ Download</a>
      </div>`).join('');
  }

  // ── 1. Load files immediately via fetch (works even if SSE fails) ─────────
  fetch('/api/files')
    .then(r => r.json())
    .then(files => renderFiles(files))
    .catch(() => {
      document.getElementById('fileList').innerHTML =
        '<div class="empty">Could not load files. Try refreshing.</div>';
      document.getElementById('statusText').textContent = 'Error';
    });

  // Also load settings
  fetch('/api/stats').catch(() => {});

  // ── 2. SSE for live updates (best-effort — page works without it) ─────────
  function connectSSE() {
    try {
      const es = new EventSource('/api/events');
      es.addEventListener('files', e => {
        renderFiles(JSON.parse(e.data));
      });
      es.addEventListener('settings', e => {
        const s = JSON.parse(e.data);
        document.getElementById('uploadCard').style.display =
          s.receiveEnabled ? 'block' : 'none';
      });
      es.onerror = () => {
        // SSE failed — fall back to polling every 5 seconds
        es.close();
        setTimeout(() => {
          fetch('/api/files').then(r => r.json()).then(renderFiles).catch(() => {});
          connectSSE();
        }, 5000);
      };
    } catch(e) {
      // SSE not supported — poll every 5 seconds
      setInterval(() => {
        fetch('/api/files').then(r => r.json()).then(renderFiles).catch(() => {});
      }, 5000);
    }
  }
  connectSSE();

  // ── Download all ──────────────────────────────────────────────────────────
  function downloadAll() {
    const btn = document.getElementById('dlAllBtn');
    btn.disabled = true;
    btn.textContent = '⏳ Preparing ZIP…';
    window.location.href = '/download/all';
    setTimeout(() => { btn.disabled = false; btn.textContent = '⬇ Download All as ZIP'; }, 3000);
  }

  // ── Drag & drop ───────────────────────────────────────────────────────────
  const dz = document.getElementById('dropZone');
  if (dz) {
    dz.addEventListener('dragover', e => { e.preventDefault(); dz.classList.add('drag'); });
    dz.addEventListener('dragleave', () => dz.classList.remove('drag'));
    dz.addEventListener('drop', e => { e.preventDefault(); dz.classList.remove('drag'); handleFiles(e.dataTransfer.files); });
  }

  // ── Upload ────────────────────────────────────────────────────────────────
  async function handleFiles(files) {
    if (!files || !files.length) return;
    const prog   = document.getElementById('uploadProgress');
    const fill   = document.getElementById('progressFill');
    const status = document.getElementById('uploadStatus');
    prog.style.display = 'block';
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      status.textContent = 'Uploading ' + file.name + ' (' + (i+1) + '/' + files.length + ')…';
      fill.style.width = '0%';
      const fd = new FormData();
      fd.append('file', file, file.name);
      try {
        await new Promise((resolve, reject) => {
          const xhr = new XMLHttpRequest();
          xhr.upload.onprogress = e => { if (e.lengthComputable) fill.style.width = (e.loaded/e.total*100)+'%'; };
          xhr.onload = () => xhr.status === 200 ? resolve() : reject(new Error('HTTP '+xhr.status));
          xhr.onerror = reject;
          xhr.open('POST', '/upload');
          xhr.send(fd);
        });
        fill.style.width = '100%';
        const item = document.createElement('div');
        item.className = 'received-item';
        item.textContent = '✅ ' + file.name + ' sent';
        document.getElementById('receivedList').prepend(item);
      } catch(err) {
        status.textContent = '❌ Failed: ' + err.message;
      }
    }
    status.textContent = 'Done!';
    setTimeout(() => { prog.style.display = 'none'; }, 3000);
  }
</script>
</body>
</html>
''';
