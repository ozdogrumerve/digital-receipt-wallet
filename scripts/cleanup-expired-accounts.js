const admin = require("firebase-admin");

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

async function deleteUserData(uid) {
  const userRef = db.collection("users").doc(uid);

  // transactions + her transaction'ın altındaki products
  const transactionsSnap = await userRef.collection("transactions").get();

  for (const txDoc of transactionsSnap.docs) {
    const productsSnap = await txDoc.ref.collection("products").get();
    const productBatch = db.batch();
    productsSnap.docs.forEach((p) => productBatch.delete(p.ref));
    if (productsSnap.size > 0) await productBatch.commit();

    await txDoc.ref.delete();
  }

  // recurring
  const recurringSnap = await userRef.collection("recurring").get();
  const recurringBatch = db.batch();
  recurringSnap.docs.forEach((doc) => recurringBatch.delete(doc.ref));
  if (recurringSnap.size > 0) await recurringBatch.commit();

  // kullanıcı dokümanının kendisi
  await userRef.delete();
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