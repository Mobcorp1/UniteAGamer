# UAG PASS 12A — Search Visibility & Organic Growth Foundation

**Baseline:** `f8cf0563c6d252feea70429c823f38bab0c7c541`
**Branch:** `codex/raid-setup-endpoints-20261005`
**Origin:** `Mobcorp1/UniteAGamer`
**Current canonical host:** `https://unite-a-gamer.web.app`
**Status:** ZIP prepared only; not installed, built, deployed, indexed or published.

## Exact scope

- 16 original indexable HTML landing pages: six tool pages + tool directory, eight update/resource guides, and maps directory.
- 27 sitemap entries including all pre-existing indexable public pages.
- Search titles, canonical, descriptions, OpenGraph, Twitter cards, JSON-LD (Article/WebPage + BreadcrumbList).
- Original content includes verified data from certified 11D, with explicit limits on pending game rules.
- Internal linking from current home and guide directory; global tools/map navigation on existing public guide pages.
- Firebase SPA fallback deliberately excludes `/tools/` and `/maps/`, including for 404 handling.
- Existing `noindex` on `/app.html` retained, existing Flutter application untouched.
- Test contract validates all public page paths and structured data. All existing Flutter tests still run.

## Guarded PowerShell installer

Place this entire ZIP in your Downloads folder, extract it, and run `Install-UAG-PASS12A-SEO.ps1` from the extracted folder. The installer never overwrites a dirty worktree or an unexpected branch/HEAD. It verifies all payload hashes, backs up affected existing files, writes overlay files, applies exact-match edits, checks HTML and sitemap, runs focused tests and full Flutter suite, and builds web + Android. It commits only scoped files, then (only with `-Publish`) deploys hosting, verifies the URL, pushes the branch and annotated release tag. **Running with `-Publish` explicitly authorises deployment and push.** Without `-Publish`, it commits locally only.

Example command (assuming extraction to `Downloads\UAG_PASS12A_SEO`):

```powershell
& "$env:USERPROFILE\Downloads\UAG_PASS12A_SEO\Install-UAG-PASS12A-SEO.ps1" -ProjectRoot "$env:USERPROFILE\uag_raid_setup_worktree" -Publish
```

Release tags are created only when `-Publish` is passed. The installer deliberately does not deploy Firebase Functions, Firestore rules, or commercial products.

## Search Console and primary domain

The existing `web.app` hostname is kept as canonical because the production availability and Firebase custom-domain binding of `uniteagamer.com` have not been independently verified. Switching canonical and 301 redirecting must wait for domain validation. Search Console ownership proof requires an action in Google's account and cannot be completed by a Git patch. After a successful deploy:

1. Open https://search.google.com/search-console and verify the `unite-a-gamer.web.app` URL-prefix property (or the confirmed custom-domain property when ready).
2. Submit `https://unite-a-gamer.web.app/sitemap.xml`.
3. Inspect the homepage, `/tools/blueprint-tracker/`, and `/guides/research-station/` for indexability.
4. Connect `uniteagamer.com` in Firebase Hosting, verify HTTPS certificate and served content, migrate all canonical/sitemap URLs together, and configure permanent single-host redirects. Never redirect until this validation is complete.
5. Monitor indexed pages, search impressions/clicks, page experience and app sign-ups; do not claim a ranking before Search Console confirms it.

## Data provenance

Site source: certified PASS 11D REV4 GitHub commit. Specific code data: `arc_frozen_trail_two_content.dart`, `arc_frozen_trail_weapon_content.dart`, `arc_research_workstation_screen.dart`. Public pages do not claim exact unknown repair/perk costs, physical tradability or guaranteed spawns.
