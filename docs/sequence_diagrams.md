# Sequence Diagrams

## Post Publishing Flow
```text
Flutter
  -> Laravel API: create post
Laravel API -> Database: store draft
Laravel API -> Queue: create publish job
Queue -> Facebook API: publish content
Facebook API -> Webhook: delivery event
Webhook -> Database: update analytics and status
Database -> Flutter Notification: notify user
```

## Retry Flow
```text
Queue
  -> Platform API: publish attempt
Platform API -> Queue: transient failure
Queue -> Queue: retry after backoff
Queue -> Dead Letter Queue: after max retries
```
