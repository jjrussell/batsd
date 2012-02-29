(function ($) {
  "use strict";

  $(function () {
    var doFbLogin, doFbLogout, FB = window.FB;

    doFbLogin = function () {
      var scope = 'offline_access,publish_stream',
        $$ = $(this);

      FB.login(function (response, scope) {
        if (response.authResponse) {
          FB.api('/me', function (response) {
            window.location = $$.data("fb-url");
          });
        } else {
          Tapjoy.Utils.notification({
            message: _t('games.grant_us_access')
          });
        }
      }, {scope: scope});
    };

    doFbLogout = function () {
      FB.getLoginStatus(function (response) {
        if (response.authResponse) {
          FB.logout(function (response) {
          });
        }
      });
    };

    $(".login-to-facebook").click(function () {
      doFbLogin();
    });

    if (window.location.search.match(/fb_logout/)) {
      doFbLogout();
    }
  });
}(jQuery));
