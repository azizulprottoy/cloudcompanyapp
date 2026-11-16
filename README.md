# Cloud Company app

One Flutter app for clients, team members and admins. Pick the account type on the login screen; each role gets its own bottom-navigation home.

| Role | Tabs |
|---|---|
| Client | Home · Packages · Projects · Blog · Account (order a package, pay by bKash/Nagad/bank, track progress, chat with the team) |
| Team | Tasks · Account (accept, submit for review, ask for more time, close with a note, chat with admin) |
| Admin | Dashboard · Orders · Tasks · Account (change order status, confirm payment, approve/send back work, chat with clients and team) |

## Run

```bash
flutter pub get
flutter run                                   # production API (api.cloudcompany.cc)
flutter run --dart-define=API_URL=http://10.0.2.2:5050 --dart-define=WS_URL=ws://10.0.2.2:5050   # local server from the Android emulator
flutter test test/live_api_smoke_test.dart    # read-only checks against the live API
```

Android application ID and iOS bundle ID: `cc.cloudcompany.app`.

## Structure (same as Kaj Ache)

GetX for state, routing and DI; Dio for HTTP; feature-first folders.

```
lib/
  app/        routes (AppRoutes, AppPages + role guard), theme
  core/       auth (SessionService, roles), network (ApiClient, ApiEndpoints, BaseRepository),
              storage (secure token, GetStorage), error, utils
  shared/     widgets used across features
  features/<feature>/{binding,controller,model,repository,view}
    auth  home  packages  orders  tasks  chat  blog  dashboard  profile  main (role shells)  splash
```

Chat uses the existing server: history and sending over REST, live updates over the WebSocket (`?orderId=` or `?taskId=`).

## Not in this version

Push notifications (needs a Firebase app for `cc.cloudcompany.app`), online card payments, support chat, reviews, careers.
