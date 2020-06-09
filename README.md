# circleci-go

CircleCI builder image for Go projects. Now for Go module projects only. Reference driveclutch/circleci-go:glide in your project's Dockerfile to continue using a Glide-compatible version.

To migrate to Go modules:

- move work outside of $GOPATH if needed (Go modules deprecate $GOPATH)

- run `go mod init github.com/DriveClutch/project-name` to create a go.mod file (commit this)

- remove the glide.yaml / glide.lock files

- in your project's .circleci/config.yml file reference driveclutch/circleci-go:latest as the builder image and update the working directory to simply be `/project-name` (instead of being relative to the go path eg, `go/src/github.com/DriveClutch/project-name`)

- go build should download the dependencies and generate a go.sum file (also commit this)

- see more: https://blog.golang.org/migrating-to-go-modules

- to enable caching, add a step like this before the build step

  ```
  - restore_cache:
      keys:
        - some-prefix-{{ .Branch }}-{{ checksum "go.sum" }}
  ```

  and add a step like this after the build and test steps

  ```
  - save_cache:
      key: some-prefix-{{ .Branch }}-{{ checksum "go.sum" }}
      paths:
        - /go/pkg/mod/cache
  ```

- modify the working directory step to not be in the \$GOPATH anymore

```
    working_directory: /src/<project name>
```

- add support for Go private repos as dependencies

```
    environment:
      GOPRIVATE: github.com/DriveClutch/*
```
