---
name: prose-copy
description: >-
  Keep copy: no hyphen or dash in running prose; no plus as and; invitational
  permissions; no HTTP codes on UI; distinguish unavailable approximate and
  stale. Use for product UI, Lab, README, comments, skills, and chat.
---

# Prose copy

Applies to product UI, Lab, comments, markdown, canvases, chat, and skills.

## Do not

* Hyphen, em dash, or en dash in running copy.
* `+` as the word "and".
* Dual labels (`12:01 AM (00:01)`).
* Benefit speak (Elevate, Unlock, Seamlessly).
* Invented metrics.
* Threat copy on optional choices.
* Denial labels (`Not granted`, `Grant access`) when the control can name the job.
* Transport errors on product UI (`HTTP 503`, status codes, `URLError`).
* Type names on product UI (`EKEventStore`, `CADisplayLink`, `WeatherService`, `TCC`).
* Fake GPS certainty when weather is approximate.
* Implying Keep is broken because an optional permission was denied.

Use a space, a colon, or a new sentence. Use **and**, **or**, or **&** (menu labels).

Identifiers, URLs, ISO dates, CLI flags, YAML names, markdown table rules (`---`), and code are syntax, not running copy.

## Permissions

Name what the grant enables. Optional means they can continue.

Right: `Keep can show your next event from Calendar.`
Right: `Keep can use your location for weather and daylight where you are.`

Empty calendar is a quiet day. Calendar off is an invitation. Approximate is time zone location, not an HTTP failure. Stale means last kind is kept. Unavailable means there is nothing useful to show.
