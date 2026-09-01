# Castellum — Build Specification

> Portfolio app 57, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Fill the sump. Crest the weir.

| Field | Value |
| --- | --- |
| Product name | Castellum |
| Bundle identifier | `com.castellum.weir` |
| Domain | https://castellum-weir.pro |
| Contact URL | https://castellum-weir.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `ctm_` |
| User-Agent | `Castellum/1.0 (iOS; +https://castellum-weir.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Castellum -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

The sump must fill.

### 2.1 User flow

1. Enter weight and an activity band (none / active / intense → 0 / 350 / 700 ml).
2. Land on the Dial page: lower sump (sweat) and upper bowl (body). The day's mark is still clamp(weightKg×33 + band, 1200…5000) rounded to 50 ml.
3. Pour 250 ml into the well. Water fills the sump first; only overflow crests the weir into the bowl.
4. A pour that would skip an open sump is refused — it does not jump the weir.
5. The day hits only when the sump is full and the bowl meets goal minus sump depth.
6. Swipe to History for crest-runs; swipe to Settings to change weight or band.

### 2.2 Essential behaviour

- goal = clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50 ml
- activityBonus 0 / 350 / 700 is the sump depth, not a fatter single ring
- Default pour 250 ml
- Pour fills the sump then crests; skipping an open sump is refused
- Day complete iff sump remaining is 0 and bowl >= goal − sumpTarget
- History counts crest-runs, not a glass list
- On-device only; no medical claims

---

## 3. Uniqueness assignment for Castellum

| Axis | Assigned value |
| --- | --- |
| Architecture | **Weir ADT fold (OpenSump | Cresting | Full; the vessels are a fold over the day's pours)** |
| UI approach | **SwiftUI hosting a UIView with communicating-vessel CAShapeLayers (tap pours; the sump path fills before the bowl)** |
| Naming convention | **Cistern / weir lexicon** |
| File organization | **By weir role (Sump, Bowl, Pour, Weir, DayMark)** |
| Dependency strategy | **None** |
| Design direction | **Cistern house (tuff stone, verdigris copper, still water, lampblack)** |
| Typography | **SF Pro** |
| Navigation pattern | **Weir-first swipe (the vessels are page one; History and Settings page beside them)** |
| AI art style | **Section engraving of a Roman cistern and weir (waterline, copper outflow)** |
| Functional twist | **Sweat-sump weir (activity fills a lower chamber; a pour crests only after the sump is full)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — hydration_goal

**Core** — The sump must fill.

**Audience** — People who add a workout and then chug at night as if the extra never existed. They will open an app if a weir has not crested.

**User flow**

1. Enter weight and an activity band (none / active / intense → 0 / 350 / 700 ml).
2. Land on the Dial page: lower sump (sweat) and upper bowl (body). The day's mark is still clamp(weightKg×33 + band, 1200…5000) rounded to 50 ml.
3. Pour 250 ml into the well. Water fills the sump first; only overflow crests the weir into the bowl.
4. A pour that would skip an open sump is refused — it does not jump the weir.
5. The day hits only when the sump is full and the bowl meets goal minus sump depth.
6. Swipe to History for crest-runs; swipe to Settings to change weight or band.

**Essential features**

- goal = clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50 ml
- activityBonus 0 / 350 / 700 is the sump depth, not a fatter single ring
- Default pour 250 ml
- Pour fills the sump then crests; skipping an open sump is refused
- Day complete iff sump remaining is 0 and bowl >= goal − sumpTarget
- History counts crest-runs, not a glass list
- On-device only; no medical claims

**Twist** — Sweat-sump weir. Activity writes a lower chamber of 0, 350 or 700 ml. A pour fills that sump first; only overflow crests the weir into the body bowl. The day's mark stays clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50 ml. Default pour 250 ml. Home verb: crest-the-weir, not tap-a-glass. History counts crest-runs.

**Why this is not a repeat** — This is the first hydration_goal product in the portfolio, not a food_tracker wearing a glass. BiteFlux tracks drinks beside meal slots as a second current on Today; this app has no catalog, no barcode, no slots and no kcal. It is also not metric_capacity: there is no sips-versus-pitchers pair, no calendar tab and no charts chrome. The family formula stays: goal = clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50 ml, default pour 250 ml. The new verb is crest-the-weir: activityBonus is a lower sump that must fill before any pour may enter the body bowl, so a night chug cannot skip the sweat. Home is the communicating vessels on a swipe Dial page, not a list of glasses.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: One radial dial. Tap = a sip.
- Invariant: goal = clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50ml. Bonus: 0 / 350 / 700. Default tap 250ml.
- Never: No medical claims.
- Desk `maidenhead_path`: Maidenhead 2–8; haversine; long path; terminator from solar declination.

### 3.1 Architecture contract

The day's vessels are an algebraic data type — OpenSump, Cresting, or Full — and the communicating vessels are a fold of that day's pours into two chamber fills. A single WeirStore owns the DayMark, the sump depth from the activity band, and the fold result; views never mutate the ADT. foldPours reduces the day's Pour list into remaining sump millilitres and bowl millilitres, keyed by DayKey as Int in YYYYMMDD form from Calendar.current.startOfDay. A pour that would skip an open sump is a refused store method, not a jump of the weir; a legal pour replaces the case and the fold reruns so the vessel layers refill. No coordinators, no ViewModels, no Combine pipelines — a view calls the store, published vessels change, the fold redraws.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI owns chrome only: the weir-first swipe pager, History, Settings, empty states, and onboarding. Home is a UIView hosted through UIViewRepresentable whose communicating vessels are two CAShapeLayers — the lower sump path and the upper bowl path — not a SwiftUI Path and not a list of glasses. A tap on the well commits one default 250 ml Pour through the store; the sump layer fills first and only overflow crests into the bowl layer. Chrome lives inside Button labels with contentShape, minimum 44pt, buttonStyle plain. Empty and onboarding are full pages with frame(maxHeight: .infinity) and a bottom full-width CTA. Background fills the safe area; the History list uses contentMargins.bottom. Colour is never the only signal: an open sump also shows a copper weir hatch. One haptic on a successful pour, none on swipe.

### 3.3 Naming contract

Convention: Cistern / weir lexicon.

Examples to follow: `SumpChamber`, `BodyBowl`, `crestPour(_:)`, `DayMark`

### 3.4 Dependency contract

Zero external dependencies. project.yml has no packages key. No SPM, no CocoaPods, no URLSession catalog client. The leftover search_api and AVCaptureMetadataOutput axes are unused; do not import AVFoundation for capture and do not call cgi/search.pl. Foundation, SwiftUI, and UIKit for the vessel representable only.

### 3.5 Navigation contract

Weir-first swipe: a page-style pager with the vessels as page one and History and Settings paging beside them. There is no tab-plus-list home and no pushed Detail. Weight and activity band edit on Settings, not on Dial. One haptic on a successful pour, none on paging. After onboarding, read ProcessInfo.processInfo.arguments once: -ReviewScreen today stays on Dial, log pages to History, goals pages to Settings.

### 3.6 Screen composition contract

Swipe pages. Physical screens: Dial, History, Settings. Dial is home: communicating vessels, tap pours into the well, the sump fills before the bowl. History is the crest-run list with a full-page empty state, not a glass log. Settings holds weight, activity band, contact URL, re-run onboarding, and resetAllData. Onboarding is a one-shot cover that writes defaults. No tab bar of records. No Today, Scan, Search, or Goals screens. ReviewScreen today opens Dial after onboarding, log opens History, goals opens Settings.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By weir role (Sump, Bowl, Pour, Weir, DayMark)**

```
Castellum/
  Sump/
