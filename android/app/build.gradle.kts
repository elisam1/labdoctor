plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")  // Updated plugin ID (preferred over "kotlin-android")
    id("com.google.gms.google-services") // For Firebase
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.labdoctor"
    compileSdk = flutter.compileSdkVersion.toInteger()  // Ensure it's an integer
    ndkVersion = flutter.ndkVersion
    defaultConfig {
        manifestPlaceholders = [
            'appAuthRedirectScheme': 'com.google.firebase.auth.default'
        ]

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // Recommended for AGP 8.0+
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"  // Match Java version (required for newer Kotlin features)
    }

    defaultConfig {
        applicationId = "com.example.labdoctor"  // Replace with your package name (e.g., "com.yourcompany.labdoctor")
        minSdk = flutter.minSdkVersion.toInteger()  // Ensure integer
        targetSdk = flutter.targetSdkVersion.toInteger()
        versionCode = flutter.versionCode.toInteger()
        versionName = flutter.versionName
        multiDexEnabled = true  // Add if using Firebase/Analytics
    }

    buildTypes {
        release {
            // TODO: Replace with your release signing config (never use debug in production)
            signingConfig = signingConfigs.debug
            // Enable code shrinking and obfuscation
            minifyEnabled true
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
    }
}

flutter {
    source = "../.."
}

// Optional: Add Firebase dependencies explicitly (if not using FlutterFire CLI)
dependencies {
    implementation platform("com.google.firebase:firebase-bom:32.7.2")  // Check latest version
    implementation "com.google.firebase:firebase-analytics-ktx"  // Recommended for Firebase Analytics
}