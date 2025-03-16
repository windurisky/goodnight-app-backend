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

### 🔒 Authentication
- JWT-based authentication
- Secure password handling with BCrypt
- Protected endpoints for user-specific operations

## Technical Architecture

### Design Highlights
- **Service Objects**: Clean separation of business logic using `ApplicationService` pattern
- **State Machine**: AASM for sleep record state management (clocked_in/clocked_out)
- **Custom Error Handling**: Standardized error responses with `HandledError` classes
- **Sorted Set for Sleep Records**: Redis sorted set used for fast retrieval of followings' sleep records
- **Optimized Keyset Pagination**: Using sorted set, we can efficiently paginate sleep records by its index range
- **Task Queue for Background Jobs**: Sidekiq handles async job processing
- **Rate Limiting**: Basic redis-based throttling for API endpoints

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
For future growth, see the detailed [Scaling Strategy](#scaling-strategy) section below which outlines the scalable multi-tier approach inspired by Twitter's timeline architecture.

## Limitations & Future Enhancements
Due to limited development time and environment constraints, this implementation does not fully reflect a production-scale system. Some of the planned enhancements including (but not limited to):
- **Sharding & Partitioning**: Not yet implemented. Future iterations will partition sleep records and shard users based on ID ranges or time periods.
- **Graph Database for Follow Relationships**: Currently, the follow system is implemented using MySQL. A future version may leverage a graph database like Neo4j for efficient traversal of social relationships.
- **Optimized Fanout for Followings' Sleep Records**: Currently, sleep records are fetched using Redis sorted sets from fanout-on-write, but do not yet implement a fanout-on-read approach to optimize use case of people with huge followers.
- **Scoring & Ranking**: Future versions should incorporate a scoring system to rank users based on sleep patterns and social connections (based on view count, etc.).

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

## Scaling Strategy
The Goodnight app's architecture is designed to scale efficiently, taking inspiration from Twitter's approach to home timeline delivery.

### Current Optimization Techniques
1. **Efficient Queries**
   - Indexed fields for fast filtering (user_id, state, duration)

2. **Data Structure Optimization**
   - Denormalized user data where appropriate (e.g.: sleep duration is pre-computed and stored in a field)
   - Soft deletion pattern for follows
   - **Redis Sorted Set for precomputed timeline**

3. **Background Job Processing**
   - Sidekiq handles async job execution for non-blocking operations

### Future Scaling Enhancements
#### Tier 1: Read Replicas & Caching
- **Read Replicas**: Direct read-only queries to replicas
- **Redis Caching Layer**: Cache frequently accessed sleep records

#### Tier 2: Fanout & Service Splitting
- **Fanout on Read Pattern**: Pre-compute and pull data on request for celebrity users (huge followers)
- **Service Decomposition**: Split into independent microservices

#### Tier 3: Sharding & Data Partitioning
- **Horizontal Sharding**: Shard users by ID
- **Time-Based Partitioning**: Partition sleep records by time periods
- **Follow Graph Partitioning**: Optimize for read-time social graph traversal

#### Tier 4: Observability & Monitoring
- **Datadog Integration**: Monitor API performance, background jobs, and Redis usage
- **Alerting & Anomaly Detection**: Automated alerts for performance degradation or errors

## Conclusion
While the current implementation is optimized for an ambitious scale, real production iterations should introduce sharding, graph databases, and improved caching strategies to handle production-level workloads efficiently.
