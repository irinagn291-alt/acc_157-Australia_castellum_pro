# Castellum

Fill the sump. Crest the weir.

Castellum is for people who add a workout and then chug at night as if the extra never existed. Home is the communicating vessels: a lower sweat-sump and an upper body bowl. A pour fills the sump first. Only overflow crests the weir. A night chug cannot jump an open sump.

No account, no ads, no Game tab. The well is the calculator.

## Architecture

Weir ADT fold — `OpenSump | Cresting | Full`. The day's vessels are a fold of that day's pours into two chamber fills. A single `WeirStore` owns the `DayMark`, the sump depth from the activity band, and the fold result. Views never mutate the ADT. `foldPours` reduces the day's `Pour` list into remaining sump millilitres and bowl millilitres, keyed by `DayKey` as `Int` in YYYYMMDD form from `Calendar.current.startOfDay`. A pour that would skip an open sump is a refused store method, not a jump of the weir.

This fits a cistern: the legal move is a pour into the well, not a row on a glass list. A tab plus a list of drinks would be a journal clone.

## Sweat-sump weir

This is why someone would pick the house. Activity writes a lower chamber of 0, 350, or 700 ml. A default 250 ml pour fills that sump first; only overflow crests into the body bowl. The day's mark stays `clamp(weightKg × 33 + activityBonus, 1200…5000)` rounded to 50 ml. The day is complete iff sump remaining is 0 and bowl ≥ goal − sump depth. History counts crest-runs, not glasses.

## Design

Cistern house: tuff stone, verdigris copper, still water, lampblack. Palette lives in `Assets.xcassets` and is reached only through `CisternInk`: background `#100E0C`, surface `#1E1B16`, ink `#E8E2D4`, accent `#3D8B74`, muted `#8C8578`. Type is SF Pro via `.system` only, six steps, none larger than 34 pt. Hard edges. Spacing unit 8 pt. Tap targets 44 pt. Navigation is a weir-first swipe: Dial, then History, then Settings.

## Art

Style: section engraving of a Roman cistern and weir (waterline, copper outflow).

Base prompt reused for every asset:

```
Section engraving of a Roman cistern and weir, waterline and copper outflow, tuff stone walls, verdigris copper fittings, still water, lampblack ground, fine hatch, no text, no letters, no logo
```

| Image set | Prompt |
| --- | --- |
| `ctm_AppIcon` | Section engraving of a Roman cistern weir in section, copper outflow and still water, tuff stone, centred, filling the canvas, no text, no letters, no rounded corners, no drop shadow, subject inside the middle 80 percent, opaque |
| `ctm_Splash` | Vertical section engraving of a dark cistern house, quiet uncluttered centre band, tuff stone and lampblack, verdigris copper at the edges, still water, no text |
| `ctm_Onboarding1` | Section engraving of an empty Roman cistern and weir, one glance at the house, tuff stone and still water, no text |
| `ctm_Onboarding2` | Section engraving of a pour cresting a copper weir from a lower sump into an upper bowl, mid-gesture, waterline, no text |
| `ctm_Onboarding3` | Section engraving of a full cistern after many crest-runs, waterline high, verdigris outflow, accumulated meaning, no text |
| `ctm_EmptyHome` | Section engraving of an empty tuff cistern waiting for the first pour, calm and inviting, never sad, lampblack ground, no text |
| `ctm_EmptyList` | Section engraving of an empty crest-run ledger page, unused copper ruling, calm, no text |
| `ctm_CardBackdrop` | Low-contrast tuff stone and faint still-water hatch, quiet enough for text, no letters |
| `ctm_ControlFace` | Square-on engraving of a single copper weir lip, the pour well face, no text |
| `ctm_TwistHero` | Section engraving of a sweat-sump weir, lower chamber full, overflow cresting into the body bowl, copper outflow, no text |
| `ctm_SuccessMark` | Small engraved copper crest spark on still water, confirmation mark, no text |
| `ctm_HeaderDecor` | Wide engraved cistern-house band, tuff stone, waterline, verdigris fittings, low contrast, no text |

## How this is not a repeat

First `hydration_goal` in the portfolio, not a food tracker wearing a glass. No catalog, no barcode, no slots, no kcal. Not metric_capacity: no sips-versus-pitchers pair, no calendar tab, no charts chrome. Home is the communicating vessels on a swipe Dial page. The verb is crest-the-weir. Distinct from Occupath (token block) and Washfolio (year wash). No Game tab.

## Build

```bash
cd Castellum
xcodegen generate
xcodebuild -scheme Castellum -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.castellum.weir`. Contact: https://castellum-weir.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `ctm.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
