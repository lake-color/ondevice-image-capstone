# Windows 개발 환경 설정 가이드

이 문서는 Windows에서 저장소를 처음 내려받은 팀원이 Android 앱을 실행할 때까지 따라 하는 순서로 작성되었습니다. 모든 명령은 **PowerShell 또는 CMD**에서 실행할 수 있습니다.

## 1. 프로젝트 기준 환경

현재 저장소의 설정을 기준으로 확인한 내용은 다음과 같습니다.

| 항목 | 프로젝트 설정 |
| --- | --- |
| Flutter | 3.47.2 stable (`.metadata`의 리비전 기준) |
| Dart | 3.13.2 (`pubspec.yaml`의 `sdk: ^3.13.2`) |
| FVM | 사용함 |
| Android 빌드 | Gradle Wrapper 9.3.1, Android Gradle Plugin 9.1.0 |
| Java 호환 수준 | 17 |
| 앱 진입점 | `lib/main.dart` |

현재 저장소에는 `.fvmrc`와 `.fvm/`이 커밋되어 있지 않습니다. 따라서 아래 절차에서는 Flutter 3.47.2를 FVM에 설치하고 FVM의 전역 기본 버전으로 지정합니다. 이후 이 프로젝트의 Flutter 명령은 모두 `fvm flutter ...` 형식으로 실행합니다.

현재 프로젝트에는 별도의 `.env`, API 키, 코드 생성, flavor 설정이 필요하지 않습니다. `pubspec.yaml`에도 별도 asset 등록이나 네이티브 플러그인 의존성이 없습니다. 팀에서 전달받지 않은 비밀키나 개인정보를 임의로 만들거나 저장소에 커밋하지 마세요.

## 2. 필수 도구 설치

다음 프로그램을 먼저 설치합니다.

1. **Git for Windows**: 저장소 clone과 FVM의 Flutter SDK 다운로드에 필요합니다.
2. **Android Studio**: Android SDK, Emulator, 빌드 도구 설치에 필요합니다.
3. **FVM**: 프로젝트에서 사용할 Flutter SDK 버전을 관리합니다.
4. **편집기 플러그인(권장)**: Android Studio 또는 VS Code에 Flutter와 Dart 플러그인을 설치합니다.

Windows용 Flutter 개발은 일반적으로 Windows 10/11 64비트 환경을 사용합니다. Flutter SDK를 직접 설치한다면 `C:\Program Files`처럼 관리자 권한이 필요하거나 공백이 포함된 경로를 피하고, 예를 들어 `C:\flutter` 또는 `C:\src\flutter`를 사용하세요. 이 프로젝트에서는 FVM이 필요한 Flutter SDK를 내려받으므로 별도 Flutter SDK 설치는 필수가 아닙니다.

### FVM 설치

Chocolatey가 설치되어 있다면 **관리자 권한** PowerShell 또는 CMD에서 다음을 실행합니다.

```powershell
choco install fvm -y
```

