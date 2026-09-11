---
name: prose-copy
description: >-
  Keep copy: no hyphen or dash in prose; no plus as and; invitational
  permissions; no HTTP codes on UI; distinguish unavailable approximate and
  stale; no fake GPS certainty. Use when writing product UI, onboarding,
  Settings, Lab, README, comments, canvases, chat, or commits.
---

# Prose copy

Applies to **every** file humans read: product UI, Lab, comments, markdown, canvases, chat, skills.

## Do not

* Hyphen, em dash, or en dash in running copy.
* `+` as the word "and".
* Dual labels (`12:01 AM (00:01)`).
* Benefit speak (Elevate, Unlock, Seamlessly).
* Invented metrics.
* Threat copy on optional choices: `If you skip this…`, `If you don’t allow…`, then something bad.
* Product labels that read like a denial (`Not granted`, `Grant access`) when the control can name the job.
* Transport errors on product UI (`HTTP 503`, status codes, `URLError`).
* Technical implementation language on product UI (`EKEventStore`, `CADisplayLink`, `WeatherService`, `TCC`).
* Fake certainty around approximate location or weather (do not imply a GPS lock when status is approximate).
* Implying Keep is broken because an optional permission was denied.

Use a space, a colon, or a new sentence. Use **and**, **or**, or **&** (menu labels).

## Permissions and supporting surfaces

Permission copy must state **what the permission enables**.

Optional means they can continue. Settings and onboarding explain consequences **positively** (what they get), never as a skip threat.

Never imply the app is broken because an optional permission was denied.

## Weather and calendar states

Distinguish unavailable, approximate, and stale. Do not collapse them into “error.” Approximate is time zone location, not an HTTP failure. Stale means last kind is kept. Unavailable means there is nothing useful to show. Empty calendar is a quiet day. Calendar off is an invitation.

## Keep as syntax

Operators, negatives, URLs, ISO dates, CLI flags, YAML image names (`macos-15`), markdown table rules (`---`), identifiers (`pauseWhenFullscreen`, `keep-process`).

## Examples

Wrong: `Pin 12:01 AM (00:01)`. Right: `Pin midnight` (test holds `00:01`).

Wrong: `calendar + location`. Right: `calendar and location` or `calendar & reminders`.

Wrong: `Stale — from yesterday`. Right: `from yesterday` or `Stale`.

Wrong: `If you skip this, Keep will not show a next event.` Right: `Keep can show your next event from Calendar.`

Wrong: `Weather unavailable (HTTP 503)`. Right: `Weather unavailable` or keep showing last kind as stale.

Wrong: `Location not granted, so weather is wrong.` Right: approximate status without blaming the person.

Wrong: `Without location, weather stays approximate.` as a threat. Right: `Keep can use your location for weather and daylight where you are.`
