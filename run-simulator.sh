#!/usr/bin/env bash
# Build and run SwiftyCitizen on an iPhone simulator.
#
#   ./run-simulator.sh
#
# Prefers any booted iPhone (skipping Pro / Pro Max / Duo). If none is booted it
# boots an iPhone 17, then iPhone 17e, then the first compatible available device.
set -euo pipefail

SCHEME="SwiftyCitizen"
PROJECT="SwiftyCitizen.xcodeproj"
APP_BUNDLE="com.andres.paladines.multimedia.project.SwiftyCitizen"
DERIVED_DATA=".build/DerivedData"

log() { printf '\033[1;36m[swiftycitizen]\033[0m %s\n' "$*" >&2; }

open_device_hub() {
    log "Opening DeviceHub (Xcode 27 simulator frontend) ..."
    open -a "DeviceHub" 2>/dev/null \
        || log "Could not open DeviceHub automatically; open it from Xcode to see the simulator."
}

list_devices() {
    xcrun simctl list devices available | awk '
        /\(Booted\)|\(Shutdown\)/ {
            line = $0
            gsub(/^[ \t]+/, "", line)
            name = line;   sub(/ \(.*$/, "", name)
            udid = line;   sub(/^[^(]*\(/, "", udid); sub(/\).*/, "", udid)
            status = line; sub(/^.*\)[ \t]*\(/, "", status); sub(/\).*/, "", status)
            print name "|" status "|" udid
        }'
}

select_device() {
    local booted available chosen name udid

    booted=$(list_devices | grep '|Booted|' | grep -i 'iphone' | grep -viE 'pro|duo' || true)
    if [[ -n "$booted" ]]; then
        IFS='|' read -r name _ udid <<< "$(printf '%s\n' "$booted" | head -1)"
        log "Using booted simulator: $name ($udid)"
        printf '%s' "$udid"
        return 0
    fi

    available=$(list_devices | grep '|Shutdown|' | grep -i 'iphone' | grep -viE 'pro|duo' || true)
    if [[ -n "$available" ]]; then
        chosen=$(printf '%s\n' "$available" | awk -F'|' '
            $1 ~ /iPhone 17$/ { print; exit }
            $1 == "iPhone 17e" { print; exit }
            END {}')
        if [[ -z "$chosen" ]]; then
            chosen=$(printf '%s\n' "$available" | head -1)
        fi
        IFS='|' read -r name _ udid <<< "$chosen"
        log "Booting simulator: $name ($udid)"
        xcrun simctl boot "$udid" >/dev/null 2>&1 || true
        printf '%s' "$udid"
        return 0
    fi

    return 1
}

UDID=$(select_device) || {
    log "No compatible iPhone simulator found (skipping Pro / Pro Max / Duo)."
    exit 1
}

log "Building $SCHEME on simulator $UDID ..."
rm -rf "$DERIVED_DATA"
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED_DATA"

APP=$(find "$DERIVED_DATA" -type d -name "*.app" | head -1)
if [[ -z "${APP:-}" ]]; then
    log "Build produced no .app under $DERIVED_DATA."
    exit 1
fi

log "Installing and launching on $UDID ..."
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$APP_BUNDLE"
log "Launched $APP_BUNDLE."

open_device_hub
