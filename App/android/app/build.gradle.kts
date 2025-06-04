// /android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.reqaize"
    // Updated based on the error log: Required by plugins
    compileSdk = 35
    // Updated based on the error log: Recommended NDK version
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Keep sourceCompatibility and targetCompatibility as they were
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Keep jvmTarget as it was
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.reqaize"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // Keep using Flutter's default unless specified otherwise
        targetSdk = flutter.targetSdkVersion // Consider updating this to 35 as well if issues persist, but compileSdk was the primary error
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add the manifestPlaceholders configuration here
        manifestPlaceholders["appAuthRedirectScheme"] = "com.example.reqaize"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Consider addingproguard rules if necessary for release builds
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Optional: Add dependencies block if needed, though none were mentioned in the error
dependencies {
    // implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version") // Example, ensure kotlin_version is defined if used
    // Add other dependencies here if required
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
}
