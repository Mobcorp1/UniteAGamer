# PASS 261F — Automatic Web Release Updates

The web release process now generates `build/web/version.json` using the deployed Git commit.
Open browser tabs and installed PWAs poll that file every 60 seconds with cache bypassing.
When the deployed build ID changes, a UAG update overlay appears and the page reloads automatically.

## Protected operations

Critical flows can defer reloads through:

```js
window.UAGUpdateManager.setCriticalFlowActive(true);
window.UAGUpdateManager.setCriticalFlowActive(false);
```

When the hold is released, any pending update is applied immediately.

## Deployment

Run:

```powershell
.\scripts\deploy_web_release.ps1
```

The script requires a clean `beta-stabilisation` working tree, builds Flutter web, writes `version.json`, selects `unite-a-gamer`, and deploys Hosting.

## Cache policy

`index.html`, `main.dart.js`, `flutter_bootstrap.js`, `version.json`, the update manager, the manifest, and any legacy Flutter service worker are configured for revalidation/no-store through Firebase Hosting headers.
