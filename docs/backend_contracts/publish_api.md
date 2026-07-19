# Publish API Specification

## POST /publish/jobs

### Request
```json
{
  "post_id": "",
  "platform_ids": [""],
  "schedule_at": null
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "post_id": "",
    "status": "queued",
    "retry_count": 0,
    "progress": 0
  }
}
```

## GET /publish/jobs/{id}

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "post_id": "",
    "status": "publishing",
    "retry_count": 0,
    "progress": 50
  }
}
```
