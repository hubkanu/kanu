pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned below the Flutter template's AGP 9 default: flutter_inappwebview_android's
    // build.gradle still calls the pre-AGP9 getDefaultProguardFile('proguard-android.txt'),
    // which AGP 9 hard-errors on (see https://github.com/pichillilorenzo/flutter_inappwebview
    // issues about AGP 9 support). AGP 8.7.x is the newest line every current plugin here
    // still supports.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Required by firebase_core/firebase_messaging to read google-services.json.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
