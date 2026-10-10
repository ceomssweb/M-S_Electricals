// Firebase Messaging Service Worker for M&S Electricals Web
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDummyKeyForServiceWorker12345",
  authDomain: "mselectricals-4cc75.firebaseapp.com",
  projectId: "mselectricals-4cc75",
  storageBucket: "mselectricals-4cc75.appspot.com",
  messagingSenderId: "337897639107",
  appId: "1:337897639107:web:25d7f5a4e291b9928c2676"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification?.title || 'M&S Electricals';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new update.',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
