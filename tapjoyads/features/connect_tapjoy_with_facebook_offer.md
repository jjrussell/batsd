# 'Connect to Tapjoy with Facebook' offer

Author: Jia Feng

## Description
1. New instruction page for 'Connect to Tapjoy with Facebook' offer
2. Update retargeting reject method
3. Add action to create/match TJM account in TJM 
4. Add offer complete popup on 'earn' page

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2971/files

Note: there's an one-off

## Test Plan

### Test 1: Earn rewards by complete 'Connect to Tapjoy with Facebook'
1. Make sure the device doesn't has app '609f5b88-80a9-48a7-ac98-d2a304bf9952' or 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
2. Go to offer wall, click the 'Connect to Tapjoy with Facebook' offer
2. An instruction page for this offer will show up
3. Click the button, do Facebook login and grant permissions
4. Page will redirect to the earn page, with a popup saying how many rewards you've earned
5. Go back to offer wall, both offers ('609f5b88-80a9-48a7-ac98-d2a304bf9952' and 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03') should disappear

### Test 2: Reject 'Connect to Tapjoy with Facebook' offer on offer wall correctly
1. Go to dashboard/tools/offer_lists, provide the udid of your device, set offer source to 'offerwall'
2. Check if the device has app '609f5b88-80a9-48a7-ac98-d2a304bf9952' or 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
3. If none of them exist, these two offer should be shown in the list without rejection reasons
4. If any of them exist, these two offer should be rejected because of 'Tapjoy games retargeting'
