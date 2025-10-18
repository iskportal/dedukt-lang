plugins {
    kotlin("jvm") version "2.2.0"
    application
    antlr
}

group = "com.iskportal.dedukt.lang"
version = "0.0.4-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    // Antlr Runtime Dependencies for the generated Parser and Lexer
    antlr("org.antlr:antlr4:4.+")
    implementation("org.antlr:antlr4-runtime:4.+")

    // Kotlin standard library
    implementation(kotlin("stdlib"))
    // Kotlin test library
    testImplementation(kotlin("test"))
}

// ANTLR code generation task configuration
tasks.generateGrammarSource {
    // Maximum heap size for ANTLR tool
    maxHeapSize = "64m"

    // Arguments passed to ANTLR
    arguments = arguments + listOf(
        "-visitor",      // Generate parse tree visitor (recommended)
        "-listener",     // Generate parse tree listener (default, but explicit)
        "-package", "com.iskportal.dedukt.lang.parser.generated",  // Java package for generated files
        "-long-messages" // More detailed error messages
    )

    // Output directory for generated sources
    outputDirectory = file("src/main/kotlin/com/iskportal/dedukt/lang/parser/generated")

}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    dependsOn(tasks.generateGrammarSource)
    dependsOn(tasks.generateTestGrammarSource)  // Add this line
}
sourceSets {
    main {
        java {
            srcDir("src/main/kotlin/com/iskportal/dedukt/lang/parser/generated")
        }
    }
}

application {
    mainClass.set("com.iskportal.dedukt.lang.parser.MainKt")

    applicationName = "dedukt-lang-parser"

    applicationDefaultJvmArgs = listOf(
        "-Xmx512m",
        "-Xms256m",
        "-XX:+UseG1GC",
        "-Dfile.encoding=UTF-8",
        "-Duser.timezone=UTC"
    )

}

tasks.named<JavaExec>("run") {
    // Arguments passed to the application (not JVM args)
    // Can be set via: gradle run --args="arg1 arg2"

    // Standard input
    standardInput = System.`in`

    // Optional: Working directory
    // workingDir = file("runtime")

    // Optional: Environment variables
    // environment("ENV_VAR", "value")

    // Optional: Additional JVM arguments (specific to 'run' task)
    // jvmArgs = listOf("-Xdebug")
}


distributions {
    main {
        // Customize the contents of the distribution
        contents {
            // Add additional files to the distribution
            from("README.md")
            from("LICENSE")

            // Add a directory
            // from("config") {
            //     into("config")
            // }
        }
    }
}


tasks.named<CreateStartScripts>("startScripts") {
    // Optional: Customize the application home directory variable name
    // applicationName = "MY_APP"

    // Optional: Add additional classpath entries
    // classpath = files("config") + classpath

    // Optional: Default JVM options (overrides applicationDefaultJvmArgs)
    // defaultJvmOpts = listOf("-Xmx1g")

    // Optional: Customize Unix script
    // unixStartScriptGenerator.template = resources.text.fromFile("customUnixScript.txt")

    // Optional: Customize Windows script
    // windowsStartScriptGenerator.template = resources.text.fromFile("customWindowsScript.txt")
}

// =============================================================================
// KOTLIN COMPILER CONFIGURATION
// =============================================================================

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlin {
        jvmToolchain(17)

    }
}

// =============================================================================
// JAVA TOOLCHAIN CONFIGURATION
// =============================================================================

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}