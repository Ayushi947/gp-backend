# GlidingPath Backend

A comprehensive 401(k) retirement plan administration platform built with Spring Boot 3.4.5, providing third-party administration (TPA), recordkeeping, and registered investment advisor (RIA) services.

## Overview

GlidingPath is a modular monolith architecture designed to manage the complete lifecycle of 401(k) retirement plans, from plan setup and payroll integration to compliance testing and investment management.

### Key Features

- **Multi-tenant Architecture** - Secure tenant isolation with automatic data filtering
- **Payroll Integration** - Supports 200+ payroll providers via Finch API
- **Compliance Engine** - Automated IRS/ERISA compliance testing using Drools
- **Event-Driven CQRS** - Event sourcing with Kafka and Redis projections
- **Batch Processing** - Scheduled jobs for payroll, compliance, and reporting
- **Custodian Integration** - Automated trade instruction processing with BTC
- **Identity Management** - Enterprise-grade authentication with Keycloak

### Supported Plan Types

- Traditional 401(k)
- Safe Harbor 401(k)
- QACA Safe Harbor 401(k)
- Starter 401(k)

## Technology Stack

- **Runtime**: Java 21, Spring Boot 3.4.5
- **Build Tool**: Gradle 8.13
- **Database**: PostgreSQL 15+ (multi-tenant)
- **Caching**: Redis 7+
- **Messaging**: Apache Kafka 3.x
- **Rules Engine**: Drools 8.44.0
- **Identity**: Keycloak 23+
- **Batch Processing**: Spring Batch 5.2.2
- **Cloud Services**: AWS (S3, SES, SQS)
- **Integrations**: Finch API (payroll), BTC (custodian)

## Quick Start

### Prerequisites

- Java 21 (Eclipse Temurin or Oracle JDK)
- Docker & Docker Compose
- Gradle 8.x (or use included wrapper)

### Local Development Setup

For detailed setup instructions, see **[SETUP.md](./SETUP.md)**.

```bash
# 1. Start required services
docker-compose up -d

# 2. Configure local properties
cp src/main/resources/application-local.properties.example \
   src/main/resources/application-local.properties
# Edit application-local.properties with your credentials

# 3. Build the application
./gradlew clean build

# 4. Run the application
./gradlew bootRun
```

The application will start on **http://localhost:9090**

API Documentation: **http://localhost:9090/v1/api/swagger-ui.html**

## Architecture

### Module Structure

This is a **modular monolith** with 12 modules organized by domain boundaries:

#### Foundation Modules
- **glidingpath-core** - Domain entities, repositories, enums (BaseEntity, multi-tenant support)
- **glidingpath-common** - Shared utilities, constants, contracts

#### Business Logic Modules
- **glidingpath-auth** - Authentication & authorization
- **glidingpath-platform** - Core business logic and services
- **glidingpath-admin** - Administrative functions, document management (AWS S3)
- **glidingpath-recordkeeping** - Transaction recordkeeping using CQRS pattern with event sourcing (Kafka) and read projections (Redis)
- **glidingpath-rules** - Business rules engine using Drools for 401(k) compliance
- **glidingpath-activity** - Activity and task management
- **glidingpath-scheduler** - Scheduled jobs using Spring Batch and ShedLock

#### Integration Modules
- **x-glidingpath-finch** - Finch payroll integration (200+ providers)
- **x-glidingpath-btc** - BTC custodian integration via SFTP
- **x-glidingpath-keycloak** - Keycloak identity management integration

### Key Architectural Patterns

1. **Multi-tenant Architecture**: All entities extend `BaseEntity` with automatic tenant filtering via JPA filters
2. **CQRS with Event Sourcing**: The `glidingpath-recordkeeping` module uses Kafka events for write operations and Redis projections for read models
3. **Event-Driven**: Modules communicate via Spring events and Kafka for loose coupling
4. **Repository Pattern**: Data access through Spring Data JPA repositories
5. **DTO Pattern**: API boundaries use DTOs with ModelMapper for entity mapping
6. **Batch Processing**: Spring Batch for payroll, compliance testing, and reporting

## Building and Running

### Build Commands

```bash
# Build without tests
./gradlew build -x test

# Clean build
./gradlew clean build

# Run tests
./gradlew test

# Run specific module tests
./gradlew :modules:glidingpath-recordkeeping:test

# Generate test coverage report
./gradlew test jacocoTestReport
```

### Running the Application

```bash
# Run with Gradle
./gradlew bootRun

# Run with Java
java -jar build/libs/core-0.0.1-SNAPSHOT.jar

# Run with specific profile
./gradlew bootRun --args='--spring.profiles.active=local'
```

### Docker Deployment

```bash
# Build Docker image
docker build -t glidingpath-backend:latest .

# Run container
docker run -p 9090:9090 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/glidingpath_db \
  -e SPRING_DATASOURCE_USERNAME=your_username \
  -e SPRING_DATASOURCE_PASSWORD=your_password \
  glidingpath-backend:latest
```

The Dockerfile uses a multi-stage build with:
- Build stage: Gradle 8.13 with JDK 21 Alpine
- Runtime stage: Eclipse Temurin 21 JRE Alpine
- Optimized layer caching for dependencies
- Non-root user execution for security
- JVM performance tuning for containers
- Built-in health checks

