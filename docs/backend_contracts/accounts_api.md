# Accounts API Specification

## GET /accounts

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": "",
      "name": "",
      "platform": "facebook",
      "is_connected": true
    }
  ]
}
```

## POST /accounts/connect

### Request
```json
{
  "platform": "facebook",
  "access_token": ""
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "platform": "facebook",
    "is_connected": true
  }
}
```
