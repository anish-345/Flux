# NotebookLM CLI - Installation Complete ✅

**Installation Date:** April 12, 2026  
**Version:** 0.1.12  
**Status:** Ready to Use

---

## ✅ Installation Summary

NotebookLM CLI has been successfully installed on your system.

### Package Details
- **Package Name:** notebooklm-cli
- **Version:** 0.1.12
- **Command:** `nlm`
- **Installation Location:** `C:\Users\anish\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\LocalCache\local-packages\Python312\site-packages`

### Dependencies Installed
- httpx (HTTP client)
- platformdirs (Platform-specific directories)
- pydantic (Data validation)
- rich (Terminal formatting)
- typer (CLI framework)
- websocket-client (WebSocket support)

---

## 🚀 Quick Start

### Verify Installation
```powershell
nlm --version
nlm --help
```

### Login to NotebookLM
```powershell
nlm login
```

### Available Commands
```
nlm notebook    - Manage notebooks
nlm source      - Manage sources
nlm chat        - Configure chat settings
nlm studio      - Manage studio artifacts
nlm research    - Research and discover sources
nlm audio       - Create audio overviews
nlm report      - Create reports
nlm quiz        - Create quizzes
nlm flashcards  - Create flashcards
nlm mindmap     - Create and manage mind maps
nlm slides      - Create slide decks
nlm infographic - Create infographics
nlm video       - Create video overviews
nlm data-table  - Create data tables
nlm auth        - Authentication status
nlm config      - Manage configuration
nlm alias       - Manage ID aliases
```

---

## 📖 Common Usage Examples

### Create a New Notebook
```powershell
nlm notebook create --name "My Research"
```

### Add a Source to a Notebook
```powershell
nlm source add --notebook-id <ID> --url "https://example.com"
```

### Chat with Your Notebook
```powershell
nlm chat --notebook-id <ID> --message "Summarize the key points"
```

### Generate Audio Overview
```powershell
nlm audio create --notebook-id <ID>
```

### Create a Quiz
```powershell
nlm quiz create --notebook-id <ID>
```

### Create a Report
```powershell
nlm report create --notebook-id <ID>
```

---

## 🔐 Authentication

### First Time Setup
```powershell
nlm login
```
This will open a browser for OAuth authentication with Google.

### Check Authentication Status
```powershell
nlm auth
```

### Configuration
```powershell
nlm config --help
```

---

## 📚 Documentation

### Get Help for Any Command
```powershell
nlm <command> --help
```

### Examples
```powershell
nlm notebook --help
nlm source --help
nlm chat --help
nlm audio --help
```

### AI-Friendly Documentation
```powershell
nlm --ai
```

---

## 🔗 Resources

- **GitHub Repository:** https://github.com/jacob-bd/notebooklm-cli
- **PyPI Package:** https://pypi.org/project/notebooklm-cli/
- **NotebookLM Official:** https://notebooklm.google.com

---

## ⚠️ Important Notes

1. **Uses Internal APIs:** This CLI uses undocumented NotebookLM APIs that may change without notice
2. **Not Official:** Not affiliated with or endorsed by Google
3. **Use at Your Own Risk:** Intended for personal/experimental purposes
4. **OAuth Required:** You need a Google account to authenticate
5. **Rate Limits:** Be aware of NotebookLM's rate limits when using the CLI

---

## 🐛 Troubleshooting

### Command Not Found
If `nlm` command is not found, try:
```powershell
python -m pip install --upgrade notebooklm-cli
```

### Authentication Issues
```powershell
nlm login
nlm auth
```

### Check Installation
```powershell
pip show notebooklm-cli
```

---

## 📝 Next Steps

1. **Authenticate:** Run `nlm login` to connect your Google account
2. **Create Notebook:** Use `nlm notebook create` to start
3. **Add Sources:** Use `nlm source add` to add documents/URLs
4. **Generate Artifacts:** Use `nlm audio`, `nlm quiz`, `nlm report`, etc.
5. **Chat:** Use `nlm chat` to interact with your notebooks

---

## ✨ Features

✅ Create and manage notebooks  
✅ Add sources (documents, URLs, etc.)  
✅ Chat with your content  
✅ Generate audio overviews  
✅ Create quizzes  
✅ Generate reports  
✅ Create flashcards  
✅ Create mind maps  
✅ Create slide decks  
✅ Create infographics  
✅ Create video overviews  
✅ Create data tables  
✅ Manage aliases and configuration  

---

**Status:** ✅ Ready to Use  
**Command:** `nlm`  
**Version:** 0.1.12  
**Last Updated:** April 12, 2026
