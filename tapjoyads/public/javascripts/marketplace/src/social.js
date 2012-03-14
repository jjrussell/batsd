(function (Tap, $) {
  "use strict";
  var _t = window.i18n.t,
    FB = window.FB,
    twitterOptions = window.twitterOptions;

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
      },

      initSocialPage: function(options){
        // local variables
        var currentPage = 1;
        var selectedFriends = [];
        var animateSpeed = "fast";
        var currentFilter = '';
        var hasNext = false;
        var pageSize = options.pageSize;
        var socialFriends = options.socialFriends;

        // local functions
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

        RegExp.escape = function(text, callee) {
          if (!callee.sRE) {
            var specials = [
              '/', '.', '*', '+', '?', '|',
              '(', ')', '[', ']', '{', '}', '\\'
            ];
            callee.sRE = new RegExp(
              '(\\' + specials.join('|\\') + ')', 'g'
            );
          }
          return text.replace(callee.sRE, '\\$1');
        };

        var showFriendList = function() {
          $('.friend_list').fadeOut(animateSpeed, function() {
            hasNext = false;
            var text      = [],
              friends     = [],
              counter     = 0,
              counterMax  = currentPage * pageSize,
              counterMin  = counterMax - pageSize;

            var search = function(regex, text) {
              for (var i in socialFriends) {
                if (counter > counterMax) { break; }
                var friend = socialFriends[i];
                var included = $.inArray(friend, friends) != -1;
                var matched = regex ?
                  friend.name.match(regex) :
                  friend.name.toLowerCase().match(RegExp.escape(currentFilter, $(this)));
                if (!included && matched) {
                  counter++;
                  if (counter > counterMin && counter <= counterMax) {
                    friends.push(friend);
                  }
                }
              }
            };

            // match first names
            var filter = RegExp.escape(currentFilter, $('.friend_list'));
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

              text.push('<li class="friend clearfix list-button soft-gray-gradient" id="', friend.social_id, '">');
              text.push('<div class="left list-squircle"><img src="', friend.image_url, '" width="50" height="50"/></div>');
              text.push('<div class="left bold mt20 ml10">', friend.name, '</div>');
              if ($.inArray(friend.social_id.toString(), selectedFriends) != -1) {
                text.push('<div class="item-check plussign right mt20 mr10">&nbsp;</div>');
              }
              else if (friend.sent == true) {
                text.push('<div class="item-check plussign right mt20 mr10 hidden">&nbsp;</div>');
                text.push('<div class="item-sent right mt20 mr10">', _t('shared.sent'), '</div>');
              }
              else {
                text.push('<div class="item-check plussign right mt20 mr10 hidden">&nbsp;</div>');
              }
              text.push('</li>');
            }

            // unregister events
            $('li.friend').unbind();
            $('.friend_list').html(text.join('')).fadeIn(animateSpeed);

            resetDirectionButtons();

            $('li.friend').click(function(){
              var li = $(this);
              var socialId = li.attr('id');
              var index = $.inArray(socialId, selectedFriends);
              var found = index != -1;

              if (found) {
                li.children('.item-check').addClass('hidden');
                if (li.children('.item-sent')) {
                  li.children('.item-sent').removeClass('hidden');
                }
                selectedFriends.splice(index, 1);
              } else if (!found) {
                li.children('.item-check').removeClass('hidden');
                li.children('.item-sent').addClass('hidden');
                selectedFriends.push(socialId);
              }
              var friend_count = selectedFriends.length;
              if (friend_count > 0) {
                $('#friend_selected').val(selectedFriends);
              }
              else {
                $('#friend_selected').val('');
              }
              $('#friend_selected').change();
              return false;
            });
          });
        }; // showFriendList

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

        $('#friend_filter').bind('input', function(event){
          var newFilter = $(this).val().toLowerCase().replace(/^ +/,'').replace(/ +$/,'');
          if(currentFilter != newFilter){
            currentFilter = newFilter;
            currentPage = 1;
            showFriendList();
          }
        });

        // call functions
        showFriendList();
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

  $(function () {
    if (window.twitterOptions) {
      Tap.Social.initSocialPage(window.twitterOptions);
    }

    $(".invite-twitter-followers").click(function (event) {
      event.preventDefault();
      var $$ = $(this),
          callback = $$.data("callback");

      document.location.href = callback;
    });
  });
}(window.Tapjoy, window.jQuery));
