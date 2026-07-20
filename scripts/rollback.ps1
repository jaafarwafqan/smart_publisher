param(
  [Parameter(Mandatory = $true)]
  [string]$TargetReleaseTag,

  [Parameter(Mandatory = $false)]
  [ValidateSet('stable', 'canary')]
  [string]$Channel = 'stable'
)

Write-Host "Starting rollback procedure..."
Write-Host "Target release tag: $TargetReleaseTag"
Write-Host "Channel: $Channel"

Write-Host "Step 1: Freeze deployments"
Write-Host "Step 2: Set canary percent to 0"
Write-Host "Step 3: Disable canary feature flags"
Write-Host "Step 4: Promote previous stable artifacts"
Write-Host "Step 5: Run smoke checks (auth, post, media, publish)"

Write-Host "Rollback checklist completed. Follow docs/operations/rollback_strategy.md for verification."
