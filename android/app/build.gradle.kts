import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.isFile) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.let {
    file(it)
}

val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {
    doLast {
        check(keystorePropertiesFile.isFile) {
            "Create android/key.properties before building a release APK."
        }

        val requiredKeys = listOf(
            "storePassword",
            "keyPassword",
            "keyAlias",
            "storeFile",
        )

        val missingKeys = requiredKeys.filter {
            keystoreProperties.getProperty(it).isNullOrBlank()
        }

        check(missingKeys.isEmpty()) {
            "Missing release signing settings: ${missingKeys.joinToString()}"
        }

        check(releaseStoreFile?.isFile == true) {
            "The release keystore was not found. Check storeFile in android/key.properties."
        }
    }
}

android {
    namespace = "rw.changa.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "rw.changa.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = releaseStoreFile
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}