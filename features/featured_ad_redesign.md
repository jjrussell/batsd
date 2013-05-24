# Featured Ad Redesign Dashboard Functionality

Author: Jon Klein

# Description
Allow for redesigned featured ad units
Adds additional offer attributes used for rendering featured ad units
Allow for dashboard configuration of redesigned featured ad contents


## Test Plan

Due to the number of pages on which offers can be edited, the test cases are somewhat complex.  A number of independent behaviors are described below: each page is listed along with the behaviors it is expected to exhibit.

### Test 1: Rewarded/Non-Rewarded Featured Installs -- /dashboard/apps/xxx/offers/xxx/edit
1. Page behaves as described in Behavior 2: offer is always featured
2. Page behaves as described in Behavior 3: featured ad creative is saved correctly
3. Page behaves as described in Behavior 4: offer can be previewed
4. Page behaves as described in Behavior 5: user can upload custom creatives

### Test 2: Pay Per Action -- /dashboard/apps/xxx/action_offers/xxx/edit
### Test 3: Partners "Edit Video Offer" -- /dashboard/tools/video_offers/xxx/edit 
### Test 4: Partners "Edit Generic Offer" -- /dashboard/tools/generic_offers/xxx/edit
1. Page behaves as described in Behavior 1: offer can toggle featured on/off
2. Page behaves as described in Behavior 3: featured ad creative is saved correctly
3. Page behaves as described in Behavior 4: offer can be previewed
4. Page behaves as described in Behavior 5: user can upload custom creatives

### Test 5: Partners "Create Generic Offer" -- /dashboard/tools/generic_offers/new 
### Test 6: Partners "Create Video Offer" -- /dashboard/tools/video_offers/new
1. Page behaves as described in Behavior 1: offer can toggle featured on/off
2. Page behaves as described in Behavior 3: featured ad creative is saved correctly
3. Offer CANNOT be previewed until it is saved
4. Offer CANNOT upload custom creatives until it is saved

### Test 7: Partners "Statz" Offer Edit -- /dashboard/statz/xxx/edit
1. Page behaves as described in Behavior 1: offer can toggle featured on/off
2. Page behaves as described in Behavior 3: featured ad creative is saved correctly
3. Offer MUST BE SAVE to show correct creative upload sizes after "feature" is toggled (existing behavior)




### Behavior 1: offer can be toggled featured/non-featured 
1. There is a "Featured" checkbox which can be toggled on and off
2. When toggled on, there are fields and a pattern selector for configuring the Featured Ad creative

### Behavior 2: offer is always featured
1. There is no "Featured" checkbox -- the offer is always featured
2. There are fields and a pattern selector for configuring the Featured Ad creative

### Behavior 3: featured ad creative is saved correctly
1. All featured ad fields (offer action, offer content and offer background) can be edited and saved
2. When returning to the offer after saving, all fields contain the correctly updated values

### Behavior 4: offer can be previewed
1. There should be a "Preview Featured Offer" row in the editing page
2. Select a preview size from the popup menu

### Behavior 5: user can upload custom creatives
1. There are custom creative upload fields at the bottom of the page
2. User can select 