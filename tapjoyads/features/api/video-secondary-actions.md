# Secondary Actions for Videos

Author: James Logsdon (Backend), Kieren Boyle (UI)

## Description

Add support for rewarded secondary actions after users view video offers and
bring the style inline with current branding.

* Git Issue: https://github.com/Tapjoy/tapjoyserver/pull/2859

## Test Plan

### Test 1: Create a non-rewarded Secondary Action button

Background: User is an Account Manager

1. User edits a Video Offer
2. User clicks "View/Edit Video Button"
3. User clicks "[Add Button]"
4. User should manually enter a "Name" and "Ordinal" value.
5. User should select an "Item"  from the list presented.
6. User should leave the "Rewarded" checkbox unchecked and the "Enabled" checkbox checked.
7. User clicks "Create Video Button"
8. The user should be redirected to the Video Button list, and the new button should be visible with the values entered.

### Test 2: Create a rewarded Secondary Action button

Background: User is an Account Manager

1. User edits a Video Offer
2. User clicks "View/Edit Video Button"
3. User clicks "[Add Button]"
4. User should manually enter a "Name" and "Ordinal" value.
5. User should select an App "Item" marked for "Android", "Windows" or "All" platforms from the list presented.
6. User should check the "Rewarded" and "Enabled" checkboxes
7. User clicks "Create Video Button"
8. The user should be redirected to the Video Button list, and the new button should be visible with the values entered.

### Test 3: Verify Rewarded actions display the reward on Android

Background: User is a Consumer on an Android Client Device

1. User selects Video Offer from Offerwall
2. After video completes, User should see a Rewarded PPI (App Install) action with a reward value.
3. User clicks rewarded action
4. User should receive the reward

### Test 4: Verify Rewarded actions display the reward on Windows

Background: User is a Consumer on an Windows Client Device

1. User selects Video Offer from Offerwall
2. After video completes, User should see a Rewarded PPI (App Install) action with a reward value.
3. User clicks rewarded action
4. User should receive the reward

### Test 5: Verify Rewarded actions do not display on iOS

Background: User is a Consumer on an iOS Client Device

1. User selects Video Offer from Offerwall
2. After video completes, User should _not_ see a Rewarded PPI (App Install) action.

### Test 6: Actions may only exist on one Video Button per Video Offer

Background: User is an Account Manager
            Video Offer has Video Buttons created

1. User edits the Video Offer
2. User clicks "View/Edit Video Button"
3. User clicks "[Add Button]"
4. Actions assigned to the Background Video Buttons should not be available to select in the Item list.

### Test 7: Actions may exist simultaneously on two Video Offers

Background: User is an Account Manager
            Video Offer has Video Buttons created
            A Second Video Offer has no Video Buttons created

1. User edits the Second Video Offer
2. User clicks "View/Edit Video Button"
3. User clicks "[Add Button]"
4. All Actions should appear in the Item list.
