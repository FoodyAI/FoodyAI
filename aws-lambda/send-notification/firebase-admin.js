// firebase-admin.js
// Firebase Admin SDK Initialization Module
// This module handles Firebase Admin SDK initialization with support for
// both service account file and environment variables

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let firebaseApp = null;

/**
 * Initialize Firebase Admin SDK
 * Supports two initialization methods:
 * 1. Using service account JSON file (local development)
 * 2. Using environment variables (production/AWS Lambda)
 *
 * @returns {admin.app.App} Firebase Admin app instance
 * @throws {Error} If Firebase configuration is not found or initialization fails
 */
function initializeFirebase() {
  // Check if already initialized
  if (firebaseApp) {
    console.log('Firebase Admin SDK already initialized');
    return firebaseApp;
  }

  try {
    console.log('Initializing Firebase Admin SDK...');

    // Method 1: Initialize with service account file (local development)
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

    if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      console.log('Using service account file for initialization');
      const serviceAccount = require(path.resolve(serviceAccountPath));

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });

      console.log(`✓ Firebase Admin SDK initialized successfully`);
      console.log(`  Project ID: ${serviceAccount.project_id}`);
      return firebaseApp;
    }

    // Method 2: Initialize with environment variables (production/AWS Lambda)
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    if (projectId && privateKey && clientEmail) {
      console.log('Using environment variables for initialization');

      // Replace escaped newlines in private key
      const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: projectId,
          privateKey: formattedPrivateKey,
          clientEmail: clientEmail
        }),
        projectId: projectId
      });

      console.log(`✓ Firebase Admin SDK initialized successfully`);
      console.log(`  Project ID: ${projectId}`);
      return firebaseApp;
    }

    // If neither method is configured
    throw new Error(
      'Firebase configuration not found. Please set either:\n' +
      '1. FIREBASE_SERVICE_ACCOUNT_PATH environment variable pointing to service account JSON, or\n' +
      '2. FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL environment variables'
    );

  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error.message);
    throw error;
  }
}

/**
 * Get Firebase Admin instance (initializes if not already done)
 *
 * @returns {admin.app.App} Firebase Admin app instance
 */
function getFirebaseAdmin() {
  if (!firebaseApp) {
    initializeFirebase();
  }
  return admin;
}

/**
 * Get Firebase Messaging instance
 *
 * @returns {admin.messaging.Messaging} Firebase Messaging instance
 */
function getMessaging() {
  const adminInstance = getFirebaseAdmin();
  return adminInstance.messaging();
}

/**
 * Reset Firebase initialization (mainly for testing)
 * Deletes the current Firebase app instance
 */
async function resetFirebase() {
  if (firebaseApp) {
    await firebaseApp.delete();
    firebaseApp = null;
    console.log('Firebase Admin SDK reset');
  }
}

module.exports = {
  initializeFirebase,
  getFirebaseAdmin,
  getMessaging,
  resetFirebase
};
