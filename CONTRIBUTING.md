# Contributing

Thanks for contributing to the Dropbox application. Please follow the steps below so changes can be reviewed and tested before they are merged.

## Getting started

Set up the project locally by following the **Run locally** instructions in [README.md](README.md).

In short:

1. Clone the repository.
2. Copy `backend/.env.example` to `backend/.env`.
3. Start the application with `docker compose up --build -d`.
4. Add local sample data with `docker compose exec app npm run db:seed`.

The application is available at http://localhost:8000.

## Development workflow

1. Make sure your local `main` branch is up to date:

   ```bash
   git switch main
   git pull origin main
   ```

2. Create a branch for your change:

   ```bash
   git switch -c feature
   ```

   Use `feature/` for new features and `fix/` for bug fixes.

3. Make your changes and commit them with a clear message:

   ```bash
   git add .
   git commit -m "Describe the change"
   ```

4. Push your branch:

   ```bash
   git push -u origin feature
   ```

5. Open a pull request on GitHub targeting `main`.

Do not push changes directly to `main`. Changes should be submitted through pull requests.

## Checks before opening a pull request

Run the checks for the part of the application you changed.

### Backend

From the `backend/` directory:

```bash
npm ci
npm run lint
npm run format:check
```

### Frontend

From the `frontend/` directory:

```bash
npm ci
npm run lint
npm run format:check
```

### Docker build

From the repository root:

```bash
docker build --target production -t drop-app .
```

Also run the application locally and manually check the feature or fix you changed. Check relevant existing functionality to make sure it has not been broken.

The GitHub Actions checks run automatically on every pull request. They check backend linting and formatting, frontend linting and formatting, and whether the production Docker image builds. Resolve any failures before requesting a review.

## Database changes

If your change updates the database schema:

1. Update the Drizzle schema as required.
2. Generate a migration using the running application container:

   ```bash
   docker compose exec app npm run db:generate
   ```

3. Review the generated migration.
4. Include the migration file in your pull request.
5. Apply and test the migration against your local database:

   ```bash
   docker compose exec app npm run db:migrate
   ```

Do not use `npm run db:seed` as a migration method. The seed script deletes existing database data and is intended only for local development.

## Opening a pull request

When opening your pull request:

- Give it a description.
- Include the relevant issue or task, if there is one.
- List the checks you ran and their results.
- Explain how you tested the change, including any manual testing.
- Include screenshots or a short recording for visible frontend changes.
- Mention any database migrations, environment variables or configuration changes.
- Note anything that still needs attention or could not be tested.

Keep pull requests focused on one feature or fix where possible. Do not include secrets, `.env` files, generated dependencies such as `node_modules`, or unrelated changes.

## Review and merge

- Explain your implementation and respond to review comments.
- Make requested changes on the same branch and push them to the pull request.
- Check that all required GitHub Actions checks pass.
- Merge only after the review is complete and the required checks have passed.

Merging a pull request into `main` triggers the production publish and deployment workflow. The workflow builds and publishes the Docker image, then deploys it to the AWS EC2 instance.
