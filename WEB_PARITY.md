# Mobile ↔ Web parity

The Flutter app is a **companion app**, not a second admin console. It covers
what an employee (and a manager on the move) needs; organisation administration
and analytics stay in the web app.

This file exists so the gaps below read as decisions, not as bugs on the next
review.

## Deliberately web-only

| Web module | Path (web) | Why it isn't on mobile |
|---|---|---|
| Reporting / analytics | `src/components/reporting` | Dense tables and exports; not useful on a phone. |
| Tasks | `src/components/tasks` | Not implemented on mobile at all — see the note below. |
| Timesheets (full) | `src/components/timesheets` | Mobile has the time clock and a personal/employee time account, not the full timesheet grid. |
| Organisation settings (13 views) | `src/components/settings/*` | Scheduling, TimeTracking, Absences, Documents, Roles, Permissions, Locations, Holidays, Payments, Announcements, Chat, … — admin configuration is a desktop job. |

Mobile **consumes** those settings (see `lib/providers/scheduling_flags_provider.dart`,
which reads `GET /api/settings/scheduling/me`) but never edits them.

## Mobile-only

| Feature | Path | Note |
|---|---|---|
| Onboarding | `lib/pages/onboarding` | First-run flow; no web equivalent. |
| Legal screens | `lib/pages/legal` | Privacy policy / terms, required for the app stores. |

## Known consequence: task notifications

The backend can send `TASK_ASSIGNED` notifications
(`NotificationType.TASK_ASSIGNED`) and the app renders them with a task icon,
but there is no tasks screen to open. Rather than dead-end the user, the
notification detail page shows an explanatory note pointing them at the web app
(`lib/pages/notification/notification_detail_page.dart`).

If tasks ever ship on mobile, replace that note with a real destination and drop
this section.

## Shared surfaces

Schedule, absences, availability, chat, announcements, notifications, documents,
employee directory, and the time clock all exist on both, driven by the same
backend. Where an org setting gates an action, the server enforces it and the
mobile UI hides or disables the control up front — see
`SchedulingFlagsProvider` and its consumers.
