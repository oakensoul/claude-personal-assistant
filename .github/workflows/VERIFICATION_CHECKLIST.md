---
title: "Workflow Verification Checklist"
description: "Step-by-step checklist for verifying GitHub Actions workflows"
category: "ci-cd"
tags: ["github-actions", "testing", "verification", "checklist"]
last_updated: "2025-10-18"
status: "published"
audience: "developers"
---

# Workflow Verification Checklist

Use this checklist to verify the `test-installer.yml` workflow implementation.

## Pre-Push Verification

### 1. YAML Validation

```bash
# Validate workflow syntax
python3 -m yamllint --strict .github/workflows/test-installer.yml
```

**Expected:** No errors or warnings

- [ ] YAML is valid
- [ ] No document-start warnings
- [ ] No line-length warnings

### 2. Dockerfile Validation

```bash
# Verify Dockerfiles exist
ls -l .github/testing/Dockerfile.*

# Test building one image
docker build -t aida-test:ubuntu-22.04 \
  -f .github/testing/Dockerfile.ubuntu-22.04 \
  .github/testing/
```

**Expected:** Build succeeds, image created

- [ ] All 3 Dockerfiles exist
- [ ] ubuntu-22.04 builds successfully
- [ ] ubuntu-24.04 builds successfully
- [ ] debian-12 builds successfully

### 3. Documentation Review

```bash
# Check all docs have frontmatter
head -10 .github/workflows/README.md
head -10 .github/workflows/QUICK_REFERENCE.md
head -10 .github/workflows/examples/test-results-example.md
head -10 .github/workflows/IMPLEMENTATION_SUMMARY.md
```

**Expected:** All start with `---` frontmatter

- [ ] README.md has frontmatter and updated content
- [ ] QUICK_REFERENCE.md complete
- [ ] test-results-example.md complete
- [ ] IMPLEMENTATION_SUMMARY.md complete

### 4. Local Test Execution

```bash
# Verify tests still pass
make test-unit
make test-integration
```

**Expected:** All tests pass

- [ ] Unit tests pass (168 tests)
- [ ] Integration tests pass (18 tests)
- [ ] No new failures introduced

## Post-Push Verification

### 5. Workflow Triggers

```bash
# Push to branch
git add .github/workflows/ .github/testing/
git commit -m "feat: Add comprehensive GitHub Actions testing workflow"
git push origin HEAD
```

**Expected:** Workflow triggered automatically

- [ ] Commit pushed successfully
- [ ] Workflow appears in Actions tab
- [ ] All jobs start executing

### 6. Job Execution

**Monitor in GitHub Actions UI:**

**Stage 1: Lint & Validation**

- [ ] lint-shell completes successfully
- [ ] validate-templates completes successfully

**Stage 2: Unit Tests**

- [ ] ubuntu-22.04 completes (~1-2 min)
- [ ] ubuntu-24.04 completes (~1-2 min)
- [ ] macos-13 completes (~2-3 min)
- [ ] macos-14 completes (~2-3 min)

**Stage 3: Integration Tests**

- [ ] fresh-install scenario passes (~1-2 min)
- [ ] upgrade-v0.1 scenario passes (~1-2 min)
- [ ] upgrade-with-content scenario passes (~1-2 min)

**Stage 4: Installation Tests**

- [ ] ubuntu-22.04 normal mode passes
- [ ] ubuntu-22.04 dev mode passes
- [ ] macos-13 normal mode passes
- [ ] macos-13 dev mode passes

**Stage 5: Docker Tests**

- [ ] ubuntu-22.04 container tests pass
- [ ] ubuntu-24.04 container tests pass
- [ ] debian-12 container tests pass

**Stage 6: Coverage**

- [ ] Coverage analysis completes
- [ ] Report generated

**Stage 7: Test Summary**

- [ ] All results aggregated
- [ ] Overall status determined

**Stage 8: PR Comment** (if PR)

- [ ] Comment posted to PR
- [ ] Formatting correct
- [ ] Links work

### 7. Artifact Verification

**Download artifacts from workflow run:**

```bash
gh run list --workflow=test-installer.yml --limit=1
gh run download <run-id>
```

**Check artifacts exist:**

- [ ] unit-test-results-ubuntu-22.04/
- [ ] unit-test-results-ubuntu-24.04/
- [ ] unit-test-results-macos-13/
- [ ] unit-test-results-macos-14/
- [ ] integration-test-results-*/
- [ ] integration-test-logs-*/
- [ ] installation-logs-*/
- [ ] docker-test-logs-*/
- [ ] coverage-report/

### 8. Execution Time

**Verify performance:**

- [ ] Total execution time < 10 minutes
- [ ] Unit tests complete in ~2-3 minutes
- [ ] Integration tests complete in ~2 minutes
- [ ] Installation tests complete in ~3 minutes
- [ ] Docker tests complete in ~3 minutes

## Pull Request Verification

### 9. Create Test PR