Chocolatey를 사용하지 않는 경우 [FVM 공식 설치 문서](https://fvm.app/documentation/getting-started/installation)의 Windows standalone archive 방법으로 설치하고, `fvm.exe`가 있는 디렉터리를 사용자 `Path` 환경 변수에 추가합니다.

설치 후 열려 있던 터미널과 IDE를 모두 닫았다가 다시 열고 확인합니다.

```powershell
git --version
fvm --version
```

`fvm`을 찾을 수 없다는 메시지가 나오면 FVM 설치 경로가 `Path`에 들어 있는지 확인한 뒤 터미널을 다시 시작합니다.

## 3. Android 개발 환경 구성

Android Studio를 실행한 뒤 **SDK Manager**에서 다음 항목을 설치합니다.

- Android SDK Platform: Flutter 3.47.2가 요구하는 플랫폼. 정확한 누락 항목은 뒤에서 실행할 `flutter doctor`가 표시합니다.
- Android SDK Build-Tools
- Android SDK Command-line Tools (latest)
- Android SDK Platform-Tools
- Android Emulator

이 프로젝트의 Gradle 설정은 Java 소스 및 Kotlin JVM 대상 버전을 17로 지정합니다. Android Studio에 포함된 JDK를 우선 사용하면 됩니다. 외부 JDK를 선택하는 경우 Java 17 이상과 현재 Android Gradle Plugin의 호환성을 확인하세요.

Android SDK 위치가 자동 감지되지 않으면 실제 설치 경로를 확인한 뒤 다음과 같이 등록합니다. 아래 경로는 기본 예시이므로 `<사용자명>`을 실제 Windows 계정명으로 바꿉니다.

```powershell
fvm flutter config --android-sdk "C:\Users\<사용자명>\AppData\Local\Android\Sdk"
```

Android 라이선스를 확인하고 동의합니다.

```powershell
fvm flutter doctor --android-licenses
```

표시되는 라이선스를 읽고 동의할 항목에 `y`를 입력합니다.

## 4. 저장소 clone

개발 폴더로 이동한 다음 저장소를 clone합니다.

```powershell
cd C:\경로\개발폴더
git clone https://github.com/lake-color/ondevice-image-capstone.git
cd ondevice-image-capstone
```

이미 clone했다면 반드시 프로젝트 루트, 즉 `pubspec.yaml`이 있는 디렉터리로 이동합니다.

```powershell
cd C:\Users\jdong\Desktop\CodingWorkspace\Projects\ondevice-image-capstone
```

## 5. Flutter 3.47.2를 FVM으로 준비

프로젝트가 생성된 Flutter 버전과 동일한 3.47.2를 설치하고 FVM 기본 버전으로 선택합니다.

```powershell
fvm install 3.47.2
fvm global 3.47.2
fvm flutter --version
fvm dart --version
```

정상이라면 Flutter 3.47.2 stable과 Dart 3.13.2가 표시됩니다. 다운로드에는 시간이 걸릴 수 있습니다.

이 저장소에는 프로젝트별 FVM 설정인 `.fvmrc`가 없으므로 `fvm install`만 실행한 뒤 `fvm flutter`를 사용하면 선택할 로컬 SDK가 없을 수 있습니다. 위의 `fvm global 3.47.2`를 빠뜨리지 마세요. 다른 프로젝트의 FVM 전역 버전을 바꾸고 싶지 않다면, 이 프로젝트에서 다음과 같이 버전을 명시해 실행할 수도 있습니다.

```powershell
fvm spawn 3.47.2 pub get
fvm spawn 3.47.2 run
```

`flutter`나 `dart`를 직접 실행하면 FVM이 선택한 버전이 아닌 시스템 `Path`의 SDK가 사용될 수 있습니다. 이 프로젝트에서는 `fvm flutter`와 `fvm dart`를 사용하세요. SDK 버전을 임의로 올리는 `flutter upgrade`도 실행하지 않습니다.

## 6. 의존성 설치와 초기 점검

프로젝트 루트에서 lock 파일에 기록된 버전대로 의존성을 설치합니다.

```powershell
fvm flutter pub get
```

`pubspec.lock`이 저장소에 포함되어 있으므로 첫 설정에서 `pub upgrade` 또는 `pub upgrade --major-versions`를 실행할 필요가 없습니다.

기본 정적 검사와 테스트도 실행할 수 있습니다.

```powershell
fvm flutter analyze
fvm flutter test
```

Android의 `local.properties`는 각 개발자의 Flutter SDK 및 Android SDK 로컬 경로를 담는 파일입니다. Flutter/Gradle 실행 과정에서 로컬 환경에 맞게 생성되며 Git에서 제외되어 있습니다. 다른 팀원의 절대 경로가 들어 있는 파일을 복사하거나 커밋하지 마세요.

## 7. `flutter doctor`로 환경 점검

FVM이 선택한 Flutter 환경을 기준으로 상세 진단을 실행합니다.

```powershell
fvm flutter doctor -v
```

Android 실행에 필요한 핵심 항목은 다음과 같습니다.

- Flutter 3.47.2 stable이 선택되어 있음
- Android toolchain이 정상임
- Android Studio와 Android SDK가 감지됨
- 사용할 Android 에뮬레이터 또는 실기기가 감지됨

Windows desktop용 Visual Studio나 Chrome 관련 경고는 Android 앱 실행만 할 경우 직접적인 차단 원인이 아닐 수 있습니다. `Android toolchain`과 연결할 Android 기기의 오류를 먼저 해결합니다. 설정을 바꾼 뒤 같은 명령을 다시 실행해 결과를 확인하세요.

## 8. Android 에뮬레이터 준비

Android Studio에서 다음 순서로 에뮬레이터를 만듭니다.

1. **Tools > Device Manager**를 엽니다.
2. **Create Device**를 선택합니다.
3. Phone 장치 정의와 Android 시스템 이미지를 선택해 다운로드합니다.
4. Windows BIOS/UEFI에서 CPU 가상화가 활성화되어 있는지 확인합니다.
5. Device Manager에서 생성한 에뮬레이터를 시작합니다.

터미널에서 인식 상태를 확인할 수 있습니다.

```powershell
fvm flutter emulators
fvm flutter devices
```

에뮬레이터 ID를 알고 있다면 터미널에서 시작할 수도 있습니다.

```powershell
fvm flutter emulators --launch <에뮬레이터_ID>
```

## 9. Android 실기기 준비

1. Android 기기에서 **개발자 옵션**과 **USB 디버깅**을 활성화합니다.
2. Windows에 기기 제조사의 USB 드라이버를 설치합니다. Google 기기는 SDK Manager의 Google USB Driver를 사용할 수 있습니다.
3. USB 케이블로 연결하고 기기에 표시되는 이 컴퓨터의 디버깅 허용 창을 승인합니다.
4. 연결 상태를 확인합니다.

```powershell
fvm flutter devices
```

기기가 `unauthorized`로 표시되면 케이블을 다시 연결한 뒤 기기의 USB 디버깅 승인 창을 확인합니다.

## 10. 프로젝트 실행

에뮬레이터를 켜거나 실기기를 연결한 상태에서 프로젝트 루트에서 실행합니다.

```powershell
fvm flutter run
```

기기가 여러 대이면 먼저 ID를 확인하고 대상 기기를 지정합니다.

```powershell
fvm flutter devices
fvm flutter run -d <기기_ID>
```

실행 중인 터미널에서 `r`은 hot reload, `R`은 hot restart, `q`는 실행 종료입니다. 현재 앱 진입점은 기본값인 `lib/main.dart`이므로 별도의 `--target` 옵션은 필요하지 않습니다.

## 11. 자주 발생하는 문제

### `fvm` 명령을 찾을 수 없음

FVM 설치 경로가 사용자 `Path`에 포함되어 있는지 확인합니다. 환경 변수를 수정했다면 PowerShell/CMD와 IDE를 모두 닫았다가 다시 실행하고 `fvm --version`을 확인합니다.

### `fvm flutter`가 SDK를 찾지 못함

현재 저장소에는 `.fvmrc`가 없습니다. 다음 명령으로 정확한 버전을 설치하고 FVM 기본 버전을 다시 지정합니다.

```powershell
fvm install 3.47.2
fvm global 3.47.2
fvm flutter --version
```

FVM 캐시나 Git 관련 상세 진단은 다음 명령으로 확인합니다.

```powershell
fvm doctor
```

### Dart SDK 버전 오류

`pubspec.yaml`은 Dart 3.13.2 이상 4.0.0 미만을 요구하지만, 팀 환경 재현을 위해 Flutter 3.47.2에 포함된 Dart 3.13.2를 사용합니다. 시스템의 오래된 Flutter가 실행된 경우가 많으므로 `flutter --version` 대신 다음 결과를 확인합니다.

```powershell
fvm flutter --version
fvm dart --version
```

### Android 라이선스 또는 command-line tools 오류

Android Studio의 SDK Manager에서 **Android SDK Command-line Tools (latest)**를 설치한 뒤 다시 실행합니다.

```powershell
fvm flutter doctor --android-licenses
fvm flutter doctor -v
```

### Android SDK를 찾지 못함

Android Studio의 SDK Manager 상단에서 실제 SDK 경로를 확인하고 등록합니다.

```powershell
fvm flutter config --android-sdk "<실제_Android_SDK_경로>"
fvm flutter doctor -v
```

### `flutter.sdk not set in local.properties`

프로젝트 루트에서 FVM을 통해 의존성을 다시 받고 실행합니다. 그러면 로컬 SDK 경로에 맞춰 Android 설정이 준비됩니다.

```powershell
fvm flutter pub get
fvm flutter run
```

직접 수정해야 한다면 `android\local.properties`의 `flutter.sdk`와 `sdk.dir`에는 본인 PC의 실제 경로만 사용합니다. 이 파일은 로컬 전용이며 커밋하지 않습니다.

### Java 또는 Gradle 빌드 오류

먼저 Flutter가 실제로 사용하는 Java 경로와 버전을 확인합니다.

```powershell
fvm flutter doctor -v
java -version
```

이 프로젝트는 Java/Kotlin 대상 버전을 17로 설정합니다. Android Studio에 포함된 JDK를 사용하거나, `flutter doctor -v`가 가리키는 JDK가 현재 Android Gradle Plugin과 호환되는지 확인합니다. Gradle은 저장소의 Wrapper가 자동으로 9.3.1을 내려받으므로 별도 Gradle 설치는 필요하지 않습니다.

### 에뮬레이터가 시작되지 않음

BIOS/UEFI의 가상화 기능과 Windows의 가상화 지원이 켜져 있는지 확인합니다. Android Studio Device Manager에서 시스템 이미지를 다시 확인하고, 다른 가상화 프로그램과의 충돌 여부도 점검합니다.

### 실기기가 목록에 나오지 않음

USB 디버깅, 기기의 연결 승인, 데이터 전송이 가능한 USB 케이블, 제조사 USB 드라이버를 순서대로 확인합니다. 연결 후 다음 명령을 다시 실행합니다.

```powershell
fvm flutter devices
```

### 의존성 다운로드 실패

인터넷 연결, 회사 프록시/VPN, 방화벽에서 GitHub·Flutter SDK 저장소·pub.dev 접근 가능 여부를 확인한 뒤 다시 실행합니다.

```powershell
fvm flutter pub get
```

캐시 문제로 의심되더라도 먼저 오류 메시지를 확인하세요. `pubspec.lock`을 삭제하거나 패키지 버전을 임의로 올리면 팀과 다른 의존성 조합이 만들어질 수 있습니다.

## 12. 최종 확인 명령

아래 명령이 모두 성공하면 기본 개발 환경 구성이 끝난 것입니다.

```powershell
fvm --version
fvm flutter --version
fvm dart --version
fvm flutter doctor -v
fvm flutter pub get
fvm flutter devices
fvm flutter run
```

공식 참고 문서:

- [Flutter: Windows에서 Android 개발 환경 구성](https://docs.flutter.dev/get-started/install/windows/mobile)
- [Flutter: Android 개발 설정](https://docs.flutter.dev/platform-integration/android/setup)
- [FVM: 설치](https://fvm.app/documentation/getting-started/installation)
- [FVM: 명령어](https://fvm.app/documentation/guides/basic-commands)
