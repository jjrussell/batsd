TJG.social = {
  setup: function(options){
    // local variables
    var animateSpeed = "fast";
    var inviteUrl = options.inviteUrl;
    var channel = options.channel;
    var advertiserAppId = options.advertiserAppId;

    // local functions
    var onWindowResize = function(event) {
      var viewportWidth = $(window).width();
      $('#friend_filter').attr('size',(viewportWidth-40)/8);
    };

    var submitEmailInvitation = function(rurl, recipients){
      sending();

      $.ajax({
        type: 'POST',
        url: rurl,
        cache: false,
        timeout: 35000,
        dataType: 'json',
        data: {
          recipients: recipients,
          advertiser_app_id: advertiserAppId
        },
        success: function(d) {
          var existDiv = '', notExistDiv = '';

          if(d.success) {
            if(d.gamers.length == 1) {
              existDiv = '<div class="dialog_content">' + d.gamers.toString().replace(/\,/g, ", ") + ' has already registered, you are now following him/her.</div>';
            }else if(d.gamers.length > 1) {
              existDiv = '<div class="dialog_content">' + d.gamers.toString().replace(/\,/g, ", ") + ' have already registered, you are now following them.</div>';
            }
            if(d.non_gamers.length != 0) {
              notExistDiv = '<div class="dialog_content">Tapjoy invites have been sent to '+d.non_gamers.toString().replace(/\,/g, ", ")+'</div>';
            }
            if(d.gamers.length == 0 && d.non_gamers.length == 0){
              var error = 'Please provide an email other than yourselves';
              showErrorDialog(error, TJG.ui.hideSender());
              return;
            }

            var msg = [
              '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Success!</div></div>',
              '<div style="margin: 5px;"></div>',
              existDiv,
              notExistDiv,
              '<div class="dialog_content"><div class="continue_invite"><div class="button grey dialog_button"  style="margin-bottom: 10px;">Continue</div></div></div>'
            ].join('');
            $('#social_dialog_content').parent().animate({}, animateSpeed);
            $('#social_dialog_content').html(msg);

            TJG.ui.hideSender();
            centerDialog($('#social_dialog').height(), '#social_dialog_content', '#social_dialog');

            $('.close_dialog, .continue_invite').click(function(){
              document.location.href = location.protocol + '//' + location.host + inviteUrl;
            });
          } else {
            showErrorDialog(d.error, TJG.ui.hideSender());
          }
        },
        error: function(d) {
          var error = 'There was an issue, please try again later';
          showErrorDialog(error, TJG.ui.hideSender());
        }
      });
    }; // submitEmailInvitation

    var loading = function(){
      $('.close_dialog').hide();
      TJG.ui.showLoaderAtCenter();
    };

    var sending = function(){
      $('.close_dialog').hide();
      TJG.ui.showSender();
    }

    var showErrorDialog = function(error, hideTransitionDialog) {
      var msg = [
        '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
        '<div class="dialog_content">', error, '. <span id="invite_again"><a href="#">Please click here to try again.</a></span><div style="margin: 5px;"></div></div>',
      ].join('');
      $('#social_dialog_content').parent().animate({}, animateSpeed);
      $('#social_dialog_content').html(msg);

      hideTransitionDialog;
      centerDialog($('#social_dialog').height(), '#social_dialog_content', '#social_dialog');

      $('#invite_again, .close_dialog').click(function(event){
        event.preventDefault();
        $('#social_dialog').fadeOut();
      });
    }; // showErrorDialog

    var centerDialog = function(height, dialog_content_selector, dialog_selector) {
      var scrollTop = $(window).scrollTop();
      var screenHeight = $(window).height();
      TJG.utils.centerDialog(dialog_selector);
      $(dialog_selector).fadeIn(350).css({ top: scrollTop + screenHeight / 2 - height / 2 });
    }; // centerDialog

    var sendInvite = function(event) {
      event.preventDefault();
      var url = $('form#invite_friends').attr('action');

      if(channel == 'EMAIL'){
        submitEmailInvitation(url, $('#recipients').val());
      }
    }; // sendInvite

    // bind events
    window.onresize = onWindowResize;

    $('#invite_button').click(function(event){
      sendInvite(event);
    });

    $('#back_button').click(function(event){
      document.location.href = location.protocol + '//' + location.host + inviteUrl;
    });

    $('#recipients').keypress(function(event){
        code= (event.keyCode ? event.keyCode : event.which);
        if (code == 13){
          $('#recipients').blur();
          sendInvite(event);
        }
    });

    // call functions
    onWindowResize();
  },

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
      }
    }, {scope: scope});
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
      if (response.authResponse) {
        var curLoginFbId = response.authResponse.userID;
        if(currentGamerFbId && curLoginFbId && currentGamerFbId != curLoginFbId){
          FB.logout(function(response) {
            TJG.social.postToFeed(link, pictureLink);
          });
        }
      } else {
        TJG.social.postToFeed(link, pictureLink);
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
      actions: [{ name: 'Join', link: link}],
      description: 'Check out Tapjoy where you can discover the best new apps and games, while also earning currency in apps you love. It\'s free to join so visit tapjoy.com today to start getting app recommendations just for you.'
    };

    function callback(response) {}

    FB.ui(obj, callback);
  },
};
