# ISLE: NodeJS <!-- omit in toc -->

[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)
[![CI](https://github.com/Islandora-Devops/isle-nodejs/actions/workflows/ci.yml/badge.svg)](https://github.com/Islandora-Devops/isle-nodejs/actions/workflows/ci.yml)

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Host-platform Builds](#host-platform-builds)
- [Multi-platform builds](#multi-platform-builds)
- [Release Builds / Updating DockerHub](#release-builds--updating-dockerhub)

## Introduction

This repository provides the `islandora/nodejs` image which only exists to
provide a custom Alpine APK package(s). As `code-server` is often one or two
versions behind what gets shipped with Alpine.

Since this does not change often and takes a very long time to cross compile for
both platforms it's been moved to it's own repository.

## Requirements

To build the Docker images using the provided Gradle build scripts requires:

- [Docker 20+](https://docs.docker.com/get-docker/)

## Host-platform Builds

You can build your host platform locally using the default builder like so.

```bash
docker context use default
docker buildx bake
```

## Multi-platform builds

To test multi-arch builds and remote build caching requires setting up a local
registry.

Please use [isle-builder] to create a builder to simplify this process. Using
the defaults provided, .e.g:

```
make start
```

After which you should be able to build with the following command:

```bash
REPOSITORY=islandora.io docker buildx bake --builder isle-builder ci --push
```

## Release Builds / Updating DockerHub

Unfortunately this takes too long to cross compile as a Github actions so
building and updating images in DockerHub must be done manually.

First create a tag that includes both the alpine version and the nodejs version.
For example:

```bash
git tag alpine-3.20.2-nodejs-18.19.1-r0
```

Then build and push the images to DockerHub, and create an manifest:

```bash
export REPOSITORY=islandora
export TAG=alpine-3.20.2-nodejs-20.15.1-r0
docker login -u islandoracommunity
docker buildx bake --builder isle-builder ci --push
docker buildx imagetools create -t islandora/nodejs:${TAG} islandora/nodejs:${TAG}-amd64 islandora/nodejs:${TAG}-arm64
docker logout
```

[isle-builder]: https://github.com/Islandora-Devops/isle-builder