# Media API

## Purpose
Upload and manage media assets for posts.

## Authentication
Bearer Token

## Endpoint
POST /api/media/upload

## Method
POST

## Headers
```http
Authorization: Bearer xxxx
Content-Type: multipart/form-data
```

## Request
- file: binary
- post_id: optional
- type: optional

## Validation
- file: required
- supported media types: image, video, document
- file size must not exceed platform limits

## Success Response
```json
{
  "success": true,
  "message": "Media uploaded.",
  "data": {
    "id": 21,
    "url": "https://cdn.example.com/media/21"
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Media too large.",
  "data": {},
  "meta": {},
  "errors": ["SP3002"]
}
```

## Permissions
- workspace member

## Notes
Media must go through the pipeline before publication.
