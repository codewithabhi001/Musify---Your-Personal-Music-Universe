// Root build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ Define Kotlin version
extra.set("kotlin_version", "1.9.22")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Set custom build directory (optional - your use case)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// ✅ Define clean task only if not defined
if (!tasks.names.contains("clean")) {
    tasks.register<Delete>("clean") {
        delete(rootProject.layout.buildDirectory)
    }
}
