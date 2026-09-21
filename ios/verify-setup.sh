#!/usr/bin/env bash
# Prüft, ob Task 2 (Xcode-Projekt) vollständig ist.
set -uo pipefail
cd "$(dirname "$0")/.."

fehler=0
ok()   { printf "  ok    %s\n" "$1"; }
fail() { printf "  FEHLT %s\n" "$1"; fehler=$((fehler+1)); }

echo "[1] Projektdateien"
[ -d ios/Kaskade.xcodeproj ] && ok "ios/Kaskade.xcodeproj" || fail "ios/Kaskade.xcodeproj"
[ -d ios/Kaskade ]           && ok "ios/Kaskade/"                || fail "ios/Kaskade/"

echo "[2] Pakete"
resolved=$(find ios -name Package.resolved -print -quit 2>/dev/null)
if [ -n "$resolved" ]; then
  grep -q "GRDB" "$resolved" && ok "GRDB aufgelöst" || fail "GRDB in Package.resolved"
  grep -qi "maplibre" "$resolved" && ok "MapLibre aufgelöst" || fail "MapLibre in Package.resolved"
else
  fail "Package.resolved (Pakete noch nicht aufgelöst?)"
fi

echo "[3] Berechtigungen"
plist=$(find ios -name "Info.plist" -not -path "*/build/*" -print -quit 2>/dev/null)
pbx="ios/Kaskade.xcodeproj/project.pbxproj"
suche() {  # Xcode 15+ legt die Keys teils in der pbxproj ab, nicht in einer Info.plist
  { [ -n "$plist" ] && grep -q "$1" "$plist"; } || { [ -f "$pbx" ] && grep -q "$1" "$pbx"; }
}
for key in NSLocationWhenInUseUsageDescription \
           NSLocationAlwaysAndWhenInUseUsageDescription \
           NSMotionUsageDescription \
           NSBluetoothAlwaysUsageDescription \
           NSNearbyInteractionUsageDescription \
           NSCameraUsageDescription \
           NSLocalNetworkUsageDescription \
           UIBackgroundModes; do
  suche "$key" && ok "$key" || fail "$key"
done

echo "[4] Schlüssel-Konfiguration"
[ -f ios/Config.local.xcconfig ] && ok "Config.local.xcconfig vorhanden" \
  || fail "Config.local.xcconfig (aus Config.example.xcconfig kopieren)"
if git ls-files --error-unmatch ios/Config.local.xcconfig >/dev/null 2>&1; then
  printf "  FEHLER Config.local.xcconfig ist eingecheckt — sofort entfernen\n"; fehler=$((fehler+1))
else
  ok "Config.local.xcconfig ist nicht eingecheckt"
fi

echo "[5] Build"
if [ -d ios/Kaskade.xcodeproj ]; then
  sim=$(xcrun simctl list devices available 2>/dev/null | grep -oE "iPhone [0-9]+" | tail -1)
  sim=${sim:-iPhone 16}
  if xcodebuild -project ios/Kaskade.xcodeproj -scheme Kaskade \
       -destination "platform=iOS Simulator,name=$sim" build >/tmp/tt-build.log 2>&1; then
    ok "xcodebuild build ($sim)"
  else
    fail "xcodebuild build — Ausgabe in /tmp/tt-build.log"
    tail -20 /tmp/tt-build.log | sed 's/^/        /'
  fi
fi

echo
if [ "$fehler" -eq 0 ]; then
  echo "Task 2 vollständig. Task 3 kann starten."
else
  echo "$fehler Punkt(e) offen — siehe ios/SETUP.md"
fi
exit "$fehler"
