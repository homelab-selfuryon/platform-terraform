# Authentication: the GITHUB_TOKEN environment variable, e.g.
#   export GITHUB_TOKEN=$(gh auth token)
# The token needs the scopes `repo` and `admin:org` (see README.md).
provider "github" {
  owner = var.owner
}
