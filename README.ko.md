# mac-mouse-scroll-is-bulpyun

[English](README.md)

맥에서 마우스 스크롤 방향만 반전시키는 메뉴바 앱입니다. 트랙패드는 건드리지 않습니다.

macOS는 "자연스러운 스크롤"을 트랙패드와 마우스에 동시에 적용합니다. 트랙패드는 자연스러운 스크롤이 좋지만 마우스는 전통적인 방향이 편하다면, 이 앱이 해결해 줍니다.

## 기능

- 마우스 스크롤 방향만 반전 (트랙패드 영향 없음)
- 메뉴바에 상주 — Dock 아이콘 없음
- 클릭 한 번으로 켜기/끄기
- 로그인 시 자동 시작 (macOS 13+)
- 외부 의존성 없음, Swift + AppKit만 사용

## 요구 사항

- macOS 13.0 이상
- 접근성 권한 (첫 실행 시 안내)

## 빌드

```bash
git clone https://github.com/hulryung/mac-mouse-scroll-is-bulpyun.git
cd mac-mouse-scroll-is-bulpyun
bash build.sh
```

## 실행

```bash
open mac-mouse-scroll-is-bulpyun.app
```

처음 실행하면 접근성 권한을 요청합니다. **시스템 설정 > 개인정보 보호 및 보안 > 접근성**에서 허용해 주세요.

## 사용법

메뉴바의 마우스 아이콘을 클릭하면:

- **스크롤 반전** 켜기/끄기
- **설정** 창 열기 (ON/OFF 스위치, 로그인 시 자동 시작 옵션)
- **종료**

## 동작 원리

`CGEventTap`으로 스크롤 휠 이벤트를 가로챕니다. `scrollWheelEventIsContinuous` 값으로 마우스(불연속, `0`)와 트랙패드(연속, `1`)를 구분하고, 마우스 이벤트만 방향을 반전시킵니다.

## 라이선스

MIT
