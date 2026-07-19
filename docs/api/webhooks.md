# Webhooks API

## Purpose
Receive platform delivery and engagement updates.

## Authentication
Signature header or shared secret.

## Endpoint
POST /api/webhooks/{platform}

## Method
POST

## Headers
```http
X-Signature: sha256=...
Content-Type: application/json
```

## Request
```json
{
  "event": "publish.completed",
  "post_id": 15,
  "platform": "facebook"
}
```

## Validation
- signature: required
- event: known event type
- platform: supported platform identifier

## Success Response
```json
{
  "success": true,
  "message": "Webhook processed.",
  "data": {},
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Invalid signature.",
  "data": {},
  "meta": {},
  "errors": ["SP9001"]
}
```

## Permissions
- platform webhook provider

## Notes
These webhooks should update analytics and publish states.
