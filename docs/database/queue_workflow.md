# Queue Workflow

## Queue States
- Pending
- Reserved
- Processing
- Completed
- Retry
- Dead Letter Queue

## Flow
```text
Create Job
-> Pending
-> Reserved
-> Processing
-> Completed
-> Retry
-> Dead Letter Queue
```

## Rules
- jobs must not be treated as simple queued items.
- retries should be handled by the queue worker with backoff.
- dead-letter should capture terminal failures for inspection.
