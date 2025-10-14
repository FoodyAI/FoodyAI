#!/bin/bash

# ============================================================
# Deploy Push Notification Schema to AWS RDS PostgreSQL
# ============================================================
# Description: Script to deploy the push notification schema
#              to your AWS RDS PostgreSQL database
# Usage: ./deploy-notification-schema.sh [options]
# ============================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/push-notification-schema.sql"
LOG_FILE="${SCRIPT_DIR}/schema-deployment.log"

# ============================================================
# Functions
# ============================================================

print_header() {
    echo -e "${BLUE}"
    echo "============================================================"
    echo "  Push Notification Schema Deployment"
    echo "============================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v psql &> /dev/null; then
        print_error "psql is not installed. Please install PostgreSQL client."
        print_info "macOS: brew install postgresql"
        print_info "Ubuntu: sudo apt-get install postgresql-client"
        exit 1
    fi

    if [ ! -f "$SCHEMA_FILE" ]; then
        print_error "Schema file not found: $SCHEMA_FILE"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Load environment variables from .env file
load_env_vars() {
    if [ -f "${SCRIPT_DIR}/.env" ]; then
        print_info "Loading environment variables from .env..."
        export $(grep -v '^#' "${SCRIPT_DIR}/.env" | xargs)
        print_success "Environment variables loaded"
    else
        print_warning ".env file not found. You'll need to provide database credentials manually."
    fi
}

# Get database credentials
get_credentials() {
    print_info "Database connection configuration"
    echo ""

    # DB Host
    if [ -z "$DB_HOST" ]; then
        read -p "Enter RDS Endpoint (DB_HOST): " DB_HOST
    else
        print_info "Using DB_HOST from environment: $DB_HOST"
    fi

    # DB Port
    if [ -z "$DB_PORT" ]; then
        read -p "Enter Port [5432]: " DB_PORT
        DB_PORT=${DB_PORT:-5432}
    else
        print_info "Using DB_PORT from environment: $DB_PORT"
    fi

    # DB Name
    if [ -z "$DB_NAME" ]; then
        read -p "Enter Database Name [foody]: " DB_NAME
        DB_NAME=${DB_NAME:-foody}
    else
        print_info "Using DB_NAME from environment: $DB_NAME"
    fi

    # DB User
    if [ -z "$DB_USER" ]; then
        read -p "Enter Database User [postgres]: " DB_USER
        DB_USER=${DB_USER:-postgres}
    else
        print_info "Using DB_USER from environment: $DB_USER"
    fi

    # DB Password
    if [ -z "$DB_PASSWORD" ]; then
        read -sp "Enter Database Password: " DB_PASSWORD
        echo ""
    else
        print_info "Using DB_PASSWORD from environment (hidden)"
    fi

    # Export for psql
    export PGPASSWORD="$DB_PASSWORD"
}

# Test database connection
test_connection() {
    print_info "Testing database connection..."

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
        print_success "Database connection successful"
        return 0
    else
        print_error "Failed to connect to database"
        print_info "Please check your credentials and RDS security group settings"
        return 1
    fi
}

# Backup existing schema
backup_schema() {
    print_info "Creating backup of current schema..."

    BACKUP_FILE="${SCRIPT_DIR}/schema-backup-$(date +%Y%m%d-%H%M%S).sql"

    # Backup users table structure
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\d+ users" > "$BACKUP_FILE" 2>&1 || true

    # Backup existing notification tables if they exist
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\d+ notifications_log" >> "$BACKUP_FILE" 2>&1 || true
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\d+ notification_campaigns" >> "$BACKUP_FILE" 2>&1 || true

    print_success "Backup created: $BACKUP_FILE"
}

# Deploy schema
deploy_schema() {
    print_info "Deploying push notification schema..."
    echo ""
    print_warning "This will modify your database. Continue? (yes/no)"
    read -r confirmation

    if [ "$confirmation" != "yes" ]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi

    print_info "Executing schema file..."

    # Execute the schema file
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$SCHEMA_FILE" > "$LOG_FILE" 2>&1; then
        print_success "Schema deployed successfully"
        print_info "Deployment log saved to: $LOG_FILE"
    else
        print_error "Schema deployment failed"
        print_error "Check log file for details: $LOG_FILE"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    print_info "Verifying schema deployment..."
    echo ""

    # Check users table columns
    print_info "Checking users table columns..."
    local users_check=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name IN ('fcm_token', 'notifications_enabled', 'is_premium', 'last_token_update');" | wc -l)

    if [ "$users_check" -eq 4 ]; then
        print_success "Users table: All columns added"
    else
        print_warning "Users table: Some columns may be missing (found $users_check/4)"
    fi

    # Check notifications_log table
    print_info "Checking notifications_log table..."
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='notifications_log';" | grep -q 1; then
        print_success "notifications_log: Table exists"
    else
        print_error "notifications_log: Table not found"
    fi

    # Check notification_campaigns table
    print_info "Checking notification_campaigns table..."
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='notification_campaigns';" | grep -q 1; then
        print_success "notification_campaigns: Table exists"
    else
        print_error "notification_campaigns: Table not found"
    fi

    # Check indexes
    print_info "Checking indexes..."
    local index_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT COUNT(*) FROM pg_indexes WHERE indexname LIKE 'idx_%notification%' OR indexname LIKE 'idx_users_fcm%' OR indexname LIKE 'idx_users_is_premium%';" | xargs)

    print_success "Indexes created: $index_count"

    # Check triggers
    print_info "Checking triggers..."
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT 1 FROM information_schema.triggers WHERE trigger_name='trigger_update_last_token_update';" | grep -q 1; then
        print_success "Trigger: trigger_update_last_token_update exists"
    else
        print_warning "Trigger: trigger_update_last_token_update not found"
    fi

    # Check views
    print_info "Checking views..."
    local view_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -t -c "SELECT COUNT(*) FROM information_schema.views WHERE table_name LIKE 'v_%notification%';" | xargs)

    print_success "Views created: $view_count"

    echo ""
    print_success "Verification complete!"
}

