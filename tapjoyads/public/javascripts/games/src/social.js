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
          var text = 'Invite';
          if (selectedFriends.length > 0) {
            var plural = selectedFriends.length > 1 ? 's' : '';
            text = 'Invite ' + selectedFriends.length + ' Friend' + plural;
          }
          $('#invite_button').text(text);
        });
      });
    }; // showFriendList

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
          var existDiv = '', notExistDiv = '';

          if(d.success) {
            if(d.gamers.length == 1) {
              existDiv = '<div class="dialog_content">' + d.gamers.toString().replace(/\,/g, ", ") + ' has already registered, you are now following him/her.</div>';
            }else if(d.gamers.length > 0) {
              existDiv = '<div class="dialog_content">' + d.gamers.toString().replace(/\,/g, ", ") + ' have already registered, you are now following them.</div>';
            }
            if(d.non_gamers.length != 0) {
              notExistDiv = '<div class="dialog_content">Tapjoy invites have been sent to '+d.non_gamers.toString().replace(/\,/g, ", ")+'</div>';
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

            TJG.ui.hideLoader();
            centerDialog($('#social_dialog').height(), '#social_dialog_content', '#social_dialog');

            $('.close_dialog, .continue_invite').click(function(){
              document.location.href = location.protocol + '//' + location.host + inviteUrl;
            });
          } else if(d.error_redirect) {
            window.setTimeout('location.reload()', 1000);
          } else {
            showErrorDialog(d.error, TJG.ui.hideLoader());
          }
        },
        error: function(d) {
          var error = 'There was an issue, please try again later';
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

      if(channel == 'FB'){
        if(selectedFriends.length == 0) {
          showErrorDialog('Please select at least one friend before sending out an invite', TJG.ui.hideLoader());
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
      document.location.href = location.protocol + '//' + location.host + inviteUrl;
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
};
