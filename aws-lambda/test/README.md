# Foody AWS Testing Tools

Clean, organized testing utilities for debugging and verifying the AWS infrastructure.

## 📁 Files

### 1. **check-database.js**
Tests connection to RDS PostgreSQL and displays database contents.

**Usage:**
```bash
cd aws-lambda/test
npm install
node check-database.js
```

**What it shows:**
- Database connection status
- List of tables
- User count and recent users
- Food analysis count and recent analyses

---

### 2. **test-api.sh**
Tests all API Gateway endpoints with sample data.

**Usage:**
```bash
cd aws-lambda/test
chmod +x test-api.sh
./test-api.sh
```

**Requirements:**
- `curl` command
- `jq` for JSON formatting (optional but recommended)

**Tests performed:**
1. Create user profile (POST /users)
2. Get user profile (GET /users/{userId})
3. Save food analysis (POST /food-analysis)
4. Get non-existent user (404 error test)

---

### 3. **test-lambda-local.js**
Tests Lambda functions locally without deploying to AWS.

**Usage:**
```bash
cd aws-lambda/test
node test-lambda-local.js
```

**Tests performed:**
- User profile creation
- User profile retrieval
- Food analysis creation

---

## 🚀 Quick Start

### Install dependencies:
```bash
cd aws-lambda/test
npm install
```

### Run all tests:
```bash
npm run test:all
```

### Run individual tests:
```bash
# Test database connection
npm run test:db

# Test API endpoints
npm run test:api

# Test Lambda functions locally
npm run test:lambda
```

---

## 🔧 Configuration

All tests are pre-configured with your AWS resources:
- **API Base URL:** `https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod`
- **Database:** `foody-database.cgfko2mcweuv.us-east-1.rds.amazonaws.com`
- **Region:** `us-east-1`

If you change any AWS resources, update the configuration in the test files.

---

## 📊 Expected Output

### ✅ Successful Test Output:
```
✅ Connected to database successfully!
📋 Tables: food_analyses, users
👥 Total users: 5
🍎 Total food analyses: 12
```

### ❌ Common Issues:

**Database Connection Error:**
- Check if RDS instance is publicly accessible
- Verify security group allows your IP
- Confirm database credentials

**API 403 Error:**
- Lambda integration not configured
- Missing Lambda permissions
- API Gateway not deployed

**API 500 Error:**
- Lambda function error (check CloudWatch logs)
- Database connection issue from Lambda
- Missing environment variables

---

## 💡 Tips

1. **Always test locally first** (`test-lambda-local.js`) before testing API
2. **Check database after API tests** to verify data was saved
3. **Use CloudWatch Logs** for debugging Lambda errors:
   ```bash
   aws logs tail /aws/lambda/foody-user-profile --follow
   aws logs tail /aws/lambda/foody-food-analysis --follow
   ```

---

## 🔒 Security Note

These test files contain database credentials and are for **development/testing only**.
- Do not commit sensitive credentials to version control
- Use environment variables in production
- Consider using AWS Secrets Manager for production credentials

