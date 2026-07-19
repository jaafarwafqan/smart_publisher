# Publish API

## Purpose
Create and manage publish jobs for posts.

## Authentication
Bearer Token

## Endpoint
POST /api/publish/jobs

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
  "platforms": ["facebook", "telegram"],
  "schedule_at": null
}
```

## Validation
- post_id: required
- platforms: at least one supported platform
- schedule_at: optional ISO 8601 value

## Success Response
```json
{
  "success": true,
  "message": "Publish job created.",
  "data": {
    "id": 88,
    "status": "queued"
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Publishing failed.",
  "data": {},
  "meta": {},
  "errors": ["SP4001"]
}
```

## Permissions
- workspace editor or above

## Notes
The publish queue will manage pending, reserved, processing, retry, and dead-letter states.
