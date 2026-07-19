# Auth API Specification

## POST /auth/login

### Request
```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

### Response
```json
{
  "success": true,
  "data": {
    "access_token": "",
    "refresh_token": "",
    "user": {
      "id": "",
      "name": "",
      "email": ""
    }
  }
}
```

## POST /auth/refresh

### Request
```json
{
  "refresh_token": ""
}
```

### Response
```json
{
  "success": true,
  "data": {
    "access_token": ""
  }
}
```
