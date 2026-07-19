# Authentication API

## Purpose
Create or refresh authentication tokens for users.

## Authentication
None for login; Bearer token for protected endpoints.

## Endpoint
POST /api/auth/login

## Method
POST

## Headers
```http
Content-Type: application/json
```

## Request
```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

## Validation
- email: required, valid format
- password: required, minimum 8 characters

## Success Response
```json
{
  "success": true,
  "message": "Authenticated successfully.",
  "data": {
    "access_token": "",
    "refresh_token": ""
  },
  "meta": {},
  "errors": []
}
```

## Error Response
```json
{
  "success": false,
  "message": "Invalid credentials.",
  "data": {},
  "meta": {},
  "errors": ["SP1001"]
}
```

## Permissions
- Public

## Notes
Use refresh token to obtain a new access token.
