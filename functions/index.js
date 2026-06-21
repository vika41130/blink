const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const nodemailer = require("nodemailer");

initializeApp();

const emailUser = defineSecret("EMAIL_USER");
const emailPass = defineSecret("EMAIL_PASS");

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

exports.sendVerificationEmail = onDocumentUpdated(
  {
    document: "users/{userId}",
    secrets: [emailUser, emailPass],
  },
  async (event) => {
    if (!event.data) return;
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only trigger when verificationCode is newly set
    if (
      !after.verificationCode ||
      !after.pendingEmail ||
      before.verificationCode === after.verificationCode
    ) {
      return;
    }

    const email = after.pendingEmail;
    const code = after.verificationCode;

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: emailUser.value(),
        pass: emailPass.value(),
      },
    });

    const mailOptions = {
      from: `"Vapor" <${emailUser.value()}>`,
      to: email,
      subject: "Vapor email verification",
      html: `
        <div style="background-color: #000000; color: #FFFFFF; font-family: monospace; text-align: center; padding: 32px;">
          <h3>Your verification code:</h3>
          <h1>${code}</h1>
          <p>Vapor team</p>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`Verification email sent to ${email}`);
    } catch (error) {
      console.error("Error sending email:", error);
    }
  }
);
