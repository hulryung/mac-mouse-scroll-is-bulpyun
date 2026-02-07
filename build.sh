#!/bin/bash
# 마우스 스크롤 방향 반전 메뉴바 앱 빌드 스크립트

set -e

APP_NAME="mac-mouse-scroll-is-bulpyun"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

# 기존 앱 번들 정리
rm -rf "${APP_BUNDLE}"

# 앱 번들 디렉토리 구조 생성
mkdir -p "${MACOS_DIR}"

# Swift 소스 컴파일
swiftc \
    Sources/main.swift \
    Sources/ScrollManager.swift \
    Sources/AppDelegate.swift \
    Sources/SettingsWindow.swift \
    -o "${MACOS_DIR}/${APP_NAME}" \
    -framework AppKit \
    -framework CoreGraphics \
    -framework CoreFoundation \
    -framework ApplicationServices \
    -framework ServiceManagement

# Info.plist 복사
cp Info.plist "${CONTENTS_DIR}/Info.plist"

echo "빌드 완료: ${APP_BUNDLE}"
echo "실행: open ${APP_BUNDLE}"
