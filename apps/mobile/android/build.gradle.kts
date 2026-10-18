allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Lock only repository-owned modules, never the Flutter SDK's test plugins.
subprojects {
    if (name == "app" || name == "session_engine") {
        dependencyLocking {
            lockAllConfigurations()
            // The pinned Flutter SDK selects engine coordinates per target ABI.
            // A single-device run must not require every APK ABI to resolve.
            ignoredDependencies.add("io.flutter:*")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
