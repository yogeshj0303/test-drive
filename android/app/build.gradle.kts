import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.driveeasy.atc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.DriveEasy.atc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 3
        versionName = "3.0.0"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            println("Keystore properties file found: ${keystorePropertiesFile.absolutePath}")
            val keystoreFile = rootProject.file(keystoreProperties["storeFile"] as String)
            println("Looking for keystore file at: ${keystoreFile.absolutePath}")
            if (keystoreFile.exists()) {
                println("Keystore file found, creating release signing config")
                create("release") {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = keystoreFile
                    storePassword = keystoreProperties["storePassword"] as String
                }
            } else {
                println("Keystore file NOT found at: ${keystoreFile.absolutePath}")
            }
        } else {
            println("Keystore properties file NOT found")
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists() && signingConfigs.findByName("release") != null) {
                println("Using custom release signing config")
                // Use custom signing config if keystore properties and file are available
                signingConfig = signingConfigs.getByName("release")
            } else {
                println("Falling back to debug signing config")
                // Use debug signing config if no keystore properties or file are available
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
