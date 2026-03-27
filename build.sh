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
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

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

# 앱 아이콘 복사
cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"

# 코드 서명
codesign -f -s - "${APP_BUNDLE}"

# /Applications에 설치
if [ "$1" = "--install" ]; then
    pkill -f "${APP_NAME}" 2>/dev/null || true
    sleep 1
    rm -rf "/Applications/${APP_BUNDLE}"
    cp -R "${APP_BUNDLE}" /Applications/
    codesign -f -s - "/Applications/${APP_BUNDLE}"
    echo "설치 완료: /Applications/${APP_BUNDLE}"
    open "/Applications/${APP_BUNDLE}"
else
    echo "빌드 완료: ${APP_BUNDLE}"
    echo "실행: open ${APP_BUNDLE}"
    echo "설치: bash build.sh --install"
fi
