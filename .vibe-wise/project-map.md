# Project Map

## Purpose
Ark gives a user small tools to regulate emotions (breathing, photo of the day,
scream tank, tear collection, memory jar, emotional detective, body map), plus a
daily mood check-in and a stats screen built from their own history.

## Requirements
- A daily check-in records emotions, an intensity (1-5) and an optional note.
- The stats screen shows only the user's own data; a new account must show that
  there is nothing yet rather than example numbers (set after a demo where a
  brand-new account displayed sample charts).
- Colours come from the design wiki palette (MS6 §2.3, eight colours, no white).

## Components
| Component | Responsibility | Paths |
|---|---|---|
| Models | Plain data (CheckIn, ToolFeedback, ToolSession, Tear…) | `lib/data/models/` |
| Repositories | Read/write a domain concept, hide the service | `lib/data/repositories/` |
| Services | Firebase, local sqflite DAO, network, remote HTTP | `lib/data/services/{local,remote,network}/` |
| Domain | Framework-free rules and patterns | `lib/domain/` |
| ViewModels | `ChangeNotifier`, no `BuildContext` | `lib/ui/<feature>/view_model/` |
| Widgets | Screens, observe via `ListenableBuilder` | `lib/ui/<feature>/widgets/` |
| Theme | Palette tokens, text styles, explicit `ColorScheme` | `lib/ui/core/theme/` |

Patterns present in the code: Repository, DAO (`PhotoDao`/sqflite), Strategy
(recommendations), Composite (`FlowStep`/`FlowGroup`, `Mood`/`SimpleEmotion`/
`CompoundEmotion`), Observer (`ChangeNotifier`).

## Main Flow
```
Widget --(user action)--> ViewModel --(call)--> Repository --> Service --> Firestore
Widget <--(notifyListeners)-- ViewModel <--(model objects)-- Repository
```
Stats, verified: `StatsScreen` -> `StatsViewModel.load()` -> `StatsRepository.dataSince(30d)`
-> `FeedbackRepository` + `CheckInRepository` -> Firestore. Returns `StatsData`,
whose `isEmpty` decides between the empty state and the charts.

## Data and Trust Boundaries
- Firebase project `ark-mobiles`, shared with the Kotlin client.
- Firestore: `users/{uid}`, `users/{uid}/check_ins/{yyyy-MM-dd}`,
  `users/{uid}/tool_feedback/{id}`; offline persistence on.
- Auth: Firebase Auth. Repositories return empty lists when nobody is signed in,
  so an unauthenticated read cannot look like a populated history.
- Analytics export (separate `analytics` repo) reads Firestore with a service
  account key kept outside both repositories and gitignored.
- `SheetsLiveService` pushes each check-in/feedback to a Google Apps Script web
  app; its shared secret arrives via `--dart-define`, never committed.

## Build and Deployment
- `flutter analyze` — currently clean.
- `flutter test` — 14 tests in `test/ui/{stats,check_in,core}`; `test/` was created
  during this session, the project had none before.
- Secrets: `--dart-define=SHEETS_SECRET=...`.
- The learner makes every commit; the AI never commits or pushes.
- `feature/stats-update#71` (commit `8ae7a78`) holds the stats empty state, the
  check-in redesign, `AppTheme.light` wired into `main.dart`, and `test/`. It is
  develop + 2 commits and is not merged into develop yet.
- Current branch: `feature/smart-feature-checkin#86`, cut from the develop tip
  (`ee409b2`), so it does not contain the work above.

## Decisions
- `AppColors.panel` (#FDF3E0) and `AppColors.surfaceDim` (#ECD3A4) stay as derived
  surfaces and get documented rather than removed (learner's call; see progress).

## Unknowns
- Whether those two tokens have been documented in the wiki yet — not done.
- What `feature/smart-feature-checkin#86` is meant to build.
- Learning scope (whole system vs only the parts we touch) not stated.
