TJG.utils = {

  genSym : function() {
    var res = '' + TJG.vars.autoKey;
    TJG.vars.autoKey++;
    return res;
  },

  isNull : function(v) {
    if (typeof v == 'boolean') {
      return false;
    } else if (typeof v == 'number') {
      return false;
    }
    else {
      return v == undefined || v == null || v == '';
    }
  },

  or : function (v, defval) {
    if (this.isNull(v)) {
      return defval;
    }
    return v;
  },

  hideURLBar : function() {
    setTimeout(function() {
      window.scrollTo(0, 1);
    }, 0);
  },

  getOrientation : function() {
    return TJG.vars.orientationClasses[window.orientation % 180 ? 0 : 1];
  },

  updateOrientation : function() {
    var orientation = this.getOrientation();
    TJG.doc.setAttribute("orient", orientation);
  },

  centerDialog : function(el) {
    var h = parseInt(($(window).height()/2)-($(el).outerHeight()+16/2));
    var w = parseInt(($(window).width()/2)-($(el).outerWidth()/2));
    if (h <= 0) {
      h = 36;
    }
    $(el).css('top',  h + "px");
    $(el).css('left', w + "px");
  },

  disableScrollOnBody : function() {
    if (!TJG.vars.isTouch) return;
    document.body.addEventListener("touchmove", function(e) {
      e.preventDefault();
    }, false);
  },

  getParam : function(name) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( window.location.href );
    if( results == null ) return "";
    else return results[1];
  },

  setLocalStorage: function(k,v) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    else {
      try {
        localStorage[k] = v;
      } catch (e) {
        localStorage.clear();
      }
    }
  },

  unsetLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    localStorage.removeItem(k);
  },

  getLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    return localStorage[k];
  },
  
  setCookie: function(name, value, days, years) {
    if (days) {
      var date = new Date();
      var time = 0;
      if (years) {
        time = years*365*24*60*60*1000;
      }
      else {
        time = days*24*60*60*1000;
      }
      date.setTime(date.getTime()+(time));
      var expires = "; expires=" + date.toGMTString();
    }
    else var expires = "";
    document.cookie = name + "=" + value+ expires + "; path=/";
  },
  
  getCookie: function(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
  },
  
  deleteCookie: function(name) {
    setCookie(name, "", -1);
  },
  
  scrollTop : function (delay){
    if (delay == null) {
      delay = "slow";
    }
    $("html, body").animate({scrollTop:0}, delay);
  },

  loadImages: function (el) {
    TJG.vars.scrolling = false;
    var preLoad = 0, padSpace = 0;
    if (TJG.vars.isIos) {
      preLoad = 60;
      padSpace = 80;
    }
    $(el).each(function (n,o) {
      if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
        var img = $(o).children("img:first");
        if ($(img).attr("loaded") == "true") {
          return;
        }
        $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
        $(img).error(function() {
          $(img).attr("src", TJG.blank_img);
        });
      }
    });
    if (!TJG.vars.imageLoaderInit) {
      $(window).scroll( function() {
        if (!TJG.vars.scrolling) {
          TJG.vars.scrolling = true;
          setTimeout( function() {
            $(el).each(function (n,o) {
              var id = $(o).attr("id");
              if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
                var img = $(o).children("img:first");
                if ($(img).attr("loaded") == "true") {
                  return;
                }
                $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
                $(img).error(function() {
                  $(img).attr("src", TJG.blank_img);
                });
              }
            });
            TJG.vars.scrolling = false;
          }, 150);
        }
      });
      $(window).trigger('scroll');
      TJG.vars.imageLoaderInit = true;
    }
  }

};
$.utils = TJG.utils;

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
       path = TJG.path;
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    $("#sign_up_dialog_content").parent().css("height", "270px");
    $("#sign_up_dialog_content").html($('#sign_up_dialog_content_placeholder').html());
    setTimeout(function() {
      TJG.utils.centerDialog("#sign_up_dialog");
      TJG.repositionDialog = ["#sign_up_dialog"];
      $(".close_dialog").show();
      $("#sign_up_dialog").fadeIn();
    }, 50);

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
          '<div class="dialog_title title_2">Registering</div>',
          '<div class="dialog_image"></div>'
        ].join('');
        $("#sign_up_dialog_content").html(loader);
        $("#sign_up_dialog_content").parent().animate({ height: "100px", }, animateSpd);
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
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Success!</div></div>',
                '<div class="dialog_header">Your Tapjoy Games account was sucessfully created!</div>',
               '<div class="dialog_content"><div class="continue_link_device"><div class="button grey dialog_button">Connect My Device</div></div></div>'
              ].join('');
              if (!TJG.vars.isTouch) {
                msg = [
                  '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Success!</div></div>',
                  '<div class="dialog_header">Your Tapjoy Games account was sucessfully created!</div>',
                 '<div class="dialog_content"><div class="continue_link_device"><div class="button grey dialog_button">Continue</div></div></div>'
                ].join('');
              }
              $('.close_dialog').unbind('click');
              $("#sign_up_dialog_content").parent().animate({ height: "140px", }, animateSpd);
              $("#sign_up_dialog_content").html(msg);
              if (d.linked) {
                $('.close_dialog,.continue_link_device').click(function(){
                  if (TJG.path) {
                    document.location.href = TJG.path;
                  }
                  else {
                    document.location.href = document.domain;
                  }
                });
              }
              else if (d.link_device_url) {
                $('.close_dialog,.continue_link_device').click(function(){
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
                $('.close_dialog,.continue_link_device').click(function(){
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
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
                '<div class="dialog_content"><div>', error ,'.</div> <div id="sign_up_again"><div class="button grey dialog_button">Try Again</div></div></div>',
              ].join('');
              $("#sign_up_dialog_content").html(msg);
              $(".close_dialog").hide();
            }
            $('#sign_up_again').click(function(){
              TJG.ui.showRegister();
            });
          },
          error: function() {
            var error = 'There was an issue';
            msg = [
              '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
              '<div class="dialog_content"><div>', error ,'.</div><div id="sign_up_again"><div class="button grey dialog_button">Try Again</div></div></div>',
            ].join('');
            $(".close_dialog").hide();
            $("#sign_up_dialog_content").html(msg);
            $('#sign_up_again').click(function(){
               TJG.ui.showRegister();
            });
          }
        });
      }
    });
  },
  
  showAcceptTos : function () {
    var animateSpd = "fast";
    $("#accept_tos_dialog_content").parent().css("height", "190px");
    $("#accept_tos_dialog_content").html($('#accept_tos_dialog_content_placeholder').html());
    setTimeout(function() {
      TJG.utils.centerDialog("#accept_tos_dialog");
      TJG.repositionDialog = ["#accept_tos_dialog"];
      $(".container").hide();
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
      message: '<div>Add <span class="bold">Tapjoy Games</span> to your home screen.</div><div class="bookmark"><span>Just tap </span><span class="bookmark_icon"></span><span> and select </span><span class="bookmark_btn"></span></div>',
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
      path = TJG.path;
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
      $('.nav_device_info').css('cursor','pointer');
      $('.nav_device_info').click(function(){
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
      $(".more_games_url").click(function() {
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

RegExp.escape = function(text) {
  if (!arguments.callee.sRE) {
    var specials = [
      '/', '.', '*', '+', '?', '|',
      '(', ')', '[', ']', '{', '}', '\\'
    ];
    arguments.callee.sRE = new RegExp(
      '(\\' + specials.join('|\\') + ')', 'g'
    );
  }
  return text.replace(arguments.callee.sRE, '\\$1');
};

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
          friends: selectedFriends
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
          recipients: recipients
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
};

RegExp.escape = function(text) {
  if (!arguments.callee.sRE) {
    var specials = [
      '/', '.', '*', '+', '?', '|',
      '(', ')', '[', ']', '{', '}', '\\'
    ];
    arguments.callee.sRE = new RegExp(
      '(\\' + specials.join('|\\') + ')', 'g'
    );
  }
  return text.replace(arguments.callee.sRE, '\\$1');
};

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
          friends: selectedFriends
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
          recipients: recipients
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
};


(function(window, document) {
  
    TJG.onload = {

      removeLoader : function () {
        TJG.ui.hideLoader(250,function(){
           $('#jqt').fadeTo(250,1);
        });
      },
      
      checkDeviceData: function() {
        var d = new Date();
        var t = d.getTime();
        TJG.vars.c_data = TJG.utils.getCookie('data');
        TJG.vars.ls_data = TJG.utils.getLocalStorage('data');
        TJG.vars.link_ts = TJG.utils.getLocalStorage('link_ts');
        TJG.vars.data_ts = TJG.utils.getLocalStorage('data_ts');
        
        // Set localStorage timestamp for previous registrations
        if (TJG.vars.ls_data && TJG.vars.isIos 
          && !TJG.utils.isNull(TJG.select_device) 
            && (TJG.select_device.length == 1) 
              && TJG.utils.isNull(TJG.vars.link_ts) 
                && TJG.utils.isNull(TJG.vars.data_ts)) {
          TJG.utils.setLocalStorage('data_ts', t);
          TJG.utils.setLocalStorage('link_ts', t);
        }
        // Sets data cookie localStorage
        if (TJG.vars.c_data && !TJG.vars.ls_data) {
          TJG.utils.setLocalStorage('data', TJG.vars.c_data);
          TJG.utils.setLocalStorage('data_ts', t);
          var install = TJG.utils.getParam("register_device");
          if (install.indexOf("true") != -1) {
            TJG.utils.setLocalStorage('link_ts', t);
          }
        }
        // Sets cookie if localStorage exists
        if (!TJG.vars.c_data && TJG.vars.ls_data) {
          TJG.utils.setCookie('data', TJG.vars.ls_data, 365, 1);
        }
      },
      
      loadEvents : function () {
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
          TJG.repositionDialog = [];
        });
        $('#sign_up, #sign_up_form').click(function() {
          TJG.ui.showRegister();
        });
        $('#how_works').click(function(){
          TJG.utils.centerDialog("#how_works_dialog");
          TJG.repositionDialog = ["#how_works_dialog"];
          $("#how_works_dialog").fadeIn(350);
        });
        $('#link_device').click(function(){
          if (TJG.vars.isAndroid &&  TJG.android_market_url) {
            document.location.href = TJG.android_market_url;
          }
          else if (TJG.vars.isIos && TJG.ios_link_device_url) {
            document.location.href = TJG.ios_link_device_url;
          }
        });
        $('.feat_toggle').click(function(){
          if ($(this).hasClass('collaspe')) {
            $(this).removeClass('collaspe');
            $(".feat_review").removeClass('min');
            $(".app_review").show();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", "true");
          }
          else {
            $(this).addClass('collaspe');
            $(".feat_review").addClass('min');
            $(".app_review").hide();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", "false");
          }
        });
        if ($('form#new_gamer_session')) {
          $('form#new_gamer_session').submit(function(e){
            $(".formError").hide();
            var inputs, email, pass, values = {};
            var emailReg = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
            inputs = $('form#new_gamer_session :input*');
            inputs.each(function() {
              if (this.type == 'checkbox' || this.type == 'radio') {
                values[this.name] = $(this).attr("checked");
              }
              else {
                values[this.name] = $(this).val();
              }
              email = values['gamer_session[email]'];
              pass = values['gamer_session[password]'];
              if ( email == '' ) {
                $(".login_error").html('Please enter your email address');
                $(".formError").show();
                e.preventDefault();
              }
              else if ( pass == '' ) {
                $(".login_error").html('Please enter your password');
                $(".formError").show();
                e.preventDefault();
              }
            });
          });
        }
        var w = $('.nav_device_info').width();
        w = w + 24;
        $('.device_name,.device_switch').fadeOut(250, function(){
          $('.nav_device_info').animate({width:"0px"}, 250);
        });
        $('.nav_device').click(function(){
          if ($('.nav_device_info').width() == 0) {
            $('.nav_device_info').animate({width:w + "px"}, 250, function() {
              $('.device_name,.device_switch').fadeIn(250);
            });
          }
          else {
            $('.device_name,.device_switch').fadeOut(250, function(){
              $('.nav_device_info').animate({width:"0px"}, 250);
            });
          }
        });
      },

      checkFlashMessages: function () {
        if($('#flash_error').length > 0) {
          TJG.utils.centerDialog("#flash_error");
          $("#flash_error").fadeIn();
          TJG.repositionDialog = ["#flash_error"];
        }
      }
    };

    TJG.init = function() {
      if (TJG.vars.isIos) {
        TJG.utils.hideURLBar();
      }
      for (var key in TJG.onload) {
        TJG.onload[key]();
      }
    };
    window.addEventListener("load", TJG.init, false);


})(this, document);
