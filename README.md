# install-scripts

## What is this?

This is a VERY OLD set of shell scripts for generating installer tarballs on linux
for Java applications. There are much better and more modern ways of solving this
problem, not just for linux, but for all platforms, but this repo exists to support
those projects that still do it this older way. 

## Supported formats

Originally, the goal was to be able to support RPM, DEB, tarball, or even Windows installer formats,
but ultimately only tarball support was ever written. 

## Configuration

Create a file called `installer.props` in the root of your Java project. You can specify 
some configuration properties to affect the outcome. A simple example is shown below:

```shell
# ALL PATHS ARE RELATIVE TO PROJECT ROOT

# Only "tarball" (.tar.gz) option is supported here.
FORMAT="tarball"

# Application name/version will also be used for the jar file name.
# The example below will generate MyApplication-1.0-SNAPSHOT.tar.gz
APPLICATION="MyApplication"
VERSION="1.0-SNAPSHOT"

# Your GitHub project page or whatever:
PROJECT_URL="https://project.example/MyApplication"

# Optionally specify an output directory for the tarball.
# If not set, will output to current dir (project root dir).
OUTPUT_DIR=target

# Extra memory settings like Xmx and Xms can optionally be specified here:
JAVAMEM=

# The executable application jar file to be bundled into the tarball:
JAR="target/myapplication-${VERSION}.jar"

# An optional space-separated list of extra files and dirs to include:
TO_COPY="target/lib"
TO_COPY="${TO_COPY} src/main/resources/ReleaseNotes.txt"

# Include a logo.png image if you want a desktop shortcut for your application:
TO_COPY="${TO_COPY} src/main/resources/images/logo.png"
```

## Running the script

### Option 1: manual run

From your project root dir, you can invoke the script (assuming it's on your PATH):

```shell
cd myapplication
make_installer
```

### Option 2: building into your maven pom.xml

There are many ways to wire up the script into maven. The cleanest, lowest-impact way
is probably to use a conditional profile and invoke the script from a known location
(let's say ${user.home}/bin for example):

```xml
<!-- If the user has make_installer installed, we can auto-generate -->
<!-- an installer package after each successful build.                 -->
<!-- See https://github.com/scorbo2/install-scripts/ for more info!    -->
<profiles>
    <profile>
        <id>make-installer</id>
        <activation>
            <file>
                <exists>${user.home}/bin/make_installer</exists>
            </file>
        </activation>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.codehaus.mojo</groupId>
                    <artifactId>exec-maven-plugin</artifactId>
                    <version>3.0.0</version>
                    <executions>
                        <execution>
                            <id>make_installer</id>
                            <phase>package</phase>
                            <goals>
                                <goal>exec</goal>
                            </goals>
                            <configuration>
                                <executable>${user.home}/bin/make_installer</executable>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

This maven profile will be activated automatically if the `make_installer` script exists in the known
location. Otherwise, the profile will not activate and the existing build workflow is unaffected.
The end result is you should be able to do `mvn package` and the tarball will just be generated automatically.

## Future development

Probably none - this is old legacy stuff. This will likely be replaced by jpackage.

## License

install-scripts is made available under the MIT license: https://opensource.org/license/mit
