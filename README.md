# ems-ios

EMS-redux client app for iOS.

Currently used for

* JavaZone
* flatMap

Can be used by anyone who is using EMS-redux or who can deliver the same Collection+JSON feed structure.

## EMS-redux

EMS-redux is provided by javaBin: https://github.com/javaBin/ems-redux

## Building

The file EMS/EMS-Keys.plist is not provided. You will need to create this plist file. Use `EMS/Config/EMS-Keys.sample.plist` as a sample, and place your file in either `JavaZone/EMS-Keys.plist` or `/flatMap/EMS-Keys.plist`.

The current keys it provides are:

* crashlytics-api-key
* google-analytics-tracking-id
* parse-client-key
* parse-app-id
* parse-client-key-prod
* parse-app-id-prod

**DO NOT JUST COPY THE SAMPLE FILE!** It will use the placeholders as keys and things will break. If you do not have keys - create an empty plist file.


The build uses cocoapods - so you will need to run the pod command and make sure you open EMS.xcworkspace and not EMS.xcodeproj.

### CFLAGS

The following CFLAGS are available

* USE_TEST_DATE
    * will use the current time but the first day of the selected conference when calculating Now & Next view
* TEST_PROD
    * will use the production server for debug builds
* TEST_PROD_NOTIFICATIONS
    * use the production notification server for a debug build (will require you to use correct certificate signing)
* SKIP_CONFIG_REFRESH
    * will not pull down new versions of the config plist file - useful when editing this locally for testing

None of these are to be used on production builds.

## But I don't have the keys or accounts?

For most things we'll detect that and not use them.

The one that this currently doesn't work totally with is Crashlytics.

To run Crashlytics in debug - you will need to change your scheme's build configuration from Debug to Debug Run Crashlytics.
