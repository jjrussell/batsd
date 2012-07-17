# 'Connect to Tapjoy with Facebook' offer

Author: Jia Feng

## Description
1. New instruction page for 'Connect to Tapjoy with Facebook' offer (In tapjoyserver repo)
2. Update retargeting reject method (In tapjoyserver repo)
3. Add action to create/match TJM account in TJM (In tapjoymarketplace repo)
4. Add offer complete popup on 'earn' page (In tapjoymarketplace repo)

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2971/files
* Git Issue: https://github.com/Tapjoy/tapjoymarketplace/pull/95/files

Note:
(1) There's an one-off
(2) Don't forget to update generic offer's (609f5b88-80a9-48a7-ac98-d2a304bf9952) destination url form '/gamers/earn/TJM_EID?data=DATA' to '/earn/TJM_EID?data=DATA', since we set the tjm routes slightly different now.

## Test Environment Setup
### Test on Local
1. Go to https://developers.facebook.com/apps/281461335227331, change the site url to 'http://tapjoy.local' and set App Domains to 'tapjoy.local'
2. Go to '/etc/hosts' add 'tapjoy.local' to the list
3. Go to 'config/local.yml' file in both tapjoyserver project and tapjoymarketplace project, set it as follow:

```
api_url: http://tapjoy.local:4000
dashboard_url: http://tapjoy.local:4000
website_url: http://tapjoy.local:3000
api_url_ext: http://tapjoy.local:4000
clear_memcache: true
```
4. Start tapjoyserver server with port 4000
5. Start tapjoymarketplace server with port 3000

### Test on Staging
1. For tapjoyserver, suggest use http://rogue.tapjoy.net or http://gambit.tapjoy.net
2. For TJM, use http://kitty.tapjoy.net
3. On Facebook: Go to https://developers.facebook.com/apps/374261032627026, change the site url to http://kitty.tapjoy.net and set App Domains to 'tapjoy.net'
4. On Rogue: Go to 'config/environments/development.rb' file, update urls to the follow:

```
API_URL = 'http://rogue.tapjoy.net'
API_URL_EXT = 'http://rogue.tapjoy.net'
DASHBOARD_URL = 'http://rogue.tapjoy.net'
WEBSITE_URL = 'http://kitty.tapjoy.net'
```

5. On Rogue: Go to 'config/facebooker.yml' file, update api_id and secret for development env to the follow:

```
development:
  app_id: '374261032627026'
  secret: 'b8daf301cd6cf2cb8ea0d3eadb4109b1'
  api_key: '374261032627026'
  oauth2: true
```

6. On Rogue: Enable ['Connect to Tapjoy with Facebook' offer](http://rogue.tapjoy.net/dashboard/statz/609f5b88-80a9-48a7-ac98-d2a304bf9952), set a large rank boost, update the its trigger action to 'Facebook Login' and change the destination url to be '/earn/TJM_EID?data=DATA'
7. On Rogue: Go to tapjoyserver console, do OfferCacher.cache_offers(true)
8. On Kitty, Go to 'config/environments/staging.rb' file, update urls to the follow:

```
API_URL = 'http://rogue.tapjoy.net'
API_URL_EXT = 'http://rogue.tapjoy.net'
DASHBOARD_URL = 'http://rogue.tapjoy.net/dashboard'
WEBSITE_URL = 'http://kitty.tapjoy.net'
```

## Test Plan

### Test 1: Earn rewards by complete 'Connect to Tapjoy with Facebook'
1. Make sure the device doesn't has app '609f5b88-80a9-48a7-ac98-d2a304bf9952' or 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
2. Go to in-app offer wall or directly use [offer wall xml](http://rogue.tapjoy.net/get_offers?app_id=30091aa4-9ff3-4717-a467-c83d83f98d6d&udid=c1bd5bd17e35e00b828c605b6ae6bf283d9bafa1&publisher_user_id=testuser&currency_id=30091aa4-9ff3-4717-a467-c83d83f98d6d&device_type=iphone)
3. Click the 'Connect to Tapjoy with Facebook' offer on offer wall
4. An instruction page for this offer will show up
5. Click the button, do Facebook login and grant permissions
6. Page will redirect to the earn page, with a popup saying how many rewards you've earned
7. Go back to offer wall, both offers ('609f5b88-80a9-48a7-ac98-d2a304bf9952' and 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03') should disappear

### Test 2: Reject 'Connect to Tapjoy with Facebook' offer on offer wall correctly
1. Go to dashboard/tools/offer_lists, provide the udid of your device, set offer source to 'offerwall'
2. Check if the device has app '609f5b88-80a9-48a7-ac98-d2a304bf9952' or 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
3. If none of them exist, these two offer should be shown in the list without rejection reasons
4. If any of them exist, these two offer should be rejected because of 'Tapjoy games retargeting'
