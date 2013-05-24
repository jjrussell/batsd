# Marketplace Login Flow

Author: Michael Wheeler


## Description
When logging in, the user can choose to log in through Facebook or else username/password. The flow will guide them through the process.

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2844/files

## Test Plan

### Test 1: Normal login flow

1. User visits the games homepage
2. Click 'Log In'
3. Click on the email or password. 
4. The login form should center itself, and the facebook button should be hidden.
5. If the form in invalid, the forward arrow should be inactive.
6. Enter valid credentials.
7. When valid credentials are entered, the forward arrow will become active.
8. You should be logged in.


### Test 2: Normal login, bad creds

1. Do steps 1-5 of Test 1.
2. Enter invalid credentials: 
  email: fake 
  password: bad
3. Click the forward button.
4. There should be an error message displayed. The error will be shown with the login form focused.


### Test 3: Facebook login

1. User visits the games homepage
2. Click 'Log In'
3. Click 'Log in with facebook'
4. There will be a popup to allow Facebook credentials to be entered.
5. Enter facebook credentials for existing user.
6. The page should be refreshed and you will be logged in

### Test 4: Facebook error

1. User visits the games homepage
2. Click 'Log In'
3. Click 'Log in with facebook'
4. There will be a popup to allow Facebook credentials to be entered.
5. Close the popup without entering credentials
6. The page should show an error, and you will be able to try to log in again.

### Test 5: Facebook login - new user
1. User visits the games homepage
2. Click 'Log In'
3. Click 'Log in with facebook'
4. There will be a popup to allow Facebook credentials to be entered.
5. Enter facebook credentials for non-existing user.
6. You will be logged in as a brand new user.
6a. On IOS - you will see a 'Connect your device' screen after login.
6a. On Android - you will see a 'Connect your device' screen after login.
