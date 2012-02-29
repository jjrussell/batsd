$(document).ready(function() {

  var _t = window.i18n.t,
      debounce,
      tjmSelectMenu = $('#recommendSelectMenu'),
      tjmSelectContainer = $('#recommendSelect').parent().closest('.select-container'),
      selectTrigger = $('#recommendSelect');
			
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

  $('#login-form .cancel-btn').bind('click', function() {
    $('#login-form').removeClass('show');
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

  $('.list-button, .btn, .greenblock').bind(Tapjoy.EventsMap.start + ' ' + Tapjoy.EventsMap.end, function(e){
    var el = $(this),
        which = e.type;

    if(which === Tapjoy.EventsMap.start){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }
  });

  Tapjoy.delay(function(){
    $('#recommedations').Carousel();
  }, 10);

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

  $("form.inline-editing").each(function () {
    var $$ = $(this),
      $rows = $(".inline-section");

    $($rows).click(function () {
      $(".show-div", this).hide();
      $(".edit-div", this).show();
    });

    function checkDirty() {

    }
  });

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
            heading = $('.heading', tjmSelectContainer),
          fix = $('.fix', tjmSelectContainer);

     if(tjmSelectContainer.hasClass('active')){
      Tapjoy.Utils.removeMask();

	     tjmSelectContainer.removeClass('active');
	
	     tjmSelectMenu.addClass('hide');
	
	     heading.text($('li.active', tjmSelectMenu).text());

		}else{
			Tapjoy.Utils.mask();

      tjmSelectContainer.addClass('active');
			tjmSelectMenu.removeClass('hide');

			heading.text('Choose a Section');

			tjmSelectMenu.css('top', tjmSelectContainer.offset().top + (tjmSelectContainer.outerHeight(true) - 4) + 'px');

			fix.css({
				width: tjmSelectContainer.width() - 4 + 'px'
			});
		}
	});

	$('li', tjmSelectMenu).each(function(){
		var li = $(this);

		li.bind('click', function(){
			$('li', tjmSelectMenu).removeClass('active');
			li.addClass('active');
      tjmSelectContainer.removeClass('active');
			tjmSelectMenu.addClass('hide');
      Tapjoy.Utils.removeMask();

      $('.heading', tjmSelectContainer).text(li.text())
		});
	});

	$(window).bind('resize orientationchange', function(){
		if(tjmSelectContainer.length != 0 && window.innerWidth < 800){
	    tjmSelectMenu.css('top', tjmSelectContainer.offset().top + (tjmSelectContainer.outerHeight(true) - 4) + 'px');

	    $('.fix', tjmSelectContainer).css({
	      width: tjmSelectContainer.width() - 4 + 'px'
	    });
		}
	});

  /*
   Tapjoy.Utils.notification({
      message: 'Thanks, your settings have been saved.'
   });

  Tapjoy.delay(function(){
     Tapjoy.Utils.notification({
       message: 'Thanks, we would like to save hello again.'
     });
   }, 4000);
   */
});
