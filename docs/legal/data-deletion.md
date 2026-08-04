# Data Deletion Request

An authenticated user can create a durable request for deletion of their
account data with:

```http
POST /api/v1/account/data-deletion-requests
Authorization: Bearer <user token>
Content-Type: application/json

{
  "confirm": true,
  "reason": "Optional explanation"
}
```

The endpoint records the requester, the account's active organisation context
when one still exists, request time, and optional reason. It remains available
to an authenticated account with no active organisation. It returns `202
Accepted` with the request ID and does not silently delete data while a request
is in flight. This protects
against accidental destructive actions and gives the operator an auditable
queue to verify identity, revoke connected-provider tokens where appropriate,
delete or anonymise eligible data, and document any legally required
retention.

Only the authenticated account owner can create a request for that account.
The requester can keep a copy of the returned request ID for support follow
up.  The deployment operator must publish a real public support contact and
the applicable response/retention timeline before inviting external testers;
the source repository intentionally does not invent either value.
