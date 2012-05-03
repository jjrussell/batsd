(function (Tap, $) {
  "use strict";
  var _t = window.i18n.t,
    FB = window.FB,
    twitterOptions = window.twitterOptions,
    notify = function (message) {
      Tapjoy.Utils.notification({
        message: message
      });
    };


  Tap.extend({
    Social: {
      doFbLogin: function (redirect_url) {
        FB.login(function (response) {
          if (response.authResponse) {
            FB.api('/me', function (response) {
              window.location = redirect_url;
            });
          } else {
            notify(_t('games.grant_us_access'));
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

      renderFriendList: function(options){
        // local variables
        var currentPage = 1;
        var selectedFriends = [];
        var animateSpeed = "fast";
        var currentFilter = '';
        var pageSize = options.pageSize;
        var socialFriends = options.socialFriends;
        var twitterId = options.twitterId;
        var hasNext = socialFriends.length >= pageSize;
        var template = Tap.Utils.underscoreTemplate($("#twitter-list script").html());

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

        var resetListButtons = function () {
          $('li.friend').click(function () {
            var li = $(this);
            var socialId = li.attr('id');
            var index = $.inArray(socialId, selectedFriends);
            var found = index != -1;

            if (found) {
              li.children('.item-check').addClass('hidden');
              li.children('.item-sent').removeClass('hidden');
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
        };

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
          hasNext = false;
          var $list = $('.friend-list'),
            text        = [],
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
                friend.name.toLowerCase().match(RegExp.escape(currentFilter, $list));
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
            search(false);
          }

          hasNext = counter >= counterMax;

          $list.fadeOut(animateSpeed, function() {
            // unregister events
            $('li.friend', $list).unbind();
            $list.html(template({friends: friends, pageSize: pageSize, start: 0, selectedFriends: selectedFriends}));
            $('.ajax-placeholder').hide();
            $list.fadeIn(animateSpeed);

            resetDirectionButtons();
            resetListButtons();
          });
        }; // showFriendList

        var updateAfterSuccess = function(invitedFriends) {
          for (var i in socialFriends) {
            var friend = socialFriends[i];
            var socialId = friend.social_id.toString();
            var index = $.inArray(socialId, invitedFriends);
            var found = index != -1;
            if (found) {
              socialFriends[i].sent = true;
              selectedFriends.splice($.inArray(socialId, selectedFriends), 1);
            }
          }
          $("#friend_filter").val('');
          showFriendList();
        }; // updateAfterSuccess

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

        $(document).bind("twitter-invite-ajax-success", function (ev, form, data) {
          if (data.success === true) {
            if (data.gamers.length === 0 ) {
              notify(_t('games.generic_issue'));
            } else {
              notify(_t('shared.success'));
              updateAfterSuccess(data.gamers);
            }
          } else if (typeof data.error === "string") {
            notify(data.error);
          } else {
            if (data.errorRedirectPath != undefined){
              document.location.href = data.errorRedirectPath;
            } else {
              notify(_t('games.generic_issue'));
            }
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
    var loadFriendsOptions = window.loadFriendsOptions, startTime = new Date().getTime();
    if (loadFriendsOptions != undefined) {
      var socialFriends = [];
      var twitterFollowerIds = [];
      fetchTwitterFriendList();
    }

    function fetchTwitterFriendList() {
      var url = 'http://api.twitter.com/1/followers/ids.json?user_id=' + loadFriendsOptions.twitterId + '&cursor=-1';
      $.ajax({
        url: url,
        dataType: 'jsonp',
        timeout: 15000,
        success: function(d) {
          twitterFollowerIds = twitterFollowerIds.concat(d.ids);
          twitterFollowerIds = twitterFollowerIds.splice(0,1000);
          fetchTwitterUsersInfo();
        },
        error: function(request, status, error) {
          $('.ajax-placeholder').hide();
          Tapjoy.Utils.notification({
            message: window.i18n.t('games.twitter_account_protected_error')
          });
        }
      });
    }; // fetchTwitterFriendList

    function fetchTwitterUsersInfo() {
      var url = 'http://api.twitter.com/1/users/lookup.json?user_id=' + twitterFollowerIds.splice(0, 100).join();
      $.ajax({
        url: url,
        type: 'POST',
        dataType: 'jsonp',
        timeout: 15000,
        success: function(d) {
          for(var i in d) {
            var user = d[i];
            var userSimple = {
             "social_id" : user.id,
             "name"      : user.name,
             "image_url" : user.profile_image_url_https
            }
            socialFriends.push(userSimple);
          }
          if (twitterFollowerIds.length > 0) {
            fetchTwitterUsersInfo(twitterFollowerIds);
          } else {
            socialFriends = socialFriends.sort(function(a, b) {
              var nameA = a.name.toLowerCase(), nameB = b.name.toLowerCase();
              if (nameA > nameB) return 1;
              if (nameA < nameB) return -1;
              return 0;
            });
            Tap.Social.renderFriendList({pageSize: loadFriendsOptions.pageSize, socialFriends: socialFriends, twitterId: loadFriendsOptions.twitterId});
            Tap.Utils.googleLog("TwitterFollowers", "load", "Time in Milliseconds", (new Date().getTime() - startTime));
          }
        }
      });
    }; // fetchTwitterFriendList

    $(".invite-twitter-followers").click(function (event) {
      event.preventDefault();
      var $$ = $(this),
          redirectPath = $$.data("redirect-path");

      document.location.href = redirectPath;
    });
  });
}(window.Tapjoy, window.jQuery));
