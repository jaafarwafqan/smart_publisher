# Notifications API Specification

## GET /notifications

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": "",
      "title": "",
      "body": "",
      "is_read": false
    }
  ]
}
```

## PATCH /notifications/{id}/read

### Response
```json
{
  "success": true,
  "data": {}
}
```
