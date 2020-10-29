# vapor-ci

## Important files

- `/pr-environments.json`
  
  The contents of this file are a JSON array of dictionaries describing the runtime environments tested when a pull request is opened against any repo. Thanks to limitations of GitHub Actions, the format is not tolerant of any extra keys, missing keys, spurious values, or any other deviation. It may, however, be pretty-printed JSON; canonical form is not required. The accepted format is:
  
  ````json
  [
      { "os": "ubuntu-latest", "image": "swift:5.3-focal", "toolchain": null },
      { "os": "macos-latest", "image": null, "toolchain": "latest-stable" },
      { "os": "windows-latest", "image": null, "toolchain": null },
  ]
  ````
  
  * `ubuntu-latest` entries _must_ have `null` as the value of `toolchain`. The `image` key specifies a Docker image to use as the container for the tests.
  * `macos-latest` entries, similarly, _must_ have `null` as the value of `image`. The `toolchain` key specifies an Xcode version to use for the tests, as understood by the `maxim-lobanov/setup-xcode` action, version 1.2.1 or newer.
  * `windows-latest` entries must have `null` as the value of both keys. This is defined only for the sake of future expansion at the time of this writing, and no Windows entries may actually appear until updates to CI are put in place.
  * There may be as many entries as desired, but be aware that every entry adds another CI check to _every_ pull request against _every_ Vapor repository. Duplicate entries are invalid.

 - `/validity-check.sh`
   
   A script which checks the other files in the repository for validity. It is invoked by this repository's own CI, which does not otherwise reference its own content.
 
 - `/.github/workflows/validate.yml`
   
   A workflow which ensures the validity of pull requests and pushes to this repository. This is critical, as errors are likely to disable CI for _all_ of Vapor's projects (notwithstanding those like `docs` and `website` which do not use this architecture).
