# ⚡ Quick Start Guide

## 🚀 **Get Started in 4 Steps**

### 1. Clone Repository
```bash
git clone https://github.com/mohammadaminrez/Foody.git
cd Foody
```

### 2. Run Setup
```bash
./setup-developer.sh
```

### 3. Configure AWS
```bash
aws configure
# Contact team lead for AWS credentials
```

### 4. Test Everything
```bash
# Test backend API
cd aws-lambda/test && ./test-api.sh

# Test database
cd aws-lambda && node database-manager.js users

# Run Flutter app
flutter run
```

## 🗄️ **Database Management**
```bash
cd aws-lambda

# Show all tables
node database-manager.js tables

# Show all users
node database-manager.js users

# Show all food analyses
node database-manager.js analyses

# Clear test data
node database-manager.js clear

# Add test data
node database-manager.js add-test

# Run custom SQL queries
node database-manager.js query "SELECT COUNT(*) FROM users"
node database-manager.js query "DELETE FROM food_analyses WHERE health_score < 50"
node database-manager.js query "UPDATE users SET daily_calories = 2000 WHERE age < 25"

# Get help
node database-manager.js help
```

## 🛡️ **Backup & Rollback System**

### **Create Backup Before Changes**
```bash
cd aws-lambda
./backup-stable.sh
```
This creates:
- 📸 RDS database snapshot
- 📦 Lambda function backups
- 💾 Source code backups
- 🔄 Rollback scripts

### **Safe Deployment Process**
```bash
# 1. Always backup first
./backup-stable.sh

# 2. Deploy your changes
# ... your deployment commands ...

# 3. If problems occur, rollback immediately
cd backups/stable-[timestamp] && ./rollback.sh
```

### **Rollback Options**
1. **Quick Fix (5 min)**: Lambda function rollback only
2. **Full Restore (15-30 min)**: Database + Lambda rollback
3. **Complete Recovery**: From RDS snapshots

### **Check Schema Version**
```bash
# View current database schema version
node database-manager.js query "SELECT * FROM schema_versions ORDER BY version;"

# Check if schema is at expected version
node database-manager.js query "SELECT check_schema_version(3);"
```

### **Emergency Rollback**
```bash
# If deployment fails, immediately run:
cd aws-lambda/backups/stable-[timestamp]
./rollback.sh

# This restores Lambda functions to last known working state
```

## 📞 **Need Help?**
- **AWS Credentials**: Contact team lead
- **Project Info**: See [GitHub Repository](https://github.com/mohammadaminrez/Foody.git)
- **Backup Issues**: Check `backups/` directory for rollback scripts