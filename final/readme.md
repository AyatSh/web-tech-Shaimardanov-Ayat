# Cinema Database Management System

## Overview
Comprehensive PostgreSQL database schema for a cinema ticket booking and management system.

## Key Features

### Database Initialization
- Creates and initializes `cinema_db` database with `cinema` schema
- Implements cascade drop for dependent tables
- Resets identity sequences for clean data state

### Core Entities

**Reference Tables:**
- `genres` - Film genre classifications (Action, Drama, Comedy, etc.)
- `countries` - Country information with ISO codes
- `directors` - Film director profiles with birth dates and nationalities

**Business Tables:**
- `films` - Movie catalog with ratings, duration, release year, and status tracking
- `halls` - Cinema auditorium information with capacity and type (standard, IMAX, VIP, 4DX)
- `customers` - Customer profiles with loyalty point tracking

**Transaction Tables:**
- `sessions` - Film showings with time, pricing, and seat availability
- `tickets` - Seat reservations linking customers to sessions with booking status
- `payments` - Transaction records with method and completion status

**Junction Tables:**
- `film_genre` - Many-to-many relationship between films and genres
- `film_director` - Many-to-many relationship between films and directors with role specification

### Data Integrity
- Constraint validations: duration > 0, prices ≥ 0, ratings 0-10, release year 1888-2100
- Status enums for films, tickets, and payments
- Foreign key relationships with ON DELETE RESTRICT/CASCADE/SET NULL policies
- UNIQUE constraints for sessions and seats

### Enhanced Functionality
- Derived `start_date` column from `start_time` timestamp
- Automatic loyalty points calculation based on completed payments
- Film status auto-archival when no reserved/confirmed tickets exist
- Payment cleanup for refunded/pending records older than 90 days

### Security & Access Control
- Role-based access: `cinema_readonly` and `cinema_writer`
- Schema-level grants with table-specific permissions
- Selective write access for tickets and payments only
- Automatic role cleanup before creation

### Sample Data
- Pre-populated with 5 films (Interstellar, Parasite, Barbie, Gladiator II, The Dark Knight)
- 4 distinguished film directors across multiple countries
- 4 cinema halls with varying capacities and technologies
- 5 customer records with loyalty point tracking
- Complete booking workflow: sessions → tickets → payments