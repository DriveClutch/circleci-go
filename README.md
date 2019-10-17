# circleci-go
CircleCI builder image for Go projects. Now for Go module projects only. Reference driveclutch/circleci-go:glide in your project's Dockerfile to continue using a Glide-compatible version.

To migrate to Go modules: 

- move work outside of $GOPATH if needed (Go modules deprecate $GOPATH)

- run `go mod init github.com/DriveClutch/project-name`

- remove the glide.yaml / glide.lock files

- reference driveclutch/circleci-go:latest in your project's .circleci/config.yml file.

- go build should download the dependencies

- see more: https://blog.golang.org/migrating-to-go-modules
