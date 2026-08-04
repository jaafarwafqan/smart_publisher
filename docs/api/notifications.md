# Notifications API

Notifications are persistent, tenant- and recipient-scoped records.  They are
created for approval-request/approved/rejected and final publishing outcomes;
they are not placeholder rows fabricated by the client.

All endpoints require a Sanctum bearer token, a resolved active organization,
and the `notifications.view` capability.

## List

```http
GET /api/v1/notifications
```

```json
{
  "success": true,
  "data": {
    "unread": 1,
    "items": [
      {
        "id": "3",
        "type": "post.publish_failed",
        "title": "Publishing failed",
        "body": "…",
        "is_read": false,
        "read": false,
        "created_at": "2026-07-30T12:00:00+00:00"
      }
    ]
  }
}
```

An empty `items` array means the inbox is genuinely empty.  A network or API
failure is a failure state and clients must present a retry action rather than
turn it into an empty inbox.

## Mark one read

```http
PATCH /api/v1/notifications/{notification}
Content-Type: application/json

{ "is_read": true }
```

Only the recipient can mutate the row.  A guessed notification ID from another
recipient or organization is returned as not found.

## Mark all read

```http
POST /api/v1/notifications/mark-all-read
```

This updates only unread rows owned by the authenticated recipient in the
active organization.
