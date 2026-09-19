# pullall - fetch + fast-forward pull every repo listed in the per-PC repo list (Windows / PowerShell 5.1)
#
#   pullall.bat                 pull all repos in %USERPROFILE%\.ai-setup\repos.local.txt
#   pullall.bat -List <file>    use another list
#   pullall.bat -FetchOnly      only fetch and show how far behind each repo is (nothing is changed)
#
# List file: one repo folder per line, "#" starts a comment. It is per-PC and not committed.
# Safe by design: only "git pull --ff-only" on the current branch. Local changes are never stashed,
# reset or merged - if the pull cannot fast-forward (diverged, or local edits would be overwritten)
# the repo is reported as FAILED and left as it was.
param(
  [string]$List = (Join-Path $env:USERPROFILE '.ai-setup\repos.local.txt'),
  [switch]$FetchOnly
)

if (-not (Test-Path $List)) {
  Write-Host "Repo list not found: $List"
  Write-Host "Create it with one repo folder per line, e.g.:"
  Write-Host "  D:\private-ai\ai-setup"
  Write-Host "  D:\private-ai\web-tester"
  exit 1
}

$repos = Get-Content $List -Encoding UTF8 | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }
$rows = @()
$reinstall = $false

foreach ($p in $repos) {
  $name = Split-Path $p -Leaf
  Write-Host "== $name ($p)"
  if (-not (Test-Path (Join-Path $p '.git'))) {
    $rows += [pscustomobject]@{ Repo = $name; Branch = ''; Result = 'SKIP: not a git repo'; Dirty = '' }
    continue
  }
  $branch = (git -C $p rev-parse --abbrev-ref HEAD).Trim()
  $dirty = @(git -C $p status --porcelain).Count
  $fetch = git -C $p fetch --prune --quiet 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    $rows += [pscustomobject]@{ Repo = $name; Branch = $branch; Result = "FAILED fetch: $($fetch.Trim())"; Dirty = $dirty }
    continue
  }
  $upstream = git -C $p rev-parse --abbrev-ref '@{u}' 2>$null
  if (-not $upstream) {
    $rows += [pscustomobject]@{ Repo = $name; Branch = $branch; Result = 'SKIP: no upstream branch'; Dirty = $dirty }
    continue
  }
  $counts = (git -C $p rev-list --left-right --count "HEAD...@{u}").Trim() -split '\s+'
  $ahead = [int]$counts[0]; $behind = [int]$counts[1]
  $aheadNote = ''
  if ($ahead -gt 0) { $aheadNote = " ($ahead local commit(s) not pushed)" }

  if ($behind -eq 0) {
    $result = "up to date$aheadNote"
  } elseif ($FetchOnly) {
    $result = "behind $behind$aheadNote"
  } else {
    $out = git -C $p pull --ff-only --quiet 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
      $result = "pulled $behind commit(s)$aheadNote"
      if ((Test-Path (Join-Path $p 'install.bat')) -and (Test-Path (Join-Path $p 'AGENTS.global.md'))) { $reinstall = $p }
    } else {
      $msg = ($out -split "`r?`n" | Where-Object { $_ -match 'error|fatal|hint: Diverging' } | Select-Object -First 2) -join ' / '
      if (-not $msg) { $msg = $out.Trim() }
      $result = "FAILED pull (behind $behind): $msg"
    }
  }
  $rows += [pscustomobject]@{ Repo = $name; Branch = $branch; Result = $result; Dirty = $dirty }
}

$rows | Format-Table -AutoSize -Wrap
if ($reinstall) { Write-Host "ai-setup was updated -> run `"$reinstall\install.bat`" to copy the new rules/skills." }
