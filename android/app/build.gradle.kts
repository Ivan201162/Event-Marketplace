import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.eventmarketplace.app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.eventmarketplace.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Web Client ID для Google Sign-In (из google-services.json)
        manifestPlaceholders["appAuthRedirectScheme"] = applicationId.toString()
        // default_web_client_id уже создаётся Google Services plugin из google-services.json
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

// Проверка наличия google-services.json перед сборкой
tasks.register("verifyGoogleServicesJson") {
    doLast {
        val f = file("$projectDir/google-services.json")
        if (!f.exists()) {
            throw GradleException("google-services.json NOT FOUND at android/app/. Aborting.")
        }
        val text = f.readText()
        if (!text.contains("\"package_name\"")) {
            throw GradleException("google-services.json missing package_name")
        }
        if (!text.contains("client_info")) {
            throw GradleException("google-services.json missing client_info")
        }
    }
}

tasks.matching { it.name == "preBuild" || it.name.startsWith("preReleaseBuild") }.configureEach {
    dependsOn(tasks.named("verifyGoogleServicesJson"))
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Firebase BOM for version management
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}
