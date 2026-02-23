/**
 * ─────────────────────────────────────────────────────────────
 * Sevadaar — Promote User to Super Admin
 * ─────────────────────────────────────────────────────────────
 *
 * Usage:
 *   # Promote existing user (user must have signed up first)
 *   node promote_super_admin.js --email user@example.com
 *
 *   # Create new super admin directly (user doesn't need to exist)
 *   node promote_super_admin.js --email user@example.com --create
 *
 * Prerequisites:
 *   1. Place your Firebase Admin SDK service account JSON file
 *      in this directory as `serviceAccountKey.json`.
 *      (Download from Firebase Console → Project Settings → Service accounts)
 *
 *   2. Run `npm install` in this directory first.
 *
 * What it does:
 *   Mode 1 (--email only):
 *   - Finds the Firestore `users` doc where email matches.
 *   - Sets `role` to "super_admin".
 *   - Requires user to have signed up first.
 *
 *   Mode 2 (--email --create):
 *   - Creates a new super_admin user directly in Firestore.
 *   - User can sign in later with Google/email and link to this account.
 *   - No pre-signup required.
 */

const admin = require("firebase-admin");
const path = require("path");

// ── Parse CLI args ──────────────────────────────────────────────
const args = process.argv.slice(2);
const emailFlagIndex = args.indexOf("--email");

if (emailFlagIndex === -1 || !args[emailFlagIndex + 1]) {
  console.error("\n❌  Usage:");
  console.error("    node promote_super_admin.js --email user@example.com");
  console.error("    node promote_super_admin.js --email user@example.com --create\n");
  console.error("  --create flag: Creates the user directly without pre-signup\n");
  process.exit(1);
}

const targetEmail = args[emailFlagIndex + 1].trim().toLowerCase();

// ── Initialise Firebase Admin ───────────────────────────────────
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (err) {
  console.error("\n❌  Could not load serviceAccountKey.json");
  console.error("    Place your Firebase Admin SDK key in:", serviceAccountPath);
  console.error("    Download from: Firebase Console → Project Settings → Service accounts\n");
  process.exit(1);
}

const db = admin.firestore();

// ── Main ────────────────────────────────────────────────────────
async function promote() {
  console.log(`\n🔍  Searching for user with email: ${targetEmail} ...\n`);

  const snapshot = await db
    .collection("users")
    .where("email", "==", targetEmail)
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.error(`❌  No user found with email "${targetEmail}".`);
    console.error("    Make sure the user has signed up in the app first.\n");
    process.exit(1);
  }

  const userDoc = snapshot.docs[0];
  const userData = userDoc.data();

  console.log(`✅  Found user:`);
  console.log(`    Name  : ${userData.name}`);
  console.log(`    Email : ${userData.email}`);
  console.log(`    Role  : ${userData.role} → super_admin`);
  console.log(`    UID   : ${userDoc.id}\n`);

  await db.collection("users").doc(userDoc.id).update({
    role: "super_admin",
  });

  console.log(`🎉  Successfully promoted "${userData.name}" to Super Admin!\n`);
  console.log(`    Next steps:`);
  console.log(`    1. Email the user their login credentials.`);
  console.log(`    2. They can now log in and create NGOs from the app.\n`);

  process.exit(0);
}

// ── Alternative: Create super admin directly (if --create flag used) ────
async function createSuperAdmin() {
  console.log(`\n📝  Creating direct super admin account...\n`);
  console.log(`    Email: ${targetEmail}\n`);

  // Check if user already exists
  const existingSnapshot = await db
    .collection("users")
    .where("email", "==", targetEmail)
    .limit(1)
    .get();

  if (!existingSnapshot.empty) {
    console.log("   (User already exists, updating role)\n");
    const userDoc = existingSnapshot.docs[0];
    await db.collection("users").doc(userDoc.id).update({
      role: "super_admin",
    });
    console.log(`✅  User role updated to super_admin!\n`);
    console.log(`    UID: ${userDoc.id}\n`);
    process.exit(0);
  }

  // Create new super admin user
  const userRef = db.collection("users").doc();
  const newUser = {
    uid: userRef.id,
    email: targetEmail,
    name: targetEmail.split("@")[0], // Use email prefix as name
    role: "super_admin",
    status: "active",
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  await userRef.set(newUser);

  console.log(`✅  Super admin account created!\n`);
  console.log(`    Email : ${targetEmail}`);
  console.log(`    Name  : ${newUser.name}`);
  console.log(`    Role  : super_admin`);
  console.log(`    UID   : ${userRef.id}\n`);
  console.log(`    Next steps:`);
  console.log(`    1. User can now sign in with any social provider (Google, etc.)`);
  console.log(`    2. Their account will automatically link to this super_admin profile\n`);

  process.exit(0);
}

// Check if --create flag is used
const createFlagIndex = args.indexOf("--create");
const shouldCreate = createFlagIndex !== -1;

if (shouldCreate) {
  createSuperAdmin().catch((err) => {
    console.error("❌  Error:", err.message);
    process.exit(1);
  });
} else {
  promote().catch((err) => {
    console.error("❌  Error:", err.message);
    process.exit(1);
  });
}
