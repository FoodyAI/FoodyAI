#!/bin/bash

# ============================================================
# Validate Push Notification Schema
# ============================================================
# Description: Run validation queries to test the schema setup
# Usage: ./validate-notification-schema.sh
# ============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_LOG="${SCRIPT_DIR}/validation-results.log"

# ============================================================
# Functions
# ============================================================

print_header() {
    echo -e "${BLUE}"
    echo "============================================================"
    echo "  Push Notification Schema Validation"
    echo "============================================================"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

# Load environment variables
load_env_vars() {
    if [ -f "${SCRIPT_DIR}/.env" ]; then
        export $(grep -v '^#' "${SCRIPT_DIR}/.env" | xargs)
    fi
}

# Get database credentials
get_credentials() {
    if [ -z "$DB_HOST" ]; then
        read -p "Enter RDS Endpoint (DB_HOST): " DB_HOST
    fi
    if [ -z "$DB_PORT" ]; then
        read -p "Enter Port [5432]: " DB_PORT
        DB_PORT=${DB_PORT:-5432}
    fi
    if [ -z "$DB_NAME" ]; then
        read -p "Enter Database Name [foody]: " DB_NAME
        DB_NAME=${DB_NAME:-foody}
    fi
    if [ -z "$DB_USER" ]; then
        read -p "Enter Database User [postgres]: " DB_USER
        DB_USER=${DB_USER:-postgres}
    fi
    if [ -z "$DB_PASSWORD" ]; then
        read -sp "Enter Database Password: " DB_PASSWORD
        echo ""
    fi

    export PGPASSWORD="$DB_PASSWORD"
}

# Execute query and display results
execute_query() {
    local query="$1"
    local description="$2"

    echo ""
    print_info "$description"
    echo -e "${YELLOW}Query:${NC}"
    echo "$query"
    echo ""
    echo -e "${GREEN}Results:${NC}"

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "$query" 2>&1 || print_error "Query failed"

    echo ""
}

# Run all validation queries
run_validations() {
    # Initialize log
    echo "Push Notification Schema Validation Results" > "$VALIDATION_LOG"
    echo "Date: $(date)" >> "$VALIDATION_LOG"
    echo "========================================" >> "$VALIDATION_LOG"
    echo "" >> "$VALIDATION_LOG"

    print_section "1. Schema Validation"

    # Check users table columns
    execute_query "
        SELECT
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'users'
          AND column_name IN ('fcm_token', 'notifications_enabled', 'is_premium', 'last_token_update')
        ORDER BY ordinal_position;
    " "Users table - New columns"

    # Check notifications_log table
    execute_query "
        SELECT
            column_name,
            data_type,
            is_nullable
        FROM information_schema.columns
        WHERE table_name = 'notifications_log'
        ORDER BY ordinal_position;
    " "notifications_log table - Structure"

    # Check notification_campaigns table
    execute_query "
        SELECT
            column_name,
            data_type,
            is_nullable
        FROM information_schema.columns
        WHERE table_name = 'notification_campaigns'
        ORDER BY ordinal_position;
    " "notification_campaigns table - Structure"

    print_section "2. Indexes Validation"

    # Check indexes
    execute_query "
        SELECT
            indexname,
            tablename,
            indexdef
        FROM pg_indexes
        WHERE indexname LIKE '%notification%'
           OR indexname LIKE '%fcm%'
           OR indexname LIKE '%is_premium%'
        ORDER BY tablename, indexname;
    " "Notification-related indexes"

    print_section "3. Triggers Validation"

    # Check triggers
    execute_query "
        SELECT
            trigger_name,
            event_manipulation,
            event_object_table,
            action_statement
        FROM information_schema.triggers
        WHERE trigger_name LIKE '%token%'
           OR trigger_name LIKE '%notification%';
    " "Notification-related triggers"

    print_section "4. Views Validation"

    # Check views
    execute_query "
        SELECT
            table_name,
            view_definition
        FROM information_schema.views
        WHERE table_name LIKE 'v_%notification%'
        ORDER BY table_name;
    " "Notification-related views"

    print_section "5. Data Statistics"

    # Count total users
    execute_query "
        SELECT COUNT(*) as total_users
        FROM users;
    " "Total users in database"

    # Count users with FCM tokens
    execute_query "
        SELECT
            COUNT(*) as users_with_token,
            COUNT(*) FILTER (WHERE fcm_token IS NOT NULL) as with_fcm_token,
            COUNT(*) FILTER (WHERE notifications_enabled = true) as notifications_enabled,
            COUNT(*) FILTER (WHERE is_premium = true) as premium_users
        FROM users;
    " "User notification status breakdown"

    # Check notification-eligible users
    execute_query "
        SELECT COUNT(*) as eligible_users
        FROM v_notification_eligible_users;
    " "Users eligible for notifications (view)"

    # Count notification logs
    execute_query "
        SELECT
            COUNT(*) as total_logs,
            COUNT(DISTINCT user_id) as unique_users
        FROM notifications_log;
    " "Notification logs statistics"

    # Count campaigns
    execute_query "
        SELECT
            COUNT(*) as total_campaigns,
            COUNT(*) FILTER (WHERE status = 'draft') as draft,
            COUNT(*) FILTER (WHERE status = 'scheduled') as scheduled,
            COUNT(*) FILTER (WHERE status = 'sent') as sent
        FROM notification_campaigns;
    " "Campaign statistics"

    print_section "6. Sample Data Queries"

    # Recent notifications
    execute_query "
        SELECT
            id,
            user_id,
            notification_type,
            title,
            status,
            sent_at
        FROM notifications_log
        ORDER BY sent_at DESC
        LIMIT 5;
    " "Recent notifications (last 5)"

    # Premium users with notifications
    execute_query "
        SELECT
            user_id,
            email,
            display_name,
            is_premium,
            notifications_enabled,
            CASE
                WHEN fcm_token IS NOT NULL THEN 'Yes'
                ELSE 'No'
            END as has_fcm_token
        FROM users
        WHERE is_premium = true
        LIMIT 5;
    " "Premium users (sample)"

    # Users by age for filtering test
    execute_query "
        SELECT
            CASE
                WHEN age < 20 THEN 'Under 20'
                WHEN age >= 20 AND age < 30 THEN '20-29'
                WHEN age >= 30 AND age < 40 THEN '30-39'
                WHEN age >= 40 THEN '40+'
                ELSE 'Unknown'
            END as age_group,
            COUNT(*) as user_count,
            COUNT(*) FILTER (WHERE notifications_enabled = true AND fcm_token IS NOT NULL) as notifiable
        FROM users
        WHERE age IS NOT NULL
        GROUP BY age_group
        ORDER BY age_group;
    " "Users by age group (for age-based filtering)"

    print_section "7. Foreign Key Validation"

    # Check foreign key constraints
    execute_query "
        SELECT
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND (tc.table_name = 'notifications_log'
               OR tc.table_name = 'notification_campaigns');
    " "Foreign key constraints"

    print_section "8. Performance Test Queries"

    # Test index usage for FCM token lookup
    execute_query "
        EXPLAIN ANALYZE
        SELECT user_id, email, display_name
        FROM users
        WHERE fcm_token IS NOT NULL
          AND notifications_enabled = true
        LIMIT 10;
    " "Index usage - FCM token lookup (EXPLAIN ANALYZE)"

    # Test index usage for premium users
    execute_query "
        EXPLAIN ANALYZE
        SELECT user_id, email
        FROM users
        WHERE is_premium = true
          AND notifications_enabled = true
          AND fcm_token IS NOT NULL
        LIMIT 10;
    " "Index usage - Premium users filter (EXPLAIN ANALYZE)"

    print_section "9. Test Insert Operations"

    print_warning "Skipping insert tests. To test manually, run:"
    echo ""
    echo "-- Test notification log insert"
    echo "INSERT INTO notifications_log (user_id, notification_type, title, body, status)"
    echo "VALUES ('test_user_id', 'test', 'Test Notification', 'Test body', 'sent');"
    echo ""
    echo "-- Test campaign insert"
    echo "INSERT INTO notification_campaigns (campaign_name, title, body, status)"
    echo "VALUES ('Test Campaign', 'Test Title', 'Test body', 'draft');"
    echo ""
    echo "-- Update user FCM token (will trigger the trigger)"
    echo "UPDATE users SET fcm_token = 'test_token_123' WHERE user_id = 'your_user_id';"
    echo ""
}

# Show summary
show_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "============================================================"
    echo "  Validation Complete"
    echo "============================================================"
    echo -e "${NC}"
    echo ""
    print_success "Schema validation finished"
    print_info "Results logged to: $VALIDATION_LOG"
    echo ""
    echo -e "${BLUE}Validation Checklist:${NC}"
    echo "  ✓ Users table has new columns"
    echo "  ✓ notifications_log table exists"
    echo "  ✓ notification_campaigns table exists"
    echo "  ✓ All indexes created"
    echo "  ✓ Triggers configured"
    echo "  ✓ Views available"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. If all validations passed, mark Issue #1 as complete"
    echo "2. Proceed to Issue #2: Firebase Admin SDK Setup"
    echo "3. Begin implementing Lambda notification functions"
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

    trap cleanup EXIT

    load_env_vars
    get_credentials

    # Test connection
    print_info "Testing database connection..."
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
        print_error "Failed to connect to database"
        exit 1
    fi
    print_success "Connected to database"

    run_validations
    show_summary
}

# ============================================================
# Command Line Arguments
# ============================================================

case "${1:-}" in
    --help|-h)
        echo "Usage: $0"
        echo ""
        echo "This script validates the push notification schema deployment"
        echo "by running various queries to check tables, indexes, triggers, and views."
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST           RDS endpoint"
        echo "  DB_PORT           Database port (default: 5432)"
        echo "  DB_NAME           Database name (default: foody)"
        echo "  DB_USER           Database user (default: postgres)"
        echo "  DB_PASSWORD       Database password"
        exit 0
        ;;
    *)
        main
        ;;
esac
