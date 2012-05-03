(function (Tap, $) {
  "use strict";
  var _t = window.i18n.t,
    twitterOptions = window.twitterOptions,
    notify = function (message) {
      Tapjoy.Utils.notification({
        message: message
      });
    };


  Tap.extend({
    Social: {
      initiateFacebook: function (options, onReady) {
        window.fbAsyncInit = function() {
          FB.init({
            appId  : options.appId,
            status : true,
            cookie : true,
            oauth : true,
            xfbml : true
          });

          onReady();
        };

        (function() {
          var e = document.createElement('script'); e.async = true;
          e.src = document.location.protocol + '//connect.facebook.net/' + options.locale + '/all.js';
          document.getElementById('fb-root').appendChild(e);
        }());
      },

      doFbLogin: function (redirect_url, submitFormId) {
        FB.login(function (response) {
          if (response.authResponse) {
            FB.api('/me', function (response) {
              if (redirect_url != undefined) {
                Tap.Social.checkPermission(function () {
                  window.location = redirect_url.replace(/&amp;/g, "&");
                });
              } else if (submitFormId != undefined) {
                Tap.Social.checkPermission(function () {
                  $("#" + submitFormId).submit();
                });
              }
            });
          } else {
            notify(_t('games.grant_us_access'));
          }
        }, {scope: 'offline_access,publish_stream,email,user_birthday,read_friendlists'});
      },

      checkPermission: function (withPerm) {
        FB.api('/me/permissions', function (response) {
          if (response['data'][0]['offline_access'] && response['data'][0]['publish_stream']) {
            withPerm();
          }
        });
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
        var hasNext = socialFriends.length >= pageSize;
        var template = Tap.Utils.underscoreTemplate($("#twitter-friends script").html());

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
            text      = [],
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
            search(false)
          }

          hasNext = counter >= counterMax;

          $list.fadeOut(animateSpeed, function() {
            // unregister events
            $('li.friend', $list).unbind();
            $list.html(template({friends: friends, pageSize: pageSize, start: 0, selectedFriends: selectedFriends}));
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
              notify(_t('shared.generic_issue'));
            } else {
              notify(_t('shared.success'));
              updateAfterSuccess(data.gamers);
            }
          } else if (typeof data.error === "string") {
            notify(data.error);
          } else {
            notify(_t('shared.generic_issue'));
          }
        });

        // call functions
        resetDirectionButtons();
        resetListButtons();
      }
    }
  });

  $(function () {
    var fbOpts = $("#fb-root").data("fb-options");

    if (!fbOpts) { return; }

    Tap.Social.initiateFacebook(fbOpts, function () {
      $(".login-to-facebook, .log-in-with-facebook").on("click", function () {
        var url = $(this).data("fb-url");
        var submitFormId = $(this).data("submit-form-id");
        Tap.Social.doFbLogin(url, submitFormId);
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
  });

  $(function () {
    var loadFriendsOptions = window.loadFriendsOptions;
    $("#twitter-friends").bind("ajax-loader-success", function (ev, data) {
      if (data.success === false) {
        if (data.error) {
          notify(data.error);
        }

        if(data.errorRedirectPath) {
          window.location = data.errorRedirectPath;
        }
      }
      else {
        Tap.Social.renderFriendList({pageSize: loadFriendsOptions.pageSize, socialFriends: data.friends});
      }
    });

    $(".invite-twitter-followers").click(function (event) {
      event.preventDefault();
      var $$ = $(this),
          redirectPath = $$.data("redirect-path");

      document.location.href = redirectPath;
    });
  });
}(window.Tapjoy, window.jQuery));
