# ems-ios

EMS-redux client app for iOS.

Main usage is JavaZone.

## EMS-redux

EMS-redux is provided by javaBin: https://github.com/javaBin/ems-redux

## Building

The file EMS/EMS-Keys.plist is not provided. You will need to create this plist file.

The current keys it provides are:

* crashlytics-api-key
* google-analytics-tracking-id

See EMS/EMS-Keys.sample.plist.

### CFLAGS

The following CFLAGS are available

* USE_TEST_DATE - will use the current time but the first day of the selected conference when calculating Now & Next view
* TEST_PROD - will use the production server for debug builds
* DO_NOT_USE_GA - removes google analytics (and therefore the need for google-analytics-tracking-id in the EMS-Keys.plist)

None of these are to be used on production builds.

DO_NOT_USE_GA is provided only as a convenience for other developers to avoid having to have a google analytics key. It should not be present in the CFLAGS setting when files are committed to git.

## Testers

Want to help us make the app better and more stable by being a beta tester?

Sign up at http://tflig.ht/dMc3DB

Note that we can't let everyone test - we have a limited number of slots available for device IDs but if you're interested - register your devices and we'll let you in if we can :)
