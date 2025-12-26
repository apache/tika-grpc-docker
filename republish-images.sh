#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing,
#   software distributed under the License is distributed on an
#   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#   KIND, either express or implied.  See the License for the
#   specific language governing permissions and limitations
#   under the License.


##
## Helper script to allow a republish of tika-grpc versions.
## This builds images from GPG-signed Apache release artifacts.
##

# tika-grpc was first released in Tika 3.0.0
# Initial 3.x releases
for version in 3.0.0; do
    echo "Building and publishing apache/tika-grpc:${version}"
    ./docker-tool.sh build "${version}" "${version}"
    ./docker-tool.sh test "${version}"
    if [ $? -eq 0 ]; then
        ./docker-tool.sh publish "${version}" "${version}"
    else
        echo "Failed to test and publish version ${version}"
        echo "$(tput setaf 1)Failed to test and publish image: apache/tika-grpc:${version}$(tput sgr0)"
        exit 1
    fi
done
