const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const serviceAccount = require("./service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

exports.onNewChatMessage = functions.firestore
  .document("chats/{chatRoomId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    if (!message) return;

    const chatRoomId = context.params.chatRoomId;
    const senderId = message.senderId;
    const messageText = message.text || "📷 Photo";
    if (!senderId) return;

    console.log(`New message from ${senderId} in ${chatRoomId}: ${messageText}`);

    const ids = chatRoomId.split("_");
    const receiverId = ids.find((id) => id !== senderId);
    if (!receiverId) {
      console.log("No receiverId found");
      return;
    }

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) {
      console.log(`Receiver ${receiverId} not found`);
      return;
    }

    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`No FCM token for ${receiverId}`);
      return;
    }

    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().username
      : "Someone";

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body: "message",
        },
        data: {
          senderId: senderId,
          receiverId: receiverId,
          senderName: senderName,
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
        android: {
          priority: "high",
        },
      });
      console.log(`FCM push sent to ${receiverId} (${senderName}: ${messageText})`);
    } catch (error) {
      console.error(`Failed to send push: ${error.message}`);
    }
  });

exports.sendVerificationEmail = functions
  .runWith({ secrets: ["EMAIL_USER", "EMAIL_PASS"] })
  .firestore.document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (
      !after.verificationCode ||
      !after.pendingEmail ||
      before.verificationCode === after.verificationCode
    ) {
      return;
    }

    const email = after.pendingEmail;
    const code = after.verificationCode;
    const username = after.username || "";

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const mailOptions = {
      from: `"Vapor" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Vapor email verification",
      html: `
        <div style="background-color: #000000; color: #FFFFFF; font-family: monospace; text-align: center; padding: 32px;">
          <h3>Your verification code:</h3>
          <h1>${code}</h1>
          <h5>Your username: ${username}</h5>
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
  });
