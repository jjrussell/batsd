(function(TJG) {
  var _t = TJG.i18n.t;
  TJG.social = {
    setup: function(options){
      // local variables
      var currentPage = 1;
      var selectedFriends = [];
      var animateSpeed = "fast";
      var currentFilter = '';
      var hasNext = false;
      var pageSize = options.pageSize;
      var fbFriends = options.fbFriends;
      var inviteUrl = options.inviteUrl;
      var channel = options.channel;
      var advertiserAppId = options.advertiserAppId;

      // local functions
      var onWindowResize = function(event) {
        var viewportWidth = $(window).width();
        $('#friend_filter').attr('size',(viewportWidth-40)/8);
      };

      var resetDirectionButtons = function() {
        if (currentPage == 1) {
          $('#prev').parent().hide();
        } else {
          $('#prev').parent().show();
        }
        if (hasNext) {
          $('#next').show();
        } else {
          $('#next').hide();
        }
      }; // resetDirectionButtons

      var showFriendList = function() {
        $('.friend_list').fadeOut(animateSpeed, function() {
          hasNext = false;
          var text      = [],
            friends     = [],
            counter     = 0,
            counterMax  = currentPage * pageSize,
            counterMin  = counterMax - pageSize;
          var search = function(regex, text) {
            for (var i in fbFriends) {
              if (counter > counterMax) { break; }
              var friend = fbFriends[i];
              var included = $.inArray(friend, friends) != -1;
              var matched = regex ?
                friend.name.match(regex) :
                friend.name.toLowerCase().match(RegExp.escape(currentFilter));
              if (!included && matched) {
                counter++;
                if (counter > counterMin && counter < counterMax) {
                  friends.push(friend);
                }
              }
            }
          };

          // match first names
          var filter = RegExp.escape(currentFilter);
          search(new RegExp('^' + filter, 'i'));

          if (currentFilter != '') {
            // then other names
            search(new RegExp('\\b' + filter, 'i'));

            // then any part of any name
            search(false)
          }

          hasNext = counter >= counterMax;

          for (var i in friends) {
            var friend = friends[i];
            var liClass = '';
            if ($.inArray(friend.fb_id, selectedFriends) != -1) {
              liClass = ' checked';
            }
            text.push('<li class="fb_select',liClass,'" id="', friend.fb_id, '">');
            text.push('<img src="http://graph.facebook.com/', friend.fb_id, '/picture" width="50" height="50"/>');
            text.push('<span>', friend.name, '</span>');
            text.push('</li>');
          }

          // unregister events
          $('li.fb_select').unbind();
          $('.friend_list').html(text.join('')).fadeIn(animateSpeed);

          resetDirectionButtons();

          $('li.fb_select').click(function(){
            var li = $(this);
            var fbId = li.attr('id');
            var index = $.inArray(fbId, selectedFriends);
            var found = index != -1;

            if (found && li.hasClass('checked')) {
              li.removeClass('checked');
              selectedFriends.splice(index, 1);
            } else if (!found && !li.hasClass('checked')) {


              li.addClass('checked');
              selectedFriends.push(fbId);
            }
            var friend_count = selectedFriends.length;
            var text = _t('games.invite_friends', {count: friend_count}, {count: friend_count});
            $('#invite_button').text(text);
          });
        });
      }; // showFriendList

      var showSuccessMessage = function(gamers, non_gamers, hidingFunction) {
        var existDiv,
            notExistDiv,
            contentTmp = TJG.utils.sprintfTemplate('<div class="dialog_content">%s</div>'),
            successDiv = '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">'+_t('shared.success')+'</div></div>',
            continueDiv = '<div class="dialog_content"><div class="continue_invite"><div class="button grey dialog_button"  style="margin-bottom: 10px;">'+_t('shared.continue')+'</div></div></div>',
            msg;

        if(gamers.length != 0) {
          existDiv = contentTmp(_t("games.already_registered",
            { name: gamers.toString().replace(/\,/g, ", ") },
            { count: gamers.length }
          ));
        }
        if(non_gamers.length != 0) {
          notExistDiv = contentTmp(_t("games.invites_sent_to", 
            { name: non_gamers.toString().replace(/\,/g, ", ") },
            { count: non_gamers.length }
          ));
        }

        msg = [
          successDiv,
          '<div style="margin: 5px;"></div>',
          existDiv,
          notExistDiv,
          continueDiv
        ].join('');

        $('#social_dialog_content').parent().animate({}, animateSpeed);
        $('#social_dialog_content').html(msg);

        hidingFunction();
        centerDialog($('#social_dialog').height(), '#social_dialog_content', '#social_dialog');

        $('.close_dialog, .continue_invite').click(function(){
          document.location.href = inviteUrl;
        });
      };

      var submitFbInvitation = function(url) {
        loading();

        $.ajax({
          type: 'POST',
          url: url,
          cache: false,
          timeout: 35000,
          dataType: 'json',
          data: {
            friends: selectedFriends,
            ajax: true,
            advertiser_app_id: advertiserAppId
          },
          success: function(d) {
            var msg;

            if(d.success) {
              showSuccessMessage(d.gamers, d.non_gamers, TJG.ui.hideLoader);
            } else if(d.error_redirect) {
              window.setTimeout('location.reload()', 1000);
            } else {
              showErrorDialog(d.error, TJG.ui.hideLoader());
            }
          },
          error: function(d) {
            var error = _t('games.generic_issue');
            showErrorDialog(error, TJG.ui.hideLoader());
          }
        });
      }; // submitFbInvitation


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
            var msg;

            if(d.success) {
              if(d.gamers.length == 0 && d.non_gamers.length == 0){
                var error = _t('games.provide_other_email');
                showErrorDialog(error, TJG.ui.hideSender());
                return;
              }
              showSuccessMessage(d.gamers, d.non_gamers, TJG.ui.hideSender);
            } else {
              showErrorDialog(d.error, TJG.ui.hideSender());
            }
          },
          error: function(d) {
            var error = _t('games.generic_issue');
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
          '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">'+_t('games.oops')+'</div></div>',
          '<div class="dialog_content">', error, '. <span id="invite_again"><a href="#">'+_t('games.click_to_try_again')+'</a></span><div style="margin: 5px;"></div></div>',
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

        if(channel == 'FB'){
          if(selectedFriends.length == 0) {
            showErrorDialog(_t('games.select_friend'), TJG.ui.hideLoader());
          } else {
            submitFbInvitation(url);
          }
        }else if(channel == 'EMAIL'){
          submitEmailInvitation(url, $('#recipients').val());
        }
      }; // sendInvite

      // bind events
      window.onresize = onWindowResize;

      $('#prev').click(function(event){
        event.preventDefault();
        if(currentPage > 1) {
          currentPage--;
          showFriendList();
        }
      });

      $('#next').click(function(event){
        event.preventDefault();
        if(hasNext) {
          currentPage++;
          showFriendList();
        }
      });

      $('#top').click(function(event){
        event.preventDefault();
        $('html, body').animate({ scrollTop: 0 }, animateSpeed);
      });

      $('.clear_search_button').click(function(event){
        $('#friend_filter').val('');
        currentFilter = '';
        showFriendList();
      });

      $('#invite_button').click(function(event){
        sendInvite(event);
      });

      $('#back_button').click(function(event){
        document.location.href = inviteUrl;
      });

      $('#friend_filter').bind('input', function(event){
        var newFilter = $(this).val().toLowerCase().replace(/^ +/,'').replace(/ +$/,'');
        if(currentFilter != newFilter){
          currentFilter = newFilter;
          currentPage = 1;
          showFriendList();
        }
      });

      $('#recipients').keypress(function(event){
          code= (event.keyCode ? event.keyCode : event.which);
          if (code == 13){
            $('#recipients').blur();
            sendInvite(event);
          }
      });

      // call functions
      showFriendList();
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
  };
}(TJG));
