# tika-grpc-docker

> **⚠️ PRE-RELEASE STATUS:** Apache Tika gRPC Server is currently in development and has not been officially released yet. It will first be available in **Tika 4.0.0**. Until then, Docker images must be built from source code (see "Building from Development Branches" below).

This repo is used to create convenience Docker images for Apache Tika Grpc Server published as [apache/tika-grpc](https://hub.docker.com/r/apache/tika-grpc) on DockerHub by the [Apache Tika](http://tika.apache.org) Dev team.

Once Tika 4.0.0 is released, the images will create a functional Apache Tika Grpc Server instance that contains the latest Ubuntu running the appropriate version's server on Port 50052 using Java 17 LTS.

There is a minimal version, which contains only Apache Tika and it's core dependencies, and a full version, which also includes dependencies for the GDAL and Tesseract OCR parsers. To balance showing functionality versus the size of the full image, this file currently installs the language packs for the following languages:
* English
* French
* German
* Italian
* Spanish.

To install more languages simply update the apt-get command to include the package containing the language you required, or include your own custom packs using an ADD command.

## Available Tags

Below are the most recent 2.x series tags:
- `latest`, `3.0.0`: Apache Tika Server 3.0.0 (Minimal)
- `latest-full`, `3.0.0-full`: Apache Tika Server 3.0.0 (Full)

You can see a full set of tags for historical versions [here](https://hub.docker.com/r/apache/tika-grpc/tags?page=1&ordering=last_updated).

## Usage

### Default

You can pull down the version you would like using:

    docker pull apache/tika-grpc:<tag>

Then to run the container, execute the following command:

    docker run -d -p 127.0.0.1:50052:50052 apache/tika-grpc:<tag>

Where <tag> is the DockerHub tag corresponding to the Apache Tika Server version - e.g. 3.0.0, 3.0.0-full.

NOTE: The latest and latest-full tags are explicitly set to the latest released version when they are published.

NOTE: In the example above, we recommend binding the server to localhost because Docker alters iptables and may expose
your tika-server to the internet.  If you are confident that your tika-server is on an isolated network
you can simply run:

    docker run -d -p 50052:50052 apache/tika-grpc:<tag>

### Custom Config

From version 3.0.0, 3.0.0-full of the image it is now easier to override the defaults and pass parameters to the running instance.

So for example if you wish to disable the OCR parser in the full image you could write a custom configuration:

```
cat <<EOT >> tika-config.xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
  <parsers>
      <parser class="org.apache.tika.parser.DefaultParser">
          <parser-exclude class="org.apache.tika.parser.ocr.TesseractOCRParser"/>
      </parser>
  </parsers>
</properties>
EOT
```
Then by mounting this custom configuration as a volume, you could pass the command line parameter to load it

    docker run -d -p 127.0.0.1:50052:50052 -v `pwd`/tika-config.xml:/tika-config.xml apache/tika-grpc:3.0.0-full -c /tika-config.xml

You can see more configuration examples [here](https://tika.apache.org/2.5.0/configuring.html).

You may want to do this to add optional components, such as the tika-eval metadata filter, or optional
dependencies such as jai-imageio-jpeg2000 (check license compatibility first!).

### Docker Compose Examples

There are a number of sample Docker Compose files included in the repos to allow you to test some different scenarios.

These files use docker-compose 3.x series and include:

* docker-compose-tika-vision.yml - TensorFlow Inception REST API Vision examples
* docker-compose-tika-grobid.yml - Grobid REST parsing example
* docker-compose-tika-customocr.yml - Tesseract OCR example with custom configuration
* docker-compose-tika-ner.yml - Named Entity Recognition example

The Docker Compose files and configurations (sourced from _sample-configs_ directory) all have comments in them so you can try different options, or use them as a base to create your own custom configuration.

**N.B.** You will want to create a environment variable (used in some bash scripts) matching the version of tika-docker you want to work with in the docker compositions e.g. `export TAG=3.0.0`. Similarly you should also consult `.env` which is used in the docker-compose `.yml` files.

You can install docker-compose from [here](https://docs.docker.com/compose/install/).

## Building

### Current Build Method - Building from Development Branches (Pre-Release)

**Since tika-grpc has not been officially released yet**, you must build from source code using the `build-from-branch.sh` script:

```bash
# Build from main branch (recommended for latest development)
./build-from-branch.sh -b main

# Build from a specific feature branch
./build-from-branch.sh -b TIKA-4578

# Build from your local tika directory (for rapid development)
./build-from-branch.sh -l /home/user/tika -t my-local-build
```

This will:
1. Clone the Apache Tika repository
2. Build tika-grpc and all dependencies from source
3. Create a Docker image with the compiled JAR
4. Run basic tests to verify the image works
5. Tag as `apache/tika-grpc:<branch-name>`

**Running your built image:**

```bash
docker run -d -p 127.0.0.1:50052:50052 apache/tika-grpc:main
```

See the "Building from Development Branches" section below for complete documentation and options.

### Future Build Method - Building from Official Apache Releases (Post-4.0.0)

**Once Tika 4.0.0 is officially released**, you'll be able to build Docker images from GPG-signed Apache release artifacts using `docker-tool.sh`:

```bash
# Build from signed release (future - requires Tika 4.0.0+)
./docker-tool.sh build 4.0.0 4.0.0
./docker-tool.sh test 4.0.0
./docker-tool.sh publish 4.0.0 4.0.0
```

This will:
1. Download the signed `tika-grpc-4.0.0.jar` from Apache distribution mirrors
2. Download and verify the GPG signature (`.asc` file)
3. Import Apache KEYS and verify the JAR is properly signed
4. Build both minimal and full Docker images

**Manual build from release (future):**

```bash
docker build -t apache/tika-grpc:4.0.0 --build-arg TIKA_VERSION=4.0.0 - < minimal/Dockerfile
docker build -t apache/tika-grpc:4.0.0-full --build-arg TIKA_VERSION=4.0.0 - < full/Dockerfile
```

> **Note:** The `minimal/` and `full/` Dockerfiles are prepared for future releases and will NOT work until tika-grpc-4.0.0.jar is published to Apache distribution mirrors.
    
## More Information

For more infomation on Apache Tika Grpc Server, go to the [Apache Tika Grpc Server documentation](https://cwiki.apache.org/confluence/display/TIKA/Apache+Tika+gRPC+Server).

For more information on Apache Tika, go to the official [Apache Tika](http://tika.apache.org) project website.

To meet up with others using Apache Tika, consider coming to one of the [Apache Tika Virtual Meetups](https://www.meetup.com/apache-tika-community/).

For more information on the Apache Software Foundation, go to the [Apache Software Foundation](http://apache.org) website.

For a full list of changes as of 3.0.0, visit [CHANGES.md](CHANGES.md).

For our current release process, visit [tika-docker Release Process](https://cwiki.apache.org/confluence/display/TIKA/Release+Process+for+tika-docker)

## Authors

Apache Tika Dev Team (dev@tika.apache.org)

## Building from Development Branches

For testing unreleased features or development branches, you can build Docker images directly from source:

### Build from Git Branch

```bash
# Build from main branch
./build-from-branch.sh -b main

# Build from a specific feature branch  
./build-from-branch.sh -b TIKA-4578
```

### Build from Local Directory

```bash
# Build from your local tika checkout (for rapid development)
./build-from-branch.sh -l /home/user/tika -t my-local-build
```

### Build Script Options

```bash
./build-from-branch.sh [OPTIONS]

Options:
  -b BRANCH       Git branch or tag to build from (default: main)
  -r REPO         Git repository URL (default: https://github.com/apache/tika.git)
  -l LOCAL_DIR    Build from local tika directory instead of cloning
  -t TAG          Docker image tag (default: branch-name or 'local')
  -p              Push to Docker registry after building
  -h              Display this help message
```

### Examples

Build from main branch:
```bash
./build-from-branch.sh -b main
```

Build from your local tika repository:
```bash
./build-from-branch.sh -l /home/user/source/tika -t my-test
```

Build from a fork and push to registry:
```bash
./build-from-branch.sh \
  -r https://github.com/yourusername/tika.git \
  -b my-feature \
  -t myregistry/tika-grpc:my-feature \
  -p
```

**Note:** Development builds compile from source and do NOT use GPG-signed releases. They are intended for development and testing only, not production use.
   
## Contributors

There have been a range of [contributors](https://github.com/apache/tika-grpc-docker/graphs/contributors) on GitHub and via suggestions, including:

- [@nddipiazza](https://github.com/nddipiazza)
- [@tallisonapache](https://github.com/tballison)

## License

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 
## Release Process and GPG Verification

### Official Release Images

Official release images are built using GPG-signed Apache release artifacts. The Dockerfiles in this repository:

1. Download the `tika-grpc-${VERSION}.jar` from Apache distribution mirrors
2. Download the corresponding `.asc` GPG signature file
3. Import the Apache Tika KEYS file
4. Verify the GPG signature before using the JAR in the Docker image

This ensures that the Docker images contain only verified, officially released Apache Tika artifacts.

### Development/Testing Images

The `build-from-branch.sh` script allows building Docker images from source code for testing purposes. These builds:
- Compile from Git source code
- Do NOT use GPG-signed releases
- Are intended for development and testing only
- Should NOT be used in production

For production use, always build from official Apache releases using the standard Dockerfiles and `docker-tool.sh`.

## Disclaimer

It is worth noting that whilst these Docker images download the binary JARs published by the Apache Tika Team on the Apache Software Foundation distribution sites, only the source release of an Apache Software Foundation project is an official release artefact. See [Release Distribution Policy](https://www.apache.org/dev/release-distribution.html) for more details.
