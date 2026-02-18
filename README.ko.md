# mac-mouse-scroll-is-bulpyun

[English](README.md)

맥에서 마우스 스크롤 방향만 반전시키는 메뉴바 앱입니다. 트랙패드는 건드리지 않습니다.

macOS는 "자연스러운 스크롤"을 트랙패드와 마우스에 동시에 적용합니다. 트랙패드는 자연스러운 스크롤이 좋지만 마우스는 전통적인 방향이 편하다면, 이 앱이 해결해 줍니다.

## 설치

### Homebrew (추천)

```bash
brew install --cask hulryung/tap/mac-mouse-scroll-is-bulpyun
```

### 수동 설치

[Releases](https://github.com/hulryung/mac-mouse-scroll-is-bulpyun/releases)에서 최신 `.dmg`를 다운로드하고, 열어서 앱을 `/Applications`으로 드래그하세요.

### 소스에서 빌드

```bash
git clone https://github.com/hulryung/mac-mouse-scroll-is-bulpyun.git
cd mac-mouse-scroll-is-bulpyun
bash build.sh
open mac-mouse-scroll-is-bulpyun.app
```

## 기능

- 마우스 스크롤 방향만 반전 (트랙패드 영향 없음)
- 메뉴바에 상주 — Dock 아이콘 없음
- 클릭 한 번으로 켜기/끄기
- 접근성 권한 부여 후 자동 활성화
- 로그인 시 자동 시작 (macOS 13+)
- 외부 의존성 없음, Swift + AppKit만 사용

## 요구 사항

- macOS 13.0 이상
- 접근성 권한 (첫 실행 시 안내)

## 사용법

메뉴바의 마우스 아이콘을 클릭하면:

- **스크롤 반전** 켜기/끄기
- **설정** 창 열기 (ON/OFF 스위치, 로그인 시 자동 시작 옵션)
- **종료**

처음 실행하면 시스템 설정이 자동으로 열립니다. **시스템 설정 > 개인정보 보호 및 보안 > 접근성**에서 허용하면 스크롤 반전이 자동으로 활성화됩니다.

> **참고:** 소스에서 다시 빌드하면 macOS가 새 바이너리를 다른 앱으로 인식합니다. 기존 항목을 삭제하고 접근성 권한을 다시 부여해야 할 수 있습니다.

## 동작 원리

`CGEventTap`을 HID 레벨에서 사용하여 스크롤 휠 이벤트를 가로챕니다. `scrollWheelEventIsContinuous` 값으로 마우스(불연속, `0`)와 트랙패드(연속, `1`)를 구분합니다. 마우스 이벤트의 경우, 반전된 델타 값으로 새 `CGEvent`를 생성하여 macOS가 스크롤 방향을 결정하는 원본 IOHIDEvent를 우회합니다.

## 후원

이 앱이 유용하다면 프로젝트를 후원해 주세요:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/hulryung)

## 라이선스

MIT
