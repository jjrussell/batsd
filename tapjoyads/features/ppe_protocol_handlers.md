# PPE Protocol Handlers

Author: Chris Nixon

## Description
1. For all PPE offers with the app's protocol handler available, a
   button will be available for the user to click to open up the app
   from that protocol handler. The button will only appear if the
   protocol handler is available.
2. On iOS, if using the Chrome browser the button to open up an app with
   a protocol handler will never show up. Therefore, be sure to be using Safari for testing,
   other than just checking that the button doesn't appear in Chrome.
3. On the dashbaord/apps/some_app_id page, when updating an app's
   protocol handler, you must have a valid protocol handler (i.e.
   "fb://" (facebook) <\any non-whitespace\>://<\any non-whitespace\>)

### Test on Staging
1. For tapjoyserver, use [Rogue](http://rogue.tapjoy.net)
2. You must find a PPE offer with a protocol handler present for that
   app, in order for the test to work properly.

## Test Plan

### Test 1: With an iOS device and Safari browser: A PPE offer with a protocol handler present, and the app
### associated with the protocol handler is on the device
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, which contains a button in
   the bottom middle of the screen, stating "Go to 'some app name'".
3. If you click the button the application should open on the device.
4. When you come back (re-open the browser) it should still be on the
   offer instructions page, however the page will refresh.

### Test 2: With an android device: A PPE offer with a protocol handler present, and the app
### associated with the protocol handler is on the device
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, which contains a button in
   the bottom middle of the screen, stating "Go to 'some app name'".
3. If you click the button the application should open on the device.
4. When you come back (re-open the browser) it should still be on the
   offer instructions page, and nothing should happen.

### Test 3: With an iOS device and Safari browser: A PPE offer with a protocol handler present, but the app
### associated with the protocol handler is not on the device.
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, which contains a button in
   the bottom middle of the screen, stating "Go to 'some app name'".
3. If you click the button there should be a pop-up message (iOS based),
   stating 'Cannot open page'. However, whether or not you click the
   'OK' button in the pop-up the page should re-direct to an 'App Not
   Installed' page.
4. The app not installed page should contain a message stating the user
   did not have the app installed, and they must install the app to
   complete the offer.

### Test 4: With an android device: A PPE offer with a protocol handler present, but the app
### associated with the protocol handler is not on the device.
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, which contains a button in
   the bottom middle of the screen, stating "Go to 'some app name'".
3. If you click the button the Google Play store will open and direct
   you to the app to install. 
4. When you come back to the browser it should still be on the offer
   instructions page.

### Test 5: With an iOS device and Safari browser: A PPE offer with no protocol
### handler present.
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, but there should be no
   button on the screen from tests 1-4.
3. There should be a link with text saying, "If you don't have this app
   click here to download it." The 'here' part of the text should be the
   link.
4. If you click the link it should direct you to some action page as
   specified by the publisher.

### Test 6: With an android device: A PPE offer with no protocol handler
### present.
1. Click on a PPE offer form the offerwall or featured ad.
2. The offer instructions page should load, but there should be no
   button on the screen from tests 1-4. 
3. There should be a link with text saying, "If you don't have this app
   click here to download it." The 'here' part of the text should be the
   link.
4. If you click the link it should direct you to some action page as
   specified by the publisher.
