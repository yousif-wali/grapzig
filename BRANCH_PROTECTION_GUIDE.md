# 🔒 Branch Protection Setup Guide

## Quick Setup (5 minutes)

### Step 1: Navigate to Settings

1. Go to: https://github.com/yousif-wali/grapzig/settings/branches
2. Click **"Add branch protection rule"**

### Step 2: Configure Protection

**Branch name pattern:** `master`

### ✅ Recommended Settings

#### 1. Require Pull Requests
```
☑️ Require a pull request before merging
   ☑️ Require approvals: 1
   ☑️ Dismiss stale pull request approvals when new commits are pushed
   ☑️ Require review from Code Owners
```

**Why:** Forces all changes to go through PR review process

#### 2. Require Status Checks
```
☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging
   Status checks (after CI is set up):
   - test (ubuntu-latest)
   - test (macos-latest)
   - test (windows-latest)
   - lint
```

**Why:** Ensures all tests pass before merging

#### 3. Conversation Resolution
```
☑️ Require conversation resolution before merging
```

**Why:** All review comments must be addressed

#### 4. Restrict Pushes
```
☑️ Restrict who can push to matching branches
   Add: yousif-wali (only you)
```

**Why:** Prevents direct pushes - everyone must use PRs (including you!)

#### 5. Linear History
```
☑️ Require linear history
```

**Why:** Keeps git history clean and easy to follow

#### 6. Admin Enforcement
```
☑️ Do not allow bypassing the above settings
```

**Why:** Even admins must follow the rules

### Step 3: Save

Click **"Create"** or **"Save changes"**

---

## 🚀 What This Achieves

### Before Protection
```
❌ Anyone can push directly to master
❌ No review required
❌ Tests can be skipped
❌ Messy git history
```

### After Protection
```
✅ All changes via Pull Requests
✅ Requires 1 approval
✅ All tests must pass
✅ Code owner review required
✅ Clean linear history
✅ No direct pushes (even by you!)
```

---

## 📋 Workflow After Protection

### For Contributors

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** changes
4. **Push** to their fork
5. **Open** a Pull Request
6. **Wait** for CI to pass
7. **Address** review comments
8. **Get** approval
9. **Merge** (if they have permission) or wait for maintainer

### For You (Maintainer)

1. **Create** a feature branch (not master)
2. **Make** changes
3. **Push** branch
4. **Open** PR (even for your own changes!)
5. **Wait** for CI
6. **Review** and approve (or get someone else to)
7. **Merge** via GitHub

**Example:**
```bash
git checkout -b feature/add-subscriptions
# make changes
git push origin feature/add-subscriptions
# Open PR on GitHub
```

---

## 🔧 CI/CD Setup (Already Done!)

The `.github/workflows/ci.yml` file is already created. After you push it:

1. Go to: https://github.com/yousif-wali/grapzig/actions
2. You'll see CI running on every PR
3. Add these status checks to branch protection:
   - `test (ubuntu-latest)`
   - `test (macos-latest)`
   - `test (windows-latest)`
   - `lint`

---

## 📝 Additional Files Created

### 1. `.github/workflows/ci.yml`
- Runs tests on Ubuntu, macOS, Windows
- Checks code formatting
- Runs on every push and PR

### 2. `CODEOWNERS`
- Automatically requests your review on all PRs
- Ensures you're notified of all changes

### 3. `SECURITY.md`
- Security policy for vulnerability reporting
- Best practices for users

---

## 🎯 Testing the Protection

After setting up, try this:

```bash
# This should FAIL (direct push blocked)
echo "test" >> README.md
git add README.md
git commit -m "test"
git push origin master
# Error: protected branch hook declined

# This is the CORRECT way
git checkout -b test-branch
echo "test" >> README.md
git add README.md
git commit -m "test"
git push origin test-branch
# Then open PR on GitHub
```

---

## 🔐 Security Levels

### Level 1: Basic (Recommended for now)
```
✅ Require PR
✅ Require 1 approval
✅ Require status checks
✅ Restrict pushes
```

### Level 2: Moderate (For growing projects)
```
✅ Everything from Level 1
✅ Require signed commits
✅ Require 2 approvals
✅ Require code owner review
```

### Level 3: Strict (For critical projects)
```
✅ Everything from Level 2
✅ Require deployments to succeed
✅ Lock branch (read-only)
✅ Require specific status checks
```

**Start with Level 1** - you can always increase security later!

---

## 🤝 Managing Contributors

### Giving Someone Merge Access

1. Go to: https://github.com/yousif-wali/grapzig/settings/access
2. Click **"Add people"**
3. Choose role:
   - **Write**: Can merge PRs
   - **Maintain**: Can manage issues + merge
   - **Admin**: Full access (be careful!)

### Recommended Roles

- **Trusted contributors**: Write access
- **Co-maintainers**: Maintain access
- **You**: Admin (owner)

---

## 📊 Monitoring

### What to Watch

1. **Pull Requests**: https://github.com/yousif-wali/grapzig/pulls
2. **Issues**: https://github.com/yousif-wali/grapzig/issues
3. **Actions**: https://github.com/yousif-wali/grapzig/actions
4. **Insights**: https://github.com/yousif-wali/grapzig/pulse

### Enable Notifications

1. Go to: https://github.com/yousif-wali/grapzig
2. Click **Watch** → **All Activity**
3. Configure email preferences in GitHub settings

---

## 🚨 Emergency: Temporarily Disable Protection

If you need to make an urgent fix:

1. Go to branch protection settings
2. **Uncheck** "Do not allow bypassing"
3. Make your fix
4. **Re-enable** immediately after

**Better approach:** Create a hotfix branch and fast-track the PR!

---

## ✅ Checklist

After setup, verify:

- [ ] Branch protection rule created for `master`
- [ ] PR required before merging
- [ ] At least 1 approval required
- [ ] Status checks configured (after CI runs once)
- [ ] Direct pushes blocked
- [ ] CODEOWNERS file in repository
- [ ] CI workflow file pushed
- [ ] Security policy in place
- [ ] Tested by trying to push directly (should fail)

---

## 🎉 You're Secure!

Your `master` branch is now protected. Contributors must:
1. Fork or create branches
2. Open Pull Requests
3. Pass CI tests
4. Get your approval
5. Then merge

**No more accidental direct pushes!** 🔒

---

## 📚 Resources

- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Code Owners Docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

---

**Made with 🔒 for secure open source!**
