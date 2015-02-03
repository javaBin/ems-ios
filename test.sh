#!/bin/sh

# Deps - brew install groovy and lcov, gem install xcpretty (or remove the pipe to it - cosmetic)

xcodebuild test -workspace EMS.xcworkspace/ -scheme 'JavaZone' -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 6,OS=8.1' | xcpretty -c --report junit

groovy http://frankencover.it/with -source-dir EMS