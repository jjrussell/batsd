# Partner search

Author: James Denton

[Trello card](https://trello.com/card/4-4-bug-fix-agency-user-data/502c19a52a04ef9b5d811fbb/146)  
[Pull request](https://github.com/Tapjoy/tapjoyserver/pull/3915)

## Description
1. Partner search allows filtering by multiple parameters.
2. Long lists of partners are paginated.
3. Search is available on all lists of partners, unless the current user has agency permissions.

## Test Plan

### Test 1: Agency user
1. Log in as a user with the agency permission, but not admin or account manager permissions.
2. Make sure that the [partners](http://localhost:8080/dashboard/partners) page loads. Only partners the user is associated with should be visible. No search box or drop-down filters should be visible. The list should be paginated if there are more than twenty partners.

### Test 2: Admin or account manager. No search terms.
1. Log in as a user with admin or account manager permissions.
2. Visit the partners page. All partners should be visible. A search box and dropdown filters should be visible.
3. Visit an agency user page. Only partners associated with the user should be visible. The search and filters should be visible.

### Test 3: Search for partners which do not have an account manager
1. Log in as a user with admin or account manager permissions.
2. Visit the partners page.
3. Change the 'Managed by' dropdown to 'not assigned' and click 'Search'
4. Everything in the 'Account Manager' column should read '(no one)'

### Test 4: Search for partners which have an account manager
1. Log in as a user with admin or account manager permissions.
2. Visit the partners page.
3. Change the 'Managed by' dropdown to an active account manager and click 'Search'
4. All partners the account manager is associated with should be visible.

### Test 5: Search by country
1. Log in as a user with admin or account manager permissions.
2. Visit the partners page.
3. Filter by Japan and click 'Search'.
4. Results from Japan should appear.
5. Filter by a country unlikely to return any results. At the time of writing, this is Antarctica. Click 'Search'.
6. A single row reading 'No partners found' should appear.

### Test 6: Search while filtering by all fields
1. Log in as a user with admin or account manager permissions.
2. Visit the partners page.
3. Put stuff in the country, partner, and account manager name/email fields.
4. Click 'Search'.
5. You may see results, or a 'No partners found' message. Things should not crash.

