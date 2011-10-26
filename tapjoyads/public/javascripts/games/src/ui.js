TJG.ui = {

  hideLoader : function(delay,fn) {
    TJG.repositionDialog = [];
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('#loader').fadeOut(delay,fn);
    });
  },

  showLoader : function(delay,fn) {
    $.utils.centerDialog("#loader");
    TJG.repositionDialog = ["#loader"];
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('#loader').fadeIn(delay,fn);
    });
  },

  showLoaderAtCenter : function(delay,fn) {
    $.utils.centerDialog("#loader");
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      var scrollTop = $(window).scrollTop();
      var screenHeight = $(window).height();
      var height = $('#sender').height();
      $('#loader').fadeIn(delay,fn).css({ top: scrollTop + screenHeight / 2 - height / 2 });
    });
  },

  hideSender : function(delay,fn) {
    TJG.repositionDialog = [];
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('#sender').fadeOut(delay,fn);
    });
  },

  showSender : function(delay,fn) {
    $.utils.centerDialog("#sender");
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      var scrollTop = $(window).scrollTop();
      var screenHeight = $(window).height();
      var height = $('#sender').height();
      $('#sender').fadeIn(delay,fn).css({ top: scrollTop + screenHeight / 2 - height / 2 });
    });
  },

  removeDialogs : function (delay) {
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('.dialog_wrapper').fadeOut(delay);
    });
    TJG.repositionDialog = [];
  },

  getOfferRow : function (obj,currency,i,hidden) {
    var t = [], clsId = "", style = "";
    if (i) {
      clsId = "offer_item_" + i;
    }
    if (hidden) {
      style = 'style="display:none;"';
    }
    $.each(obj, function(i,v){
      var freeCls = "";
      if (v.Cost == "Free") {
        freeCls = "free";
      }
      t.push('<a href="' + v.RedirectURL + '">');
        t.push('<li class="offer_item clearfix '+ clsId +'" '+ style +'>');
          t.push('<a href="' + v.RedirectURL + '">');
            t.push('<div class="offer_image">');
              t.push('<div id="'+ TJG.utils.genSym() +'" class="offer_image_loader_wrapper"><img src="' + TJG.blank_img + '" s="' + v.IconURL + '"></div>');
            t.push('</div>');
          t.push('</a>');
          t.push('<div class="offer_text">');
            t.push('<div class="offer_title title">');
              t.push(v.Name);
            t.push('</div>');
            if (v.Type && v.Type == 'App') {
              t.push('<div class="offer_install">');
                t.push('Install and run ' + v.Name);
              t.push('</div>');
            }
            t.push('<div class="offer_info">');
                t.push('<a href="' + v.RedirectURL + '">');
                  t.push('<div class="offer_button my_apps">');
                    t.push('<div class="button grey">');
                      t.push('<span class="amount">');
                        t.push(v.Amount);
                      t.push('</span>');
                      t.push(' ');
                      t.push('<span class="currency">');
                        t.push(currency);
                      t.push('</span>');
                      t.push('<span class="cost '+ freeCls +'">');
                        t.push(v.Cost);
                      t.push('</span>');
                    t.push('</div>');
                  t.push('</div>');
                t.push('</a>');
            t.push('</div>');
          t.push('</div>');
        t.push('</li>');
      t.push('</a>');
    });
    return t.join('');
  },

  showRegister : function () {
    var hasLinked = true, path, animateSpd = "fast";
    if (TJG.path) {
       path = TJG.path.replace(/\/$/, '');
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }

    $('form#new_gamer').submit(function(e){
      e.preventDefault();
      var rurl, inputs, values = {}, data, hasError = false, emailReg;
      rurl = $(this).attr('action');
      inputs = $('form#new_gamer :input');
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
      var form_height = $('.register_form').outerHeight();

      $(".email_error").hide();
      emailReg = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
      if(values['date[day]'] == '' || values['date[month]'] == '' || values['date[year]'] == '') {
        $(".email_error").html('Please enter your birthdate');
        hasError = true;
      }
      else if(values['gamer[email]'] == '') {
        $(".email_error").html('Please enter your email address');
        hasError = true;
      }
      else if(!emailReg.test(values['gamer[email]'])) {
        $(".email_error").html('Enter a valid email address');
        hasError = true;
      }
      else if(values['gamer[password]'] == '') {
        $(".email_error").html('Please enter a password');
        hasError = true;
      }
      else if(values['gamer[terms_of_service]'] == false) {
        $(".email_error").html('Please agree to the terms and conditions above');
        hasError = true;
      }
      if (hasError) {
        $(".email_error").show();
      }
      else if (hasError != true) {
        var loader = [
          '<div class="title_2 center">Registering</div>',
          '<div class="loading_animation"></div>'
        ].join('');
        $('.register_form').animate({ height: "0px" }, animateSpd, function() {
          $('.register_progess').html(loader);
        });
        $.ajax({
          type: 'POST',
          url: rurl,
          cache: false,
          timeout: 15000,
          dataType: 'json',
          data: {
            'authenticity_token': values['authenticity_token'],
            'gamer[email]': values['gamer[email]'],
            'gamer[password]': values['gamer[password]'],
            'gamer[referrer]': values['gamer[referrer]'],
            'gamer[terms_of_service]': values['gamer[terms_of_service]'],
            'date[day]': values['date[day]'],
            'date[month]': values['date[month]'],
            'date[year]': values['date[year]']
          },
          success: function(d) {
            var msg;
            if (d.success) {
              hasLinked = false;
              msg = [
                '<div class="title_2 center">Success!</div>',
                '<div class="dialog_content center">Your Tapjoy account was sucessfully created!</div>',
                '<div class="continue_link_device"><div class="button red">Continue</div></div>',
              ].join('');
              if (!TJG.vars.isTouch) {
                msg = [
                  '<div class="title_2 center">Success!</div>',
                  '<div class="dialog_content center">Your Tapjoy account was sucessfully created!</div>',
                  '<div class="continue_link_device"><div class="button red">Continue</div></div>',
                ].join('');
              }
              $('.register_progess').html(msg);
              if (d.linked) { // Device already linked with account
                $('.continue_link_device').click(function(){
                  if (TJG.path) {
                    document.location.href = TJG.path;
                  }
                  else {
                    document.location.href = document.domain;
                  }
                });
              }
              else if (d.link_device_url) { // Link device
                $('.continue_link_device').click(function(){
                  if (TJG.vars.isAndroid &&  TJG.android_market_url) {
                    document.location.href = TJG.android_market_url;
                  }
                  else if (TJG.vars.isIos && TJG.ios_link_device_url) {
                    document.location.href = TJG.ios_link_device_url;
                  }
                  else {
                    if (TJG.path) {
                      document.location.href = TJG.path;
                    }
                    else {
                      document.location.href = document.domain;
                    }
                  }
                });
              }
              else {
                $('.continue_link_device').click(function(){
                  if (TJG.path) {
                    document.location.href = TJG.path;
                  }
                  else {
                    document.location.href = document.domain;
                  }
                });
              }
            }
            else {
              var error = 'There was an issue with registering your account';
              if (d.error && d.error[0]) {
                if (d.error[0][0] == 'birthdate') {
                  error = 'Sorry we are currently unable to process your request'
                }
                else if (d.error[0][0] && d.error[0][1]) {
                  error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div class="title_2 center">Oops!</div>',
                '<div class="dialog_content center">', error ,'.</div>',
                '<div class="sign_up_again"><div class="button red try_again">Try Again</div></div>',
              ].join('');
              $('.register_progess').html(msg);
            }
            $('.sign_up_again').click(function(){
              $('.register_progess').html('');
              $('.register_form').animate({ height: form_height + "px" }, animateSpd);
            });
          },
          error: function() {
            var error = 'There was an issue';
            msg = [
              '<div class="title_2 center">Oops!</div>',
              '<div class="dialog_content center">', error ,'.</div>',
              '<div id="sign_up_again"><div class="button red try_again">Try Again</div></div>',
            ].join('');
            $('.register_progess').html(msg);
            $('.sign_up_again').click(function(){
               $('.register_progess').html('');
               $('.register_form').animate({ height: form_height + "px" }, animateSpd);
            });
          }
        });
      }
    });
  },

  showAcceptTos : function () {
    var animateSpd = "fast";
    $("#accept_tos_dialog_content").parent().css("height", "250px");
    $("#accept_tos_dialog_content").html($('#accept_tos_dialog_content_placeholder').html());
    setTimeout(function() {
      TJG.utils.centerDialog("#accept_tos_dialog");
      TJG.repositionDialog = ["#accept_tos_dialog"];
      $("#home").hide();
      $("#accept_tos_dialog").fadeIn();
    }, 50);

    $('#accept_tos_dialog form').submit(function(e){
      e.preventDefault();
      var rurl, hasError = false;
      rurl = $(this).attr('action');
      $(".tos_error").hide();
      if(!$('#gamer_terms_of_service').attr('checked')) {
        $(".tos_error").html('Please agree to the terms and conditions');
        hasError = true;
      }
      if (hasError) {
        $(".tos_error").show();
      }
      else if (hasError != true) {
        var loader = [
          '<div class="dialog_title title_2">Updating</div>',
          '<div class="dialog_image"></div>'
        ].join('');
        $("#accept_tos_dialog_content").html(loader);
        $("#accept_tos_dialog_content").parent().animate({ height: "100px", }, animateSpd);
        $.ajax({
          type: 'POST',
          url: rurl,
          cache: false,
          timeout: 15000,
          dataType: 'json',
          data: {
            '_method': 'put',
            'authenticity_token': $('#authenticity_token').val(),
            'tos_version': $('#tos_version').val()
          },
          success: function(d) {
            var msg;
            if (d.success) {
              document.location.href = TJG.path;
            }
            else {
              var error = 'There was an issue processing your request';
              if (d.error && d.error[0]) {
                if (d.error[0][0] && d.error[0][1]) {
                  error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
                '<div class="dialog_content"><div>', error ,'.</div> <div id="accept_tos_again"><div class="button grey dialog_button">Try Again</div></div></div>',
              ].join('');
              $("#accept_tos_dialog_content").html(msg);
            }
            $('#accept_tos_again').click(function(){
              TJG.ui.showAcceptTos();
            });
          },
          error: function() {
            var error = 'There was an issue';
            msg = [
              '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
              '<div class="dialog_content"><div>', error ,'.</div><div id="accept_tos_again"><div class="button grey dialog_button">Try Again</div></div></div>',
            ].join('');
            $("#accept_tos_dialog_content").html(msg);
            $('#accept_tos_again').click(function(){
               TJG.ui.showAcceptTos();
            });
          }
        });
      }
    });
  },

  showAddHomeDialog : function() {
    var startY = startX = 0,
    options = {
      message: '<div>Add <span class="bold">Tapjoy</span> to your home screen.</div><div class="bookmark"><span>Just tap </span><span class="bookmark_icon"></span><span> and select </span><span class="bookmark_btn"></span></div>',
      animationIn: 'fade',
      animationOut: 'fade',
      startDelay: 2000,
      lifespan: 10000,
      bottomOffset: 14,
      expire: 0,
      arrow: true,
      iterations: 5
    },
    theInterval, closeTimeout, el, i, l,
    expired = TJG.utils.getLocalStorage("tjg.bookmark.expired"),
    shown = TJG.utils.getLocalStorage("tjg.bookmark.shown");
    if (TJG.utils.isNull(shown)) {
      shown = 0;
    }
    shown = parseInt(shown);
    if (expired == "true") {
      return;
    }
    if (shown >= 4) {
      TJG.utils.setLocalStorage("tjg.bookmark.expired", "true");
    }
    TJG.vars.version =  TJG.vars.version ?  TJG.vars.version[0].replace(/[^\d_]/g,'').replace('_','.')*1 : 0;
    expired = expired == 'null' ? 0 : expired*1;
    var div = document.createElement('div'), close;
    div.id = 'addToHome';
    div.style.cssText += 'position:absolute;-webkit-transition-property:-webkit-transform,opacity;-webkit-transition-duration:0;-webkit-transform:translate3d(0,0,0);';
    div.style.left = '-9999px';
    div.className = (TJG.vars.isIPad ? 'ipad wide' : 'iphone');
    var m =  options.message;
    var a = (options.arrow ? '<span class="arrow"></span>' : '');
    var t = [
      m,
      a
    ].join('');
    div.innerHTML = t;
    document.body.appendChild(div);
    el = div;

    function transitionEnd () {
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      el.style.webkitTransitionProperty = '-webkit-transform';
      el.style.webkitTransitionDuration = '0.2s';
      if (closeTimeout) {
        clearInterval(theInterval);
        theInterval = setInterval(setPosition, options.iterations);
      }
      else {
        el.parentNode.removeChild(el);
      }
    }
    function setPosition () {
      var matrix = new WebKitCSSMatrix(window.getComputedStyle(el, null).webkitTransform),
      posY = TJG.vars.isIPad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
      posX = TJG.vars.isIPad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX;
      if (posY == matrix.m42 && posX == matrix.m41) return;
      clearInterval(theInterval);
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      setTimeout(function () {
        el.addEventListener('webkitTransitionEnd', transitionEnd, false);
        el.style.webkitTransform = 'translate3d(' + posX + 'px,' + posY + 'px,0)';
      }, 0);
    }
    function addToHomeClose () {
      clearInterval(theInterval);
      clearTimeout(closeTimeout);
      closeTimeout = null;
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      var posY = TJG.vars.isIPad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
      posX = TJG.vars.isIPad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX,
      opacity = '0.95',
      duration = '0';
      el.style.webkitTransitionProperty = '-webkit-transform,opacity';
      switch (options.animationOut) {
        case 'drop':
        if (TJG.vars.isIPad) {
          duration = '0.4s';
          opacity = '0';
          posY = posY + 50;
        } else {
          duration = '0.6s';
          posY = posY + el.offsetHeight + options.bottomOffset + 50;
        }
        break;
        case 'bubble':
        if (TJG.vars.isIPad) {
          duration = '0.8s';
          posY = posY - el.offsetHeight - options.bottomOffset - 50;
        }
        else {
          duration = '0.4s';
          opacity = '0';
          posY = posY - 50;
        }
        break;
        default:
        duration = '0.8s';
        opacity = '0';
      }
      el.addEventListener('webkitTransitionEnd', transitionEnd, false);
      el.style.opacity = opacity;
      el.style.webkitTransitionDuration = duration;
      el.style.webkitTransform = 'translate3d(' + posX + 'px,' + posY + 'px,0)';
    }
    setTimeout(function () {
      var duration;
      startY = TJG.vars.isIPad  ? window.scrollY : window.innerHeight + window.scrollY;
      startX = TJG.vars.isIPad  ? window.scrollX : Math.round((window.innerWidth - el.offsetWidth)/2) + window.scrollX;
      el.style.top = TJG.vars.isIPad ? startY + options.bottomOffset + 'px' : startY - el.offsetHeight - options.bottomOffset + 'px';
      el.style.left = TJG.vars.isIPad ? startX + (TJG.vars.version >=5 ? 160 : 208) - Math.round(el.offsetWidth/2) + 'px' : startX + 'px';
      switch (options.animationIn) {
        case 'drop':
        if (TJG.vars.isIPad) {
          duration = '0.6s';
          el.style.webkitTransform = 'translate3d(0,' + -(window.scrollY + options.bottomOffset + el.offsetHeight) + 'px,0)';
        }
        else {
          duration = '0.9s';
          el.style.webkitTransform = 'translate3d(0,' + -(startY + options.bottomOffset) + 'px,0)';
        }
        break;
        case 'bubble':
        if (TJG.vars.isIPad) {
          duration = '0.6s';
          el.style.opacity = '0'
          el.style.webkitTransform = 'translate3d(0,' + (startY + 50) + 'px,0)';
        }
        else {
          duration = '0.6s';
          el.style.webkitTransform = 'translate3d(0,' + (el.offsetHeight + options.bottomOffset + 50) + 'px,0)';
        }
        break;
        default:
        duration = '1s';
        el.style.opacity = '0';
      }
      setTimeout(function () {
        el.style.webkitTransitionDuration = duration;
        el.style.opacity = '0.95';
        shown = shown + 1;
        TJG.utils.setLocalStorage("tjg.bookmark.shown", shown);
        el.style.webkitTransform = 'translate3d(0,0,0)';
        el.addEventListener('webkitTransitionEnd', transitionEnd, false);
        }, 0);
        closeTimeout = setTimeout(addToHomeClose, options.lifespan);
    }, options.startDelay);
    window.addToHomeClose = addToHomeClose;
  },

  showDeviceSelection : function(devices, showClose) {
    var fadeSpd = 350, fadeSpdFast = 250, fadeSpdSlow = 700;
    var div = document.createElement('div');
    var id = "deviceSelect";
    var obj = "#" + id;
    div.id = id;
    div.style.cssText += 'position:absolute;';
    var d = [];
    var a = [];
    var path;
    if (TJG.path) {
      path = TJG.path.replace(/\/$/, '');
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    var device_found = false, device_count = 0, device_data, matched_data;
    $.each(devices, function(i,v){
      var device_type = v.device_type;
      if (!TJG.utils.isNull(device_type)
        && TJG.vars.device_type
          && (device_type.toLowerCase() == TJG.vars.device_type.toLowerCase())) {
        device_count++;
        device_found = true;
        device_data = v.data;
        matched_data - v.data;
        d.push('<a href="', path ,'/switch_device?data=', v.data ,'">');
          d.push('<li class="button grey">');
            d.push(v.name);
          d.push('</li>');
        d.push('</a>');
      }
      else if (!TJG.vars.isTouch){ // Web
        a.push('<a href="', path ,'/switch_device?data=', v.data ,'">');
          a.push('<li class="button grey">');
            a.push(v.name);
          a.push('</li>');
        a.push('</a>');
      }
    });
    var m = "", link_device = "", close = "";
    if (showClose) {
      close = '<div class="close_button close_device_select"></div>';
    }
    // If no matching device is found, link user to appropriate linking URL
    if (device_found == false) {
      if (TJG.vars.isIos && TJG.ios_link_device_url) {
        link_device = '<a href="' + TJG.ios_link_device_url + '"><div class="button grey">Connect My Device</div></a>';
        m =  [
          close,
          '<div class="dialog_header bold">Please connect your device:</div>',
          '<div class="dialog_content">',
            '<ul>',
              link_device,
            '</ul>',
          '</div>'
        ].join('');
      }
      else if (TJG.vars.isAndroid &&  TJG.android_market_url) {
        link_device = '<a href="' + TJG.android_market_url + '"><div class="button grey">Connect My Device</div></a>';
        m =  [
          close,
          '<div class="dialog_header bold">Please connect your Android device:</div>',
          '<div class="dialog_content">',
            '<ul>',
              link_device,
            '</ul>',
          '</div>'
        ].join('');
      }
      else if (!TJG.vars.isTouch) { // Web - Allow user to select device
        m =  [
          close,
          '<div class="dialog_header bold">Please select your device:</div>',
          '<div class="dialog_content">',
            '<ul>',
              a.join(''),
            '</ul>',
          '</div>'
        ].join('');
      }
    }
    else {
      var other = "";
      if (TJG.vars.isAndroid &&  TJG.android_market_url) {
        other = '<a href="' +  TJG.android_market_url + '"><div class="button grey">Other</div></a>';
      }
      else if (TJG.vars.isIos && TJG.ios_link_device_url) {
        other = '<a href="' +  TJG.ios_link_device_url + '"><div class="button grey">Other</div></a>';
      }
      m =  [
        close,
        '<div class="dialog_header bold">Please select your current device:</div>',
        '<div class="dialog_content">',
          '<ul>',
            d.join(''),
            other,
          '</ul>',
        '</div>'
      ].join('');
    }
    div.innerHTML = m;
    document.body.appendChild(div);
    var h = parseInt(($(window).height()/2)-($(obj).outerHeight()+16/2));
    var w = parseInt(($(window).width()/2)-($(obj).outerWidth()/2));
    if (h <= 0) {
      h = 36;
    }
    $(obj).css('top',  h + "px");
    $(obj).css('left', w + "px");
    $("#jqt >*").each(function(){
      $(this).animate({opacity: 0.025}, fadeSpd, function() {
        $(obj).fadeIn(fadeSpd);
      });
    });
    $('.close_device_select').click(function() {
      $(obj).fadeOut(fadeSpd);
      $("#jqt >*").each(function(){
        $(this).animate({opacity: 1}, fadeSpd, function() {
          $(obj).remove();
        });
      });
    });
  },

  homeInit : function () {
    var jQT = new $.jQTouch({
      slideSelector: '#jqt',
    });
    var fadeSpd = 350, fadeSpdFast = 250, fadeSpdSlow = 700;
    var install = TJG.utils.getParam("register_device");

    // Enable bookmarking modal
    if (TJG.vars.isIos || TJG.vars.hasHomescreen) {
      TJG.ui.showAddHomeDialog();
    }
    var expand = TJG.utils.getLocalStorage("tjg.feat_review.expand");
    if (expand == "true") {
      $(".feat_toggle").removeClass('collaspe');
      $(".feat_review").removeClass('min');
      $(".app_review").show();
    }
    // Checks if new user. If so, shows intro tutorial
    var repeat = TJG.utils.getLocalStorage("tjg.new_user");
    if (install.indexOf("true") != -1) {
      TJG.utils.centerDialog("#register_device");
      $("#register_device").fadeIn(fadeSpd);
      if (repeat != "false") {
         $("#register_device .close_dialog").click(function() {
           showIntro();
         });
      }
    }
    // Cookie is missing, so prompt user to select device
    else if (TJG.require_select_device && TJG.select_device) {
      TJG.ui.showDeviceSelection(TJG.select_device, false);
    }
    else if (repeat != "false") {
      showIntro();
    }
    // If user has multiple devices, enable device selection UI
    if (TJG.select_device && (TJG.select_device.length > 1)) {
      $('.device_switch').html("wrong device?");
      $('.device_name').addClass("has_switch");
      $('.device_info').css('cursor','pointer');
      $('.device_info').click(function(){
        TJG.ui.showDeviceSelection(TJG.select_device, true);
      });
    }

    function showIntro() {
      var div = document.createElement('div'), close;
      var id = "newUser";
      var obj = "#" + id;
      div.id = id;
      div.style.cssText += 'position:absolute;';
      var m =  '<div class="close_button"></div><div class="dialog_content bold">How does it work?</div><div>All your games are listed below. Click the buttons next to the apps to start earning currency.</div>';
      var a = '<span class="arrow"></span>';
      var t = [
        m,
        a
      ].join('');
      div.innerHTML = t;
      document.body.appendChild(div);
      var pos = $("#home .offer_list").position();
      if (pos) {
        var top = pos.top;
        var elW = $(obj).outerWidth();
        var winW = $(window).width();
        var w = parseInt((winW-elW)/2);
        $(obj).css({
          "top": top - $(obj).outerHeight() - 12 + "px",
          "left": w + "px"
        });
        $("#home").animate({opacity: 0.25}, fadeSpd, function(){
          $(obj).fadeIn(fadeSpd);
        });
        $("#home, #newUser .close_button").click(function() {
          $("#home").animate({opacity: 1}, fadeSpd);
          $(obj).fadeOut(fadeSpd);
          TJG.utils.setLocalStorage("tjg.new_user", "false");
        });
      }
    }

    TJG.ui.loadRatings();

    function slidePage(el,dir) {
      if (dir == 'right') {
        dir = 'slideright'
      }
      else {
        dir = 'slideleft'
      }
      jQT.goTo(el, dir);
    }

    function getOfferWalls() {
      $("#home").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#home .content_wrapper").fadeOut("fast");
        }
      });
      $("#earn").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#earn .content_wrapper").fadeOut("fast");
        }
      });
      $("#more_games").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#more_games .content_wrapper").fadeOut("fast");
        }
      });
      $("#feat_app").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#feat_app .content_wrapper").fadeOut("fast");
        }
      });
      $("#home").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#home .content_wrapper").fadeIn("fast");
        }
      });
      $("#earn").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#earn .content_wrapper").fadeIn("fast");
        }
      });
      $("#more_games").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#more_games .content_wrapper").fadeIn("fast");
        }
      });
      $("#feat_app").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#feat_app .content_wrapper").fadeIn("fast");
        }
      });
      $(".get_offerwall_jsonp").each(function() {
        var i = 0;
        $(this).click(function(){
          slidePage("#earn", "left");
          $("#earn_content").empty();
          var url = $(this).attr("jsonp_url"), appId = $(this).attr("id"), appName = $(this).attr("app_name"), currencyName = $(this).attr("currency");
          if (!TJG.appOfferWall[appId]) {
            TJG.appOfferWall[appId] = {};
          }
          TJG.appOfferWall[appId]['jsonp_url'] = url;
          var title = 'Complete any of the offers below to earn <span class="bold">' + currencyName + '</span> for <span class="bold">' + appName + '</span>';
          $("#app_title").html(title).show();
          if (url) {
            TJG.ui.showLoader();
            $.ajax({
              url: url+"&callback=?",
              dataType: 'json',
              timeout: 15000,
              success: function(data) {
                TJG.ui.hideLoader();
                if (data.OfferArray) {
                  var offers = data.OfferArray;
                  offerOffset = offers.length;
                  if (data.MoreDataAvailable) {
                    TJG.appOfferWall[appId]['offers_left'] = data.MoreDataAvailable;
                  }
                  else {
                    TJG.appOfferWall[appId]['offers_left'] = 0;
                  }
                  TJG.appOfferWall[appId]['offset'] = offerOffset;
                  var offerRows = TJG.ui.getOfferRow(offers, currencyName);
                  var t = [
                    '<ul id="offerwall_id-', appId ,'">',
                      offerRows,
                    '</ul>',
                  ];
                  if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                    t.push('<div class="more_button_wrapper"><div class="get_more_apps" app_id="' + appId + '"><div class="get_more_apps_content">Load More</div></div></div>');
                  }
                  else {
                    t.push('<div class="more_button_wrapper"><div class="back_to_top grey_button"><div class="grey_button_content">Back to Top</div></div></div>');
                    $(".back_to_top").click(function(){
                      TJG.utils.scrollTop();
                    });
                  }
                  t = t.join('');
                  $("#earn_content").html(t).fadeIn(fadeSpd, function(){
                    TJG.utils.loadImages(".offer_image_loader_wrapper");
                  });
                  var isLoading = false;
                  var hasFailed = false;
                  $(".get_more_apps").click(function(){
                    if (isLoading) { return; }
                    $(".get_more_apps_content").html('<div class="image_loader"></div>');
                    var appId = $(this).attr("app_id");
                    $(".load_more_loader").show();
                    if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                      var url = TJG.appOfferWall[appId]['jsonp_url'];
                      url = url + "&start=" + TJG.appOfferWall[appId]['offset'] + "&max=25&callback=?";
                      isLoading = true;
                      $.ajax({
                        url: url,
                        dataType: 'json',
                        timeout: 15000,
                        success: function(data) {
                          if (data.OfferArray) {
                            var offers = data.OfferArray;
                            if (data.MoreDataAvailable) {
                              TJG.appOfferWall[appId]['offers_left'] = data.MoreDataAvailable;
                            }
                            else {
                              TJG.appOfferWall[appId]['offers_left'] = 0;
                            }
                            TJG.appOfferWall[appId]['offset'] = TJG.appOfferWall[appId]['offset'] + 25;
                            var moreOfferRows = TJG.ui.getOfferRow(offers, currencyName, i, true);
                            $("#offerwall_id-" + appId).append(moreOfferRows);
                            var el = ".offer_item_" + i;
                            $.each($(el), function(n,o) {
                              $(o).fadeIn(fadeSpd);
                            });
                            TJG.utils.loadImages(".offer_image_loader_wrapper");
                            if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                              $(".get_more_apps_content").html("Load More");
                            }
                            else {
                              $(".more_button_wrapper").html('<div class="back_to_top grey_button"><div class="grey_button_content">Back to Top</div></div>');
                              $(".back_to_top").click(function(){
                                TJG.utils.scrollTop();
                              });
                            }
                          }
                          isLoading = false;
                        },
                        error: function () {
                          var m = [
                            '<div class="center">There was an issue fetching more offers. Please try again.</div>'
                          ].join('');
                          if (!hasFailed) {
                            $("#offerwall_id-" + appId).append(m).fadeIn(fadeSpd);
                          }
                          hasFailed = true;
                          $(".get_more_apps_content").html("Load More");
                          $(".load_more_loader").hide();
                          isLoading = false;
                        }
                      });
                      i++;
                    }
                  });
                }
              },
              error: function() {
                TJG.ui.hideLoader();
                var m = [
                 '<div class="center">There was an issue. Please try again</div>'
                ].join('');
                $("#earn_content").html(m).fadeIn(fadeSpd);
                TJG.utils.scrollTop();
              }
            });
          }
          else {
            var m = [
              '<div class="center">There was an issue. Please try again</div>'
            ].join('');
            $("#earn_content").html(m).fadeIn(fadeSpd);
            TJG.utils.scrollTop();
         }
        });
      });
    }

    function reloadOfferWalls () {
      $(".get_offerwall_jsonp").unbind("click");
      getOfferWalls();
    }

    function getMoreGames() {
      $(".more_apps_path").click(function() {
        slidePage("#more_games", "left");
        $("#recommended_games_button").addClass("dark_grey").removeClass("grey");
        $("#top_grossing_games_button").addClass("grey").removeClass("dark_grey");
        $("#top_grossing_games_button_arrow").hide();
        $("#recommended_games_button_arrow").show();
        if (TJG.moreAppOfferWall) {
          $("#more_games_content").html(TJG.moreAppOfferWall).fadeIn(fadeSpdSlow, function() {
            TJG.utils.loadImages(".offer_image_loader_wrapper");
            TJG.ui.loadRatings();
          });
        }
        else {
          TJG.ui.showLoader();
          $.ajax({
            url: TJG.more_games_editor_picks,
            timeout: 15000,
            success: function(c) {
              TJG.moreAppOfferWall = c;
              TJG.ui.hideLoader();
              $("#more_games_content").html(c).fadeIn(fadeSpd, function(){
                TJG.utils.loadImages(".offer_image_loader_wrapper");
                TJG.ui.loadRatings();
              });
            },
            error: function() {
              var m = [
                '<div>There was an issue. Please try again</div>'
              ].join('');
              $("#more_games_content").html(m).fadeIn(fadeSpd);
            }
          });
        }
      });
    }

    function getTopGames() {
      $("#top_grossing_games_tab").click(function() {
        $("#top_grossing_games_button").addClass("dark_grey").removeClass("grey");
        $("#recommended_games_button").addClass("grey").removeClass("dark_grey");
        $("#recommended_games_button_arrow").hide();
        $("#top_grossing_games_button_arrow").show();
        $("#recommended_games_tab").unbind("click");
        $("#recommended_games_tab").click(function() {
          $("#recommended_games_button").addClass("dark_grey").removeClass("grey");
          $("#top_grossing_games_button").addClass("grey").removeClass("dark_grey");
          $("#top_grossing_games_button_arrow").hide();
          $("#recommended_games_button_arrow").show();
          if (TJG.moreAppOfferWall) {
            $("#more_games_content").fadeOut(fadeSpdFast, function () {
              $("#more_games_content").html(TJG.moreAppOfferWall).fadeIn(fadeSpdFast, function(){
                TJG.utils.loadImages(".offer_image_loader_wrapper");
                TJG.ui.loadRatings();
              });
            });
          }
        });
        if (TJG.topAppOfferWall) {
          $("#more_games_content").fadeOut(fadeSpdFast, function () {
            $("#more_games_content").html(TJG.topAppOfferWall).fadeIn(fadeSpdSlow, function() {
              TJG.utils.loadImages(".offer_image_loader_wrapper");
              TJG.ui.loadRatings();
            });
          });
        }
        else {
          TJG.ui.showLoader();
          $.ajax({
            url: TJG.more_games_popular,
            timeout: 15000,
            success: function(c) {
              TJG.topAppOfferWall = c;
              TJG.ui.hideLoader();
              $("#more_games_content").fadeOut(fadeSpdFast, function () {
                $("#more_games_content").html(c).fadeIn(fadeSpdFast, function() {
                  TJG.utils.loadImages(".offer_image_loader_wrapper");
                  TJG.ui.loadRatings();
                });
              });
            },
            error: function () {
              var m = [
                '<div>There was an issue. Please try again</div>'
              ].join('');
              $("#more_games_content").fadeOut(fadeSpdFast, function () {
                $("#more_games_content").html(m).fadeIn(fadeSpdFast);
              });
            }
          });
        }
      });
    }
    function featuredReview() {
      $(".feat_app_url").click(function() {
         slidePage("#feat_app", "left");
      });
    }
    getOfferWalls();
    getMoreGames();
    getTopGames();
    featuredReview();
  },

  loadRatings : function () {
    $(".offer_rating, .app_rating").each(function (n,o) {
      var rating = $(this).attr("rating");
      var t = [], max = 5, start = 0;
      if (rating) {
        rating = parseFloat(rating);
      }
      for (var i = 1; i <= 5; i++) {
        var starcls = "star off";
        if (rating >= i) {
          starcls = "star on";
          start++;
        }
        else if (rating > start){
          starcls = "star half";
          start++;
        }
        t.push('<span class="', starcls ,'"></span>');
      }
      $(this).html(t.join('')).fadeIn("slow");
    });
  }

};
