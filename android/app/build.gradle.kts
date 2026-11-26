import java.util.Properties

plugins {
    id("com.android.application")
    // O plugin Gradle do Flutter deve ser aplicado depois dos plugins Gradle do Android e do Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.isFile) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val signingFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning = signingFields.all {
    !keystoreProperties.getProperty(it).isNullOrBlank()
}

val validateReleaseSigning by tasks.registering {
    doLast {
        check(hasReleaseSigning) {
            "Configure android/key.properties a partir de key.properties.example. " +
                "Consulte docs/DISTRIBUICAO.md. A versão release exige sua chave de publicação."
        }
        check(rootProject.file(keystoreProperties.getProperty("storeFile")).isFile) {
            "O keystore de publicação não foi encontrado. Verifique storeFile em android/key.properties."
        }
    }
}

tasks.matching {
    it.name in setOf("validateSigningRelease", "packageRelease", "signReleaseBundle", "bundleRelease", "assembleRelease")
}.configureEach {
    dependsOn(validateReleaseSigning)
}

android {
    namespace = "com.suiany.meuplanner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.suiany.meuplanner"
        // Atualize os valores abaixo conforme as necessidades do aplicativo.
        // Para saber mais, consulte: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Usa o número da compilação de pubspec.yaml. Nos APKs separados por arquitetura, 1000 * ABI_VERSION
        // é adicionado automaticamente pelo Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // Para forçar o uso de versionCode, informe a opção `-P force-version-code-ignoring-abi=true`
        // durante a compilação.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
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
