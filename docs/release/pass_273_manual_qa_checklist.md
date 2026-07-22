# PASS 273 Manual QA Checklist

Use this checklist after the final automated validation and deployment to a hosted beta/staging environment.

## Required Viewports

| Viewport | Target |
| --- | --- |
| Android portrait | 390 x 844 or comparable real device/emulator |
| Android landscape | 844 x 390 or comparable real device/emulator |
| Tablet | 820 x 1180 or comparable tablet |
| Desktop/web | 1366 x 768 and one wide viewport |

## Release Smoke

| Area | Manual Check | Expected Result | Status |
| --- | --- | --- | --- |
| Registration | Create a new account on hosted web | User registers, credential manager recognises email/password fields and app reaches onboarding/home flow | Pending |
| Login | Log in on hosted web with a saved credential | Browser can offer/fill credentials, Firebase login succeeds, user lands on Command Centre | Pending |
| Password reset | Open Forgot password on hosted web | Email field is recognised as an email/username field and reset email request succeeds | Pending |
| Onboarding | Complete legal consent, profile setup and required steps on mobile portrait | Active actions remain visible, Next/Back works, no overflow | Pending |
| Command Centre | Open after login and through `/my-hub` | First screen answers the next action and old My Hub is not the primary home | Pending |
| Drawer/navigation | Open core routes from drawer and compact navigation | Routes open without duplicate cards or dead destinations | Pending |
| Profile | Open Profile & Reputation | Equipped badge, title, frame and banner display without clipping | Pending |
| Blueprint Tracker | Open Full Grid Overview | Full Grid is default for users with no saved preference, order is stable, ownership/duplicate UI works | Pending |
| Blueprint Tracker | Switch to In-Game Framed View | View groups the grid for side-by-side game comparison, zoom/pan and top/bottom jumps work | Pending |
| Progress trackers | Open Scrappy, Bench, Quest and Hunt Targets | Cards remain usable on mobile and desktop | Pending |
| Favourite Loadout | Open, edit and reload loadout | Weapon/attachment images fill cards, six quick-use slots remain reachable | Pending |
| Raid Planner | Create or inspect a plan | Layout remains usable and navigation returns to Command Centre | Pending |
| Trading | Open listings, Smart Trade, sessions and notifications | Lists and cards load safely with empty/live data and no overflow | Pending |
| Match Rider | Open matchmaking flow | Main calls to action remain reachable | Pending |
| Operations | Open Operations and Reward Vault | Claim/equip preview panels remain responsive | Pending |
| Notifications | Register web push and Android notifications | Device registration succeeds and test notification works with permission granted | Pending |
| Settings | Open from drawer/navigation | Notification settings remain integrated and route opens correctly | Pending |
| Admin tools | Open as admin and non-admin | Admin tools are gated and read-only/preview controls do not expose destructive actions | Pending |
| Expedition reset | Open reset/season flow | Reset messaging is clear and no protected tracker logic is altered unexpectedly | Pending |

## Pass / Fail Gate

Closed Beta can proceed only when all P0 checks above are marked Passed or explicitly waived by the release owner.

Manual-only checks that cannot be completed locally must remain Pending until verified on the hosted beta environment.
