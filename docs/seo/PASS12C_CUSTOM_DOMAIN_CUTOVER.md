# PASS 12C - Unite A Gamer custom-domain SEO cutover

**Canonical address:** `https://uniteagamer.com`
**Firebase project:** `unite-a-gamer`
**Certified source baseline:** `8d9665e349e284d36179eca6a58e124a0e944139` (PASS 12A)
**Local PASS 12B commit accepted:** a descendant of the certified baseline; its dependency lockfile is not changed.
**Release mode:** gated PowerShell installer. This document is not evidence of live indexing.

## Scope

- Replace exact absolute `https://unite-a-gamer.web.app` SEO references in all 27 public sitemap-linked HTML pages and 404 page.
- Update four legal/support canonical pages, Open Graph links and JSON-LD URLs where the old host appears.
- Change all 27 sitemap loc values and robots.txt sitemap declaration to the new canonical domain.
- Update the existing SEO contract and add a custom-domain regression test covering 27 routes.
- Preserve `web/app.html`, Firebase authentication, `/app.html` links, site entry redirects, hosting rewrites, Blueprint Tracker and Favourite Loadout logic.
- Do NOT redirect the default Firebase `web.app` hostname using a path-only Hosting redirect. Firebase serves the same hosting config on the custom domain and that can create a loop. Google gets canonical signals from the public HTML and sitemap; the old address remains operational for existing app links.

## After deployment

1. Open `https://uniteagamer.com/`, `https://uniteagamer.com/tools/blueprint-tracker/`, and `https://uniteagamer.com/sitemap.xml` to confirm HTTPS and static HTML responses.
2. In the VERIFIED `uniteagamer.com` Domain property in Google Search Console, submit `https://uniteagamer.com/sitemap.xml`.
3. Inspect the homepage and Blueprint Tracker URL; test live URLs and request indexing if eligible.
4. Monitor Indexing > Pages, Search results > Performance, impressions, clicks, and canonical selection. Search indexing and rankings are never guaranteed.
5. Optional: connect `www.uniteagamer.com` in Firebase Hosting and set an apex redirect from www, after confirming DNS and existing services. This pass does not change DNS or hosting domains.
6. Do not replace any Firebase Auth authorised domains, API credentials, session links, PWA start URLs, or the default authDomain solely to complete SEO.

## Rollback

Release installer writes a per-run backup to Downloads. Before Git commit, it restores only installer-owned paths on a failed gate. If a deployment succeeds but a subsequent publish or post-deploy verification fails, use Firebase Hosting release history for rollback, and review the recorded local commit before making further changes. No broad Git clean/reset is used.

## PASS 12C REV2 Windows recovery

The existing tracked `web/robots.txt` may show as modified because PASS 12A left a line-ending difference on Windows. REV2 allows only this precise unstaged path after verifying that normalized content matches `HEAD:web/robots.txt`. It then backs up the original file, replaces the original canonical-host reference with the custom domain, and stages exactly the SEO allowlist. Any non-line-ending change aborts without modifying sources. Existing legal pages receive canonical-host replacements but no unrelated metadata rewrite.

## PASS 12C REV3 manifest correction

REV2 incorrectly truncated one expected 40-character Git blob SHA to 39 characters for `web/guides/raid-planning/index.html`. REV3 corrects that entry and validates all expected SHA formats before any source modification. The source HTML and SEO replacements remain unchanged.

## PASS 12C REV4 release-gate invocation correction

REV3 incorrectly declared `Invoke-Gate(...,[string[]]$args)`, colliding with the automatic PowerShell `$args` variable and making the gated external executables run without their intended arguments. REV4 renames the parameter to `$commandArgs`, explicitly splats it, refuses empty invocations, and logs the command. Source SEO replacements, release branch guards, immutable blob SHAs, and test content are unchanged.
