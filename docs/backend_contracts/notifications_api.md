# Notifications Backend Contract v1

The Flutter notification repository unwraps the standard API envelope and
expects `data` to contain:

```json
{
  "unread": 0,
  "items": [
    {
      "id": "42",
      "type": "post.approved",
      "title": "Post approved",
      "body": "…",
      "is_read": false,
      "read": false,
      "created_at": "2026-07-30T12:00:00+00:00"
    }
  ]
}
```

`is_read` is the canonical field. `read` remains a compatibility alias while
clients transition. The read endpoints are:

- `PATCH /api/v1/notifications/{notification}` with `{ "is_read": true }`
- `POST /api/v1/notifications/mark-all-read`

The repository must return a failure result for a non-successful response;
the presentation layer intentionally renders that separately from an empty
`items` list.