# Run sample queries
run_sample_queries() {
    print_info "Running sample validation queries..."
    echo ""

    # Count users with FCM tokens
    print_info "1. Users with FCM tokens:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT COUNT(*) as users_with_fcm_token FROM users WHERE fcm_token IS NOT NULL;"

    # Count notification-enabled users
    print_info "2. Users with notifications enabled:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT COUNT(*) as notification_enabled FROM users WHERE notifications_enabled = true;"

    # Count premium users
    print_info "3. Premium users:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT COUNT(*) as premium_users FROM users WHERE is_premium = true;"

    # List eligible users view
    print_info "4. Eligible users (view):"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT COUNT(*) as eligible_users FROM v_notification_eligible_users;"

    echo ""
    print_success "Sample queries executed"
}

# Show summary
show_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "============================================================"
    echo "  Deployment Summary"
    echo "============================================================"
    echo -e "${NC}"
    echo "✅ Database: $DB_NAME"
    echo "✅ Host: $DB_HOST:$DB_PORT"
    echo "✅ Schema file: $SCHEMA_FILE"
    echo "✅ Log file: $LOG_FILE"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Review the deployment log: cat $LOG_FILE"
    echo "2. Test with validation queries: ./validate-notification-schema.sh"
    echo "3. Proceed to Issue #2: Firebase Admin SDK Setup"
    echo "4. Update Lambda functions to use new schema"
    echo ""
    print_success "Push notification schema deployment complete!"
    echo ""
}

# Cleanup
cleanup() {
    unset PGPASSWORD
}

# ============================================================
# Main Execution
# ============================================================

main() {
    print_header

    # Set trap for cleanup
    trap cleanup EXIT

    # Run deployment steps
    check_prerequisites
    load_env_vars
    get_credentials

    if ! test_connection; then
        exit 1
    fi

    backup_schema
    deploy_schema
    verify_deployment
    run_sample_queries
    show_summary
}

# ============================================================
# Command Line Arguments
# ============================================================

case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h        Show this help message"
        echo "  --verify-only     Only verify the schema without deploying"
        echo "  --no-backup       Skip backup step"
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST           RDS endpoint"
        echo "  DB_PORT           Database port (default: 5432)"
        echo "  DB_NAME           Database name (default: foody)"
        echo "  DB_USER           Database user (default: postgres)"
        echo "  DB_PASSWORD       Database password"
        echo ""
        echo "Example:"
        echo "  DB_HOST=your-rds.amazonaws.com DB_PASSWORD=yourpass $0"
        exit 0
        ;;
    --verify-only)
        print_header
        check_prerequisites
        load_env_vars
        get_credentials
        test_connection
        verify_deployment
        exit 0
        ;;
    *)
        main
        ;;
esac