```bash
# Open PR to trigger workflow
gh pr create --title "Test: Verify workflow implementation" \
  --body "Testing new test-installer.yml workflow"
```

**Expected:** Workflow runs, comment appears

- [ ] PR created successfully
- [ ] Workflow triggered
- [ ] All checks run
- [ ] Status checks show in PR

### 10. PR Comment Verification

**Check comment appears with:**

- [ ] Test summary table
- [ ] Stage-by-stage status (✅/❌)
- [ ] Overall status
- [ ] Link to detailed logs
- [ ] Correct formatting

**Example expected comment:**

```markdown
## 🧪 Installer Test Results

| Stage | Status |
|-------|--------|
| Shell Linting | ✅ |
| Template Validation | ✅ |
| Unit Tests | ✅ |
| Integration Tests | ✅ |
| Installation Tests | ✅ |
| Docker Tests | ✅ |

**Overall Status:** ✅ All tests passed!

[View detailed logs](...)
```

### 11. Status Checks

**In PR UI, verify:**

- [ ] "Installer Tests" check appears
- [ ] Check shows as required (if configured)
- [ ] Check passes/fails correctly
- [ ] Can click to view details

## Troubleshooting

### If Workflow Doesn't Trigger

**Check:**

1. Path filters - did you modify `lib/`, `tests/`, or `install.sh`?
2. Branch name - is it `main` or `milestone-*`?
3. Workflow syntax - any YAML errors?

**Debug:**

```bash
# View workflow runs
gh run list --workflow=test-installer.yml

# Check workflow file
yamllint --strict .github/workflows/test-installer.yml
```

### If Jobs Fail

**Check:**

1. Download artifacts for error logs
2. View job logs in GitHub Actions UI
3. Run tests locally: `make test-all`
4. Test in Docker: See QUICK_REFERENCE.md

**Debug:**

```bash
# Download artifacts
gh run download <run-id>

# View specific job logs
gh run view <run-id> --job=<job-id> --log

# Run same test locally
make test-unit
```

### If PR Comment Doesn't Appear

**Check:**

1. Workflow permissions (pull-requests: write)
2. GitHub token has correct permissions
3. pr-comment job ran successfully
4. Comment not hidden/minimized in PR

**Debug:**

```bash
# View pr-comment job logs
gh run view <run-id> --job=pr-comment --log
```

### If Execution is Slow

**Check:**

1. Matrix jobs running in parallel?
2. Docker layer caching working?
3. Any jobs hanging/timing out?

**Optimize:**

```bash
# Check execution time per job
gh run view <run-id>

# Look for slow jobs
# Consider: reducing matrix, skip unnecessary platforms
```

## Manual Testing Commands

### Test Individual Stages

```bash
# Stage 1: Lint
make lint
./scripts/validate-templates.sh --verbose

# Stage 2: Unit tests
make test-unit

# Stage 3: Integration tests
make test-integration

# Stage 4: Installation tests
echo -e "testassistant\n1\n" | ./install.sh
echo -e "testassistant\n1\n" | ./install.sh --dev

# Stage 5: Docker tests
docker build -t test -f .github/testing/Dockerfile.ubuntu-22.04 .github/testing/
docker run --rm -v $(pwd):/workspace -w /workspace test make test-all

# Stage 6: Coverage
make test-coverage
```

### Test in Docker (Matches CI)

```bash
# Build test image
docker build -t aida-test:ubuntu-22.04 \
  -f .github/testing/Dockerfile.ubuntu-22.04 \
  .github/testing/

# Run unit tests
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  aida-test:ubuntu-22.04 \
  make test-unit

# Run full suite
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  aida-test:ubuntu-22.04 \
  make test-all

# Test installation
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  aida-test:ubuntu-22.04 \
  bash -c 'echo -e "testassistant\n1\n" | ./install.sh'
```

## Final Checklist

### Pre-Merge

- [ ] All workflows pass
- [ ] All platforms tested
- [ ] PR comment works
- [ ] Artifacts generated
- [ ] Documentation reviewed
- [ ] No regressions introduced

### Post-Merge

- [ ] Main branch workflow passes
- [ ] Future PRs trigger correctly
- [ ] Status badges updated (if added)
- [ ] Team notified of new workflow

## Success Criteria

**All these should be true:**

- ✅ Workflow executes in < 10 minutes
- ✅ All matrix jobs pass
- ✅ Artifacts uploaded correctly
- ✅ PR comment appears and is correct
- ✅ No false positives/negatives
- ✅ Documentation accurate

## Notes

**Record any issues encountered:**

```text
Issue 1: [Description]
Fix: [Solution]

Issue 2: [Description]
Fix: [Solution]
```

**Performance observations:**

```text
Actual execution time: [X] minutes
Slowest job: [job-name] ([X] minutes)
Optimization opportunities: [notes]
```

---

**Verification Date:** _______________
**Verified By:** _______________
**Status:** ☐ Pass ☐ Fail ☐ Needs Work

**Notes:**

```text




```
