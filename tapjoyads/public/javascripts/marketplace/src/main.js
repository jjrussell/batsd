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
      $(".form-error").hide();
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
        Tapjoy.Utils.Cookie.delete('cookies_enabled');
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
      $(".active", $$).removeClass("active");
      $(":checked").attr("checked", false);

      $(".ui-joy-button[value='" + value + "']", $$).addClass("active");
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



/*
    doFbLogout : function(){
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

       tjmSelectContainer.removeClass('active');
       tjmSelectMenu.addClass('hide');
       heading.text($('li.active', tjmSelectMenu).text());

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
      }else{
        $('.row').hide();

        if(li.hasClass('showRecommendations')){
          $('#recommendationsRow').show();
        }else if(li.hasClass('showGames')){
          $('#gamesRow').show();
        }else if(li.hasClass('showFavorites')){
          $('#favoritesRow').show();
        }
      }

      $('.heading', tjmViewContainer).text(li.text())
    });
  });

  $(window).bind('resize orientationchange', debounce(function(){
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
      if(!$('#gamesRow').is(':hidden')){
        $('.row').hide();
        $('li.showGames', tjmViewMenu).trigger('click');
      }

    }
  }));

  Tapjoy.delay(function(){
    $('#recommedations').Carousel({
      cssClass : 'complete'
    });
  }, 50);


  if (Tapjoy.device.idevice) {
    Tapjoy.Plugins.showAddHomeDialog();
  }
});
