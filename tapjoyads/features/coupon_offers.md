# 'Coupon' offer

Author: Chris Nixon

If you have any issues with any parts of the testing feel free to ask my
any questions and I can help. Also, any suggestions for improvement I am
all ears!

https://trello.com/card/coupon-offers-13/5031a2f43e4a57b84cdf4a08/11

## Description
1. New offer type, coupon, for the offerwall.
2. New coupon instructions page, user will input their email address and
   review the coupon, currency being rewarded, etc.
3. New coupons complete page, shows the user successfully completed
   getting their coupon sent to their email.
4. New dashboard tools create coupons page. Account manager will
   generate coupons for a particular partner. They can also upload an
   icon, input a price or instructions.

### Test on Staging
1. For tapjoyserver, suggest use [Rogue](http://rogue.tapjoy.net) (or [Gambit](http://gambit.tapjoy.net))
2. Refer to Test 4, you must generate coupons for a partner first.
3. On Rogue: Go to tapjoyserver console, do OfferCacher.cache_offers(true)
4. On Rogue: Go to 'config/environments/development.rb' file, update urls to the follow:

API_URL = 'http://rogue.tapjoy.net'
API_URL_EXT = 'http://rogue.tapjoy.net'
DASHBOARD_URL = 'http://rogue.tapjoy.net'
WEBSITE_URL = 'http://rogue.tapjoy.net'

## Test Plan

### Test 1: Successfully complete a coupon offer and obtaining a voucher in the email
1. First, make sure coupons exists. Refer to Test 4.
2. Make sure you have cached offers. Go to tapjoyserver console, do OfferCacher.cache_offers(true).
3. Go to in-app offer wall or directly use, for example [offer wall webpage](http://rogue.tapjoy.net/get_offers/webpage?app_id=5e355f54-7353-4450-ad13-842692e1342d&udid=statz_test_udid&publisher_user_id=testuser&currency_id=5e355f54-7353-4450-ad13-842692e1342d&device_type=android).
4. Find a coupon offer and click on it, most start with 'Save 40%...' or 'Save 50$...'.
   It also has the '/click/coupon?data=' url when you hover over the link.
5. An instructions page whill show up.
6. Fill in the email field with a valid email and click 'Send Coupon' submit button.
   Make sure the email is valid so that you can check you receive the
   coupon.
7. A completion page will show up saying that you successfully created a
   coupon. Also has some fine print stating you must redeem the coupon
   before you can earn your currency.
8. If you go back to the offerwall, the coupon offer should no longer appear.
9. Check your email inbox that you used from step 6, in order to verify that a coupon was
   delivered to that email address.
10. The email should contain the coupon's advertiser, barcode for the coupon, coupon's description,
    coupon's name, redemption code, and a date for when the coupon expires.

### Test 2: Fail completing a coupon offer (invalid or blank email)
1. First, make sure coupons exists. Refer to Test 4.
2. Make sure you have cached offers. Go to tapjoyserver console, do OfferCacher.cache_offers(true).
3. Go to in-app offer wall or directly use, for example [offer wall webpage](http://rogue.tapjoy.net/get_offers/webpage?app_id=5e355f54-7353-4450-ad13-842692e1342d&udid=statz_test_udid&publisher_user_id=testuser&currency_id=5e355f54-7353-4450-ad13-842692e1342d&device_type=android).
4. Find a coupon offer and click on it, most start with 'Save 40%...' or 'Save 50$...'.
   It also has the '/click/coupon' url when you hover over the link.
5. An instructions page whill show up.
6. Fill in the email field with an invalid or blank email.
7. It redirects you back to the same page you were just on, and has a
   notification stating to 'Input a valid email address.'
8. Once you have inputted a valid email, refer to Test 1 #7.

### Test 3: Fail completing a coupon offer using the same device to request a coupon more than once.
1. First, make sure coupons exists. Refer to Test 4.
2. Make sure you have cached offers. Go to tapjoyserver console, do OfferCacher.cache_offers(true).
3. Go to in-app offer wall or directly use, for example [offer wall webpage](http://rogue.tapjoy.net/get_offers/webpage?app_id=5e355f54-7353-4450-ad13-842692e1342d&udid=statz_test_udid&publisher_user_id=testuser&currency_id=5e355f54-7353-4450-ad13-842692e1342d&device_type=android).
4. Find a coupon offer and click on it, most start with 'Save 40%...' or 'Save 50$...'.
   It also has the '/click/coupon?data=' url when you hover over the link.
5. An instructions page whill show up.
6. Fill in the email field with a valid email and click 'Send Coupon'submit button.
   Make sure the email is valid so that you can check you receive the
   coupon.
7. A completion page will show up saying that you successfully created a
   coupon. Also has some fine print stating you must redeem the coupon
   before you can earn your currency.
8. Click the back button in your browser to go back to the instructions
   page. Re-fill in the email address box, with the same or any other
   valid email address. When you click the 'Send Coupon' button it should
   redirect you back to the same page with a notice stating, 'Coupon has
   already been requested.'

### Test 4: Generate coupons for a partner for the first time (new coupons in adility) as account manager
1. Go to [partner page](http://rogue.tapjoy.net/dashboard/partners)
2. Select a partner (Zynga, Com2uS, etc.) and act as that partner.
3. On the same partner page i.e. for Zynga (http://rouge.tapjoy.net/dashboard/partners/64e40a83-4724-4ba4-9b38-1c8ca906777a)
   there should be a link 'Create Coupons'. Click that link.
4. There should be a new dashboard tools coupon page 
5. The page should have the Partner's name i.e. (Zynga), price field
   ('$0.00' as default), instructions text field, and an icon upload
   button. Only price is required to be filled out.
*Note: price will default to 0.00 if invalid params such as 'afafa' is
inputted for price.
6. Click the confirm button to generate coupons.
7. You should be redirected to i.e. for Zynga (http://rogue.tapjoy.net/dashboard/tools/coupons?partner_id=64e40a83-4724-
   4ba4-9b38-1c8ca906777a).
8. The page should contain a table of information about the coupons,
   it's type, the value, a link to the specific coupon, expiration date,
   and whether it contains a voucher.

### Test 5: Generate coupons for a partner, but all coupons from adility have already been obtained as account manager.
1. Go to [partner page](http://rogue.tapjoy.net/dashboard/partners)
2. Select a partner (Zynga, Com2uS, etc.) and act as that partner, make
   sure it is the same partner from Test 4.
3. On the same partner page i.e. for Zynga (http://rouge.tapjoy.net/dashboard/partners/64e40a83-4724-4ba4-9b38-1c8ca906777a)
   there should be a link 'Create Coupons'. Click that link.
4. There should be a new dashboard tools coupon page 
5. The page should have the Partner's name i.e. (Zynga), price field
   ('$0.00' as default), instructions text field, and an icon upload
   button. Only price is required to be filled out.
6. Click the confirm button to generate coupons.
7. You should be redirected to the page you were just on with a notice
   stating, 'All coupons have been retrieved at this time. View coupons
   here.'.
8. Click the link 'View coupons here.' and it will take you to i.e. for Zynga (http://rogue.tapjoy.net/dashboard/tools/
   coupons?partner_id=64e40a83-4724-4ba4-9b38-1c8ca906777a).
8. The page should contain a table of information about the coupons,
   it's type, the value, a link to the specific coupon, expiration date,
   and whether it contains a voucher.

### Test 6: Generate coupons for a partner, but not account manager
1. Go to [partner page](http://rogue.tapjoy.net/dashboard/partners).
2. Select a partner (Zynga, Com2uS, etc.).
3. Since you're not the account manager you should not see a link to
   'Create Coupons'.

### Test 7: Redeeming your voucher (point of sale, mainly adility)
This is to be determined, but works as follows:
1. Go to the advertiser store (physically or online, depends) and redeem
   the voucher sent to that email address from Test 1.
2. Adility will ping us back with the voucher's id that was used, and we will
   complete the conversion (reward the user their currency).
