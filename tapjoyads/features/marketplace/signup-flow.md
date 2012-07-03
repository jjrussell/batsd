# Marketplace Signup Flow

Author: Michael Wheeler


## Description
New users can create their account through facebook or by manually entering information. They will be guided through this process by a changing UI.

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2844/files

## Test Plan

### Test 1: Normal signup flow

1. User visits /games/gamer/new
2. Click on any of the form fields
3. The form should center itself, and the facebook button should be hidden.
4. If the form in invalid, the forward arrow should be inactive.
5. Enter valid details.
6. When valid credentials are entered, the forward arrow will become active.
7a. Desktop - will be logged in with their new credentials.
7b. IOS/Android - will be shown a 'Connect your device' link appropriate for their platform


### Test 2: Normal signup flow, bad info

1. Do steps 1-4 of Test 1.
2. Enter invalid credentials: 
  email: fake 
  password: bad
3. Click the forward button.
4. There should be an error message displayed. The error will be shown with the signup form focused.


### Test 3: Facebook signup

1. User visits /games/gamer/new
2. Click 'Sign up with facebook'
3. There will be a popup to allow Facebook credentials to be entered.
4. Enter facebook credentials for existing user.
5a. Desktop - The page should be refreshed and you will be logged in
5b. IOS/Android - will be shown a 'Connect your device' link appropriate for their platform


### Test 4: Facebook signup error

1. User visits /games/gamer/new
2. Click 'Sign up with facebook'
3. There will be a popup to allow Facebook credentials to be entered.
4. Close the popup without entering credentials
5. The page should show an error, and you will be able to try to log in again.
