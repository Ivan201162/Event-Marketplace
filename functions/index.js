/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest, onCall} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");
const cors = require("cors")({origin: true});

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// VK OAuth configuration
const VK_CLIENT_ID = process.env.VK_CLIENT_ID || 'YOUR_VK_APP_ID';
const VK_CLIENT_SECRET = process.env.VK_CLIENT_SECRET || 'YOUR_VK_APP_SECRET';
const VK_REDIRECT_URI = process.env.VK_REDIRECT_URI || 'http://localhost:8080/vk-callback';

// VK Custom Token function
exports.vkCustomToken = onCall(async (data, context) => {
  try {
    logger.info('VK Custom Token request received', {structuredData: true});
    
    const {code} = data;
    if (!code) {
      throw new Error('VK authorization code is required');
    }

    // Exchange code for access token
    const tokenResponse = await axios.get('https://oauth.vk.com/access_token', {
      params: {
        client_id: VK_CLIENT_ID,
        client_secret: VK_CLIENT_SECRET,
        redirect_uri: VK_REDIRECT_URI,
        code: code,
      },
    });

    const {access_token, user_id, email} = tokenResponse.data;
    
    if (!access_token || !user_id) {
      throw new Error('Failed to get VK access token');
    }

    // Get user profile from VK
    const profileResponse = await axios.get('https://api.vk.com/method/users.get', {
      params: {
        access_token: access_token,
        user_ids: user_id,
        fields: 'photo_200,first_name,last_name',
        v: '5.199',
      },
    });

    const vkUser = profileResponse.data.response[0];
    if (!vkUser) {
      throw new Error('Failed to get VK user profile');
    }

    // Create or update user in Firestore
    const vkUid = `vk_${user_id}`;
    const userRef = admin.firestore().collection('users').doc(vkUid);
    
    const userData = {
      id: vkUid,
      email: email || `${user_id}@vk.com`,
      displayName: `${vkUser.first_name} ${vkUser.last_name}`,
      photoURL: vkUser.photo_200,
      role: 'customer',
      socialProvider: 'vk',
      socialId: user_id.toString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await userRef.set(userData, {merge: true});

    // Create Firebase custom token
    const customToken = await admin.auth().createCustomToken(vkUid, {
      provider: 'vk',
      vk_id: user_id,
    });

    logger.info('VK Custom Token created successfully', {
      vkUid,
      vkUserId: user_id,
      structuredData: true,
    });

    return {
      firebaseCustomToken: customToken,
      user: userData,
    };
  } catch (error) {
    logger.error('VK Custom Token error', error, {structuredData: true});
    throw new Error(`VK authentication failed: ${error.message}`);
  }
});

// CORS-enabled VK callback handler
exports.vkCallback = onRequest((request, response) => {
  return cors(request, response, async () => {
    try {
      const {code, error} = request.query;
      
      if (error) {
        logger.error('VK OAuth error', {error, structuredData: true});
        response.status(400).send(`VK OAuth error: ${error}`);
        return;
      }

      if (!code) {
        response.status(400).send('VK authorization code is required');
        return;
      }

      // Redirect back to the app with the code
      const redirectUrl = `http://localhost:8080/vk-callback?code=${code}`;
      response.redirect(redirectUrl);
    } catch (error) {
      logger.error('VK callback error', error, {structuredData: true});
      response.status(500).send('Internal server error');
    }
  });
});

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
