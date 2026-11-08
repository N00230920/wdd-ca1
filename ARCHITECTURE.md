# Architecture

## 1. Overview

This project is a cloud-based file storage application inspired by Dropbox. It allows users to register, log in and manage their files through a web interface. Users can upload, download, rename, star and delete files.
The main objective of this project was to take an existing application and deploy it to AWS, making it accessible through a public domain. I also wanted to introduce an automated deployment process so that future changes could be tested and released without having to manually update the application on the server.

The application consists of two main components:

- **Frontend:** React, responsible for the user interface and communicating with the backend.
- **Backend:** Node.js and Express, responsible for authentication, file management, database operations and communication with external services.
MySQL is used as the relational database, with Drizzle ORM handling database queries and migrations. Amazon S3 is used for file storage in production.

The application is containerised using Docker and hosted on an AWS EC2 instance. Other AWS services include CloudFront, RDS, ECR, S3, IAM and Systems Manager.

The live application is available at:

https://n00230920.webdevdelivery.com/

## 2. System architecture

The application uses a combination of AWS services to handle incoming requests, application processing, database storage and file storage.

### Architecture diagram

```
Go to ArchitectureDiagram.png
```

## 3. AWS infrastructure

### Amazon EC2

Amazon EC2 is used to host the application in production. The instance runs Linux and uses a `t3.micro` instance type. It is deployed in the AWS Ireland region (`eu-west-1`).
The application runs inside a Docker container, which contains the frontend and backend. This makes it easier to manage the application and update it without manually installing dependencies on the EC2 instance.
The instance has an IAM role attached to it called `drop-app-role`. This role provides the permissions required to communicate with other AWS services, including ECR, S3 and Systems Manager.
AWS Systems Manager Session Manager is also used to access the instance without needing to manage SSH keys or expose an SSH port.

### Amazon CloudFront

CloudFront is used as the entry point for users accessing the application. It receives requests from the browser over HTTPS and forwards them to the EC2 instance.

The EC2 security group is configured to allow incoming HTTP traffic on port 80 from an AWS-managed CloudFront prefix list. This restricts direct access to the application server and ensures that incoming web traffic is routed through CloudFront.

Using CloudFront also provides a separation between the public-facing website and the application server.

### Docker

Docker is used to package the application and its dependencies into a container image.

The project uses different Docker build targets for development and production. During local development, Docker Compose starts the application and MySQL together. It also creates persistent volumes for the database and uploaded files.

For production, a Docker image is built using the production target:

```bash
docker build --target production -t drop-app .
```

The image is then pushed to Amazon ECR, where it can be retrieved by the EC2 instance during deployment.

### Amazon ECR

Amazon Elastic Container Registry is used to store the production Docker images.
When a change is merged into the `main` branch, GitHub Actions builds a new production image and pushes it to the ECR repository.Images are tagged using the Git commit SHA, making it easier to identify which version of the application is being deployed. The image is also tagged as `latest`.
The EC2 instance uses its IAM role to authenticate with ECR and retrieve the latest application image.

### Amazon RDS

Amazon RDS is used to host the application's MySQL database separately from the EC2 instance.
The database uses MySQL and a `db.t4g.micro` instance. The database is named `dropbox` and is deployed in the Ireland region.The database stores structured application information, including user details and file metadata. Drizzle ORM is used by the backend to interact with the database and manage schema migrations.

Separating the database from the application server means that restarting or replacing the application container does not require the database to be recreated.
The database storage is encrypted using an AWS KMS key. It uses General Purpose SSD (gp3) storage with an initial allocation of 20 GiB and storage autoscaling enabled.
The database is not publicly accessible. Its security group allows MySQL connections on port 3306 from the EC2 application's security group rather than allowing connections from the public internet.

Multi-AZ deployment is currently disabled, meaning the database does not have a standby instance in another availability zone.

### Amazon S3

Amazon S3 is used to store uploaded files in production.
Rather than storing files directly inside the application container, the backend communicates with S3 using the AWS SDK. This keeps uploaded files separate from the application itself.

This is important because application containers can be replaced during deployments. Keeping file storage separate means that uploaded files are not dependent on the lifetime of the container.
The EC2 instance accesses S3 through the permissions provided by its IAM role.

## 4. Security and access management

IAM is used to control how the different components access AWS resources. Instead of sharing AWS credentials between services, separate IAM roles are used for the application instance and the deployment pipeline.

