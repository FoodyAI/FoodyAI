#!/bin/bash

# Backup Stable Version Script
# Run this NOW to backup your current working state

echo "🛡️ Creating backup of stable version..."

# Create timestamp for backup names
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# 1. Create RDS Snapshot
echo "📸 Creating RDS snapshot..."
aws rds create-db-snapshot \
  --db-instance-identifier foody-database \
  --db-snapshot-identifier "foody-stable-backup-$TIMESTAMP" \
  --region us-east-1

echo "✅ RDS snapshot created: foody-stable-backup-$TIMESTAMP"

# 2. Backup Lambda functions
echo "📦 Backing up Lambda functions..."

# Create backup directory
mkdir -p backups/stable-$TIMESTAMP

# Download current Lambda code
echo "📥 Downloading food-analysis Lambda..."
aws lambda get-function \
  --function-name foody-food-analysis \
  --query 'Code.Location' \
  --output text | xargs curl -o "backups/stable-$TIMESTAMP/food-analysis-stable.zip"

echo "📥 Downloading user-profile Lambda..."
aws lambda get-function \
  --function-name foody-user-profile \
  --query 'Code.Location' \
  --output text | xargs curl -o "backups/stable-$TIMESTAMP/user-profile-stable.zip"

# 3. Backup current source code
echo "💾 Backing up source code..."
cp -r food-analysis "backups/stable-$TIMESTAMP/"
cp -r user-profile "backups/stable-$TIMESTAMP/"

# 4. Create rollback script
cat > "backups/stable-$TIMESTAMP/rollback.sh" << 'EOF'
#!/bin/bash
echo "🔄 Rolling back to stable version..."

# Rollback Lambda functions
aws lambda update-function-code \
  --function-name foody-food-analysis \
  --zip-file fileb://food-analysis-stable.zip

aws lambda update-function-code \
  --function-name foody-user-profile \
  --zip-file fileb://user-profile-stable.zip

echo "✅ Rollback completed!"
EOF

chmod +x "backups/stable-$TIMESTAMP/rollback.sh"

echo "✅ Backup completed in backups/stable-$TIMESTAMP/"
echo "📋 To rollback: cd backups/stable-$TIMESTAMP && ./rollback.sh"
