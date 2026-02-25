/**
 * Sevadaar — Create Developer Admin
 *
 * Usage:
 *   node create_developer_admin.js --email k@gmail.com --password 123456
 *
 * Prerequisites:
 *   1. Place your Firebase Admin SDK service account JSON file
 *      in this directory as `serviceAccountKey.json`.
 *   2. Run `npm install` in this directory first.
 */

const admin = require("firebase-admin");
const path = require("path");

// ── Parse CLI args ──────────────────────────────────────────────
const args = process.argv.slice(2);

function getArg(flag) {
  const idx = args.indexOf(flag);
  return idx !== -1 && args[idx + 1] ? args[idx + 1].trim() : null;
}

const email = getArg("--email");
const password = getArg("--password");

if (!email || !password) {
  console.error("\n❌  Usage:");
  console.error(
    "    node create_developer_admin.js --email user@example.com --password yourpassword\n"
  );
  process.exit(1);
}

// ── Initialise Firebase Admin ───────────────────────────────────
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (err) {
  console.error("\n❌  Could not load serviceAccountKey.json");
  console.error(
    "    Place your Firebase Admin SDK key in:",
    serviceAccountPath
  );
  process.exit(1);
}

const db = admin.firestore();

// ── Main ────────────────────────────────────────────────────────
async function createDeveloperAdmin() {
  console.log(`\n📝  Creating developer admin account...`);
  console.log(`    Email   : ${email}`);
  console.log(`    Password: ${"*".repeat(password.length)}\n`);

  // 1. Check if a Firestore user doc already exists for this email
  const existingSnap = await db
    .collection("users")
    .where("email", "==", email)
    .limit(1)
    .get();

  if (!existingSnap.empty) {
    const doc = existingSnap.docs[0];
    const data = doc.data();
    if (data.role === "developer_admin") {
      console.log(`⚠️   User already exists as developer_admin (UID: ${doc.id})\n`);
      process.exit(0);
    }
    // Update existing user to developer_admin
    await db.collection("users").doc(doc.id).update({ role: "developer_admin" });
    console.log(`✅  Existing user promoted to developer_admin (UID: ${doc.id})\n`);
    process.exit(0);
  }

  // 2. Create Firebase Auth user
  let authUser;
  try {
    authUser = await admin.auth().getUserByEmail(email);
    console.log(`    Auth user already exists (UID: ${authUser.uid}), updating password.`);
    // Ensure email/password sign-in works by updating the password
    await admin.auth().updateUser(authUser.uid, { password: password });
    console.log(`    Password updated successfully.`);
  } catch (e) {
    if (e.code === "auth/user-not-found") {
      authUser = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: email.split("@")[0],
      });
      console.log(`    Auth user created (UID: ${authUser.uid}).`);
    } else {
      throw e;
    }
  }

  // 3. Create Firestore user doc
  const now = admin.firestore.Timestamp.now();
  const userDoc = {
    uid: authUser.uid,
    name: email.split("@")[0],
    email: email,
    role: "developer_admin",
    status: "active",
    fcmToken: "",
    orgId: null,
    ngoId: null,
    ngoRequestStatus: "none",
    createdAt: now,
  };

  await db.collection("users").doc(authUser.uid).set(userDoc);

  console.log(`\n🎉  Developer admin created successfully!\n`);
  console.log(`    Email : ${email}`);
  console.log(`    Role  : developer_admin`);
  console.log(`    UID   : ${authUser.uid}\n`);
  console.log(`    The user can now sign in with email/password in the app.\n`);

  process.exit(0);
}

createDeveloperAdmin().catch((err) => {
  console.error("❌  Error:", err.message);
  process.exit(1);
});
