# Posts API

## Purpose
Create and manage publishing drafts and posts.

## Authentication
Bearer Token

## Endpoint
POST /api/posts

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
  "title": "Summer Campaign",
  "content": "Hello world",
  "attachments": [15, 16],
  "platforms": ["facebook", "telegram"],
  "scheduled_at": "2026-08-15T10:00:00Z"
}
```

## Validation
- title: required, max 255
- content: required
- platforms: array of supported platform identifiers
- scheduled_at: ISO 8601 when present

## Success Response
```json
{
  "success": true,
  "message": "Post created.",
  "data": {
    "id": 15,
    "status": "draft"
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Validation failed.",
  "data": {},
  "meta": {},
  "errors": ["SP2001"]
}
```

## Permissions
- workspace member

## Notes
The post is created as a draft first and can later be queued for publishing.
