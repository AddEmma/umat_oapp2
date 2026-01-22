const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Set global options for all functions (e.g., region)
setGlobalOptions({ region: "us-central1" });

/**
 * Cloud Function that triggers when a new announcement is created.
 * Sends a push notification to all users and SMS to all registered phone numbers.
 */
exports.sendAnnouncementNotification = onDocumentCreated("announcements/{announcementId}", async (event) => {
    const announcement = event.data.data();
    const announcementId = event.params.announcementId;

    const title = announcement.title || "New Announcement";
    const body = announcement.body || "";
    const senderName = announcement.senderName || "Admin";

    // 1. Send Push Notification via FCM Topic
    const fcmMessage = {
        notification: {
            title: title,
            body: body,
        },
        android: {
            priority: "high",
            notification: {
                channelId: "announcements",
                priority: "high",
                defaultSound: true,
                defaultVibrateTimings: true,
            },
        },
        apns: {
            payload: {
                aps: {
                    contentAvailable: true,
                    sound: "default",
                    badge: 1,
                },
            },
        },
        data: {
            type: "announcement",
            announcementId: announcementId,
            senderName: senderName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        topic: "announcements",
    };

    try {
        await admin.messaging().send(fcmMessage);
        console.log("Push notification sent to announcements topic.");
    } catch (error) {
        console.error("Error sending push notification:", error);
    }

    // 2. Fetch all users with phone numbers and send SMS
    // Note: You need a Twilio account for this to work.
    const TWILIO_ACCOUNT_SID = ''; // Add your Twilio SID
    const TWILIO_AUTH_TOKEN = ''; // Add your Twilio Token
    const TWILIO_FROM_NUMBER = ''; // Add your Twilio Number

    if (TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN) {
        const client = require('twilio')(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

        try {
            const usersSnapshot = await admin.firestore().collection('users').get();
            const smsPromises = [];

            usersSnapshot.forEach(doc => {
                const userData = doc.data();
                if (userData.phoneNumber) {
                    smsPromises.push(
                        client.messages.create({
                            body: `[UMAT Announcement] ${title}: ${body}`,
                            from: TWILIO_FROM_NUMBER,
                            to: userData.phoneNumber
                        }).catch(err => console.error(`Failed SMS to ${userData.phoneNumber}:`, err))
                    );
                }
            });

            await Promise.all(smsPromises);
            console.log(`Sent SMS notifications to ${smsPromises.length} users.`);
        } catch (error) {
            console.error("Error sending SMS notifications:", error);
        }
    } else {
        console.log("SMS sending skipped: Twilio credentials not provided.");
    }

    return null;
});
