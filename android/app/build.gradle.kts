plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// These values are supplied by the release environment or CI secret store.
// Do not add a checked-in keystore or fall back to the debug signing key.
val releaseStoreFile = providers.environmentVariable("ANDROID_RELEASE_STORE_FILE").orNull
val releaseStorePassword = providers.environmentVariable("ANDROID_RELEASE_STORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("ANDROID_RELEASE_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("ANDROID_RELEASE_KEY_PASSWORD").orNull

android {
    namespace = "com.smartpublisher.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.smartpublisher.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Never fall back to the debug signing key. The verification task below
            // blocks release artifacts when any value is absent or invalid.
            storeFile = releaseStoreFile?.let(::file)
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val verifyReleaseSigning by tasks.registering {
    group = "verification"
    description = "Fails release artifact builds unless all release-signing inputs are present."

    doLast {
        val signingInputs = mapOf(
            "ANDROID_RELEASE_STORE_FILE" to releaseStoreFile,
            "ANDROID_RELEASE_STORE_PASSWORD" to releaseStorePassword,
            "ANDROID_RELEASE_KEY_ALIAS" to releaseKeyAlias,
            "ANDROID_RELEASE_KEY_PASSWORD" to releaseKeyPassword,
        )
        val missingInputs = signingInputs.filterValues { it.isNullOrBlank() }.keys
        check(missingInputs.isEmpty()) {
            "Release signing is not configured. Set: ${missingInputs.joinToString(", ")}."
        }

        check(file(releaseStoreFile!!).isFile) {
            "ANDROID_RELEASE_STORE_FILE does not reference a readable keystore file."
        }
    }
}

tasks.configureEach {
    if (name in setOf("assembleRelease", "bundleRelease", "packageRelease")) {
        dependsOn(verifyReleaseSigning)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
