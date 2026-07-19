# AI API

## Purpose
Generate and manage AI-driven content improvements.

## Authentication
Bearer Token

## Endpoint
POST /api/ai/compose

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
  "prompt": "Rewrite this post in a more engaging tone",
  "context": "Campaign for summer launch"
}
```

## Validation
- prompt: required
- context: optional

## Success Response
```json
{
  "success": true,
  "message": "AI content generated.",
  "data": {
    "text": "Improved marketing copy"
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "AI service unavailable.",
  "data": {},
  "meta": {},
  "errors": ["SP8001"]
}
```

## Permissions
- workspace member

## Notes
AI operations should be logged in ai_requests for traceability.
