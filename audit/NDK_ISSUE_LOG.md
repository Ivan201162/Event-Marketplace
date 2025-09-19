# NDK Issue Log

## E23 - NDK Disable Attempt

**Date:** $(Get-Date)

**Issue:** NDK still being used despite attempts to disable it

**Error Details:**
```
FAILURE: Build failed with an exception.

* Where:
Build file 'C:\Users\BlizZ\event_marketplace_app\android\build.gradle.kts' line: 29

* What went wrong:
A problem occurred configuring project ':app'.
> com.android.builder.errors.EvalIssueException: [CXX1101] NDK at C:\Android\ndk\27.0.12077973 did not have a source.properties file

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get the log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 3s
Running Gradle task 'assembleDebug'...                              4,2s        

┌─ Flutter Fix ───────────────────────────────────────────────────────────────┐
│     [!] This is likely due to a malformed download of the NDK.              │ 
│     This can be fixed by deleting the local NDK copy at:                    │
│     C:\Android\ndk\27.0.12077973                                            │ 
│     and allowing the Android Gradle Plugin to automatically re-download it. │ 
│                                                                             │ 
└─────────────────────────────────────────────────────────────────────────────┘ 
```

**Actions Taken:**
1. Commented out `ndkVersion = flutter.ndkVersion` in `android/app/build.gradle.kts`
2. Removed `android.bundle.enableUncompressedNativeLibs=false` from `android/gradle.properties`
3. Removed deprecated R8 options from `android/gradle.properties`
4. Added `android.useDeprecatedNdk=false` to `android/gradle.properties`

**Status:** NDK still being referenced by Android Gradle Plugin despite configuration changes. Continuing with next steps as per instructions.

**Next Steps:** Proceed to E24 (Windows release build) without further NDK troubleshooting.
