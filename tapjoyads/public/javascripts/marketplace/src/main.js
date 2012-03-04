$(document).ready(function() {

  var _t = window.i18n.t,
      debounce,
      tjmViewMenu = $('#viewSelectMenu'),
      tjmViewContainer = $('#viewSelect').closest('.select-container'),
      selectTrigger = $('#viewSelect'),
      notify = function (message) {
        Tapjoy.Utils.notification({
          message: message
        });
      };

  // Login Modal
  $('#login, #login-web').bind('click', function() {
    if ($('#login-form').hasClass('show')) {
      $('#login-form').removeClass('show');
    }
    else {
      $('#login-form').addClass('show').css({
        'height' : $(document).height()
      });
    }
  });
  $('#signup, #signup-btn').bind('click', function() {
    if ($('#signup-form').hasClass('show')) {
      $('#signup-form').removeClass('show');
    }
    else {
      $('#signup-form').addClass('show').css({
        'height' : $(document).height()
      });
    }
  });

  $('#login-form .cancel-btn').bind('click', function() {
    $('#login-form').removeClass('show');
  });

  $('#signup-form .cancel-btn').bind('click', function() {
    $('#signup-form').removeClass('show');
  });

  // Login Validation
  if ($('form#new_gamer_session')) {
    $('form#new_gamer_session input').focus(function() {
      $('form#new_gamer_session .form-error').html('&nbsp;').css({opacity: '0', visibility: 'hidden'});
    });
    $('form#new_gamer_session').submit(function(e){
      Tapjoy.Utils.Cookie.set('cookies_enabled', 'test', 1);
      var test_cookie = Tapjoy.Utils.Cookie.get('cookies_enabled');
      $(".form-error").css({opacity: '0', visibility: 'hidden'});
      var inputs, email, pass, values = {};
      var emailRegex = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
      inputs = $('form#new_gamer_session :input*');
      inputs.each(function() {
        if (this.type == 'checkbox' || this.type == 'radio') {
          values[this.name] = $(this).attr("checked");
        }
        else {
          values[this.name] = $(this).val();
        }
      });
      email = values['gamer_session[email]'];
      pass = values['gamer_session[password]'];
      if (Tapjoy.Utils.isEmpty(email) || email == 'Email') {
        $(".form-error").html(_t('games.enter_email')).css({opacity: '1', visibility: 'visible !important'});
        e.preventDefault();
      }
      else if (Tapjoy.Utils.isEmpty(pass) || pass == 'Password') {
        $(".form-error").html(_t('games.enter_password')).css({opacity: '1', visibility: 'visible !important'});
        e.preventDefault();
      }
      else if (Tapjoy.Utils.isEmpty(test_cookie)) {
        $(".form-error").html(_t('games.cookies_required')).css({opacity: '1', visibility: 'visible !important'});
        e.preventDefault();
      }
      else {
        Tapjoy.Utils.Cookie.remove('cookies_enabled');
      }
    });
  }

  // Signup Validation
  if($('form#new_gamer')) {
    var values = {}, tempVal = {}, data, preSelected = false, hasError = false, cookieError = false;
    var activeState = 'orange-action', inactiveState = 'grey-action';
    var rurl = $('form#new_gamer').attr('action');

    // Detect device type auto set
    if (Tapjoy.device.idevice || Tapjoy.device.android) {
      if (Tapjoy.device.idevice) {
        tempVal['default_platform_ios'] = '1';
        preSelected = true;
      }
      else if (Tapjoy.device.android) {
        tempVal['default_platform_android'] = '1';
        preSelected = true;
      }
      if (preSelected) {
        $('#platform-row').hide();
      }
    }
    else {
      var iosSelected = false, androidSelected = false;
      $('#platform_ios, label[for=default_platform_ios]').bind('click', function() {
        if ($('#platform_ios').hasClass(inactiveState)) {
          $('#platform_ios').removeClass('grey-action').addClass(activeState);
          iosSelected = true;
          tempVal['default_platform_ios'] = '1';
          if (androidSelected) {
            $('#platform_android').removeClass(activeState).addClass(inactiveState);
            androidSelected = false;
            tempVal['default_platform_android'] = '';
          }
        }
        else {
          $('#platform_ios').removeClass(activeState).addClass(inactiveState);
          if (iosSelected) {
            iosSelected = false;
            tempVal['default_platform_ios'] = '';
          }
        }
      });
      $('#platform_android, label[for=default_platform_android]').bind('click', function() {
       if ($('#platform_android').hasClass(inactiveState)) {
          $('#platform_android').removeClass(inactiveState).addClass(activeState);
          androidSelected = true;
          tempVal['default_platform_android'] = '1';
          if (iosSelected) {
            $('#platform_ios').removeClass(activeState).addClass(inactiveState);
            iosSelected = false;
            tempVal['default_platform_ios'] = '';
          }
        }
        else {
          $('#platform_android').removeClass(activeState).addClass(inactiveState);
          androidSelected = false;
          tempVal['default_platform_android'] = '';
        }
      });
    }
    // Validate form inputs
    function validate(e) {
      hasError = false, cookieError = false;
      // Test Cookie
      Tapjoy.Utils.Cookie.set('cookies_enabled', 'test', 1);
      var test_cookie = Tapjoy.Utils.Cookie.get('cookies_enabled');
      var inputs = $('form#new_gamer :input');
      inputs.each(function() {
        if (this.type == 'radio') {
          values[this.name] = $(this).attr("checked");
        }
        else if (this.type == 'checkbox') {
          if ($(this).attr("checked")) {
            values[this.name] = '1';
          }
          else {
            values[this.name] = '0';
          }
        }
        else {
          values[this.name] = $(this).val();
        }
      });
      var emailReg = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
      /*if(values['gamer[nickname]'] == '' || values['gamer[nickname]'] == "Name") {
      //  $(".form-error").html(_t('games.enter_name'));
      //  hasError = true;
      }*/
      if(values['date[day]'] == '' || values['date[month]'] == '' || values['date[year]'] == '') {
        $(".form-error").html(_t('games.enter_birthdate'));
        hasError = true;
      }
      else if(values['gamer[email]'] == '' || values['gamer[email]'] == _t("shared.email")) {
        $(".form-error").html(_t('games.enter_email'));
        hasError = true;
      }
      else if(!emailReg.test(values['gamer[email]'])) {
        $(".form-error").html(_t('games.enter_valid_email'));
        hasError = true;
      }
      else if(values['gamer[password]'] == '' || values['gamer[password]'] == _t("shared.password")) {
        $(".form-error").html(_t('games.enter_password'));
        hasError = true;
      }
      else if(values['gamer[terms_of_service]'] == false) {
        $(".form-error").html(_t('games.enter_tos'));
        hasError = true;
      }
      else if (Tapjoy.Utils.isEmpty(test_cookie)) {
        hasError = true;
        cookieError = true;
      }
      else {
        Tapjoy.Utils.Cookie.remove('cookies_enabled');
      }
    }
    // Form Validation
    $('form#new_gamer input, form#new_gamer select').bind('focus', function(e){
      $(".form-error").css({opacity: '0', visibility: 'hidden'});
    });

    $('form#new_gamer input, form#new_gamer select').bind('input, change', function(e){
      validate(e);
      if(!hasError) {
        $(".form-error").css({opacity: '0', visibility: 'hidden'});
        $('#gamer_submit').addClass('orange-action').removeClass('soft-grey-action').removeClass('disabled').addClass('enabled').css({cursor:'pointer'});
      }
      else if($('#gamer_submit').hasClass('enabled')) {
        $(".form-error").css({opacity: '0', visibility: 'hidden'});
        $('#gamer_submit').removeClass('orange-action').addClass('soft-grey-action').removeClass('enabled').addClass('disabled').css({cursor:'default'});
      }
    });
    // Form Submit
    var unbindSubmit = false;
    $('form#new_gamer').bind('submit', function(e){
      e.preventDefault();
      if (unbindSubmit) {
        return;
      }
      validate(e);
      if (tempVal['default_platform_android'] || tempVal['default_platform_ios']) {
        values['default_platform_android'] = tempVal['default_platform_android'];
        values['default_platform_ios'] = tempVal['default_platform_ios'];
      }
      if (hasError && cookieError) {
        $(".form-error").html(_t('games.cookies_required')).css({opacity: '1', visibility: 'visible !important'});
      }
      else if (hasError) {
        $(".form-error").css({opacity: '1', visibility: 'visible !important'});
      }
      else if (!hasError) {
        $(".register-form").addClass('close').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'});
        $(".form-error").css({opacity: '0', visibility: 'hidden'});
        $('.register-progress').show().css({opacity: '1', visibility: 'visible !important', height: 'auto'});
        $('.register-loader').css({opacity: '1', visibility: 'visible !important'});
        $.ajax({
          type: 'POST',
          url: rurl,
          cache: false,
          timeout: 15000,
          dataType: 'json',
          data: {
            'authenticity_token': values['authenticity_token'],
            'data': values['data'],
            'src': values['src'],
            'gamer[email]': values['gamer[email]'],
            'gamer[password]': values['gamer[password]'],
            'gamer[referrer]': values['gamer[referrer]'],
            'gamer[terms_of_service]': values['gamer[terms_of_service]'],
            'date[day]': values['date[day]'],
            'date[month]': values['date[month]'],
            'date[year]': values['date[year]'],
            'default_platforms[android]': values['default_platform_android'],
            'default_platforms[ios]': values['default_platform_ios']
          },
          success: function(d) {
            $('.register-progress').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'}).hide();
            var msg, goHome = false, unbindSubmit = true;
            if (d.success) {
              if (d.link_device_url) { // link device url returned
                if (Tapjoy.device.idevice) { // is ios device
                  $('.register-loader').show().css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'});
                  $('#register-ios').show().css({opacity: '1', visibility: 'visible !important'});
                  $('#gamer_submit').click(function() {
                    document.location.href = d.link_device_url;
                  });
                }
                else if (Tapjoy.device.android && d.android) { // if coming from tjm android app
                  document.location.href = d.link_device_url;
                }
                else if (Tapjoy.device.android && Tapjoy.androidAppPath) { // if android device
                  $('.register-loader').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'});
                  $('#register-android').show().css({opacity: '1', visibility: 'visible !important'});
                  $('#gamer_submit').click(function() {
                    document.location.href = Tapjoy.androidAppPath;
                  });
                }
                else {
                  goHome = true;
                }
              }
              else if (Tapjoy.device.android && Tapjoy.androidAppPath){
                  $('.register-loader').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'});
                  $('#register-android').show().css({opacity: '1', visibility: 'visible !important'});
              }
              else if (Tapjoy.rootPath) {
                document.location.href = Tapjoy.rootPath;
              }
              else {
                goHome = true;
              }
              if (goHome) {
                document.location.href = document.domain;
              }
            }
            else {
              var error = _t('games.issue_registering');
              if (d.error && d.error[0]) {
                if (d.error[0][0] == 'birthdate') {
                  error = _t('games.unable_to_process');
                }
                else if (d.error[0][0] && d.error[0][1]) {
                  error = d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div>'+_t('games.oops')+'</div>',
                '<div class="error">', error ,'.</div>',
                '<div class="try-again ui-joy-button soft-grey-action">'+_t('shared.try_again')+'</div>',
              ].join('');
              $('.register-progress').show().css({opacity: '1', visibility: 'visible !important', height: 'auto'});
              $('.register-message').html(msg).show().css({opacity: '1', visibility: 'visible !important'});
            }
            $('.try-again').click(function(){
              $('.register-message').html('&nbsp;').css({opacity: '0', visibility: 'hidden'});
              $('.register-progress').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'}).hide();
              $(".register-form").removeClass('close').css({opacity: '1', visibility: 'visible !important', height: 'auto'});

            });
          },
          error: function() {
            var error = 'There was an issue';
            msg = [
              '<div>'+_t('games.oops')+'</div>',
              '<div class="error ">', error ,'.</div>',
              '<div class="try-again ui-joy-button orange-action">'+_t('shared.try_again')+'</div>',
            ].join('');
            $('.register-progress').show().css({opacity: '1', visibility: 'visible !important', height: 'auto'});
            $('.register-message').html(msg).css({opacity: '1', visibility: 'visible !important'});
            $('.register-loader').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'});
            $('.try-again').click(function(){
              $('.register-message').html('&nbsp;').css({opacity: '0', visibility: 'hidden'});
              $('.register-progress').css({opacity: '0', visibility: 'hidden', height: '0', overflow : 'hidden'}).hide();
              $(".register-form").removeClass('close').css({opacity: '1', visibility: 'visible !important', height: 'auto'});
            });
          }
        });
      }
    });
  }

  // Menu Grid
  $('.menu-grid').bind('click', function(){
    if ($(this).hasClass('active')) {
      $(this).removeClass('active');
      $('.menu-dropdown').removeClass('open').addClass('close');
    }
    else {
      $(this).addClass('active');
      $('.menu-dropdown').removeClass('close').addClass('open');
    }
  });

  // Menu - Device Toggle
  $('.device-toggle').bind('click', function(){
    if ($(this).hasClass('up')) {
      $(this).removeClass('up').addClass('down');
    }
    else {
      $(this).removeClass('down').addClass('up');
    }
  });

  // Device switch toggle
  $('.device-change').bind('click', function(){
    if ($('#device-select').hasClass('open')) {
      $('#device-select').removeClass('open').addClass('closed');
      $('.device-change').html('(' + _t('games.change') + ')');
    }
    else {
      $('#device-select').removeClass('closed').addClass('open');
      $('.device-change').html('(' + _t('games.close') + ')');
    }
  });

  // App Icons
  $('.app-icon img').each(function(n, o){
    var el = $(o);

    el.attr("src", el.attr("source"));
    el.load(function(){
      $(this).fadeIn('slow');
    });
    el.error(function(){
      el.attr("src", "data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==");
    });
  });

  $('.toggle').bind(Tapjoy.EventsMap.start, function(){
    var el = $(this),
        img = $('img', el),
        content = $(this).parent().next('div');

    if(img.hasClass('uparrow')){
     img.removeClass('uparrow').addClass('downarrow');
     content.removeClass('hide');
    }else{
      img.removeClass('downarrow').addClass('uparrow')
      content.addClass('hide');
    }
  });

  $('.list-button, .btn, .greenblock, #signup, #login').live(Tapjoy.EventsMap.start + ' ' + Tapjoy.EventsMap.end + ' ' + Tapjoy.EventsMap.cancel, function(e){
    var el = $(this),
        target = $(e.target),
        which = e.type;

     if(el.hasClass('ui-no-action'))
      return;

    if(which === Tapjoy.EventsMap.start){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }
  });

  $('.ui-joy-button').bind(Tapjoy.EventsMap.start + ' ' + Tapjoy.EventsMap.end + ' ' + Tapjoy.EventsMap.cancel, function(e){
    var el = $(this),
        which = e.type;

     if(el.hasClass('disabled'))
      return;

    if(which === Tapjoy.EventsMap.start){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }

  });

  (function () {
    var showSuccessMessage = function (gamers, non_gamers) {
      var msg = _t("shared.success"),
          template = function (txt) {
            return "<div>"+txt+"</div>";
          };

      if (gamers.length !== 0) {
        msg += template(_t("games.already_registered",
          { name: gamers.toString().replace(/\,/g, ", ") },
          { count: gamers.length }
        ));
      }
      if (non_gamers.length !== 0) {
        msg += template(_t("games.invites_sent_to",
          { name: non_gamers.toString().replace(/\,/g, ", ") },
          { count: non_gamers.length }
        ));
      }

      notify(msg);
    };

    $(document).bind("email-invite-ajax-success", function (ev, form, data) {
      if (data.success === true) {
        if (data.gamers.length === 0 && data.non_gamers.length === 0) {
          notify(_t('games.provide_other_email'));
        } else {
          showSuccessMessage(data.gamers, data.non_gamers);
          $("#recipients", form).val('');
        }
      } else if (typeof data.error === "string") {
        notify(data.error);
      } else {
        notify(_t('shared.generic_issue'));
      }
    });
  }());

  $('.button-bar').each(function(){
    var $t = $(this),
      radios = $(':radio', $t),
      buttons = $('.ui-joy-button', $t),
      value = $(":checked", $t).val(),
      render;

    render = function(){
      $('.primary', $t).removeClass('primary').addClass('secondary');
      $(':checked').attr('checked', false);

      $('.ui-joy-button[value="' + value + '"]', $t).removeClass('secondary').addClass('primary');
      $('[value="' + value + '"]:radio', $t).attr('checked', 'checked');
    };

    $('.ui-joy-button', $t).click(function(){
      value = $(this).attr("value");

      render();
    });

    render();
  });

  // debouncing function from John Hann
  // http://unscriptable.com/index.php/2009/03/20/debouncing-javascript-methods/
  debounce = function (func, threshold, execAsap) {
    var timeout;

    return function debounced() {
      var obj = this, args = arguments;
      function delayed() {
        if (!execAsap) {
          func.apply(obj, args);
        }
        timeout = null;
      }

      if (timeout) {
        clearTimeout(timeout);
      } else if (execAsap) {
        func.apply(obj, args);
      }

      timeout = setTimeout(delayed, threshold || 100);
    };
  };

  $(document).bind("email-invite-ajax-success", function (ev, form, data) {
    if (data.success) {
      if (data.gamers.length === 0 && data.non_gamers.length === 0) {
        notify(_t('games.provide_other_email'));
      } else {
        showSuccessMessage(data.gamers, data.non_gamers);
        $("#recipients", form).val('');
      }
    } else {
      notify(data.error);
    }
  });

  $(".submit-child-form").click(function () {
    $("form", this).submit();
    return false;
  });

  $(".login-to-facebook").click(function () {
    var scope = 'offline_access,publish_stream',
      $$ = $(this),
      FB = window.FB;
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
  });

  /*
    doFbLogout : function(){
      FB.getLoginStatus(function(response) {
        if (response.authResponse) {
          FB.logout(function(response) {
          });
        }
      });
    },
    */


  (function () {
    var $flash = $('#flash-notice');

    if ($flash.length === 0) { return; }

    Tapjoy.Utils.notification({
      message: $flash.html()
    });
  }());

  $(".enable-when-valid").each(function () {
    var $$ = $(this),
      $form = $$.closest("form"),
      $req = $("[required]", $form),
      $psword = $("input[name*='password']", $form),
      invalid;

    $$.click(function () {
      if(invalid.length > 0) {
        notify(_t('games.invalid_fields'));
        return false;
      }
    });

    function enable() {
      $$.removeClass("disabled");
    }

    function disable() {
      $$.addClass("disabled");
    }

    function checkValid() {
      invalid = [];

      $req.each(function () {
        if (!$(this).val()) {
          invalid.push($(this));
        }
      });

      if ($psword.length === 2) {
        if($psword.first().val() !== $psword.last().val()) {
          invalid = invalid.concat($psword);
        }
      }

      return invalid.length === 0 ? enable() : disable();
    }

    $req.bind("change keyup", debounce(checkValid));
    checkValid();
  });

  selectTrigger.bind(Tapjoy.EventsMap.start, function(){
      var el = $(this),
            heading = $('.heading', tjmViewContainer),
          fix = $('.fix', tjmViewContainer);

     if(tjmViewContainer.hasClass('active')){
      Tapjoy.Utils.removeMask();

       tjmViewContainer.removeClass('active');
       tjmViewMenu.addClass('hide');
       heading.text($('li.active', tjmViewMenu).text());

    }else{
      Tapjoy.Utils.mask();

      tjmViewContainer.addClass('active');
      tjmViewMenu.removeClass('hide');

      heading.text(_t('games.choose_section'));

      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px');

      fix.css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }
  });

  function handleTabs($anchor) {
    if (!$anchor) { return; }

    var targetSelector = $anchor.attr("href"),
        $target = $(targetSelector);
    $(".buffer").hide();
    $target.show();
    $(".ajax-loader", $target).trigger("ajax-initiate");
  }

  $('li', tjmViewMenu).each(function(){
    var li = $(this);

    li.bind('click', function(){
      $('li', tjmViewMenu).removeClass('active');
      li.addClass('active');
      tjmViewContainer.removeClass('active');
      tjmViewMenu.addClass('hide');
      Tapjoy.Utils.removeMask();

      if(li.hasClass('showAll')){
        $('.row').show().addClass('view-all');
        $('#recommendationsRow').removeClass('nbb');
      }else{
        $('.row').hide().removeClass('view-all');

        if(li.hasClass('showRecommendations')){
          $('#recommendationsRow').show().addClass('nbb');
        }else if(li.hasClass('showGames')){
          $('#gamesRow').show();
        }else if(li.hasClass('showFavorites')){
          $('#favoritesRow').show();
        }
      }

      handleTabs($("a.ui-joy-reveal", li));

      $('.heading', tjmViewContainer).text(li.text())
      return false;
    });
  });

  function manageResize() {
    if(tjmViewContainer.length != 0 && window.innerWidth < 800){
      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px');

      $('.fix', tjmViewContainer).css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }
    var rows = $('#content .row');
    if(window.innerWidth > 770){
      if(rows.is(':hidden'))
        rows.show();
    }else{
      if($('#recommendationsRow').hasClass('nbb'))
        $('#recommendationsRow').show().removeClass('nbb');

      if(!$('#gamesRow').is(':hidden')){
        rows.hide();
        $('li.showGames', tjmViewMenu).trigger('click');
      }
    }
  }

  $(window).bind('resize orientationchange', debounce(manageResize));
  // run logic on ready
  manageResize();

  setTimeout(function(){
    // Hide the ios address bar!
    window.scrollTo(0, 1);
  }, 0);

  Tapjoy.delay(function(){
    $('#recommendations').Carousel({
      cssClass : 'complete'
    });
  }, 50);

  // Device Switcher
  Tapjoy.selectDevice = [{"device_type":"ipod","name":"Android (R800x)","data":"cccf46abc68d9cba60b699fd808f6403b84528be420d5f6ba9a40b70193df3b2c877d558565789e6a4cfc2c87b5c90a542e7c3a8e0fdb07ce2e052d4cf59390cba9898494eb7f47de59c8488dc8b85fd63f6ef6fc3eb15898a48ceaded3b08ba"},{"device_type":"ipod","name":"iPod Touch","data":"cccf46abc68d9cba60b699fd808f64037ba278d7c09a8e878acba677a272aa13077f9a3bc645e11142e971e402d8c7d49404e5fa59c9347e185e325e92abdbc668094f84bf8c60f31c5f3784d741d3ec34ba27ae691788ebcdc0f077cca68d60a05f1def37b19844eca6cfc7d03adc8d950d4740616b5b37f8f78458998ba89c"}];
 
  Tapjoy.device.name = 'ipod';
  Tapjoy.device.idevice = true;
  Tapjoy.supportsTouch = true;
  Tapjoy.device.android = false;

  if (Tapjoy.selectDevice) {
    var path, device_found = false, device_count = 0, device_data, matched_data;
    var d = [], a = [], m = [];
    if (Tapjoy.rootPath) {
      path = Tapjoy.rootPath.replace(/\/$/, '');
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    $.each(Tapjoy.selectDevice, function(i,v){
      var device_type = v.device_type;
      if (!Tapjoy.Utils.isEmpty(device_type) && Tapjoy.device.name && (device_type.toLowerCase() == Tapjoy.device.name.toLowerCase())) {
        device_count++;
        device_found = true;
        d.push('<a href="', path ,'/switch_device?data=', v.data ,'">');
          d.push('<li class="device-item">');
            d.push(v.name);
          d.push('</li>');
        d.push('</a>');
      }
      else if (!Tapjoy.supportsTouch) { // Web
        a.push('<a href="', path ,'/switch_device?data=', v.data ,'">');
          a.push('<li class="device-item">');
            a.push(v.name);
          a.push('</li>');
        a.push('</a>');
      }
    });
    if (!device_found) {
      if (Tapjoy.device.idevice && Tapjoy.iosLinkDevicePath) {
        link_device = '<a href="' + Tapjoy.iosLinkDevicePath + '"><li class="device-item">'+_t('games.connect_my_device')+'</li></a>';
        m =  [
          '<ul>',
            link_device,
          '</ul>'
        ].join('');
      }
      else if (Tapjoy.device.android &&  Tapjoy.androidAppPath) {
        link_device = '<a href="' + Tapjoy.androidAppPath + '"><li class="device-item">'+_t('games.connect_my_device')+'</li></a>';
        m =  [
          '<ul>',
            link_device,
          '</ul>'
        ].join('');
      }
      else if (!Tapjoy.supportsTouch) { // Web - Allow user to select device
        m =  [
          '<ul>',
            a.join(''),
          '</ul>'
        ].join('');
      }
    }
    else {
      var other = "";
      if (Tapjoy.device.android &&  Tapjoy.androidAppPath) {
        other = '<a href="' +  Tapjoy.androidAppPath + '"><li class="device-item add">'+_t('shared.other')+'</li></a>';
      }
      else if (Tapjoy.device.idevice && Tapjoy.iosLinkDevicePath) {
        other = '<a href="' +  Tapjoy.iosLinkDevicePath + '"><li class="device-item add">'+_t('shared.other')+'</li></a>';
      }
      m =  [
        '<ul>',
          d.join(''),
          other,
        '</ul>',
      ].join('');
    }
    $('#device-select-list').html(m);
  }

  // If on mobile device and cookie missing, prompt user to select closest matching device
  if (Tapjoy.requireSelectDevice && Tapjoy.selectDevice.length > 0 && (Tapjoy.device.idevice || Tapjoy.device.android)) {
 //commenting out until we can talk to Van
  //  Tapjoy.Utils.mask();
  }



  //if (Tapjoy.device.idevice) {
  //  Tapjoy.Plugins.showAddHomeDialog();
  //}
});
