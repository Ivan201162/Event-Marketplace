#!/usr/bin/env node

/**
 * Production wipe script for Firestore and Storage
 * Usage: ts-node tools/wipe_production.ts
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';

const PROJECT_ID = 'event-marketplace-mvp';

// Initialize Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  './firebase-service-account.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Service account file not found:', serviceAccountPath);
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS env var or place firebase-service-account.json in root');
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: PROJECT_ID,
});

const db = admin.firestore();
const storage = admin.storage();

// Collections to wipe
const COLLECTIONS = [
  'users',
  'user_profiles',
  'specialists',
  'posts',
  'post_likes',
  'post_comments',
  'follows',
  'ideas',
  'idea_likes',
  'idea_comments',
  'stories',
  'requests',
  'chats',
  'messages',
  'notifications',
  'feed',
];

// Storage prefixes to wipe
const STORAGE_PREFIXES = [
  'uploads/avatars/',
  'uploads/posts/',
  'uploads/reels/',
  'uploads/ideas/',
  'uploads/stories/',
];

async function deleteCollection(collectionPath: string): Promise<number> {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.get();
  
  if (snapshot.empty) {
    return 0;
  }

  const batch = db.batch();
  let count = 0;

  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
    count++;
  });

  await batch.commit();

  // If more than 500 docs, recurse
  if (count === 500) {
    const nextCount = await deleteCollection(collectionPath);
    return count + nextCount;
  }

  return count;
}

async function deleteStoragePrefix(prefix: string): Promise<number> {
  const bucket = storage.bucket();
  const [files] = await bucket.getFiles({ prefix });
  
  let count = 0;
  for (const file of files) {
    await file.delete();
    count++;
  }

  return count;
}

async function main() {
  console.log('🧹 Starting production wipe...\n');

  let totalDeleted = 0;
  const results: Record<string, number> = {};

  // Wipe Firestore collections
  console.log('📦 Wiping Firestore collections...');
  for (const collection of COLLECTIONS) {
    try {
      const count = await deleteCollection(collection);
      results[collection] = count;
      totalDeleted += count;
      console.log(`  ${collection}: ${count} documents`);
    } catch (error: any) {
      console.error(`  ❌ ${collection}: ${error.message}`);
      results[collection] = -1; // Error marker
    }
  }

  // Wipe Storage prefixes
  console.log('\n📁 Wiping Storage prefixes...');
  for (const prefix of STORAGE_PREFIXES) {
    try {
      const count = await deleteStoragePrefix(prefix);
      results[`storage:${prefix}`] = count;
      totalDeleted += count;
      console.log(`  ${prefix}: ${count} files`);
    } catch (error: any) {
      console.error(`  ❌ ${prefix}: ${error.message}`);
      results[`storage:${prefix}`] = -1;
    }
  }

  console.log(`\n✅ Total deleted: ${totalDeleted}`);
  console.log('\n📊 Summary:');
  for (const [key, value] of Object.entries(results)) {
    if (value === -1) {
      console.log(`  ❌ ${key}: ERROR`);
    } else {
      console.log(`  ✅ ${key}: ${value}`);
    }
  }

  process.exit(0);
}

main().catch((error) => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});

