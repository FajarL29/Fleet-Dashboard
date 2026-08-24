# Authentication Integration

## Backend contract

The frontend uses `API_BASE_URL`, which defaults to `http://localhost:3000/api/v1`.

### Login

`POST /auth/login` sends:

```json
{
  "username": "string",
  "password": "string"
}
```

The successful response supplies `data.token`, `data.refreshToken`, and an allowlisted `data.user`. The user model contains `user_id`, `username`, `fullname`, and `email`, with optional `role` and `status`. Password and refresh-token database fields are not modeled.

### Register

`POST /auth/register` sends the confirmed registration fields:

```json
{
  "fullname": "string",
  "username": "string",
  "password": "string",
  "role": "string",
  "division": "string"
}
```

Both `role` and `division` are supported by the deployed product contract and remain part of the request. Registration succeeds only when the backend returns a successful 2xx envelope. A non-2xx response is converted into an `AuthException`; it cannot trigger success feedback or navigation to Login.

### Refresh

`POST /auth/refresh` sends the current token as `refreshToken`. A successful response supplies `data.accessToken` and a rotated `data.refreshToken`. Access tokens last one hour and refresh tokens last seven days.

### Logout

`POST /auth/logout` receives `Authorization: Bearer <access token>` and no request body. The backend clears the stored refresh token. Local session deletion runs even if this request fails.

## Frontend architecture

`AuthCubit` owns the current in-memory `AuthSession` and coordinates login, startup restoration, refresh, and logout. HTTP contract parsing remains in `AuthService`; Login widgets contain no backend request logic.

Application startup is:

```text
MyApp
  -> AuthCubit.restoreSession
  -> AuthGate loading state
  -> LoginPage when no usable session exists
  -> DashboardScreen when authenticated
```

`DashboardBloc` is created inside the authenticated branch of `AuthGate`. Leaving that branch disposes the dashboard state and its polling subscriptions.

## Session storage and Remember Me

The app stores a remembered session with `flutter_secure_storage`. On Windows, the plugin uses its Windows secure-storage implementation rather than a source file or Dart define. Plaintext passwords are never stored.

- Remember Me on: access token, refresh token, and sanitized user data are persisted.
- Remember Me off: the session remains in memory for the running process and any previously persisted session is deleted.

At startup, the client reads the JWT `exp` claim locally. A usable access token enters the dashboard. An expired access token with a usable refresh token is refreshed first. Missing, malformed, or expired sessions are cleared. The backend has no dedicated `/me` endpoint, so startup restoration cannot reload an authoritative profile.

## Authenticated requests and HTTP 401

`AuthenticatedHttpClient` is the shared runtime fallback for Vehicle Status, Vehicle Management, Drowsiness, Vital Sign, and Air Quality services. It replaces independent `API_AUTH_TOKEN` handling and attaches:

```http
Authorization: Bearer <active access token>
```

On HTTP 401 it:

1. reuses a refresh already completed by another request when possible;
2. otherwise asks `AuthCubit` to perform one shared refresh operation;
3. stores the rotated tokens when Remember Me is enabled;
4. retries the original request once;
5. clears the session if refresh fails or the retry is still unauthorized.

There is no infinite retry. Login, refresh, and logout use `AuthService`'s unwrapped client so authentication endpoints cannot recursively trigger the interceptor.

## Login behavior

The approved Login layout is preserved. The form now validates required username and password fields, prevents duplicate submissions, and displays invalid-credential, timeout, unavailable-backend, malformed-response, and unexpected server errors.

Forgot Password and Company SSO remain disabled because their backend contracts do not exist. The language dropdown is disabled because application localization is not implemented. Narrow layouts wrap or constrain long controls and security text.

The secondary `Create an account` action pushes the existing `RegisterPage` onto the current Navigator. It is intentionally styled below the primary Sign In action. Register's `Sign in` action pops that route instead of creating another Login route.

## Register behavior

Register preserves required-field validation, password confirmation, role selection, division input, terms acceptance, loading feedback, and duplicate-submit prevention. A successful request shows account-created feedback and pops back to Login without automatically authenticating the new account.

Registration uses the same 15-second request timeout and network exception mapping as Login. Timeout, unavailable-backend, malformed-response, duplicate username/email, validation, and other safe backend messages leave the user on Register with their input intact. Server-side and SQL implementation details are replaced with a generic safe error.

Terms of Service and Privacy Policy remain agreement labels rather than links because the repository contains no approved legal documents or destinations. Supplying those destinations remains a product/legal dependency and is not simulated with placeholder URLs.

## Logout behavior

Settings exposes the Logout action. Logout attempts the backend endpoint, always clears secure and in-memory session data, removes the authenticated subtree, disposes `DashboardBloc`, and returns to Login.

The backend does not blacklist access JWTs, so a copied access token can remain valid until its one-hour expiration. The backend owner should revoke or rotate the JWT that was previously embedded in `DashboardBloc`; the frontend no longer contains or uses it.

`AuthCubit` maintains a session generation. Logout invalidates the in-memory generation before any network wait, then drains an already-running refresh before the final secure-storage clear. A refresh response is applied only when both its captured generation and session identity are still current, so a stale response cannot authenticate the user again after logout.

## Files changed

Authentication models, service, storage, controller, HTTP client, and gate were added under `lib/models`, `lib/services`, `lib/bloc/auth`, and `lib/widgets/auth`. Startup, Login widgets, Settings, Dashboard routing/polling, and the five REST services were integrated. `pubspec.yaml` now includes `flutter_secure_storage`.

Focused tests cover the backend login/register/refresh/logout contracts, login validation and errors, Login/Register navigation, registration success and failure feedback, duplicate-user mapping, timeout and unavailable-backend recovery, duplicate-submit prevention, Remember Me persistence, startup refresh, failed-refresh clearing, refresh/logout ordering, bearer injection, and one-time 401 retry.

## Verification and limitations

- `dart format` completed for the focused authentication source and test files.
- Focused `dart analyze` completed with no issues.
- Full-project `dart analyze` reports nine pre-existing warning/info findings in Overview, Report, and responsive-layout code; it reports no authentication findings.
- The focused Flutter authentication suite completed all 33 tests successfully, covering Login, Register, service errors, session lifecycle, and authenticated HTTP retry behavior.
- The first sandboxed `flutter test` invocation stalled because Flutter could not write its SDK lock/cache outside the workspace. After the required SDK-cache permission was granted, the focused suite ran normally. Early widget-test failures were limited to off-screen test controls in the default 800x600 harness; the harness viewport was corrected before the successful final run.
- No live login lifecycle was run because no non-production backend credentials were provided.
- `git diff --check` completed without whitespace errors.
- GPS WebSocket authentication was not changed because the supplied backend contract only specifies Bearer authentication for protected HTTP APIs.
- Backend reversible AES password storage is an acknowledged backend limitation and is outside this frontend scope.
- Approved Terms of Service and Privacy Policy destinations are still unavailable, so the agreement labels intentionally remain non-clickable.
