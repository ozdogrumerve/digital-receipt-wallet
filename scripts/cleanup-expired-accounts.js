const admin = require("firebase-admin");

// GitHub Actions'tan env variable olarak gelecek
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

async function deleteUserData(uid) {
  // Alt koleksiyonları sil (örn. receipts)
  const receiptsSnap = await db
    .collection("users")
    .doc(uid)
    .collection("receipts")
    .get();

  const batch = db.batch();
  receiptsSnap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  // Kullanıcı dokümanını sil
  await db.collection("users").doc(uid).delete();
}

async function run() {
  const now = Date.now();

  const snapshot = await db
    .collection("users")
    .where("isDeleted", "==", true)
    .get();

  console.log(`Pasif hesap sayısı: ${snapshot.size}`);

  let deletedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const deletedAt = data.deletedAt?.toDate?.();

    if (!deletedAt) continue;

    const elapsed = now - deletedAt.getTime();

    if (elapsed >= THIRTY_DAYS_MS) {
      const uid = doc.id;
      console.log(`Siliniyor: ${uid} (${Math.floor(elapsed / 86400000)} gün geçmiş)`);

      try {
        await deleteUserData(uid);
        await auth.deleteUser(uid);
        deletedCount++;
      } catch (err) {
        console.error(`Hata (${uid}):`, err.message);
      }
    }
  }

  console.log(`Toplam silinen hesap: ${deletedCount}`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Script hatası:", err);
    process.exit(1);
  });