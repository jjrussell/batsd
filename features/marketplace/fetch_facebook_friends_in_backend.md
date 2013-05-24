# Fetch Facebook friends in backend

Author: Jia Feng

## Description
Fetch current gamer's facebook friends if he connect his FB account to TJM, and save it to MC.
Not being hooked up with any existing page, will be used for showing Facebook friends page later.

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2865/files

## Test Plan

### Test 1: Fetch friend for the first time with valid fb_access_token
1. Go to SocialUtils::Facebook.friends_for(current_gamer), add ```Rails.cache.delete("facebook_friends.#{gamer.id}")```, so that the fetch friend logic will always be executed. Don't forget to restart server.
2. Login TJM
3. Make sure current gamer connected his FB account
4. Add ```Rails.logger.info(SocialUtils::Facebook.friends_for(current_gamer).inspect)``` to any controller#action, say social_controller#invites
5. Access the page that will send request to social_controller#invites
6. Check the log, see if there's correct response, the response is an array, each element structured like this:
```
          {
            :id            => fb_friend_id,
            :name          => fb_friend_name,
            :is_tjm_gamer  => true/false, # indicate if this friend has already joined TJM
            :is_tjm_friend => true/false # indicate if this friend also current gamer's TJM friend
          }
```

### Test 2: Fetch friend for the first time without fb_access_token
1. Go to SocialUtils::Facebook.friends_for(current_gamer), add ```Rails.cache.delete("facebook_friends.#{gamer.id}")```, so that the fetch friend logic will always be executed. Don't forget to restart server.
2. Login TJM
3. Make sure current gamer does not connect any FB account
4. Add ```Rails.logger.info(SocialUtils::Facebook.friends_for(current_gamer).inspect)``` to any controller#action, say social_controller#invites
5. Access the page that will send request to social_controller#invites
6. An error will be raised, with 'There was an issue. Please try again.' as error message.

### Test 3: Fetch friend for the first time with invalide fb_access_token
1. Go to SocialUtils::Facebook.friends_for(current_gamer), add ```Rails.cache.delete("facebook_friends.#{gamer.id}")```, so that the fetch friend logic will always be executed. Don't forget to restart server.
2. Login TJM
3. Make sure current gamer connected his FB account and grant permissions
4. Go to Facebook account App settings page (https://www.facebook.com/settings?tab=applications), find the app and remove it:
   If under development environment, the App name is 'Tapjoy Dev';
   If under staging environment, the App name is 'Tapjoy Staging';
   If under production environment, the App name is 'Tapjoy'
5. Add ```Rails.logger.info(SocialUtils::Facebook.friends_for(current_gamer).inspect)``` to any controller#action, say social_controller#invites
6. Access the page that will send request to social_controller#invites
7. An error will be raised, with 'There was an issue. Please try again.' as error message.

### Test 4: Fetch friend for the second time before the MC expire
1. Finish Test 1
2. Remove ```Rails.cache.delete("facebook_friends.#{gamer.id}")``` from games_controller#friends_for if it's there. Don't forget to restart server.
3. Revisit social_controller#invites
4. Response with the same set of result as Test 1, and the response time will be much shorter than Test 1
