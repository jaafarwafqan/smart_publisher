# Accounts API

## Purpose
Manage connected social accounts and platform identities.

## Authentication
Bearer Token

## Endpoint
GET /api/accounts

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
  "message": "Accounts retrieved.",
  "data": [
    {
      "id": 1,
      "platform": "facebook",
      "name": "Business Page",
      "connected": true
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
  "errors": ["SP1002"]
}
```

## Permissions
- authenticated user

## Notes
This endpoint returns accounts linked to the current workspace.
