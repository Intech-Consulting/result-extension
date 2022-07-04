# ResultExtension

Some extensions needed and not implemented by Swift team.

## Documentation

See [proposal](https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md) [source-code](https://github.com/apple/swift/blob/main/stdlib/public/core/Result.swift)

## Linux

To generate UnitTests for Linux run `swift test --generate-linuxmain`, not needed in new version of swift.

To test the library on Linux using Docker run
`docker run --rm --privileged --interactive --tty --volume "$(pwd):/src" --workdir "/src" swift:latest swift test`
