# 블랙오션 모드팩 (접속기가 내려받는 파일들)

접속기는 이 저장소의 `manifest.json` 을 읽어서 `pack/` 안의 파일을 시청자 PC 의 `.blackocean` 폴더에 맞춥니다.

## 모드 바꾸는 법 (스트리머용)
1. `pack/mods/` 에 jar 를 넣거나 지웁니다. (`pack/config/` 에 설정 파일도 가능)
2. `pack.config.json` 의 `notes` 에 업데이트 내용을 적습니다. (접속기 "소식" 칸에 보임)
3. 터미널에서 `node tools/build-manifest.js` 실행 → `manifest.json` 이 새로 만들어집니다.
4. GitHub Desktop 으로 commit → push.
5. 시청자는 접속기를 켜면(또는 "게임 시작"을 누르면) 자동으로 바뀐 파일만 내려받습니다.
   `mods/` 안에서 목록에 없는 파일은 자동으로 지워져요 (옛 버전 충돌 방지).

## 서버도 자동으로 (서버시작.bat)
`server-tools/서버시작.bat` 을 **서버 폴더**(run.bat 이 있는 곳)에 한 번 넣고, 앞으로는 서버를 이 파일로 켭니다.
- 켤 때마다 이 저장소의 manifest 를 보고 서버 `mods` 를 최신으로 맞춥니다.
- 시청자 PC 전용 모드(`clientOnly`)는 서버에 안 넣고, 실수로 있으면 치웁니다.
- 같은 모드의 옛 버전은 `mods_old` 폴더로 옮깁니다 (지우지 않음). 직접 넣은 다른 서버 모드는 건드리지 않습니다.
- `config` 는 서버에 없는 파일만 새로 넣습니다 (서버에서 바꾼 설정은 그대로).
- 서버에서 `stop` 하면 10초 뒤 업데이트 확인 → 자동으로 다시 켜집니다. 완전히 끄려면 창을 닫으세요.
- 실제 작업은 `server-start.ps1`, `server-update.ps1` 이 하고, 켤 때마다 최신으로 받아 오므로 bat 은 다시 받을 필요가 없습니다.
- bat 파일에는 한글을 넣지 마세요 (윈도우 명령창이 잘못 읽어 창이 바로 꺼짐). 안내 문구는 ps1 에 넣습니다.

## pack.config.json
- `rawBase`: `https://raw.githubusercontent.com/<깃허브아이디>/<저장소이름>/main` — 저장소 만들고 한 번만 맞추면 됨
- `server`: 접속기가 게임을 켜면 바로 이 서버로 들어감 (주소:포트)
- `onceFiles`: 처음 한 번만 복사하고 그 뒤로는 건드리지 않는 파일 (옵션·서버목록처럼 시청자가 바꾸는 것)
- `managedDirs`: 목록에 없는 파일을 지울 폴더
- `resourcePacks`: 접속기가 자동으로 켜 둘 리소스팩 (`pack/resourcepacks/` 에 넣은 zip 을 `file/이름.zip` 으로). 접속기 1.0.4 이상
- `removedResourcePacks`: 예전에 자동으로 켰다가 뺀 팩 이름 (시청자 목록에서 지움)
- `clientOnly`: 시청자 PC 에만 필요한 파일 (앞부분이 같으면 해당). 서버 업데이트가 건너뜀

## 주의
- 저장소는 **공개(public)** 여야 접속기가 로그인 없이 받을 수 있어요.
- 파일 하나 100MB 제한 (GitHub). 지금 가장 큰 파일은 sable 13MB 라 여유 있어요.
