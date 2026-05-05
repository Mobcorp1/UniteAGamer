const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

exports.sendTradingNotificationPush = onDocumentCreated(
  'trading_notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const targetUid = data.targetUid;
    if (!targetUid) return;

    const tokensSnap = await admin
      .firestore()
      .collection('users')
      .doc(targetUid)
      .collection('notification_tokens')
      .get();

    const tokens = tokensSnap.docs
      .map((doc) => doc.id || doc.data().token)
      .filter(Boolean);

    if (!tokens.length) return;

    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: data.title || 'UAG Traders Hub',
        body: data.body || 'You have a new trading update.',
      },
      data: {
        type: String(data.type || ''),
        listingId: String(data.listingId || ''),
        offerId: String(data.offerId || ''),
        sessionId: String(data.sessionId || ''),
        notificationId: snap.id,
      },
      tokens,
    });

    const batch = admin.firestore().batch();
    response.responses.forEach((result, index) => {
      if (!result.success) {
        const code = result.error && result.error.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          batch.delete(
            admin
              .firestore()
              .collection('users')
              .doc(targetUid)
              .collection('notification_tokens')
              .doc(tokens[index])
          );
        }
      }
    });

    await batch.commit();
  }
);
