# Publishing Workflow Specification

## Main States

1. Draft
2. Processing
3. Queued
4. Publishing
5. Success
6. Failed
7. Cancelled

## Workflow

```text
Create Draft
  -> AI Rewrite
  -> Attach Media
  -> Compress Media
  -> Select Platforms
  -> Schedule
  -> Create Publish Job
  -> Queue
  -> Publishing
  -> Success
  -> Retry
  -> Completed
```

## State Rules

- Draft: initial local state before validation.
- Processing: AI rewrite or media processing is running.
- Queued: job accepted and waiting for execution.
- Publishing: actual platform publishing in progress.
- Success: publish completed successfully.
- Failed: permanent failure or max retries exceeded.
- Cancelled: user cancelled or schedule removed.

## Retry Policy

- Maximum retries: 3
- Retry interval: 5 minutes
- Retry only for transient errors such as rate limits or network failures.
