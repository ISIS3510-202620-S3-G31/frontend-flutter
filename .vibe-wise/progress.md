# Learning Progress

## GPS location service (issue #70, branch feature/gps-first-integration#70)
Learner's decisions, with his own reasoning:
- One-shot reading, low accuracy: weather is about the city, not the street.
- Reuse the `permission_handler` pattern of `MicrophoneService` instead of
  geolocator's own permission API, to keep one way of asking for permissions.
- Keep "permission denied" and "location switched off" apart.
- Shared instance (factory singleton, like `AnalyticsService`) once shown that a
  per-caller instance would give each caller its own cache and defeat the TTL.
- Add a fifth outcome for "granted but no reading", after his own device log
  proved the case was real.
- Accept the Google Play Services accuracy dialog rather than switch to the
  legacy LocationManager; it can be accepted before a demo.

Introduced (AI explained):
- The Play Services dialog comes from using the fused provider at all, not from
  the accuracy level, so raising accuracy would not remove it.
- A stale fallback must carry the phone's timestamp, not the current one, or it
  passes the freshness check and blocks the next reading.

Needs reinforcement:
- Nothing has been verified on a physical phone; the emulator has no radios, so
  the fused provider fails there more than it would on a real device.

## Strategies required by the course
Surveyed on 2026-10-29 and still open:
- Local storage: already covered twice (sqflite DAOs plus file storage).
- Caching: covered by the breathing audio cache; authorship not confirmed.
- Concurrency: the weak one. Only `unawaited`, a broadcast `StreamController`
  and a `Timer`; no `compute()` or isolate anywhere. He has not chosen between
  an isolate for the insights engine and one for photo compression.
- Eventual connectivity: photo-of-the-day has a real outbox; Firestore offline
  persistence is never configured explicitly, only inherited as the default.

## Design tokens outside the design system
Decision: keep `AppColors.panel` and `surfaceDim`, document them in the Sprint 3
wiki rather than editing MS6. Not done yet.
