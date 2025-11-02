#!/usr/bin/env ts-node

import { execSync } from 'child_process';

const PROJECT_ID = 'event-marketplace-mvp';

const COLLECTIONS = [
  'users',
  'user_profiles',
  'specialists',
  'follows',
  'posts',
  'post_likes',
  'post_comments',
  'ideas',
  'idea_likes',
  'idea_comments',
  'stories',
  'requests',
  'chats',
  'messages',
  'notifications',
  'categories',
  'tariffs',
  'plans',
  'feed',
];

const STORAGE_PREFIXES = [
  'uploads/avatars',
  'uploads/posts',
  'uploads/reels',
  'uploads/ideas',
  'uploads/stories',
];

const deletedCounts: Record<string, number> = {};

function deleteCollection(collection: string): number {
  try {
    console.log(`Deleting collection: ${collection}...`);
    const output = execSync(
      `firebase firestore:delete --project ${PROJECT_ID} --recursive --force ${collection} 2>&1`,
      { encoding: 'utf-8', stdio: 'pipe' }
    );
    const match = output.match(/Deleted (\d+) documents?/i);
    return match ? parseInt(match[1]) : 0;
  } catch (error: any) {
    if (error.message.includes('not found') || error.message.includes('does not exist')) {
      return 0;
    }
    console.error(`Error deleting ${collection}: ${error.message}`);
    return 0;
  }
}

function deleteStoragePrefix(prefix: string): number {
  try {
    console.log(`Deleting storage prefix: ${prefix}...`);
    execSync(
      `firebase storage:delete --project ${PROJECT_ID} --force gs://${PROJECT_ID}.appspot.com/${prefix}/* 2>&1`,
      { encoding: 'utf-8', stdio: 'pipe' }
    );
    return 1;
  } catch (error: any) {
    const msg = error.message || error.toString();
    if (msg.includes('not found') || msg.includes('does not exist') || msg.includes('No such object')) {
      return 0;
    }
    console.error(`Error deleting ${prefix}: ${msg}`);
    return 0;
  }
}

console.log('Starting cleanup...\n');

let totalDocs = 0;
for (const collection of COLLECTIONS) {
  const count = deleteCollection(collection);
  deletedCounts[collection] = count;
  totalDocs += count;
}

let totalStorage = 0;
for (const prefix of STORAGE_PREFIXES) {
  const count = deleteStoragePrefix(prefix);
  totalStorage += count;
}

console.log('\n=== CLEANUP SUMMARY ===');
console.log(`Total documents deleted: ${totalDocs}`);
console.log(`Collections:`, deletedCounts);
console.log(`Storage prefixes deleted: ${totalStorage}`);
