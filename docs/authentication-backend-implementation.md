# Authentication Backend Implementation

**Status:** Implemented minimum hardening for the existing login/JWT/refresh architecture.

## Final Flutter Contract

### Login

`POST /api/v1/auth/login`

```json
{
  "username": "string",
  "password": "string"
}
```

Success remains the existing envelope. The access field remains `token` for compatibility:

```json
{
  "status": "success",
  "stat_code": 200,
  "data": {
    "token": "<access JWT>",
    "refreshToken": "<refresh JWT>",
    "user": {
      "user_id": 1,
      "username": "driver",
      "fullname": "Driver Name",
      "email": "driver@example.com"
    }
  }
}
```

The user object is allowlisted from the existing database row. It never includes `password` or `refreshToken`; optional `role` and `status` are included only when those columns exist in the returned row.

Missing credentials return HTTP 400 using the common envelope. Invalid credentials return HTTP 401. Existing database/decryption failures remain HTTP 500 through the existing controller error handling.

### Authenticated requests

Send:

```http
Authorization: Bearer <access JWT>
```

`x-device: MOBILE` is no longer required. It is also no longer used to bypass validation. Existing clients may continue sending it, but it has no authentication effect.

### Refresh

`POST /api/v1/auth/refresh`

```json
{
  "refreshToken": "<refresh JWT>"
}
```

Success:

```json
{
  "status": "success",
  "stat_code": 200,
  "data": {
    "accessToken": "<new access JWT>",
    "refreshToken": "<rotated refresh JWT>"
  }
}
```

The refresh token must be valid, unexpired, and equal to the token stored for its `userId` in `tb_m_users.refreshToken`. Missing, invalid, expired, or logged-out tokens return HTTP 401.

### Logout

`POST /api/v1/auth/logout`

Requires the access-token header. The backend clears the user's stored refresh token and returns:

```json
{
  "status": "success",
  "stat_code": 200,
  "data": "Successfully logged out"
}
```

Flutter must delete its locally stored access and refresh tokens. The current access JWT is not blacklisted and remains usable until its one-hour expiry; refresh is blocked after logout.

## JWT Details

Access tokens use `jsonwebtoken`, `SECRET_KEY`, and a one-hour lifetime. Claims are:

```json
{
  "user_id": "user id",
  "username": "username",
  "fullname": "fullname",
  "email": "email",
  "created_by": "created_by",
  "created_dt": "created_dt",
  "address": "address"
}
```

The access ID is generated from `payload.id ?? payload.user_id`. Refresh tokens use the existing seven-day lifetime and claims `userId` and `username`.

## Protected and Open Routes

Existing routes that attach `verifyToken` now genuinely require a Bearer JWT, including vehicles, user vehicles, safety, drowsiness reads/reviews/reports, geofencing, trip, trip history, camera, users, and protected pothole reads.

The following route families remain intentionally open because they are ingestion or legacy auxiliary operations:

- `POST /api/v1/vehicles/status`
- `GET /api/v1/vehicles/status`
- `POST /api/v1/drowsiness/`
- `POST /api/v1/pothole/add`
- health-report routes
- air-monitor routes
- several visitor, service-information, and odometer routes as currently registered

This implementation does not automatically add authentication to those routes or change telemetry behavior.

## Password Limitation

Existing AES encrypt/decrypt behavior in `helpers/security.js` is unchanged to preserve compatibility. It is reversible credential storage and should be replaced through a separately planned backward-compatible migration. No passwords were silently migrated.

## Changed Files

- `middleware/auth.js`: strict Bearer validation, canonical user ID claim, and parameterized refresh-token clearing.
- `controllers/auth/auth.controllers.js`: required-credential handling, safe login projection, refresh validation, and logout ID handling.
- `routes/auth/index.js`: login input protection and registered authenticated logout.
- `routes/drowsiness_detection/index.js`: drowsiness event ingestion remains open while dashboard operations remain protected.

## Tests and Verification

Completed locally:

- Node syntax checks passed for all changed JavaScript files.
- Static route audit confirms `/auth/logout` is registered.
- Static route audit confirms drowsiness POST ingestion is open and drowsiness reads/reviews/reports retain `verifyToken`.
- Static inspection confirms login output is allowlisted and excludes `password` and `refreshToken`.
- Static inspection confirms logout uses a parameterized `SET refreshToken = NULL` query.

Live lifecycle calls were not executed because the repository contains real database and third-party credentials in `.env`, and no dummy/test database or test credentials were provided. The endpoint-level behavior is documented above; run the lifecycle against a non-production test database before deployment.