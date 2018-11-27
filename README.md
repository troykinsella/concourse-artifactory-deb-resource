# Concourse Artifactory Debian Package Resource

A [Concourse CI](https://concourse-ci.org) resource for manipulating debs in Artifactory.

This resource is specific to debs hosted on Artifactory due to Artifactory's
non-standard publication mechanism, which is uploading deb archives
via HTTP/S `PUT`.

## Source Configuration

* `repository`: Required: The URL at which the Debian repository in Artifactory 
   can be located. Example: `https://tools.example.com/artifactory/debian-local`.
* `username`: Required. The username with which to access the repository.
* `password`: Required. The password with which to access the repository.
* `distribution`: Required. The target distribution name of the deb package being 
   manipulated. This is the value of the `deb.distribution` property 
   when `put`ing to Artifactory. Example: `bionic`.
* `package`: Required. The name of the deb package being manipulated.
* `apt_keys`: Optional. A list of URLs at which GPG keys can be fetched and 
  configured with `apt-key add`. 
* `architecture`: Optional. Default: `amd64`. The target architecture of the deb
  package. Also the value of the `deb.architecture` property 
  when `put`ing to Artifactory.
* `trusted`: Optional. A boolean indicating if the `/etc/apt/sources.list` entry
  generated from these configuration values will be annotated with `[trusted=yes]`.
* `components_dir`: Optional. Default: `pool`. The name of the root directory of the repository
  in which package components can be located.
* `other_sources`: Optional. A list of `/etc/apt/source.list` entries to include.
  Useful for when the deb package stored in Artifactory has upstream dependencies.
  Example: `- deb http://archive.ubuntu.com/ubuntu/ bionic main restricted`
* `component`: Optional. Default: `main`. The component field in the generated
  `/etc/apt/sources.list` entry, as well as the value of the `deb.component`
  property when `put`ing to Artifactory.
* `version_pattern`: Optional. Instructs `check` to only observe versions of the
  configured package matching this regular expression.

### Example

```yaml
resources_types:
- name: deb-package
  type: docker-image
  source:
    repository: troykinsella/concourse-artifactory-deb-resource
    tag: latest

resources:
- name: deb
  type: deb-package
  source:
    repository: https://tools.example.com/artifactory/debian-local
    username: concourse
    password: naughty
    apt_keys:
    - https://tools.example.com/artifactory/api/gpg/key/public
    distribution: bionic
    trusted: true
    package: libwicked
    other_sources:
    - deb http://archive.ubuntu.com/ubuntu/ bionic main restricted
```

## Behaviour

### `check`: Check for New Versions

Firstly, an `/etc/apt/sources.list` entry is generated from source configuration 
values following this template:
```
deb <trusted_flag> <repository> <distribution> <component>
```

Then following an `apt-get update`, the apt cache is queried for version
information pertaining to the configured deb package. 

### `in`: Fetch `deb` Information and Archives

The apt cache is updated in the same manner as the `check` operation, 
then queried for information pertaining to the version of the
deb package being fetched.

#### Output Files

Optionally, deb archives are downloaded and made available at `/<archive-file>`.

An `/info` file is created containing the output of 
`apt-cache show <package>=<version>`. For convenience, each
field is extracted from this file and put in a file `/<field-name>`.
For example, if a field from `/info` was `Installed-Size: 1982`,
a file called `/installed-size` would be created, containing `1982`.

Typical info files generated may be:
* `architecture`
* `depends`
* `description`
* `description-md5`
* `filename`
* `homepage`
* `info`
* `installed-size`
* `maintainer`
* `package`
* `priority`
* `section`
* `sha1`
* `sha256`
* `size`
* `suggests`
* `version`

#### Parameters

* `fetch_archives`: Optional. Default: `false`. A boolean indicating
  whether or not deb package archives should be downloaded.

#### Example

```yaml
# Extends example in Source Configuration

jobs:
- name: test-deb
  plan:
  - get: deb
    trigger: true
    params:
      fetch_archives: true
  - task: integration test
    file: tasks/integration-test.yml
    input_mapping:
      archives: deb
```

### `out`: Publish debs to Artifactory

Since building debs is a pretty customized process, this resource
doesn't attempt to actually build deb files; It just accepts ones that
you've built in a task script (for example), and publishes them
to Artifactory.

One of the deb archive files passed to the `put` step must be the
package represented by the `source` configuration, and it's from that
package that the version is extracted and returned from the this
resource's `out` script. All deb archive files supplied will
be published to Artifactory. This, for example, allows your
build to produce `yourpackage-<version>.deb` and 
`yourpackage-dev-<version>.deb`, and publish both in one step. 

#### Parameters

* `debs`: Required. The path to a directory containing `*.deb` files to publish.
* `dry_run`: Optional. Default: `false`. A boolean indicating that, when `true`, deb
  files will not actually be published to Artifactory.

#### Example

```yaml
# Extends example in Source Configuration

jobs:
- name: 
  plan:
  - get: master # git resource
    trigger: true
  - task: build debs
    file: tasks/build-debs.yml
    input_mapping:
      source: master
    output_mapping:
      archives: built-debs
  - put: deb
    params:
      debs: built-debs 
```

## License

MIT © Troy Kinsella
