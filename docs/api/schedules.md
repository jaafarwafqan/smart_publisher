# Schedules API

## Purpose
Create and manage scheduled publishing operations.

## Authentication
Bearer Token

## Endpoint
POST /api/schedules

## Method
POST

## Headers
```http
Authorization: Bearer xxxx
Content-Type: application/json
```

## Request
```json
{
  "post_id": 15,
  "publish_at": "2026-08-15T10:00:00Z"
}
```

## Validation
- post_id: required
- publish_at: required, future date

## Success Response
```json
{
  "success": true,
  "message": "Schedule created.",
  "data": {
    "id": 7,
    "status": "scheduled"
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Invalid schedule time.",
  "data": {},
  "meta": {},
  "errors": ["SP5001"]
}
```

## Permissions
- workspace editor or above

## Notes
Scheduled posts should be evaluated by the queue worker.
