# Automation Tools - VSBTek Chocolatey Installer

Bộ công cụ tự động hóa để maintain và verify dự án.

## 📋 Danh sách công cụ

**Lưu ý:** Tất cả scripts nằm trong thư mục `scripts/`. Các scripts này chỉ dùng cho development và không được commit lên Git.

### Development Utilities (`scripts/utils/`)

#### 1. **update-sha256.ps1** - Cập nhật SHA256 hash thủ công

Tính toán và cập nhật SHA256 hash cho `install-apps.ps1`.

**Sử dụng:**
```powershell
.\scripts\utils\update-sha256.ps1
```

**Khi nào dùng:**
- Sau khi modify `install-apps.ps1`
- Trước khi commit changes
- Khi muốn verify hash đang đúng

---

#### 2. **install-git-hooks.ps1** - Cài đặt Git hooks tự động

Setup pre-commit hook tự động update SHA256 hash.

**Sử dụng:**
```powershell
.\scripts\utils\install-git-hooks.ps1
```

**Chỉ cần chạy 1 lần!** Hook sẽ tự động:
- Detect khi `install-apps.ps1` được staged
- Calculate hash mới (LF line endings)
- Update `install-apps.ps1.sha256`
- Stage file `.sha256` vào cùng commit

**Hoặc dùng quick setup:**
```powershell
.\setup-dev.ps1  # Tự động install hooks + verify structure
```

---

### Testing Scripts (`scripts/tests/`)

#### 3. **verify-hash.ps1** - Verify local hash

Kiểm tra hash của file local có khớp với `.sha256` file không.

**Sử dụng:**
```powershell
.\scripts\tests\verify-hash.ps1
```

---

#### 4. **verify-github-hash.ps1** - So sánh local vs GitHub

Kiểm tra xem local file có match với file trên GitHub không.

**Sử dụng:**
```powershell
.\scripts\tests\verify-github-hash.ps1
```

---

#### 5. **check-github-sync.ps1** - Verify GitHub repository sync

Kiểm tra xem file `install-apps.ps1` và `.sha256` trên GitHub có đồng bộ không.

**Sử dụng:**
```powershell
.\scripts\tests\check-github-sync.ps1
```

**Khi nào dùng:**
- Sau khi push lên GitHub
- Để verify SHA256 verification sẽ work cho users

---

#### 6. **simulate-quick-install.ps1** - Simulate user download

Mô phỏng chính xác những gì xảy ra khi user chạy quick-install.

**Sử dụng:**
```powershell
.\scripts\tests\simulate-quick-install.ps1
```

**Test được:**
- Download từ GitHub
- SHA256 verification process
- Xem kết quả PASS hay FAIL

---

## 🔄 Workflow khuyên dùng

### Cài đặt lần đầu:

**Option 1: Quick setup (khuyên dùng)**
```powershell
# Chạy setup script - tự động cài hooks + verify structure
.\setup-dev.ps1
```

**Option 2: Manual setup**
```powershell
# Install Git hooks (chỉ cần 1 lần)
.\scripts\utils\install-git-hooks.ps1
```

### Khi modify install-apps.ps1:

```powershell
# 1. Edit install-apps.ps1 như bình thường
# 2. Stage changes
git add install-apps.ps1

# 3. Commit (hook sẽ tự động update hash!)
git commit -m "feat: Add new feature"

# 4. Push
git push
```

**Bạn không cần manual update hash!** Git hook làm tự động.

### Nếu muốn manual update:

```powershell
# Update hash thủ công
.\scripts\utils\update-sha256.ps1

# Verify local
.\scripts\tests\verify-hash.ps1

# Stage và commit
git add install-apps.ps1.sha256
git commit -m "chore: Update SHA256 hash"
```

### Verify trước khi push:

```powershell
# Verify local files OK
.\scripts\tests\verify-hash.ps1

# (Optional) Sau khi push, verify GitHub sync
.\scripts\tests\check-github-sync.ps1

# Test end-to-end như user sẽ thấy
.\scripts\tests\simulate-quick-install.ps1
```

---

## 🔐 Tại sao cần SHA256 hash?

**Vấn đề:** GitHub serve raw files với LF line endings, nhưng Windows local có CRLF.

**Giải pháp:** Tính hash với LF endings (match với GitHub).

**Automation giải quyết:**
- ✅ Tự động convert CRLF → LF
- ✅ Tính hash chính xác
- ✅ Không bao giờ quên update
- ✅ SHA256 verification hoạt động 100%

---

## ⚠️ Lưu ý

1. **Git hooks** không được commit vào repo (nằm trong `.git/hooks/`)
2. **Utility scripts** này được ignore trong `.gitignore`
3. Chỉ **install-apps.ps1.sha256** được track trong Git
4. Hook chỉ chạy khi `install-apps.ps1` được staged

---

## 🐛 Troubleshooting

### Hook không chạy?

```powershell
# Re-install hook
.\scripts\utils\install-git-hooks.ps1
# Chọn 'y' để overwrite

# Test
git add install-apps.ps1
git commit -m "test"
# Phải thấy message "Auto-updating SHA256 hash..."
```

### Hash sai?

```powershell
# Manual update
.\scripts\utils\update-sha256.ps1

# Verify
.\scripts\tests\verify-hash.ps1
```

### GitHub sync fail?

```powershell
# Check sync status
.\scripts\tests\check-github-sync.ps1

# Nếu out of sync, update và push:
.\scripts\utils\update-sha256.ps1
git add install-apps.ps1.sha256
git commit -m "chore: Fix SHA256 hash"
git push

# Wait 30 seconds cho GitHub CDN cache invalidate
# Rồi check lại
.\scripts\tests\check-github-sync.ps1
```

---

## ❓ FAQ

### Tại sao chỉ hash install-apps.ps1, không hash các file khác?

**Lý do:**

1. **Quick-install workflow** chỉ download và verify `install-apps.ps1`:
   ```
   User → quick-install.ps1 → Download install-apps.ps1 + .sha256
                            → Verify hash
                            → Execute
   ```

2. **Config files** (JSON) được load BỞI `install-apps.ps1`, không được download riêng
3. Chỉ cần verify file được execute từ internet (security boundary)

### Nếu tôi sửa config files thì sao?

**Không cần update hash!**

Config files không ảnh hưởng đến `install-apps.ps1` hash. Chúng được:
- Load runtime bởi `install-apps.ps1`
- Track bởi Git (version control)
- Không cần cryptographic verification riêng

### Nếu tôi muốn verify TẤT CẢ files?

**Optional: Manifest verification**

Nếu muốn paranoid security level:

```powershell
# 1. Tạo manifest cho tất cả files
.\create-manifest.ps1

# 2. Verify tất cả files
.\verify-manifest.ps1
```

Manifest sẽ hash tất cả files quan trọng:
- install-apps.ps1
- quick-install.ps1
- All config JSON files

**Lưu ý:** Đây là optional, không bắt buộc cho normal workflow.

---

**Tạo bởi:** Claude Code
**Mục đích:** Đảm bảo SHA256 verification luôn hoạt động 100% cho users
