import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) {
    FileInputStream(signingFile).use { signingProperties.load(it) }
}

android {
    namespace = "app.lumaledger.luma_ledger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "app.lumaledger.luma_ledger"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingFile.exists()) {
            create("release") {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (signingFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
                throw GradleException("Configure android/key.properties before making a release build. See docs/DISTRIBUTION.md.")
            }
        }
    }
}

flutter {
    source = "../.."
}
