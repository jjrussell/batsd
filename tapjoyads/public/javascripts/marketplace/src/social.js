(function(TJG) {
  var _t = window.i18n.t;
  TJG.social = {
    doFbLogin : function(connect_acct_path){
      var scope = 'offline_access,publish_stream';
      FB.login(function(response, scope) {
        if (response.authResponse) {
          FB.api('/me', function(response) {
            <!--
            window.location = connect_acct_path;
            //-->
          });
        } else {
          showError(_t('games.grant_us_access'));
        }
      }, {scope: scope});

      var showError = function(error){
        var msg = [
          '<div id="flash_error" class="dialog_wrapper hide" style="top: 179px; left: 533px; display: block;">',
          '<div class="close_dialog">',
          '<div class="close_button"></div>',
          '</div>',
          '<div class="dialog">',
          '<div class="dialog_content">',
          '<div class="error">', error ,'</div>',
          '</div></div></div>',
        ].join('');
        $('body').append(msg);

        $(".close_button").click(function(event) {
          $("#flash_error").fadeOut();
          $("#flash_error").remove();
        });
      };
    },

    doFbLogout : function(){
      FB.getLoginStatus(function(response) {
        if (response.authResponse) {
          FB.logout(function(response) {
          });
        }
      });
    },

    checkAndPost : function(currentGamerFbId, link, pictureLink) {
      FB.getLoginStatus(function(response) {
        var postToFeed = function() { TJG.social.postToFeed(link, pictureLink); };
        var currentLoginFbId = response.authResponse && response.authResponse.userID;
        if (currentLoginFbId && currentGamerFbId && currentGamerFbId != currentLoginFbId) {
          FB.logout(postToFeed);
        } else {
          postToFeed();
        }
      });
    },

    postToFeed : function(link, pictureLink) {
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
    },
  };
}(TJG));
