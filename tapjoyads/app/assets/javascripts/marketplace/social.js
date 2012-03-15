(function (Tap, $) {
  "use strict";
  var _t = window.i18n.t,
    FB = window.FB;
  Tap.extend({
    Social: {
      doFbLogin: function (redirect_url) {
        FB.login(function (response) {
          if (response.authResponse) {
            FB.api('/me', function (response) {
              window.location = redirect_url;
            });
          } else {
            Tap.Utils.notification({
              message: _t('games.grant_us_access')
            });
          }
        }, {scope: 'offline_access,publish_stream'});
      },

      doFbLogout: function () {
        FB.getLoginStatus(function (response) {
          if (response.authResponse) {
            FB.logout(function (response) {
            });
          }
        });
      },

      checkAndPost: function (currentGamerFbId, link, pictureLink) {
        FB.getLoginStatus(function (response) {
          var postToFeed = function () { Tap.Social.postToFeed(link, pictureLink); },
              currentLoginFbId = response.authResponse && response.authResponse.userID;
          if (currentLoginFbId && currentGamerFbId && currentGamerFbId !== currentLoginFbId) {
            FB.logout(postToFeed);
          } else {
            postToFeed();
          }
        });
      },

      postToFeed: function (link, pictureLink) {
        var obj = {
          method: 'feed',
          display: 'popup',
          name: 'Tapjoy',
          link: link,
          picture: pictureLink,
          caption: ' ',
          actions: [{ name: _t('shared.join'), link: link}],
          description: _t('games.post_to_facebook_content')
        };

        FB.ui(obj);
      }
    }
  });


  $(function () {
    if (!FB) { return; }

    $(".login-to-facebook").click(function () {
      var url = $(this).data("fb-url");
      Tap.Social.doFbLogin(url);
      return false;
    });

    if (window.location.search.match(/fb_logout/)) {
      Tap.Social.doFbLogout();
    }

    $(".post-to-facebook").click(function () {
      var $$ = $(this),
          icon = $$.data("icon"),
          callback = $$.data("callback"),
          facebookId = $$.data("fb-id"),
          res;

      res = facebookId ? Tap.Social.checkAndPost(facebookId, callback, icon) : Tap.Social.postToFeed(callback, icon);
      return false;
    });
  });
}(window.Tapjoy, window.jQuery));
