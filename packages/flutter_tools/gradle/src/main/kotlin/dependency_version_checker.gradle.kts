// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper

// This buildscript block supplies dependencies for this file's own import
// declarations above. It exists solely for compatibility with projects that
// have not migrated to declaratively apply the Flutter Gradle Plugin;
// for those that have, FGP's `build.gradle.kts`  takes care of this.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // When bumping, also update:
        //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/flutter.groovy
        //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
        //  * AGP version in dependencies block in packages/flutter_tools/gradle/build.gradle.kts
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10")
    }
}

apply<FlutterDependencyCheckerPlugin>()

class FlutterDependencyCheckerPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        DependencyVersionChecker.checkDependencyVersions(project)
    }
}


class DependencyVersionChecker {
    companion object {
        // The following versions define our support policy for Gradle, Java, AGP, and KGP.
        // All "error" versions are currently set to 0 as this policy is new. They will be increased
        // to match the current values of the "warn" versions in the next release.
        // Before updating any "error" version, ensure that you have updated the corresponding
        // "warn" version for a full release to provide advanced warning. See
        // flutter.dev/go/android-dependency-versions for more.
        val warnGradleVersion : Version = Version(7,0,2)
        val errorGradleVersion : Version = Version(0,0,0)

        val warnJavaVersion : JavaVersion = JavaVersion.VERSION_11
        val errorJavaVersion : JavaVersion = JavaVersion.VERSION_1_1

        val warnAGPVersion : Version = Version(7,0,0)
        val errorAGPVersion : Version = Version(0,0,0)

        val warnKGPVersion : Version = Version(1,5,0)
        val errorKGPVersion : Version = Version(0,0,0)

        /**
         * Checks if the project's Android build time dependencies are each within the respective
         * version range that we support. When we can't find a version for a given dependency
         * we treat it as within the range for the purpose of this check.
         */
        fun checkDependencyVersions(project : Project) {
            var agpVersion : Version? = null
            var kgpVersion : Version? = null

            checkGradleVersion(getGradleVersion(project), project)
            checkJavaVersion(getJavaVersion(project), project)
            agpVersion = getAGPVersion(project)
            if (agpVersion != null) {
                checkAGPVersion(agpVersion, project)
            } else {
                project.logger.error("Warning: unable to detect project AGP version. Skipping " +
                        "version checking. ")
            }

            kgpVersion = getKGPVersion(project)
            if (kgpVersion != null) {
                checkKGPVersion(kgpVersion, project)
            } else {
                project.logger.error("Warning: unable to detect project KGP version. Skipping " +
                        "version checking.")
            }
        }

        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api.invocation/-gradle/index.html#-837060600%2FFunctions%2F-1793262594
        fun getGradleVersion(project : Project) : Version {
            return Version.fromString(project.gradle.getGradleVersion())
        }

        // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api/-java-version/index.html#-1790786897%2FFunctions%2F-1793262594
        fun getJavaVersion(project : Project) : JavaVersion {
            return JavaVersion.current()
        }

        // This approach is taken from AGP's own version checking plugin:
        // https://android.googlesource.com/platform/tools/base/+/1839aa23b8dc562005e2f0f0cc8e8b4c5caa37d0/build-system/gradle-core/src/main/java/com/android/build/gradle/internal/utils/agpVersionChecker.kt#58.
        fun getAGPVersion(project: Project): Version? {
            var agpVersion: Version? = null
            try {
                agpVersion = Version.fromString(
                    project.plugins.getPlugin("com.android.base")::class.java.classLoader.loadClass(
                        com.android.Version::class.java.name
                    ).fields.find { it.name == "ANDROID_GRADLE_PLUGIN_VERSION" }!!
                        .get(null) as String
                )
            } catch (ignored: ClassNotFoundException) {
                // Use deprecated Version class as it exists in older AGP (com.android.Version) does
                // not exist in those versions.
                agpVersion = Version.fromString(
                    project.plugins.getPlugin("com.android.base")::class.java.classLoader.loadClass(
                        com.android.builder.model.Version::class.java.name
                    ).fields.find { it.name == "ANDROID_GRADLE_PLUGIN_VERSION" }!!
                        .get(null) as String
                )
            }
            return agpVersion
        }

        fun getKGPVersion(project : Project) : Version? {
            // This property corresponds to application of the Kotlin Gradle plugin in the
            // top-level build.gradle file.
            if (project.hasProperty("kotlin_version")) {
                return Version.fromString(project.properties.get("kotlin_version") as String)
            }
            val kotlinPlugin = project.getPlugins()
                .findPlugin(KotlinAndroidPluginWrapper::class.java)
            val versionfield =
                kotlinPlugin?.javaClass?.kotlin?.members?.first { it.name == "pluginVersion" || it.name == "kotlinPluginVersion" }
            val versionString = versionfield?.call(kotlinPlugin)
            if (versionString == null) {
                return null
            } else {
                return Version.fromString(versionfield!!.call(kotlinPlugin) as String)
            }
        }

        private fun getErrorMessage(dependencyName : String,
                                    versionString : String,
                                    errorVersion : String) : String {
            return "Error: Your project's $dependencyName version ($versionString) is lower " +
                    "than Flutter's minimum supported version of $errorVersion. Please upgrade " +
                    "your $dependencyName version. \nAlternatively, use the flag " +
                    "\"--android-skip-build-dependency-validation\" to bypass this check."
        }

        private fun getWarnMessage(dependencyName : String,
                                   versionString : String,
                                   warnVersion : String) : String {
            return "Warning: Flutter support for your project's $dependencyName version " +
                    "($versionString) will soon be dropped. Please upgrade your $dependencyName " +
                    "version to a version of at least $warnVersion soon." +
                    "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                    " to bypass this check."
        }

        fun checkGradleVersion(version : Version, project : Project) {
            if (version < errorGradleVersion) {
                throw GradleException(
                    getErrorMessage(
                        "Gradle",
                        version.toString(),
                        errorGradleVersion.toString()
                    )
                )
            }
            else if (version < warnGradleVersion) {
                project.logger.error(
                    getWarnMessage(
                        "Gradle",
                        version.toString(),
                        warnGradleVersion.toString()
                    )
                )
            }
        }

        fun checkJavaVersion(version : JavaVersion, project : Project) {
            if (version < errorJavaVersion) {
                throw GradleException(
                    getErrorMessage(
                        "Java",
                        version.toString(),
                        errorJavaVersion.toString()
                    )
                )
            }
            else if (version < warnJavaVersion) {
                project.logger.error(
                    getWarnMessage(
                        "Java",
                        version.toString(),
                        warnJavaVersion.toString()
                    )
                )
            }
        }

        fun checkAGPVersion(version : Version, project : Project) {
            if (version < errorAGPVersion) {
                throw GradleException(
                    getErrorMessage(
                        "AGP",
                        version.toString(),
                        errorAGPVersion.toString()
                    )
                )
            }
            else if (version < warnAGPVersion) {
                project.logger.error(
                    getWarnMessage(
                        "AGP",
                        version.toString(),
                        warnAGPVersion.toString()
                    )
                )
            }
        }

        fun checkKGPVersion(version : Version, project : Project) {
            if (version < errorKGPVersion) {
                throw GradleException(
                    getErrorMessage(
                        "Kotlin",
                        version.toString(),
                        errorKGPVersion.toString()
                    )
                )
            }
            else if (version < warnKGPVersion) {
                project.logger.error(
                    getWarnMessage(
                        "Kotlin",
                        version.toString(),
                        warnKGPVersion.toString()
                    )
                )
            }
        }
    }
}


// Helper class to parse the versions that are provided as plain strings (Gradle, Kotlin) and
// perform easy comparisons.
class Version(val major : Int, val minor : Int, val patch : Int) : Comparable<Version> {
    companion object {
        fun fromString(version : String) : Version {
            val asList : List<String> = version.split(".")
            return Version(
                major = asList.getOrElse(0, {"0"}).toInt(),
                minor = asList.getOrElse(1, {"0"}).toInt(),
                patch = asList.getOrElse(2, {"0"}).toInt()
            )
        }
    }
    override fun compareTo(otherVersion : Version) : Int {
        if (major != otherVersion.major) {
            return major - otherVersion.major
        }
        if (minor != otherVersion.minor) {
            return minor - otherVersion.minor
        }
        if (patch != otherVersion.patch) {
            return patch - otherVersion.patch
        }
        return 0
    }
    override fun toString() : String {
        return major.toString() + "." + minor.toString() + "." + patch.toString()
    }
}
