const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendChatNotification = onDocumentCreated(
  "chats/{chatRoomId}/messages/{messageId}",
  async (event) => {
    if (!event.data) return;
    const message = event.data.data();
    if (!message) return;

    const chatRoomId = event.params.chatRoomId;
    const senderId = message.senderId;
    const messageText = message.text;
    if (!senderId || !messageText) return;

    const ids = chatRoomId.split("_");
    const receiverId = ids.find((id) => id !== senderId);
    if (!receiverId) return;

    const receiverDoc = await getFirestore()
      .collection("users")
      .doc(receiverId)
      .get();

    if (!receiverDoc.exists) return;
    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return;

    const senderDoc = await getFirestore()
      .collection("users")
      .doc(senderId)
      .get();

    const senderName = senderDoc.exists
      ? senderDoc.data().username
      : "Someone";

    await getMessaging().send({
      token: fcmToken,
      notification: {
        title: senderName,
        body: messageText,
      },
      data: {
        senderId: senderId,
        receiverId: receiverId,
        senderName: senderName,
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "chat_messages",
        },
      },
    });
  }
);
