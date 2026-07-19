# Publish State Machine

## States
- draft
- editing
- processingAi
- processingMedia
- queued
- publishing
- published
- partialSuccess
- retrying
- failed
- cancelled
- archived

## Allowed Transitions
```text
draft -> editing
editing -> processingAi
editing -> processingMedia
processingAi -> queued
processingMedia -> queued
queued -> publishing
publishing -> published
publishing -> partialSuccess
publishing -> retrying
retrying -> queued
retrying -> failed
published -> archived
partialSuccess -> archived
failed -> archived
cancelled -> archived
```

## Rules
- direct transition from draft to published is not allowed.
- retrying can only happen after a publish attempt fails.
- archived is terminal for completed, failed, or cancelled jobs.