## Configuration

### Environment Variables

Configure the application using environment variables or `application-local.properties`:

- `SPRING_DATASOURCE_URL` - PostgreSQL connection URL
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password
- `FINCH_CLIENT_ID` - Finch API client ID
- `FINCH_CLIENT_SECRET` - Finch API client secret
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `KEYCLOAK_AUTH_SERVER_URL` - Keycloak server URL
- `SPRING_KAFKA_BOOTSTRAP_SERVERS` - Kafka bootstrap servers
- `SPRING_DATA_REDIS_HOST` - Redis host

See `application-local.properties.example` for complete list.

### Spring Profiles

- **local** - Local development (default)
- **dev** - Development environment
- **test** - Testing environment
- **prod** - Production environment

See [PROFILES.md](./PROFILES.md) for detailed profile configurations.

## API Documentation

### OpenAPI/Swagger

Interactive API documentation is available at:
- **Swagger UI**: http://localhost:9090/v1/api/swagger-ui.html
- **OpenAPI JSON**: http://localhost:9090/v1/api/api-docs

### Health & Monitoring

- **Health Check**: http://localhost:9090/v1/api/actuator/health
- **Info Endpoint**: http://localhost:9090/v1/api/actuator/info

## Testing

### Running Tests

```bash
# Run all tests
./gradlew test

# Run tests for specific module
./gradlew :modules:glidingpath-recordkeeping:test

# Run with coverage report
./gradlew test jacocoTestReport

# View coverage report
open build/reports/jacoco/test/html/index.html
```

### Test Coverage

Current test coverage for `glidingpath-recordkeeping` module:
- **Instruction Coverage**: 92%
- **Branch Coverage**: 83%
- **Test Count**: 987 tests across 60+ test classes

## Development

### Code Conventions

- Use Lombok (@Builder, @Data, @Slf4j) for boilerplate reduction
- Prefer constructor injection over field injection
- All new entities must extend `BaseEntity` (provides multi-tenant support, audit fields)
- Use DTOs for all API requests/responses
- Follow Spring Boot best practices
- Write comprehensive tests (aim for 90%+ coverage)

### Project Structure

```
gp-backend/
├── src/main/java/com/glidingpath/
│   ├── GlidingPathApplication.java     # Main application class
│   └── modules/                        # Business modules
│       ├── auth/                       # Authentication
│       ├── platform/                   # Core business logic
│       ├── admin/                      # Administration
│       ├── recordkeeping/              # CQRS recordkeeping
│       ├── rules/                      # Compliance rules
│       ├── activity/                   # Activity management
│       ├── scheduler/                  # Batch processing
│       └── integrations/               # External integrations
├── src/main/resources/
│   ├── application.properties          # Common configuration
│   ├── application-local.properties    # Local config (gitignored)
│   └── db/migration/                   # Flyway migrations
├── docs/                               # Module documentation
├── Dockerfile                          # Production Docker image
├── docker-compose.yml                  # Local services
└── build.gradle                        # Build configuration
```

### Documentation

Comprehensive documentation is available in the `docs/` folder:

- **[PROJECT_OVERVIEW.md](./docs/PROJECT_OVERVIEW.md)** - System architecture and business domain
- **[MODULE_*.md](./docs/)** - Detailed documentation for each module
- **[ERD_*.md](./docs/)** - Database and entity relationship diagrams
- **[401K_DOMAIN_GUIDE.md](./docs/401K_DOMAIN_GUIDE.md)** - 401(k) domain knowledge
- **[COMPLIANCE_GUIDE.md](./docs/COMPLIANCE_GUIDE.md)** - Compliance requirements
- **[BATCH_SCHEDULER_ARCHITECTURE.md](./BATCH_SCHEDULER_ARCHITECTURE.md)** - Batch job architecture

## Deployment

### Docker Compose (Local)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

Services started by Docker Compose:
- PostgreSQL (port 5432)
- Redis (port 6379)
- Kafka (port 9092)
- Zookeeper (port 2181)
- Keycloak (port 8080)

### Production Deployment

The application is containerized and ready for deployment to:
- AWS ECS/Fargate
- Kubernetes
- Any container orchestration platform

Environment-specific configuration should be provided via environment variables or external configuration management.

## Business Domain

This is a **401(k) retirement plan administration platform** serving as:
- **Third-Party Administrator (TPA)** - Plan setup, compliance testing, government filings
- **Recordkeeper** - Participant account management, transaction processing
- **Registered Investment Advisor (RIA)** - Investment selection and monitoring

### Key Operations

- Plan setup and lifecycle management
- Payroll integration and contribution processing
- IRS/ERISA compliance testing (ADP, ACP, 402(g), 415)
- Participant account management and reporting
- Investment management via custodian integration
- Automated trade instruction generation
- Regulatory reporting and government filings

## Support

### Troubleshooting

For common issues and solutions, see **[SETUP.md](./SETUP.md)** - Common Issues & Troubleshooting section.

### Getting Help

1. Check documentation in `docs/` folder
2. Review module-specific READMEs
3. Check application logs
4. Contact the development team

## License

Proprietary - All Rights Reserved

## Version

**Current Version**: 0.0.1-SNAPSHOT
**Spring Boot**: 3.4.5
**Java**: 21


