# ems-ios

EMS-redux client app for iOS.

Main usage is JavaZone but anyone who is using EMS-redux or who can deliver the same Collection+JSON feed structure can use the app.

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

## But I don't have the keys or accounts?

As noted in the building section we have two sets of keys that are used.

Google analytics is used for usage tracking. If you don't have a google analytics account then add the CFLAG -DDO_NOT_USE_GA=1

Crashlytics provides crash reporting. If you don't have a crashlytics account then add the CFLAG -DDO_NOT_USE_CRASHLYTICS=1

Note that this will also remove most debug logging - since that goes thru Crashlytics CLS_LOG (so that we get the logging alongside the crashlogs when reported).

You will also need to remove the target > Build Phases > Run Script that calls Crashlytics (this uploads dsym information to Crashlytics so that they can re-hydrate the crash log with file, line, method info etc).

On a final note - please **do not** commit the project files with either of these DO_NOT_... build flags set.

## Testers

Want to help us make the app better and more stable by being a beta tester?

Sign up at http://tflig.ht/dMc3DB

Note that we can't let everyone test - we have a limited number of slots available for device IDs but if you're interested - register your devices and we'll let you in if we can :)
