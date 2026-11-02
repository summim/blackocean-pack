# 블랙오션 모드팩 (접속기가 내려받는 파일들)

접속기는 이 저장소의 `manifest.json` 을 읽어서 `pack/` 안의 파일을 시청자 PC 의 `.blackocean` 폴더에 맞춥니다.

## 모드 바꾸는 법 (스트리머용)
1. `pack/mods/` 에 jar 를 넣거나 지웁니다. (`pack/config/` 에 설정 파일도 가능)
2. `pack.config.json` 의 `notes` 에 업데이트 내용을 적습니다. (접속기 "소식" 칸에 보임)
3. 터미널에서 `node tools/build-manifest.js` 실행 → `manifest.json` 이 새로 만들어집니다.
4. GitHub Desktop 으로 commit → push.
5. 시청자는 접속기를 켜면(또는 "게임 시작"을 누르면) 자동으로 바뀐 파일만 내려받습니다.
   `mods/` 안에서 목록에 없는 파일은 자동으로 지워져요 (옛 버전 충돌 방지).

## pack.config.json
- `rawBase`: `https://raw.githubusercontent.com/<깃허브아이디>/<저장소이름>/main` — 저장소 만들고 한 번만 맞추면 됨
- `server`: 접속기가 게임을 켜면 바로 이 서버로 들어감 (주소:포트)
- `onceFiles`: 처음 한 번만 복사하고 그 뒤로는 건드리지 않는 파일 (옵션·서버목록처럼 시청자가 바꾸는 것)
- `managedDirs`: 목록에 없는 파일을 지울 폴더

## 주의
- 저장소는 **공개(public)** 여야 접속기가 로그인 없이 받을 수 있어요.
- 파일 하나 100MB 제한 (GitHub). 지금 가장 큰 파일은 sable 13MB 라 여유 있어요.
