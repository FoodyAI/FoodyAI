# Contributing to Foody

Thanks for your interest in contributing! Please follow these guidelines to help us maintain quality and velocity.

## Setup
1. Fork this repository and clone your fork
2. Create a new branch from `main`
   - Feature: `feature/<short-name>`
   - Fix: `fix/<short-name>`
   - Chore/Docs: `chore/<short-name>` or `docs/<short-name>`
3. Install deps: `flutter pub get`
4. Create `.env` in project root if needed (see README)

## Development
- Keep PRs small and focused
- Match existing code style and formatting
- Prefer readable code over clever code
- Avoid introducing warnings/lints
- Add/update tests where applicable

## Commit Messages
Use conventional commits:
- `feat: ...` new feature
- `fix: ...` bug fix
- `chore: ...` tooling or maintenance
- `docs: ...` documentation updates
- `refactor: ...` code changes without behavior impact

## Pull Requests
- Rebase onto latest `main` before opening PR
- Fill out the PR template (summary, screenshots, testing notes)
- Link related issues
- Ensure `flutter analyze` passes

## Code Review
- Be respectful and constructive
- Focus on clarity, correctness, and consistency
- Suggest improvements with rationale

## Security / Secrets
- Never commit real API keys or secrets
- `.env` is required locally and must not be committed

## License
By contributing, you agree that your contributions will be licensed under the project’s GPL-3.0 license.