### EC2 instance role

The `drop-app-role` IAM role is attached to the EC2 instance. It has four policies:

- `AmazonSSMManagedInstanceCore` – allows the instance to communicate with AWS Systems Manager.
- `DropAppParameterStoreAccess` – provides access to the application's configuration stored in Parameter Store.
- `DropboxECRAccess` – allows the instance to retrieve Docker images from ECR.
- `DropboxS3Access` – provides the permissions required to access the application's S3 bucket.

This allows the application to communicate with the required AWS services without storing long-lived AWS access keys directly on the server.

### GitHub deployment role

A separate IAM role called `drop-app-github-publish` is used by GitHub Actions.

This role has two policies:

- `push-drop-app` – provides permissions to authenticate with ECR and push the production Docker image.
- `deploy-to-ec2` – provides permissions to trigger deployments through AWS Systems Manager.

GitHub Actions uses OpenID Connect (OIDC) to authenticate with AWS and obtain temporary credentials. This avoids having to store permanent AWS access keys in GitHub repository secrets.

### Environment configuration

The application uses environment variables to manage configuration. This allows different values to be used for local development and production without changing the application code.

For local development, the repository provides a `backend/.env.example` file. Developers copy this file to `backend/.env` and configure their local environment.

In production, AWS Systems Manager Parameter Store is used to provide the required configuration to the application infrastructure.Environment files containing credentials are excluded from Git to prevent sensitive information from being committed to the repository.

## 5. CI/CD pipeline

GitHub Actions is used to automate the checking, building and deployment processes. The repository contains two workflows: `checks.yml` and `publish.yml`.

### Automated checks

The `checks.yml` workflow runs when a pull request is opened or updated and when changes are pushed to `main`.

It contains three jobs:

1. **Backend checks:** Installs dependencies, runs ESLint and checks formatting using Prettier.
2. **Frontend checks:** Installs dependencies, runs ESLint and checks formatting using Prettier.
3. **Docker build:** Builds the production Docker image to ensure that the application can be packaged successfully.

These checks help identify issues before changes are merged into the main branch.

### Publishing and deployment

The `publish.yml` workflow is responsible for deploying changes to production. It runs when changes are pushed to `main`.

The process works as follows:

1. A developer creates a feature branch and makes their changes.
2. A pull request is opened targeting `main`.
3. GitHub Actions runs the automated checks.
4. Once the pull request is reviewed and merged, the publishing workflow starts.
5. GitHub Actions authenticates with AWS using OIDC.
6. A new production Docker image is built and tagged with the Git commit SHA.
7. The image is pushed to the private ECR repository.
8. GitHub Actions sends a deployment command to the EC2 instance through Systems Manager.
9. The EC2 instance retrieves the new image from ECR and updates the running application.
10. GitHub Actions waits for the deployment command to finish and reports its result.

This process reduces the need for manual deployments and provides a consistent way to release changes.

## 6. Architectural decisions and trade-offs

One of the main decisions was to use Docker for application deployment. Docker provides a consistent environment for running the application and makes it easier to package and deploy updates.

EC2 was chosen because it provides control over the server environment and allows the application to be hosted using Docker. A managed container service could reduce some server management responsibilities, but would introduce additional infrastructure and configuration.

RDS was chosen to keep the database separate from the application server. This makes database management easier and prevents application container restarts from affecting database storage.

Amazon S3 was chosen for file storage because uploaded files should not depend on the lifetime of the application container. It also allows storage to be managed independently from the application.

CloudFront provides an additional layer between the public internet and the EC2 instance. Restricting the EC2 security group to CloudFront traffic helps prevent users from bypassing the public-facing entry point.

GitHub Actions was chosen for CI/CD because the source code is already hosted on GitHub. It provides an integrated way to run checks, build Docker images and deploy changes without manually connecting to the server.

There are some limitations to the current architecture. The application runs on a single EC2 instance, so there is no automatic scaling or application-level redundancy if the instance becomes unavailable. The RDS database also uses a single Availability Zone, meaning there is no Multi-AZ standby.

Future improvements could include introducing a staging environment, implementing automated health checks and rollback procedures, and managing AWS infrastructure using Terraform or OpenTofu.

Overall, the architecture provides a relatively straightforward way to host the application in AWS. It separates application processing, database storage and file storage while using automation to make deployments more manageable.