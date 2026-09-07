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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val compileKotlinTask = this
        compilerOptions.jvmTarget.set(project.provider {
            val javaTaskName = compileKotlinTask.name.replace("Kotlin", "JavaWithJavac")
            val javaTask = project.tasks.findByName(javaTaskName) as? JavaCompile
            val javaVersion = javaTask?.targetCompatibility
                ?: (project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
                    ?.compileOptions?.targetCompatibility?.toString()
                ?: "17"

            when (javaVersion) {
                "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
        })
    }
}
