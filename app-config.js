// I've come to realise that it is okay to commit this file.
//
// The apiKey isn't so secret after all, apparently; the contents here is used for identification,
// rather than protection. Actual data is protected using database rules.

var firebaseConfig = {
  apiKey: "AIzaSyD14UAtvaDw6uCc0_nDHa8-US13kNJGWOI",
  authDomain: "ahlgroceries.firebaseapp.com",
  databaseURL: "https://ahlgroceries.firebaseio.com",
  projectId: "ahlgroceries",
  storageBucket: "ahlgroceries.appspot.com",
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
