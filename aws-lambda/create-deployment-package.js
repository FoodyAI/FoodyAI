const fs = require('fs');
const archiver = require('archiver');
const path = require('path');

async function createDeploymentPackage() {
  console.log('📦 Creating deployment package for send-notification Lambda...\n');

  const output = fs.createWriteStream(path.join(__dirname, 'send-notification-deploy.zip'));
  const archive = archiver('zip', { zlib: { level: 9 } });

  return new Promise((resolve, reject) => {
    output.on('close', () => {
      const sizeMB = (archive.pointer() / 1024 / 1024).toFixed(2);
      console.log(`\n✅ Deployment package created: ${sizeMB} MB`);
      console.log(`   Total bytes: ${archive.pointer()}`);
      resolve();
    });

    archive.on('error', (err) => {
      reject(err);
    });

    archive.pipe(output);

    // Add function code
    console.log('Adding Lambda function code...');
    archive.file(path.join(__dirname, 'send-notification', 'index.js'), { name: 'index.js' });
    archive.file(path.join(__dirname, 'send-notification', 'package.json'), { name: 'package.json' });

    // Add shared dependencies
    console.log('Adding shared dependencies...');
    archive.file(path.join(__dirname, 'firebase-admin.js'), { name: 'firebase-admin.js' });
    archive.file(path.join(__dirname, 'notification-helpers.js'), { name: 'notification-helpers.js' });
    archive.file(path.join(__dirname, 'firebase-service-account.json'), { name: 'firebase-service-account.json' });

    // Add node_modules
    console.log('Adding node_modules (this may take a moment)...');
    archive.directory(path.join(__dirname, 'node_modules'), 'node_modules');

    console.log('Finalizing archive...');
    archive.finalize();
  });
}

createDeploymentPackage()
  .then(() => {
    console.log('\n✅ Deployment package ready: send-notification-deploy.zip');
    process.exit(0);
  })
  .catch((err) => {
    console.error('❌ Error creating deployment package:', err);
    process.exit(1);
  });