Bowl/
Pour/
Weir/
DayMark/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Dial
A first-class screen for **Dial**. Must render empty, populated and error states.

### 5.3 History
A first-class screen for **History**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **IntakeEntry** — named per this app's convention.
- **HydrationGoal** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Cistern house (tuff stone, verdigris copper, still water, lampblack)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#100E0C` | Screen background |
| `surface` | `#1E1B16` | Cards, rows, sheets |
| `ink` | `#E8E2D4` | Primary text and icons |
| `accent` | `#3D8B74` | Primary action, key figure, progress fill |
| `muted` | `#8C8578` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via .system only; no Font.custom and no fixedSize. Weights carry hierarchy. At most six steps behind one accessor, none larger than 34pt. Millilitres, weight, and dates go through NumberFormatter. Dynamic Type; vessel captions stay readable at the largest size.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable root document (DayMark, activity band, day's Pour list, crest-runs) encoded to JSON in UserDefaults under a single versioned key. Day keys are Int in YYYYMMDD form derived from Calendar.current.startOfDay; never Date as a dictionary key. Debounced saves through one store seam; views never touch UserDefaults. resetAllData() from Settings. Simulator seed only, once, behind ctm.demo.v1, and the same seed marks onboarding complete so the vessels are not empty.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Castellum/1.0 (iOS; +https://castellum-weir.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.healthcare-fitness`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.healthcare-fitness
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Sweat-sump weir (activity fills a lower chamber; a pour crests only after the sump is full)

Activity writes a lower sweat-sump of 0, 350 or 700 ml; that depth is a chamber, not a fatter single ring. A default 250 ml pour fills the sump first; only overflow crests the weir into the body bowl. The day's mark stays clamp(weightKg×33 + activityBonus, 1200…5000) rounded to 50 ml. The day is complete iff sump remaining is 0 and bowl >= goal − sumpTarget; a pour that would skip an open sump is refused. History counts crest-runs, not a glass list. Unit-test the formula, the refuse-skip rule, and the complete predicate; a water list or a typed goal with no body/activity formula fails.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Section engraving of a Roman cistern and weir (waterline, copper outflow)**

Base prompt, reused and extended for every asset:

```
Section engraving of a Roman cistern and weir, waterline and copper outflow, tuff stone walls, verdigris copper fittings, still water, lampblack ground, fine hatch, no text, no letters, no logo
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ctm_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ctm_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ctm_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ctm_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `ctm_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `ctm_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `ctm_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ctm_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `ctm_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ctm_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `ctm_TwistHero` | 1024x1024 | allowed | Hero art for the 'Sweat-sump weir (activity fills a lower chamber; a pour crests only after the sump is full)' feature screen. |
| 11 | `ctm_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `ctm_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`ctm_AppIcon`** — 1024x1024

```
Section engraving of a Roman cistern weir in section, copper outflow and still water, tuff stone, centred, filling the canvas, no text, no letters, no rounded corners, no drop shadow, subject inside the middle 80 percent, opaque
```

**`ctm_Splash`** — 1290x2796

```
Vertical section engraving of a dark cistern house, quiet uncluttered centre band, tuff stone and lampblack, verdigris copper at the edges, still water, no text
```

**`ctm_Onboarding1`** — 1024x1536

```
Section engraving of an empty Roman cistern and weir, one glance at the house, tuff stone and still water, no text
```

**`ctm_Onboarding2`** — 1024x1536

```
Section engraving of a pour cresting a copper weir from a lower sump into an upper bowl, mid-gesture, waterline, no text
```

**`ctm_Onboarding3`** — 1024x1536

```
Section engraving of a full cistern after many crest-runs, waterline high, verdigris outflow, accumulated meaning, no text
```

**`ctm_EmptyHome`** — 1024x1024

```
Section engraving of an empty tuff cistern waiting for the first pour, calm and inviting, never sad, lampblack ground, no text
```

**`ctm_EmptyList`** — 1024x1024

```
Section engraving of an empty crest-run ledger page, unused copper ruling, calm, no text
```

**`ctm_CardBackdrop`** — 1200x800

```
Low-contrast tuff stone and faint still-water hatch, quiet enough for text, no letters
```

**`ctm_ControlFace`** — 512x512

```
Square-on engraving of a single copper weir lip, the pour well face, no text
```

**`ctm_TwistHero`** — 1024x1024

```
Section engraving of a sweat-sump weir, lower chamber full, overflow cresting into the body bowl, copper outflow, no text
```

**`ctm_SuccessMark`** — 512x512

```
Small engraved copper crest spark on still water, confirmation mark, no text
```

**`ctm_HeaderDecor`** — 1200x600

```
Wide engraved cistern-house band, tuff stone, waterline, verdigris fittings, low contrast, no text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `ctm.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `CastellumTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Castellum -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Weir ADT fold (OpenSump | Cresting | Full; the vessels are a fold over the day's pours)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView with communicating-vessel CAShapeLayers (tap pours; the sump path fills before the bowl)**.
- [ ] Navigation matches **Weir-first swipe (the vessels are page one; History and Settings page beside them)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Castellum
xcodegen generate
xcodebuild -scheme Castellum -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Castellum -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
