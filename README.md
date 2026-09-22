# Remind Me

Location-based reminders for iPhone. Save places you visit often (like your
department or a hospital), attach reminder notes to them, and get a
notification when you enter that place's geofence — even if the app isn't
open.

## How it works

- **Places**: saved locations with a name, coordinates, and a trigger radius.
- **Reminders**: text notes attached to a place, with an optional due date.
  A reminder fires **every time** you enter its place's geofence, and keeps
  firing on future visits until you tap it to mark it done — it isn't
  auto-dismissed after the first notification.
- **Linked places**: a place can be linked to other nearby places. Entering
  a place's geofence also surfaces reminders from anything linked to it —
  so linking "Hospital" to "CSE Dept" means walking near CSE dept reminds
  you about hospital-related things too. This is the general mechanism
  behind the original use case, and works for any pair of nearby places you
  add later.
- Geofencing uses `CLLocationManager` region monitoring (up to 20 regions,
  an iOS system limit), which keeps working in the background/killed-app
  state via "Always" location permission. Entering a region fires a local
  notification per not-yet-completed reminder at that place (and any linked
  places).
- **Daily summary**: once a day (9pm by default, editable in Settings via
  the gear icon), you get a notification with how many reminders you
  finished that day and how many are due by tomorrow (overdue or due
  today/tomorrow) and still not marked done. Because a local notification's
  content is fixed when it's scheduled rather than computed live, this gets
  recomputed and rescheduled whenever the app is opened or a geofence fires
  — so it stays accurate as long as you interact with the app or pass a
  saved place at some point during the day.

## Project layout

```
RemindMe/
  RemindMeApp.swift          # App entry point, SwiftData container setup
  Models/
    Place.swift               # SwiftData model: name, coords, radius, links
    Reminder.swift             # SwiftData model: text, due date, completion
  Services/
    LocationManager.swift      # CLLocationManager wrapper, geofencing logic
    NotificationManager.swift  # UNUserNotificationCenter wrapper (immediate + scheduled)
    DigestManager.swift        # Computes and (re)schedules the daily summary
    DigestSettings.swift       # Shared UserDefaults keys for the digest time
  Views/
    ContentView.swift
    PlacesListView.swift
    AddEditPlaceView.swift     # Map picker + radius slider
    PlaceDetailView.swift      # Reminders list + linked-places toggles
    AddReminderView.swift      # Reminder text + optional due date
    SettingsView.swift         # Pick the daily summary time
project.yml                    # XcodeGen spec to produce the .xcodeproj
```

## Running it (you'll need a Mac with Xcode)

This was written in a Linux sandbox with no Xcode available to compile it,
so it hasn't been built/run yet. To get it onto your iPhone:

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you don't
   have it: `brew install xcodegen`
2. From the repo root, generate the Xcode project:
   ```
   xcodegen generate
   ```
   This creates `RemindMe.xcodeproj` from `project.yml`.
3. Open `RemindMe.xcodeproj` in Xcode.
4. Select your Apple ID under **Signing & Capabilities** for the `RemindMe`
   target (any free personal team works for running on your own device).
5. Plug in your iPhone, select it as the run destination, and hit Run.
6. On first launch, grant "While Using the App" location access, then grant
   "Always" (iOS asks for this as a second, separate prompt after a delay
   or on a real background trigger) so geofences fire when the app is
   closed. Also allow notifications when prompted.

### Testing geofences

Region monitoring only fires reliably on a real device outdoors with a GPS
fix — the simulator's location simulation is unreliable for region-entry
events. Easiest test: add a place using "Use Current Location" with a small
radius, add a reminder, then walk (or drive) out of and back into that
radius.

## Known limitations / next steps

- Max 20 monitored places at once (iOS system limit on simultaneous
  geofences). If you save more, only the first 20 are actively monitored.
- The daily summary is only as fresh as the last time it was recomputed
  (app opened or a geofence fired) — there's no background timer forcing a
  recompute exactly at the digest time. For a personal app driven by your
  own location, this is usually fine, but if you go a full day without
  opening the app or passing a saved place, the numbers can be stale.
- No editing of an existing reminder's text or due date (delete and re-add
  for now).
- Repeated geofence entries fire a fresh notification each time, so
  standing right at the edge of a geofence boundary could, in principle,
  trigger a burst of duplicate notifications for the same reminder.

These are natural next additions once the core loop is working end to end.
