# Analytics API

## Purpose
Return publishing and engagement analytics for posts.

## Authentication
Bearer Token

## Endpoint
GET /api/analytics/posts/{post_id}

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
- post_id: required
- user must have access to that post

## Success Response
```json
{
  "success": true,
  "message": "Analytics retrieved.",
  "data": {
    "post_id": 15,
    "impressions": 1200,
    "clicks": 80,
    "shares": 10,
    "reactions": 25
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Post not found.",
  "data": {},
  "meta": {},
  "errors": ["SP6001"]
}
```

## Permissions
- workspace member

## Notes
Analytics should be aggregated from publish logs and platform webhooks.
