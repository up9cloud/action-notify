# Contributing

## Releasing

Versions follow `v<major>.<minor>[.<patch>]`. While at `0.x`, a breaking change bumps the minor
version and everything else bumps the patch.

1. Add a `## v<version> (YYYY-MM-DD)` section at the top of [CHANGELOG.md](CHANGELOG.md), commit
   it and push to `master`.
2. Wait for the CI run on `master` to pass.
3. Tag the commit and push the tag:

   ```sh
   git tag v<version>
   git push origin v<version>
   ```

4. Wait for the CI run triggered by the tag to pass as well. A tag push exercises paths a branch
   push does not: its event has no `commits`, and the ref contains a `.`. If it fails, delete the
   tag, fix on `master`, and start again from step 2:

   ```sh
   git push origin :refs/tags/v<version>
   git tag -d v<version>
   ```

5. Open <https://github.com/up9cloud/action-notify/releases/new>, choose the tag, use it as the
   title, paste the version's CHANGELOG section without its heading, tick **Publish this Action to
   the GitHub Marketplace**, and publish.

   **Point of no return:** once the release is published, people can pin the tag. Do not move or
   delete it afterwards; release a new patch version instead.
