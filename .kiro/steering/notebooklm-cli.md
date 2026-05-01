---
inclusion: manual
---

# NotebookLM CLI & MCP Guide

**Quick Navigation:** [Installation](#installation) | [Authentication](#authentication) | [Notebooks](#notebooks) | [Sources](#sources) | [Content Creation](#studio-content-creation) | [Batch Operations](#batch-operations) | [MCP Setup](#mcp-server-configuration)

**Last Updated:** April 12, 2026  
**Status:** ✅ Active Knowledge Base  
**Confidence Level:** High (Official Documentation)  
**Use Case:** Complete reference for NotebookLM CLI (`nlm`) command-line interface and MCP server integration

---

## 📋 Document Summary

This guide covers the complete NotebookLM CLI (`nlm`) command reference:
- **Installation:** Setup via `uv` or `pip`
- **Authentication:** Multi-profile support with browser-based login
- **Notebooks:** Create, manage, query, and organize notebooks
- **Sources:** Add URLs, files, YouTube, Google Drive, and text content
- **Content Creation:** Generate podcasts, videos, reports, quizzes, flashcards, mindmaps, slides, infographics
- **Batch Operations:** Query and manage multiple notebooks at once
- **MCP Integration:** Configure for Claude Code, Cursor, Gemini, and other AI tools
- **Pipelines:** Automated workflows for common tasks
- **Diagnostics:** Troubleshoot installation and authentication issues

**When to use:** When working with NotebookLM programmatically, automating research workflows, or integrating with AI tools via MCP.

---

## Installation

### Using uv (Recommended)
```bash
uv tool install notebooklm-mcp-cli
```

### Using pip
```bash
pip install notebooklm-mcp-cli
```

After installation, the `nlm` command is available globally.

---

## Authentication

### Basic Login
```bash
nlm login                         # Opens browser, extracts cookies automatically
nlm login --check                 # Check if authenticated
```

### Multi-Profile Support
```bash
nlm login --profile work          # Named profile for multiple accounts
nlm login switch <profile>        # Switch default profile
nlm login profile list            # List all profiles with email addresses
nlm login profile delete <name>   # Delete a profile
nlm login profile rename <old> <new>  # Rename a profile
```

### External CDP Provider
```bash
# For OpenClaw-managed browser or custom CDP
nlm login --provider openclaw --cdp-url http://127.0.0.1:18800
```

**Key Points:**
- Each profile gets isolated browser session
- Supports Chrome, Arc, Brave, Edge, Chromium, Vivaldi, Opera
- Session lasts ~20 minutes; re-run `nlm login` if operations fail
- Use `nlm login profile list` to see all profiles with associated emails

---

## Command Structure

The CLI supports two command styles - use whichever feels natural:

### Noun-First (Resource-Oriented)
```bash
nlm notebook create "Title"
nlm source add <notebook> --url <url>
nlm audio create <notebook>
```

### Verb-First (Action-Oriented)
```bash
nlm create notebook "Title"
nlm add url <notebook> <url>
nlm create audio <notebook>
```

---

## Notebooks

### List & Get
```bash
nlm notebook list                      # List all notebooks
nlm notebook list --json               # JSON output
nlm notebook get <id>                  # Get details
nlm notebook describe <id>             # AI summary of notebook
```

### Create & Manage
```bash
nlm notebook create "Title"            # Create notebook
nlm notebook rename <id> "New Title"   # Rename
nlm notebook delete <id> --confirm     # Delete (IRREVERSIBLE)
```

### Query & Chat
```bash
nlm notebook query <id> "question"     # Chat with sources in notebook
```

### Aliases (Shortcuts)
```bash
nlm alias set myproject <notebook-id>  # Create alias
nlm alias list                         # List all aliases
nlm alias get myproject                # Resolve to UUID
nlm alias delete myproject             # Remove alias

# Use aliases anywhere
nlm notebook get myproject
nlm source list myproject
```

### Tags & Organization
```bash
nlm tag add <notebook> --tags "ai,research,llm"           # Add tags
nlm tag add <notebook> --tags "ai" --title "My Notebook"  # With display title
nlm tag remove <notebook> --tags "ai"                     # Remove tags
nlm tag list                                              # List all tagged notebooks
nlm tag select "ai research"                              # Find notebooks by tag match
```

---

## Sources

### List & Get
```bash
nlm source list <notebook>                         # List sources
nlm source get <source-id>                         # Get content
nlm source describe <source-id>                    # AI summary
```

### Add Sources
```bash
# URL
nlm source add <notebook> --url "https://..."      # Add URL
nlm source add <notebook> --url "https://..." --wait  # Add and wait until ready

# Text/Notes
nlm source add <notebook> --text "content" --title "Notes"  # Add text

# File Upload
nlm source add <notebook> --file document.pdf --wait  # Upload file

# YouTube
nlm source add <notebook> --youtube "https://..."  # Add YouTube video

# Google Drive
nlm source add <notebook> --drive <doc-id>         # Add Drive document
```

### Manage Sources
```bash
nlm source stale <notebook>                        # Check stale Drive sources
nlm source sync <notebook> --confirm               # Sync stale sources
nlm source delete <source-id> --confirm            # Delete (IRREVERSIBLE)
```

**Tips:**
- Use `--wait` when adding sources to ensure they're ready before querying
- Drive sources can become stale; use `sync` to update them

---

## Studio Content Creation

### Audio (Podcasts)
```bash
nlm audio create <notebook> --confirm
nlm audio create <notebook> --format deep_dive --length long --confirm

# Formats: deep_dive, brief, critique, debate
# Lengths: short, default, long
```

### Video
```bash
nlm video create <notebook> --confirm
nlm video create <notebook> --format explainer --style classic --confirm
nlm video create <notebook> --style custom --style-prompt "A children's storybook illustration" --confirm

# Formats: explainer, brief, cinematic
# Styles: auto_select, custom, classic, whiteboard, kawaii, anime, watercolor, retro_print, heritage, paper_craft
```

### Reports
```bash
nlm report create <notebook> --format "Briefing Doc" --confirm

# Formats: "Briefing Doc", "Study Guide", "Blog Post", "Create Your Own"
```

### Quiz & Flashcards
```bash
nlm quiz create <notebook> --count 10 --difficulty medium --focus "Focus on key concepts" --confirm
nlm flashcards create <notebook> --difficulty hard --focus "Focus on definitions" --confirm
```

### Other Formats
```bash
nlm mindmap create <notebook> --confirm
nlm slides create <notebook> --confirm
nlm infographic create <notebook> --orientation landscape --style professional --confirm
nlm data-table create <notebook> --description "Sales by region" --confirm
```

### Revise Content
```bash
# Revise slides (creates new deck)
nlm slides revise <artifact-id> --slide '1 Make the title larger' --confirm
nlm slides revise <artifact-id> --slide '1 Fix title' --slide '3 Remove image' --confirm
```

---

## Downloads

### Download Artifacts
```bash
nlm download audio <notebook> <artifact-id> --output podcast.mp3
nlm download video <notebook> <artifact-id> --output video.mp4
nlm download report <notebook> <artifact-id> --output report.md
nlm download mind-map <notebook> <artifact-id> --output mindmap.json
nlm download slide-deck <notebook> <artifact-id> --output slides.pdf
nlm download infographic <notebook> <artifact-id> --output infographic.png
```

### Interactive Formats
```bash
nlm download quiz <notebook> <artifact-id> --format html --output quiz.html
nlm download flashcards <notebook> <artifact-id> --format markdown --output cards.md
```

---

## Research

### Start Research
```bash
nlm research start "query" --notebook-id <id> --mode fast  # Quick search
nlm research start "query" --notebook-id <id> --mode deep  # Extended research
nlm research start "query" --notebook-id <id> --source drive  # Search Drive
nlm research start "query" --notebook-id <id> --auto-import # Start, poll, and import in one step
```

### Check Status & Import
```bash
nlm research status <notebook> --max-wait 300              # Poll until done
nlm research import <notebook> <task-id>                   # Import sources
nlm research import <notebook> <task-id> --timeout 600     # Custom timeout (default: 300s)
```

---

## Studio Status & Management

```bash
nlm studio status <notebook>           # Check artifact generation status
nlm studio delete <notebook> <artifact-id> --confirm  # Delete artifact
```

**Note:** Audio/video takes 1-5 minutes; poll with `nlm studio status`

---

## Sharing

```bash
nlm share status <notebook>                    # View sharing settings
nlm share public <notebook>                    # Enable public link
nlm share private <notebook>                   # Disable public link
nlm share invite <notebook> email@example.com  # Invite viewer
nlm share invite <notebook> email --role editor  # Invite editor
```

---

## Batch Operations

### Query Multiple Notebooks
```bash
nlm batch query "What are the key takeaways?" --notebooks "id1,id2"
nlm batch query "Summarize" --tags "ai,research"          # Query by tag
nlm batch query "Summarize" --all                         # Query ALL notebooks
```

### Add Sources to Multiple
```bash
nlm batch add-source --url "https://..." --notebooks "id1,id2"
```

### Create Multiple Notebooks
```bash
nlm batch create "Project A, Project B, Project C"        # Create multiple
```

### Delete Multiple
```bash
nlm batch delete --notebooks "id1,id2" --confirm          # Delete multiple
```

### Generate Content Across Notebooks
```bash
nlm batch studio --type audio --tags "research" --confirm # Generate across notebooks
```

---

## Cross-Notebook Query

```bash
nlm cross query "What features are discussed?" --notebooks "id1,id2"
nlm cross query "Compare approaches" --tags "ai,research"
nlm cross query "Summarize everything" --all              # Query ALL notebooks
```

---

## Pipelines

### Built-In Pipelines
```bash
nlm pipeline list                                         # List available pipelines
nlm pipeline run <notebook> ingest-and-podcast --url "https://..."
nlm pipeline run <notebook> research-and-report --url "https://..."
nlm pipeline run <notebook> multi-format                  # Audio + report + flashcards
```

### Custom Pipelines
Create custom pipelines by adding YAML files to `~/.notebooklm-mcp-cli/pipelines/`

---

## Chat Configuration

```bash
nlm chat configure <notebook> --goal default --length default
nlm chat configure <notebook> --goal learning_guide --length longer
nlm chat configure <notebook> --goal custom --prompt "You are an expert..."
```

---

## Configuration

### View & Modify Settings
```bash
nlm config show                         # Show all settings
nlm config get auth.default_profile     # Get a specific value
nlm config set auth.default_profile work  # Set default profile
nlm config set output.format json       # Change default output format
```

### Available Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `output.format` | table | Default output format (table, json) |
| `output.color` | true | Enable colored output |
| `output.short_ids` | true | Show shortened IDs |
| `auth.browser` | auto | Preferred browser for login (auto, chrome, arc, brave, edge, chromium, vivaldi, opera) |
| `auth.default_profile` | default | Profile to use when --profile not specified |

---

## Skills (AI Assistant Integration)

### Install Skills
```bash
nlm skill list                           # Show installation status
nlm skill install claude-code            # Install for Claude Code
nlm skill install cursor                 # Install for Cursor AI
nlm skill install <tool> --level project # Install at project level
nlm skill uninstall <tool>               # Remove skill
nlm skill show                           # View skill content
```

### Supported Tools
- `claude-code` - Claude Code
- `cursor` - Cursor AI
- `agents` - Generic agents
- `gemini-cli` - Google Gemini CLI
- `codex` - OpenAI Codex
- `opencode` - OpenCode
- `antigravity` - Antigravity
- `cline` - Cline
- `openclaw` - OpenClaw
- `alef-agent` - Alef Agent
- `other` - Other tools

---

## MCP Server Configuration

### Quick Setup
```bash
nlm setup add claude-code       # Configure via `claude mcp add`
nlm setup add gemini            # Write ~/.gemini/settings.json
nlm setup add cursor            # Write ~/.cursor/mcp.json
nlm setup add windsurf          # Write mcp_config.json
nlm setup add json              # Generate JSON config for any tool

nlm setup remove gemini         # Remove from Gemini CLI
nlm setup list                  # Show all clients and config status
```

### Supported Clients
- `claude-code` - Claude Code
- `gemini` - Google Gemini CLI
- `cursor` - Cursor AI
- `windsurf` - Windsurf
- `cline` - Cline
- `antigravity` - Antigravity
- `codex` - OpenAI Codex
- `opencode` - OpenCode

### Custom Configuration
```bash
nlm setup add json              # Generate JSON config snippet for any tool
```

---

## Diagnostics

### Run Diagnostics
```bash
nlm doctor              # Run all checks
nlm doctor --verbose    # Include additional details
```

### Checks Performed
- **Installation:** Package version, nlm and notebooklm-mcp binary paths
- **Authentication:** Profile status, cookies present, CSRF token, account email
- **Browser:** Chromium-based browser installed, saved profiles for headless auth
- **AI Tools:** MCP configuration status for each supported client

Each issue includes a suggested fix.

---

## Output Formats

| Flag | Format |
|------|--------|
| (none) | Rich table format |
| `--json` | JSON output |
| `--quiet` | IDs only |
| `--title` | "ID: Title" format |
| `--full` | All columns |

---

## Complete Workflow Example

```bash
# 1. Authenticate and configure
nlm login
nlm setup add claude-code       # One-time MCP setup

# 2. Create notebook and set alias
nlm notebook create "AI Research"
nlm alias set ai <notebook-id>

# 3. Add sources (with --wait to ensure ready)
nlm source add ai --url "https://example.com/article" --wait
nlm source add ai --file research.pdf --wait

# 4. Generate podcast
nlm audio create ai --format deep_dive --confirm

# 5. Wait for generation
nlm studio status ai

# 6. Download when ready
nlm download audio ai <artifact-id> --output podcast.mp3
```

---

## Pro Tips

- **Session Management:** Session lasts ~20 minutes; run `nlm login` if operations fail
- **Scripts:** Use `--confirm` for all create/delete commands in scripts
- **Source Readiness:** Use `--wait` when adding sources to ensure they're ready before querying
- **Frequently Used:** Use aliases for frequently-used notebooks
- **Generation Time:** Audio/video takes 1-5 minutes; poll with `nlm studio status`
- **Profile Switching:** Use `nlm login switch <name>` to change the default profile
- **Profile List:** Run `nlm login profile list` to see all profiles with their associated email addresses
- **Troubleshooting:** Run `nlm doctor` to diagnose installation, auth, or config issues
- **MCP Setup:** Use `nlm setup add <client>` to quickly configure MCP for your AI tool

---

## Important Notes

⚠️ **Disclaimer:** This CLI uses internal APIs that are undocumented and may change without notice. Not affiliated with or endorsed by Google. Use at your own risk for personal/experimental purposes.

---

## Resources

- **GitHub Repository:** https://github.com/jacob-bd/notebooklm-mcp-cli
- **PyPI Package:** https://pypi.org/project/notebooklm-mcp-cli/
- **Official CLI Guide:** https://github.com/jacob-bd/notebooklm-mcp-cli/blob/main/docs/CLI_GUIDE.md

---

**Status:** ✅ Active Knowledge Base  
**Last Updated:** April 12, 2026  
**Confidence Level:** High (Official Documentation)  
**Use Case:** Complete reference for NotebookLM CLI and MCP integration
