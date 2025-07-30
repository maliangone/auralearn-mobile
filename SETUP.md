# AuraLearn Setup Guide

This guide will help you set up the AuraLearn backend (Django) and mobile app (Flutter) for development.

## Prerequisites

Before you begin, ensure you have the following installed:

### Backend Requirements
- **Python 3.11+** - [Download Python](https://python.org/downloads/)
- **PostgreSQL 14+** - [Download PostgreSQL](https://postgresql.org/download/)
- **Redis 6+** - [Download Redis](https://redis.io/download/)
- **Git** - [Download Git](https://git-scm.com/downloads/)

### Mobile Requirements
- **Flutter SDK 3.0+** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Optional (Recommended)
- **Docker & Docker Compose** - [Install Docker](https://docs.docker.com/get-docker/)

## Backend Setup (Django)

### Option 1: Local Development Setup

1. **Clone the Repository**
```bash
git clone <repository-url>
cd auralearn
```

2. **Create Python Virtual Environment**
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

3. **Install Python Dependencies**
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

4. **Setup PostgreSQL Database**
```bash
# Create database (using psql)
createdb auralearn

# Or using PostgreSQL CLI:
psql -U postgres
CREATE DATABASE auralearn;
CREATE USER auralearn WITH PASSWORD 'auralearn_password';
GRANT ALL PRIVILEGES ON DATABASE auralearn TO auralearn;
\q
```

5. **Setup Redis**
```bash
# Start Redis server
redis-server

# Verify Redis is running
redis-cli ping
# Should return: PONG
```

6. **Configure Environment Variables**
```bash
# Copy example environment file
cp .env.example .env

# Edit .env file with your configuration
nano .env  # or use your preferred editor
```

**Required Environment Variables:**
```bash
# Django Configuration
SECRET_KEY=your-secret-key-here-make-it-very-long-and-secure-at-least-50-chars
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# Database Configuration
DB_NAME=auralearn
DB_USER=auralearn
DB_PASSWORD=auralearn_password
DB_HOST=localhost
DB_PORT=5432

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# AI Provider Keys (get from respective providers)
OPENAI_API_KEY=sk-your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Stripe Keys (get from Stripe dashboard)
STRIPE_SECRET_KEY=sk_test_your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=whsec_your-webhook-secret

# Email Configuration (for password reset, etc.)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

7. **Run Database Migrations**
```bash
python manage.py makemigrations
python manage.py migrate
```

8. **Create Superuser (Optional)**
```bash
python manage.py createsuperuser
```

9. **Collect Static Files**
```bash
python manage.py collectstatic --noinput
```

10. **Start Development Server**
```bash
python manage.py runserver 8000
```

The backend should now be running at `http://localhost:8000`

### Option 2: Docker Setup (Recommended)

1. **Clone the Repository**
```bash
git clone <repository-url>
cd auralearn
```

2. **Configure Environment**
```bash
# Copy example environment file
cp backend/.env.example backend/.env

# Edit backend/.env with your configuration
# At minimum, set:
# - OPENAI_API_KEY
# - ANTHROPIC_API_KEY
# - STRIPE_SECRET_KEY
# - EMAIL configuration
```

3. **Start Services with Docker Compose**
```bash
# Start all services in background
docker-compose up -d

# View logs
docker-compose logs -f backend
```

4. **Run Initial Setup**
```bash
# Run database migrations
docker-compose exec backend python manage.py migrate

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Collect static files
docker-compose exec backend python manage.py collectstatic --noinput
```

5. **Verify Services**
```bash
# Check service status
docker-compose ps

# Test backend API
curl http://localhost:8000/api/core/health/
```

## Mobile Setup (Flutter)

1. **Navigate to Mobile Directory**
```bash
cd mobile
```

2. **Install Flutter Dependencies**
```bash
flutter pub get
```

3. **Verify Flutter Installation**
```bash
flutter doctor
```
Fix any issues reported by `flutter doctor`.

4. **Configure Backend URL**
Edit `lib/core/config/app_config.dart` and set the backend URL:
```dart
static const String baseUrl = 'http://localhost:8000/api';
// For Android emulator: 'http://10.0.2.2:8000/api'
// For iOS simulator: 'http://localhost:8000/api'
```

5. **Run the App**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run on available device
flutter run
```

## API Keys Setup

### OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Add it to your `.env` file as `OPENAI_API_KEY`

### Anthropic API Key
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Add it to your `.env` file as `ANTHROPIC_API_KEY`

### Stripe Configuration
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Create an account or sign in
3. In test mode, get your:
   - Secret key (starts with `sk_test_`)
   - Webhook endpoint secret (create webhook endpoint first)
4. Add them to your `.env` file

## Development Workflow

### Backend Development
```bash
# Start backend with auto-reload
python manage.py runserver 8000

# In another terminal, start Celery worker
celery -A auralearn_backend worker --loglevel=info

# Run tests
python manage.py test

# Create new Django app
python manage.py startapp new_app_name

# Create database migrations after model changes
python manage.py makemigrations
python manage.py migrate
```

### Frontend Development
```bash
# Hot reload development
flutter run

# Build APK for testing
flutter build apk

# Run tests
flutter test
```

## Common Issues & Troubleshooting

### Backend Issues

**Issue**: `psycopg2` installation fails
**Solution**: Install PostgreSQL development headers
```bash
# Ubuntu/Debian
sudo apt-get install libpq-dev python3-dev

# macOS
brew install postgresql

# Windows
# Use psycopg2-binary instead of psycopg2
```

**Issue**: Redis connection error
**Solution**: Ensure Redis is running
```bash
# Start Redis
redis-server

# Check if running
redis-cli ping
```

**Issue**: API key errors
**Solution**: Verify your API keys are correctly set in `.env`

### Mobile Issues

**Issue**: Flutter doctor shows issues
**Solution**: Follow Flutter installation guide for your platform

**Issue**: App can't connect to backend
**Solution**: 
- Check backend is running on correct port
- Use correct IP for emulator (10.0.2.2 for Android, localhost for iOS)
- Check firewall settings

## Production Deployment

### Environment Variables for Production
```bash
DEBUG=False
SECRET_KEY=<generate-strong-secret-key>
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
DB_HOST=your-production-db-host
STRIPE_SECRET_KEY=sk_live_your-production-stripe-key
# ... other production settings
```

### Deploy with Docker
```bash
# Build production image
docker-compose -f docker-compose.prod.yml build

# Start production services
docker-compose -f docker-compose.prod.yml up -d

# Run migrations in production
docker-compose -f docker-compose.prod.yml exec backend python manage.py migrate
```

## Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

## Support

If you encounter any issues:
1. Check this setup guide
2. Review the error logs
3. Check the project's issue tracker
4. Reach out to the development team 