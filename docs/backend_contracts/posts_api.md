# Posts API Specification

## POST /posts

### Request
```json
{
  "title": "",
  "content": "",
  "attachments": [],
  "platforms": [],
  "scheduled_at": null
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "title": "",
    "content": "",
    "status": "draft",
    "created_at": ""
  }
}
```

## GET /posts/{id}

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "title": "",
    "content": "",
    "status": "draft"
  }
}
```

## PATCH /posts/{id}

### Request
```json
{
  "title": "Updated title",
  "content": "Updated content"
}
```

## DELETE /posts/{id}

### Response
```json
{
  "success": true,
  "data": {}
}
```
