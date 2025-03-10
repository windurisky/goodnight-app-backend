# Goodnight App - Sleep Tracking API

A Ruby on Rails API-only microservice for tracking sleep patterns and following other users' sleep records, built with scalability in mind and following an API-first design approach.

## Technical Specifications
- Rails 7.2.1
- Ruby 3.3.0
- MySQL 8.0.40
- Redis 7.0

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
For future growth, see the detailed [Scaling Strategy](#scaling-strategy) section below which outlines our multi-tier approach inspired by Twitter's timeline architecture.

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

## Scaling Strategy

The Goodnight app's architecture is designed to scale efficiently, taking inspiration from Twitter's approach to timeline delivery. The followings sleep records feature closely resembles Twitter's home timeline, where users view content from accounts they follow.

### Current Optimization Techniques

1. **Efficient Queries**
   - Indexed fields for fast filtering (user_id, state, duration)
   - Selective includes to prevent N+1 queries
   - Pagination without COUNT queries for better performance

2. **Data Structure Optimization**
   - Pre-computed duration values to avoid calculation at read-time
   - Denormalized user data where appropriate
   - Soft deletion pattern for follows to maintain history

### Multi-Tier Scaling Approach

#### Tier 1: Database Optimization (Current Stage)
- Strategic indexing on query patterns
- Query optimization using EXPLAIN and monitoring
- Connection pooling to efficiently manage database connections
- Database parameter tuning for read-heavy workloads

#### Tier 2: Read Replicas & Caching (1M+ Users)
- **Read Replicas**
  - Direct read-only queries to replicas
  - Keep writes on primary database
  - Use replicas for followings sleep records queries
  - Configure connection pools to distribute load across replicas

- **Redis Caching Layer**
  - Cache frequently accessed sleep records
  - Cache user follow relationships
  - Implement cache invalidation on state changes
  - Time-based expiry for sleep data

#### Tier 3: Fanout & Service Splitting (10M+ Users)
- **Fanout on Write Pattern** (Twitter's approach)
  - When a user clocks out, pre-compute and store the sleep record in followers' timelines
  - Store timeline data in Redis sorted sets
  - For users with many followers, process fanout asynchronously via jobs
  - Significantly reduces read-time complexity

- **Service Decomposition**
  - Split into independent microservices:
    - Authentication service
    - User/Follow service
    - Sleep record service
    - Timeline service
  - Implement API gateway for client requests

#### Tier 4: Sharding & Data Partitioning (100M+ Users)
- **Horizontal Sharding**
  - Shard users by ID (consistent hashing)
  - Co-locate user data with their sleep records
  - Maintain shard maps in a distributed configuration store

- **Time-Based Partitioning**
  - Partition sleep records by time periods
  - Recent data in hot storage
  - Historical data in cold storage
  - Automated archiving policies

- **Follow Graph Partitioning**
  - Partition social graph data
  - Optimize for read-time social graph traversal
  - Cache frequently accessed social connections

### Handling Edge Cases

- **Celebrity Problem** (users with many followers)
  - Separate processing for users with high follower counts
  - Asynchronous fanout for high-follow accounts
  - Potential for special caching rules

- **Data Hotspots**
  - Detect and mitigate hotspots through adaptive sharding
  - Dynamic cache warming for trending users
  - Load balancing across read replicas

- **Global Distribution**
  - Regional database clusters
  - Data locality based on user geography
  - CDN for static resources and cached data

### Monitoring & Scaling Triggers

- Key metrics that trigger scaling decisions:
  - Read/write ratio per database instance
  - Query latency thresholds
  - Cache hit/miss rates
  - Follow graph density changes
  - Peak vs average loads

- Automated scaling responses:
  - Add read replicas when read load increases
  - Increase cache size when hit rates decline
  - Adjust connection pools when throughput changes
  - Implement new shards when existing shards exceed capacity thresholds

### Implementation Roadmap

1. **Current Phase**: Focus on query optimization and index tuning
2. **Next Phase**: Implement Redis caching and read replicas
3. **Future Phase**: Evaluate fanout approach as user base grows
4. **Scale Phase**: Implement sharding and partitioning when metrics indicate need

By taking inspiration from Twitter's architecture while adapting to our specific use case of sleep tracking, this scaling strategy provides a clear path from current implementation to supporting hundreds of millions of users.
