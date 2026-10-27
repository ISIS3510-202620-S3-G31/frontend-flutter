# Learning Progress

Learning mode started after the stats, check-in and theme work was already
implemented by the AI at the learner's request, so that code is not evidence of
the learner's own reasoning.

## Design tokens outside the design system
Learner's decision (own reasoning, recorded 2026-10-27):
- Keep `AppColors.panel` and `AppColors.surfaceDim` even though the wiki palette
  (MS6 §2.3) does not list them, and document them instead of removing them.
- Criterion he gave: documenting is cheap, changing is not, because teammates
  already build around those tokens and would have to adapt.
- Alternative he rejected: aligning the code strictly to the eight wiki colours.
- He judged the deviation low-risk for the evaluation and framed it as a
  consistency/UX matter, naming the default white clashing with the app's warm
  aesthetic as the actual problem.

Demonstrated understanding:
- Weighed coordination cost against design-document purity and chose explicitly,
  rather than defaulting to the stricter option.

Documentation: deliberately deferred. MS6 will not be edited; the two tokens get
written up in the Sprint 3 wiki instead (learner's call).

Needs reinforcement:
- The extra tokens were never the cause of the white. What removed it was
  assigning the ten palette colours to all 34 scheme roles. Keeping the tokens and
  fixing the white are independent changes.
- Undocumented tokens tend to multiply, so the Sprint 3 write-up is the mitigation
  for a decision already in the code.

## Theme and colour tokens
Introduced (AI explained):
- Material 3 generates a full `ColorScheme` from a seed colour, and the roles it
  generates for light surfaces and for text on colour come out white.
- A `ColorScheme` has 34 roles, eight of them surfaces, while the palette defines
  a single background colour — which is why derived surfaces were needed at all.
Resolved: `AppTheme.light` is wired into `lib/main.dart` and committed on
`feature/stats-update#71`. An earlier report that it was left unwired was correct
about the working tree at that moment but is now superseded.

## Empty state vs sample data
Introduced (AI explained and implemented):
- `StatsRepository` used to fall back to `SampleStatsService` when the user had no
  history, so a brand-new account showed fabricated charts.
- A second, subtler fabrication derived "Happiness" check-ins from tool feedback.
- The regression is held by a test asserting the chart widgets are absent from the
  tree, not by asserting a text string.
Needs reinforcement:
- Why the sample fallback is a design decision with a cost, not a harmless default.
