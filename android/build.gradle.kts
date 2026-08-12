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

// flutter_facebook_auth (added 2026-08-12 for native mobile sign-in) ships
// an Android module whose Kotlin compile task defaults to a newer JVM
// target (21) than its Java compile task (1.8) — Gradle refuses to link
// them ("Inconsistent JVM Target Compatibility"). The app's own module
// already targets 17 (app/build.gradle.kts); forcing every subproject's
// Java/Kotlin compile tasks to the same target here is the standard fix —
// it can't be patched inside the plugin itself since that source lives in
// the pub cache, not this repo.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
