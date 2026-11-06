# Free checks for the context plugin. No credential, no model calls, no cost.
# Run from anywhere: .\scripts\check.ps1
Set-Location (Join-Path $PSScriptRoot '..')
$fail = 0

Write-Output "== claude plugin validate --strict =="
claude plugin validate . --strict
if ($LASTEXITCODE -ne 0) { $fail = 1 }

Write-Output ""
Write-Output "== plugin directory profile (informational, not blocking) =="
# --profile directory --strict currently fails on ICON_MISSING, which needs a
# human-made square PNG and is locked in at first submission. See
# docs/token-budget.md for what is and is not enforced here.
claude plugin validate . --profile directory

Write-Output ""
Write-Output "== always-loaded budget =="
# Only each skill's name and description are loaded on every request; the SKILL.md
# bodies and everything under references/ load on demand. The ceiling is a
# regression guard, not a hard limit from the runtime.
$ceiling = 1200
$total = 0
foreach ($dir in Get-ChildItem skills -Directory) {
    $path = Join-Path $dir.FullName 'SKILL.md'
    $head = [System.IO.File]::ReadAllLines($path) | Select-Object -First 10
    $chars = 0
    foreach ($line in $head) {
        # UTF-8 bytes plus the newline — matches check.sh exactly. Counting
        # $line.Length instead would undercount every em dash by two.
        if ($line -match '^(name|description):') {
            $chars += [System.Text.Encoding]::UTF8.GetByteCount($line) + 1
        }
    }
    Write-Output ("  {0,-24} {1,5} chars" -f "skills/$($dir.Name)/SKILL.md", $chars)
    $total += $chars
}
Write-Output ("  {0,-24} {1,5} chars (~{2} tokens), ceiling {3}" -f 'total', $total, [math]::Floor($total / 4), $ceiling)
if ($total -gt $ceiling) {
    Write-Output "  FAIL: always-loaded frontmatter is over the ceiling; shorten a description or raise the ceiling deliberately."
    $fail = 1
}

Write-Output ""
if ($fail -eq 0) { Write-Output "All checks passed." } else { Write-Output "Checks failed." }
exit $fail
