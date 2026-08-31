# Pilot: devprofile

Repo: `{REPO_ROOT}` = the Next.js profile site. Origin: `http://localhost:3000`. Brave Beta. Doctor: `pnpm verify:doctor`.

## Graph source

`.cursor/skills/verify-devprofile/features/*.md` — `loadFeatureMap()` in `tests/e2e/helpers/feature-map.ts`. Paths today: `/`, `/qa`, `/x`, `/profile`, CV dialog, certificates, focus. Do not copy them here.

Existing UX already checks **document** horizontal overflow (`assertNoHorizontalOverflow` in `tests/e2e/helpers/assert-ux.ts`). LCV adds inner-clip + must-show.

## Default roles (until `data-lcv` lands)

| Region | Role | Why |
|--------|------|-----|
| `h1` | must-show | Page identity |
| Hero / invite copy | must-show | Hiring data, not a chip |
| `#projects` descriptions with `line-clamp-*` | preview | Card blurbs |
| `/qa` `line-clamp-3` question peek | preview | Desk chrome; the answer pane is must-show |
| `.profile-deck__pager-label` | must-show until marked | Causal probe: view box stable, label `scrollW` ≫ `clientW` |
| `data-visual-live` | live | Paint mask, not ellipse |

## Viewports

Use plugin `VIEWPORTS` only: 375×812, 768×1024, 1280×720. Pixel project is desktop-only; LCV still runs phone/tablet.

## One-shot example

Finding: `/profile` @ tablet, pager label `inner-clip-must-show`.  
Recipe: drop ellipsis on the label **or** mark `data-lcv=preview` if the label is chrome. Re-run that path × viewport.

Do not route print-CV `src/lib/cv-layout-policy.ts` into this pass.
