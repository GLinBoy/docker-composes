# Guidelines for AI Assistants

This document provides essential guidance for AI assistants contributing to this repository.

## Important

**Before contributing, AI assistants MUST read and follow:**

1. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Complete contribution guidelines, Docker Compose conventions, file structure, healthchecks, security requirements, and testing procedures
2. **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community standards and behavior expectations

## Key Reminders

### Restart Policy

**DO NOT add `restart: unless-stopped`** or any restart policy unless explicitly requested. Containers should stop when the host system restarts to save resources.

### File Naming

- Compose folders: lowercase, hyphenated (e.g., `my-service/`)
- Always include: `docker-compose.yml`, `.env.example`, `README.md`

### README Updates

When adding new compose files, add an entry to the root [README.md](README.md) in **alphabetical order** following the existing format:
```markdown
- [Service Name](folder/) ([website](https://example.com))
```

## Quick Reference

For detailed conventions, see [CONTRIBUTING.md](CONTRIBUTING.md) section:
- Docker Compose Conventions (file structure, service order, healthchecks, image versioning, etc.)
- Adding a New Stack
- Testing Locally
- Quick Reference Checklist