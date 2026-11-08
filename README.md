# Dropbox

A file-storage web application that allows users to register, log in, and upload, download, rename, star and delete files.

The application includes:
- **Frontend:** React
- **Backend:** Node.js and Express
- **Database:** MySQL with Drizzle ORM
- **File storage:** Local storage during development, with Amazon S3 available for production
- **Deployment:** Docker on AWS

**Live application:** https://n00230920.webdevdelivery.com/

## Run locally

### Prerequisites
- Git
- Docker Desktop
- Docker Compose
- Node.js 22.23

The application and MySQL run in Docker, so you do not need to install Node.js or MySQL separately to run the app locally.

### 1. Clone the repository

```bash
git clone https://github.com/N00230920/wdd-ca1.git
cd wdd-ca1
```

### 2. Create your local environment file

Copy the backend example environment file:

```bash
cp backend/.env.example backend/.env
```
The example file contains development settings. Do not use these values in production, and never commit your `.env` file.

### 3. Build and start the application

From the repository root, run:
```bash
docker compose up --build -d
```
This builds the application image and starts the application and MySQL containers. Docker Compose waits for MySQL to become healthy before starting the application.

### 4. Add the sample data

Run the seed command inside the application container:

```bash
docker compose exec app npm run db:seed
```

**Warning:** The seed command deletes the existing data in the configured database before recreating the tables and adding sample users and files. Only use it with your local development database.

### 5. Open the application

Visit:

- Application: http://localhost:8000
- API health check: http://localhost:8000/health

You can sign in with any of these sample accounts. The password for all three is `password123`.

| Email | Password |
|---|---|
| `alice@example.com` | `password123` |
| `bob@example.com` | `password123` |
| `charlie@example.com` | `password123` |

These are development accounts only. Do not use sample credentials in production.

## Useful Docker commands

Run these commands from the repository root.

| Command | Description |
|---|---|
| `docker compose up --build -d` | Build and start the application and database in the background |
| `docker compose logs -f app` | Follow application logs |
| `docker compose logs -f db` | Follow database logs |
| `docker compose exec app npm run db:migrate` | Apply migrations that have not yet run |
| `docker compose exec app npm run db:seed` | Reset the local database and add sample data |
| `docker compose down` | Stop and remove the containers |
| `docker compose down -v` | Stop containers and delete the database and uploads volumes |

**Note:** `docker compose down` keeps the named volumes, so your local database and uploaded files remain. Use `docker compose down -v` only when you intentionally want to delete that local data.

## Running code checks

The project uses GitHub Actions to run linting, formatting checks and a production Docker build for pull requests. You can run the same checks locally.

### Backend

```bash
cd backend
npm ci
npm run lint
npm run format:check
```

### Frontend

```bash
cd frontend
npm ci
npm run lint
npm run format:check
```

### Production Docker build

From the repository root:

```bash
docker build --target production -t drop-app .
```

## Database migrations

When database schema changes are made, create a migration using the backend's Drizzle tooling:

```bash
docker compose exec app npm run db:generate
```

Review the generated migration and include it in your pull request. To apply pending migrations to the local database:

```bash
docker compose exec app npm run db:migrate
```

Do not use `db:seed` to update a database that contains data you need to keep; it deletes the existing application data. Use migrations for normal schema updates.

## API documentation

The API's OpenAPI specification is available at `backend/openapi.yaml`. You can import it into a REST API client such as Postman to explore and send requests to the API.

If using Postman, in the import settings, set "Parameter generation" to "Example" so the requests use the sample users.

Most requests need you to be logged in. Send the "Log in" request, and copy the `token` from its response. Then open the collection's Authorization tab, choose "Bearer Token", and paste the token in. Every request in the collection then sends it. Tokens expire after 7 days.
