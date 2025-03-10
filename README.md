# Goodnight App - Sleep Tracking API

A Ruby on Rails API-only microservice for tracking sleep patterns and following other users' sleep records.

## Features

### 🌙 Sleep Tracking
- Clock in when going to bed
- Clock out when waking up
- Automatic sleep duration calculation
- State-based tracking using AASM

### 👥 Social Features
- Follow/unfollow other users
- View sleep records of users you follow
- Pagination of sleep records with efficient without_count implementation

### 🔐 Authentication
- JWT-based authentication
- Secure password handling with BCrypt
- Protected endpoints for user-specific operations

## Technical Architecture

### Design Patterns
- **Service Objects**: Clean separation of business logic using `ApplicationService` pattern
- **State Machine**: AASM for sleep record state management (clocked_in/clocked_out)
- **Custom Error Handling**: Standardized error responses with `HandledError` classes
- **Optimized Pagination**: Using Kaminari's `without_count` for efficient large dataset handling

### Key Design Decisions

#### API-First Design
The project follows an API-first design methodology:
- API interfaces are designed and documented before implementation
- OpenAPI (Swagger) specifications serve as the source of truth
- Consistent patterns for endpoints, request/response formats, and error handling
- Documentation-driven development ensures frontend and backend alignment

#### Read-Heavy Architecture
The application is designed with the assumption that it's heavily read-oriented:
- Users clock in/out only 1-2 times per day (writes)
- Users frequently check their own and others' sleep records (reads)
- Read-to-write ratio is approximately 10:1 or higher

#### Performance Optimizations
- Strategic indexing on frequently queried fields (user_id, state, duration)
- Pre-computed duration to avoid calculation at read time
- Efficient pagination without expensive COUNT queries
- Includes necessary associated data to minimize N+1 queries

#### Scaling Strategy
For future growth, the application can scale through:
1. **Read Replicas**: Direct read queries to replicas while keeping writes on the primary
2. **Data Partitioning**: Time-based partitioning of historical sleep records
3. **Caching**: Redis caching for frequently accessed data
4. **Horizontal Sharding**: User-based sharding for very large deployments

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login

### User Management
- `GET /api/v1/users/me` - Get current user

### Social Features
- `POST /api/v1/socials/follow` - Follow a user
- `POST /api/v1/socials/unfollow` - Unfollow a user

### Sleep Tracking
- `POST /api/v1/sleep_records/clock_in` - Start sleep tracking
- `POST /api/v1/sleep_records/clock_out` - End sleep tracking
- `GET /api/v1/sleep_records/followings` - Get paginated sleep records of followed users

## Development with GitHub Codespaces

This project is configured to work with GitHub Codespaces, which provides a complete development environment in the cloud.

### Getting Started

1. Click on the "Code" button in your GitHub repository
2. Select the "Codespaces" tab
3. Click "Create codespace on main"

The codespace will automatically:
- Set up a development container with Ruby 3.3.0
- Install Rails 7.2.1
- Set up MySQL 8.0.40 and Redis 7.0
- Install all the necessary extensions for VS Code
- Run `bundle install` to install all dependencies
- Create the development database

### Available VS Code Extensions

The devcontainer comes with these pre-installed extensions:
- GitLens
- Ruby LSP
- Solargraph
- Ruby
- Endwise
- Ruby Rubocop
- YAML
- Rainbow CSV
- Docker
- ESLint
- Prettier

### Development Workflow

1. Once the Codespace is started, you can run Rails commands in the terminal:
```bash
# Setup .env file
cp .env.sample .env
# Start the Rails server
rails s
# Run a console
rails c
```

2. The following ports are forwarded:
- 3000: Rails server
- 3306: MySQL
- 6379: Redis

3. Database commands:
```bash
# Create the database, load schema, and seed data
rails db:setup
```

## Services

- **MySQL**: Available at `db:3306` with default username `root` and default password `password`
- **Redis**: Available at `redis:6379`

## Project Structure

This is an API-only Rails application. The main components are:
- `app/controllers/api`: Contains API controllers
- `app/models`: Data models
- `app/services`: Service objects for business logic
- `app/jobs`: Sidekiq background jobs
- `app/services/sleeps`: Sleep tracking service objects
- `app/services/socials`: Social features service objects

## Testing

This project uses RSpec for testing:
```bash
# Run all tests
rspec
# Run specific tests
rspec spec/services/sleeps/clock_in_service_spec.rb
```

## API Documentation

This project follows an **API-first design approach** for clarity and better developer experience. The OpenAPI (Swagger) documentation serves as both a design tool and living documentation.

### API-First Development
- API interfaces are designed and documented before implementation
- Swagger definitions serve as a contract between frontend and backend
- Clear endpoint specifications with request/response examples
- Consistent error handling patterns defined in the documentation

### Swagger Documentation
The application comes with pre-configured Swagger documentation:
```bash
# Generate API documentation
rails rswag:specs:swaggerize
```

After generating, the API documentation is available at `/api-docs` once the server is started. This interactive documentation allows you to:
- Browse all available endpoints
- See request/response formats
- Test endpoints directly from the browser
- Understand authentication requirements

## Technical Specifications
- Rails 7.2.1
- Ruby 3.3.0
- MySQL 8.0.40
- Redis 7.0