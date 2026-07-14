# Versioning and Changelog Workflow

When modifying the codebase and preparing a new release, you MUST ensure that you do not reuse an already published version tag.

**Rule for Agents:**
Before modifying `debian/changelog` or committing changes meant for a release, ALWAYS run `git fetch --tags` to synchronize remote tags. If the version at the top of `debian/changelog` (e.g., `1.0.7`) already exists as a tag (e.g., `v1.0.7`), you MUST bump the version to a new number (e.g., `1.0.8-1`) by creating a new changelog block in `debian/changelog`.
Do NOT append your changes to an already released changelog block, as this will cause tag conflicts in the CI/CD pipeline.
