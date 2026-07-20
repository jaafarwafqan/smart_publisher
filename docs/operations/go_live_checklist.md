# Go-Live Checklist

## Pre-Launch (T-24h)
- [ ] CI pipeline green on `main`
- [ ] Release pipeline dry-run completed
- [ ] Required GitHub secrets configured
- [ ] Feature flags verified for release channel
- [ ] Rollback tag validated

## Launch Window
- [ ] Trigger release workflow with correct channel
- [ ] Confirm release manifest generated
- [ ] Confirm Android artifact distributed
- [ ] Confirm web package generated/deployed
- [ ] Start canary at agreed percentage

## Post-Launch (First 60 min)
- [ ] Monitor HTTP error rate
- [ ] Monitor publish queue failures and retries
- [ ] Monitor auth refresh success rate
- [ ] Confirm crash-free sessions threshold

## Rollback Triggers
- [ ] Error budget burn breach
- [ ] Queue failures > threshold
- [ ] Critical auth failures regression

## Sign-off
- [ ] Engineering Lead
- [ ] QA Lead
- [ ] Product Owner
- [ ] Operations Lead
