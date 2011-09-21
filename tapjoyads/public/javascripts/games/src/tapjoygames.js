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
    var winH = $(window).height();
    var winW = $(window).width();
    $(el).css('top',  winH/2-$(el).height()/2);
    $(el).css('left', winW/2-$(el).width()/2); 
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
  
  resizeDialogs: function () {
    $.each($(".dialog_wrapper"), function() {
      var h = $(this).outerHeight();
      var c = $(this).children('.   ');
      c.css("height", h - 4 + "px");
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
    TJG.repositionDialog = ["#sign_up_dialog"];
    $("#sign_up_dialog_content").html($('#sign_up_dialog_content_placeholder').html());
    $(".close_dialog").show();
    $("#sign_up_dialog_content").parent().animate({ height: "290px", }, animateSpd);
    $("#sign_up_dialog").fadeIn();
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
               '<div class="dialog_content">A confirmation email has been sent to the address you entered.  Please follow the registration in the email to verify your address and complete the account registration. :)</div>',
               '<div class="dialog_content"><div class="continue_link_device"><div class="button grey dialog_button">Continue</div></div></div>'
              ].join('');
              $('.close_dialog').unbind('click');
              $("#sign_up_dialog_content").parent().animate({ height: "230px", }, animateSpd);
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
                  $('.close_dialog').unbind('click');
                  
                  /*
                  msg = [
                    '<div id="link_device" class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Link Device</div></div>',
                    '<div class="dialog_header">The final step is to link your device to your Tapjoy Games account.  Please continue and click install on the next screen.</div>',
                    '<div class="dialog_content"><div class="link_device_url"><div class="button grey dialog_button">Link Device</div></div></div>'
                  ].join('');
                  */
                  //$("#sign_up_dialog_content").parent().animate({ height: "170px", }, animateSpd);
                  less_pad
                  $("#sign_up_dialog_content").addClass("less_pad");
                  $("#sign_up_dialog_content").html($("#link_device_dialog").html());
                  $('.close_dialog,.link_device_url').click(function(){
                    document.location.href = d.link_device_url;
                  });
                }); 
              }
              else {
                $('.close_dialog,.continue_link_device').click(function(){
                  document.location.href = location.protocol + '//' + location.host;
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
              $("#sign_up_dialog_content").parent().animate({ height: "290px", }, animateSpd);
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
              $("#sign_up_dialog_content").parent().animate({ height: "290px", }, animateSpd);
            });
          }
        });
      }
    });
  },
  
  showAddHomeDialog : function() {
    var startY = startX = 0,
    options = {
      message: 'Add <span class="bold">Tapjoy Games</span> to your home screen.',
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
      TJG.utils.setLocalStorage("tjg.bookmark.expired", true);
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
  
  homeInit : function () {
    var jQT = new $.jQTouch({
      slideSelector: '#jqt',
    });
    var fadeSpd = 350, fadeSpdFast = 250, fadeSpdSlow = 700;
    var install = TJG.utils.getParam("register_device");
    if (TJG.vars.isIos || TJG.vars.isSafari) {
      TJG.ui.showAddHomeDialog();
    }
    var expand = TJG.utils.getLocalStorage("tjg.feat_review.expand");
    if (expand == "true") {
      $(".feat_toggle").removeClass('collaspe');
      $(".feat_review").removeClass('min');
      $(".app_review").show(); 
    }
    var repeat = TJG.utils.getLocalStorage("tjg.repeat_visit");
    if (install.indexOf("true") != -1) {
      TJG.utils.centerDialog("#register_device");
      $("#register_device").fadeIn(fadeSpd); 
    } 
    else if (repeat != "true") {
      /*
      var div = document.createElement('div'), close;
      div.id = 'firstTime';
      div.style.cssText += 'position:absolute;-webkit-transition-property:-webkit-transform,opacity;-webkit-transition-duration:0;-webkit-transform:translate3d(0,0,0);';
      div.style.left = '-9999px';
      var m =  "message";
      var a = '<span class="arrow"></span>';
      var t = [
        m,
        a
      ].join('');
      div.innerHTML = t;
      document.body.appendChild(div);
      */
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
  
(function(window, document) {

    TJG.onload = {

      removeLoader : function () {
        TJG.ui.hideLoader(250,function(){
           $('#jqt').fadeTo(250,1,function(){
             TJG.ui.resizeDialogs();
           });
        });
      },

      loadEvents : function () {
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
          TJG.repositionDialog = [];
        });
        $('#sign_up, #sign_up_form').click(function() {
            TJG.utils.centerDialog("#sign_up_dialog");
            TJG.repositionDialog = ["#sign_up_dialog"];
            TJG.ui.showRegister();
        });
        $('#how_works').click(function(){
          TJG.utils.centerDialog("#how_works_dialog");
          TJG.repositionDialog = ["#how_works_dialog"];
          $("#how_works_dialog").fadeIn(350);
        });
        $('.top_nav_bar').click(function(){
           TJG.utils.centerDialog("#my_account_dialog");
           TJG.repositionDialog = ["#my_account_dialog"];
           $("#my_account_dialog").fadeIn(350);
        });
        $('.my_account_url').click(function(){
          $("#my_account_dialog").fadeOut(350, function() {
            TJG.utils.centerDialog("#my_account_dialog_content");
            TJG.repositionDialog = ["#my_account_dialog_content"];
            $("#my_account_dialog_content").fadeIn(350);
          });
        });
        $('#link_device').click(function(){
          TJG.utils.centerDialog("#link_device_dialog");
          TJG.repositionDialog = ["#link_device_dialog"];
          $("#link_device_dialog").fadeIn(350);
        });
        $('.feat_toggle').click(function(){
          if ($(this).hasClass('collaspe')) {
            $(this).removeClass('collaspe');
            $(".feat_review").removeClass('min');
            $(".app_review").show();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", true);
          }
          else {
            $(this).addClass('collaspe');
            $(".feat_review").addClass('min');
            $(".app_review").hide();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", false);
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
