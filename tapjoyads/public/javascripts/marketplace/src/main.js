$(document).ready(function() {

  var _t = window.i18n.t,
      debounce,
      tjmViewMenu = $('#viewSelectMenu'),
      tjmViewContainer = $('#viewSelect').parent().closest('.select-container'),
      selectTrigger = $('#viewSelect');

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
      $('form#new_gamer_session .login-error').empty();
    });
    $('form#new_gamer_session').submit(function(e){
      Tapjoy.Utils.Cookie.set('cookies_enabled', 'test', 1);
      var test_cookie = Tapjoy.Utils.Cookie.get('cookies_enabled');
      $(".signup-error").removeClass('f-in');.addClass('f-out');
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
        $(".login-error").html(_t('games.enter_email'));
        $(".form-error").show();
        e.preventDefault();
      }
      else if (Tapjoy.Utils.isEmpty(pass) || pass == 'Password') {
        $(".login-error").html(_t('games.enter_password'));
        $(".form-error").show();
        e.preventDefault();
      }
      else if (Tapjoy.Utils.isEmpty(test_cookie)) {
        $(".login-error").html(_t('games.cookies_required'));
        $(".form-error").show();
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
    var rurl = $(this).attr('action');

    // Detect device type and pre-select
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
        if ($('#platform_ios').hasClass('grey-action')) {
          $('#platform_ios').removeClass('grey-action').addClass('orange-action');
          iosSelected = true;
          tempVal['default_platform_ios'] = '1';
          if (androidSelected) {
            $('#platform_android').removeClass('orange-action').addClass('grey-action');
            androidSelected = false;
            tempVal['default_platform_android'] = '';
          }
        }
        else {
          $('#platform_ios').removeClass('orange-action').addClass('grey-action');
          if (iosSelected) {
            iosSelected = false;
            tempVal['default_platform_ios'] = '';
          }
        }
      });
      $('#platform_android, label[for=default_platform_android]').bind('click', function() {
       if ($('#platform_android').hasClass('grey-action')) {
          $('#platform_android').removeClass('grey-action').addClass('orange-action');
          androidSelected = true;
          tempVal['default_platform_android'] = '1';
          if (iosSelected) {
            $('#platform_ios').removeClass('orange-action').addClass('grey-action');
            iosSelected = false;
            tempVal['default_platform_ios'] = '';
          }
        }
        else {
          $('#platform_android').removeClass('orange-action').addClass('grey-action');
          androidSelected = false;
          tempVal['default_platform_android'] = '';
        }
      });
    }

    function validate(e) {
      hasError = false, cookieError = false;
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
      //if(values['gamer[nickname]'] == '' || values['gamer[nickname]'] == "Name") {
      //  $(".signup-error").html(_t('games.enter_name'));
      //  hasError = true;
      //}
      if(values['date[day]'] == '' || values['date[month]'] == '' || values['date[year]'] == '') {
        $(".signup-error").html(_t('games.enter_birthdate'));
        hasError = true;
      }
      else if(values['gamer[email]'] == '' || values['gamer[email]'] == "Email") {
        $(".signup-error").html(_t('games.enter_email'));
        hasError = true;
      }
      else if(!emailReg.test(values['gamer[email]'])) {
        $(".signup-error").html(_t('games.enter_valid_email'));
        hasError = true;
      }
      else if(values['gamer[password]'] == '' || values['gamer[password]'] == "Password") {
        $(".signup-error").html(_t('games.enter_password'));
        hasError = true;
      }
      else if(values['gamer[terms_of_service]'] == false) {
        $(".signup-error").html(_t('games.enter_tos'));
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
      $(".signup-error").removeClass('show');
    });
    $('form#new_gamer input, form#new_gamer select').bind('input, change', function(e){
      validate(e);
      $(".signup-error").removeClass('show');
      if(!hasError) {
        $('#gamer_submit').removeClass('disabled').addClass('enabled').removeClass('soft-grey-action').addClass('orange-action').css({cursor:'pointer'});
      }
      else if($('#gamer_submit').hasClass('enabled')) {
        $('#gamer_submit').removeClass('enabled').addClass('disabled').removeClass('orange-action').addClass('soft-grey-action').css({cursor:'default'});
      }
    });
    // Form Submit
    $('form#new_gamer').bind('submit', function(e){
      e.preventDefault();
      validate(e);
      if (tempVal['default_platform_android'] || tempVal['default_platform_ios']) {
        values['default_platform_android'] = tempVal['default_platform_android'];
        values['default_platform_ios'] = tempVal['default_platform_ios'];
      }
      if (hasError && cookieError) {
        $(".signup-error").html(_t('games.cookies_required')).addClass('show');
      }
      else if (hasError) {
        $(".signup-error").addClass('show');
        e.preventDefault();
      }
      else if (hasError != true) {
        $(".register-form").removeClass('open').addClass('close');
        $('.register-loader').removeClass('f-in').addClass('f-out');
        $.ajax({
          type: 'POST',
          url: rurl + "/games",
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
            var msg;
            if (d.success) {

              if (d.link_device_url) { // Link device
                $('.continue_link_device').click(function(){
                  if (Tapjoy.device.android && d.android) {
                    document.location.href = d.link_device_url;
                  }
                  else if (Tapjoy.device.android && Tapjoy.android_market_url) {
                    document.location.href = Tapjoy.android_market_url;
                  }
                  else if (Tapjoy.device.idevice) {
                    document.location.href = d.link_device_url;
                  }
                  else {
                    if (Tapjoy.path) {
                      document.location.href = Tapjoy.path;
                    }
                    else {
                      document.location.href = document.domain;
                    }
                  }
                });
              }
              else {
                $('.continue_link_device').click(function(){
                  if (Tapjoy.path) {
                    document.location.href = Tapjoy.path;
                  }
                  else {
                    document.location.href = document.domain;
                  }
                });
              }
            }
            else {
              var error = _t('games.issue_registering');
              if (d.error && d.error[0]) {
                if (d.error[0][0] == 'birthdate') {
                  error = _t('games.unable_to_process');
                }
                else if (d.error[0][0] && d.error[0][1]) {
                  error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div>'+_t('games.oops')+'</div>',
                '<div class="error">', error ,'.</div>',
                '<div class="try-again ui-joy-button soft-grey-action">'+_t('shared.try_again')+'</div>',
              ].join('');
              $('.register-message').html(msg).removeClass('f-out').addClass('f-in');
            }
            $('.try-again').click(function(){
              $('.register-message').html('').removeClass('f-in').addClass('f-out');
              $(".register-form").removeClass('close').addClass('open');
            });
          },
          error: function() {
            var error = 'There was an issue';
            msg = [
              '<div>'+_t('games.oops')+'</div>',
              '<div class="error ">', error ,'.</div>',
              '<div class="try-again ui-joy-button orange-action">'+_t('shared.try_again')+'</div>',
            ].join('');
            $('.register-message').html(msg).removeClass('f-out').addClass('f-in');
            $('.register-loader').removeClass('f-in').addClass('f-out');
            $('.try-again').click(function(){
               $('.register-message').html('').removeClass('f-in').addClass('f-out');
               $(".register-form").removeClass('close').addClass('open');
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
    if ($('.device-select').hasClass('open')) {
      $('.device-select').removeClass('open').addClass('closed');
    }
    else {
      $('.device-select').removeClass('closed').addClass('open');
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

  $('.list-button, .btn, .greenblock, #signup, #login, #login-form .ui-joy-button').bind(Tapjoy.EventsMap.start + ' ' + Tapjoy.EventsMap.end + ' ' + Tapjoy.EventsMap.cancel, function(e){
    var el = $(this),
        which = e.type;

    if(which === Tapjoy.EventsMap.start){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }
  });

  $(".button-bar").each(function () {
    var $$ = $(this),
      radios = $(":radio", $$),
      buttons = $(".ui-joy-button", $$),
      value = $(":checked", $$).val(),
      render_state;

    render_state = function () {
      $(".orange-action", $$).removeClass("orange-action").addClass("grey-action");
      $(":checked").attr("checked", false);

      $(".ui-joy-button[value='" + value + "']", $$).removeClass("grey-action").addClass("orange-action");
      $("[value='" + value + "']:radio", $$).attr("checked", "checked");
    };

    $(".ui-joy-button", $$).click(function () {
      value = $(this).attr("value");

      render_state();
    });
    render_state();
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

  $(".submit-button").click(function () {
    $(this).closest("form").submit();
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

  $(".enable-when-valid").each(function () {
    var $$ = $(this),
      $form = $$.closest("form"),
      $req = $("[required]", $form);

    function enable() {
      $$.removeAttr("disabled").removeClass("disabled");
    }

    function disable() {
      $$.attr("disabled", "disabled").addClass("disabled");
    }

    function checkValid() {
      var all_valid = true;

      $req.each(function () {
        if (!$(this).val()) {
          all_valid = false;
          return false;
        }
      });

      return all_valid ? enable() : disable();
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

      heading.text('Choose a Section');

      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px');

      fix.css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }
  });

  $('li', tjmViewMenu).each(function(){
    var li = $(this);

    li.bind('click', function(){
      $('li', tjmViewMenu).removeClass('active');
      li.addClass('active');
      tjmViewContainer.removeClass('active');
      tjmViewMenu.addClass('hide');
      Tapjoy.Utils.removeMask();

      if(li.hasClass('showAll')){
        $('.row').show();
        $('#recommendationsRow').removeClass('nbb');
      }else{
        $('.row').hide();

        if(li.hasClass('showRecommendations')){
          $('#recommendationsRow').show().addClass('nbb');
        }else if(li.hasClass('showGames')){
          $('#gamesRow').show();
        }else if(li.hasClass('showFavorites')){
          $('#favoritesRow').show();
        }
      }

      $('.heading', tjmViewContainer).text(li.text())
    });
  });

  $(window).bind('resize orientationchange', function(){
    if(tjmViewContainer.length != 0 && window.innerWidth < 800){
      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px');

      $('.fix', tjmViewContainer).css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }

    if(window.innerWidth > 770){
      if($('.row').is(':hidden'))
        $('.row').show();
    }else{
      if($('#recommendationsRow').hasClass('nbb'))
        $('#recommendationsRow').show().removeClass('nbb');

      if(!$('#gamesRow').is(':hidden')){
        $('.row').hide();
        $('li.showGames', tjmViewMenu).trigger('click');
      }
    }
  });

  Tapjoy.delay(function(){
    $('#recommedations').Carousel({
      cssClass : 'complete'
    });
  }, 50);


  //if (Tapjoy.device.idevice) {
  //  Tapjoy.Plugins.showAddHomeDialog();
  //}
});
