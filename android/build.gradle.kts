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
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            if (requested.group == "androidx.activity") {
                if (requested.name == "activity" || requested.name == "activity-ktx") {
                    useVersion("1.9.0")
                }
            }
            if (requested.group == "androidx.core") {
                if (requested.name == "core" || requested.name == "core-ktx") {
                    useVersion("1.13.1")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroid: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                
                if (getNamespace.invoke(android) == null) {
                    val namespace = "com.${name.replace("-", ".")}"
                    setNamespace.invoke(android, namespace)
                }
            } catch (e: Exception) {
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate { configureAndroid() }
    }
}


