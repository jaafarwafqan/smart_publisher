# Media API Specification

## POST /media/upload

### Request
```json
{
  "post_id": "",
  "file_name": "image.png",
  "mime_type": "image/png",
  "file_size": 1024
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "post_id": "",
    "url": "",
    "mime_type": "image/png",
    "size_in_bytes": 1024,
    "is_compressed": false
  }
}
```

## POST /media/compress

### Request
```json
{
  "media_id": ""
}
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "",
    "url": "",
    "is_compressed": true
  }
}
```
