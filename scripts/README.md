# Scripts Directory

Thư mục chứa các utility và test scripts cho development.

## Cấu trúc:

```
scripts/
├── utils/          # Development utilities
│   ├── update-sha256.ps1           # Manual SHA256 hash updater
│   ├── install-git-hooks.ps1       # Git hooks installer
│   ├── create-manifest.ps1         # Create file manifest
│   └── verify-manifest.ps1         # Verify all files
│
└── tests/          # Testing scripts
    ├── verify-hash.ps1             # Verify local hash
    ├── verify-github-hash.ps1      # Compare local vs GitHub
    ├── check-github-sync.ps1       # Check GitHub sync status
    └── simulate-quick-install.ps1  # End-to-end simulation
```

## Quick Reference:

### Development Utils (`utils/`)

- **update-sha256.ps1** - Update SHA256 hash manually
- **install-git-hooks.ps1** - Setup Git hooks (run once)
- **create-manifest.ps1** - Create hash manifest for all files
- **verify-manifest.ps1** - Verify all files integrity

### Testing Scripts (`tests/`)

- **verify-hash.ps1** - Verify local file hash
- **verify-github-hash.ps1** - Compare local vs GitHub
- **check-github-sync.ps1** - Verify GitHub repository sync
- **simulate-quick-install.ps1** - Simulate user download & verify

---

**Note:** All scripts trong thư mục này được ignore trong `.gitignore` (local development only).

Xem [docs/AUTOMATION-README.md](../docs/AUTOMATION-README.md) để biết chi tiết sử dụng.
