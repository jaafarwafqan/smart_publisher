# Notifications API

## Purpose
Expose in-app notifications for publishing events.

## Authentication
Bearer Token

## Endpoint
GET /api/notifications

## Method
GET

## Headers
```http
Authorization: Bearer xxxx
Content-Type: application/json
```

## Request
None

## Validation
- user must be authenticated

## Success Response
```json
{
  "success": true,
  "message": "Notifications retrieved.",
  "data": [
    {
      "id": 3,
      "title": "Publish failed",
      "body": "Post 15 failed on Facebook.",
      "read": false
    }
  ],
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Unauthorized.",
  "data": {},
  "meta": {},
  "errors": ["SP7001"]
}
```

## Permissions
- authenticated user

## Notes
Notifications can be triggered by failed publish jobs or successful publication.
