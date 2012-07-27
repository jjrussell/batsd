# Support for Multiple Android App Stores

Authors: Norman Chan, Jeremy Chotiner, James Huang


## Description
Allow an Android app to have multiple distributions on different app stores.  For now, support Google Play and China's GFan.

* Google Doc: https://docs.google.com/a/tapjoy.com/document/d/1FdsrRU7Sdcz-GCM5r3_DPWGul1lBWjnDwsqQNB8rGjc/edit

## Test Plan

### Prerequisite

1. Add 'Android Distribution Config' role to user to allow access to multi-app store functionality in dashboard.

### Test 1: Add a new app from GFan

1. Click on Apps Tab, then Add App button
2. Choose Live for App State, Android for Platform, and GFan (China) for Market
3. Enter a search term, and click Search GFan button
4. Select desired app
5. Click Add App button
6. App should be created and selected in the app dropdown list at top of page
7. Click on Rewarded Installs
8. Primary offer should be created, with name of App as Offer Name

### Test 2: Add a new distribution from GFan to Google Play app

1. Click on Apps Tab
2. Choose an Android/Google Play app that is live from dropdown
3. Click on Distributions link in Left Nav Bar
4. Choose GFan (China) for Market
5. Enter a search term and click Search GFan button
6. Select desired app
7. Click Add Distribution button
8. Distribution details are displayed
9. Click on Rewarded Installs
10. Primary offer should be created, with name of App (from store) as Offer Name

### Test 3: Update GFan app

1. Choose a GFan distribution
2. Click Update from GFan
3. "Notice: Distribution was successfully updated." should be displayed

### Test 4: Remove secondary distribution

1. Choose an Android app with two distributions
2. Click on Distributions link in Left Nav Bar
3. In the table of distributions, secondary distribution has a "Remove" link under Action column
4. Click Remove
5. Distribution should be removed

### Test 5: Show offerwall from GFan app

1. Make sure there are at least two active GFan distributions
2. Choose one distribution to be the publisher app, make sure its currency is enabled
3. The other GFan distributions will be advertisers, make sure their primary offers are Tapjoy and user enabled
4. Run `OfferCacher.cache_offers(true)` in rails console
5. Go to statz page for GFan publisher app
6. Click on "View Offerwall" link under Currency section to view offerwall
7. Add extra parameter to indicate app store source: `&store_name=gfan`
8. Only generic offers and GFan store offers should appear.  No Google Play offers should be visible.

