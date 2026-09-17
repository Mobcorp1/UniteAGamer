import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties()
if (releaseSigningPropertiesFile.exists()) {
    FileInputStream(releaseSigningPropertiesFile).use { stream ->
        releaseSigningProperties.load(stream)
    }
}

fun releaseSigningValue(propertyName: String, environmentName: String): String? {
    val environmentValue = System.getenv(environmentName)?.trim()
    if (!environmentValue.isNullOrEmpty()) {
        return environmentValue
    }

    return releaseSigningProperties
        .getProperty(propertyName)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

val releaseStoreFile = releaseSigningValue("storeFile", "UAG_ANDROID_STORE_FILE")
val releaseStorePassword = releaseSigningValue("storePassword", "UAG_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = releaseSigningValue("keyAlias", "UAG_ANDROID_KEY_ALIAS")
val releaseKeyPassword = releaseSigningValue("keyPassword", "UAG_ANDROID_KEY_PASSWORD")
val hasCompleteReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "com.mobcorp.uagtradershub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mobcorp.uagtradershub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (hasCompleteReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseBuildRequested = allTasks.any { task ->
        task.path.startsWith(":app:") &&
            task.name.contains("Release", ignoreCase = true)
    }

    if (releaseBuildRequested && !hasCompleteReleaseSigning) {
        throw GradleException(
            "Android release signing is not configured. " +
                "Provide android/key.properties or all four UAG_ANDROID_* signing environment variables. " +
                "Debug builds remain available without release signing.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
