var TJG = {}; TJG.vars = {};
TJG.doc = document.documentElement;
TJG.vars.orientationClasses = ['landscape', 'portrait'];
TJG.vars.isDev = true;
TJG.vars.isSwapped = false;
TJG.vars.isIos = false;
TJG.vars.isTouch = false;
TJG.appOfferWall = {};
TJG.utils = {

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
  }
  
};
TJG.ui = { 
  
  hideLoader : function(delay,fn) {
    if (delay == null) {
      delay = 300;
    }
    setTimeout(function() {
      $('#loader').fadeOut(delay,fn);
    });
  },
  
  showLoader : function(delay,fn) {
    TJG.utils.centerDialog("#loader");
    if (delay == null) {
      delay = 300;
    } 
    setTimeout(function() {
      $('#loader').fadeIn(delay,fn);
    });
  },
  
  removeDialogs : function () {
    $('.dialog_wrapper').fadeOut();
  },
  
  getOffferRow : function (o,c) {
    var t = [];
    t.push('<ul>');
    $.each(o, function(i,v){
      t.push('<li class="offer_item">'); 
        t.push('<div class="offer_image">');
          t.push('<img src="' + v.IconURL + '">');
        t.push('</div>');
        t.push('<div class="offer_text">');
          t.push('<div class="offer_title title">');
            t.push(v.Name);
          t.push('</div>');
          t.push('<div class="offer_info">');
            t.push('<a href="' + v.RedirectURL + '" target="_blank">');
              t.push('<div class="offer_button">');
                t.push('<div class="button blue">');
                  t.push('<span class="amount">');
                    t.push(v.Amount + ' ' + c);
                  t.push('</span>');
                t.push('</div>');
              t.push('</div>'); 
            t.push('</a>');             
          t.push('</div>');
        t.push('</div>');
      t.push('</li>');
    });
    t.push('<ul>');
    return t.join('');    
  },
  
  
  showRegister : function () {
    var hasLinked = true;
    var path = location.pathname.replace(/\/$/, '');
    path = path + "/.."; 
    $.ajax({
      url: path + "/register",
      cache: false,
      success: function(t){
        $("#sign_up_dialog_content").html(t);
        $("#sign_up_dialog").fadeIn();
        $('form#new_gamer').submit(function(e){
          e.preventDefault();
          var rurl, inputs, values = {}, data, hasError = false, emailReg;
          rurl = $(this).attr('action');
          inputs = $('form#new_gamer :input');
          inputs.each(function() {
            if (this.type == 'checkbox' || this.type == 'radio') {
              values[this.name] = $(this).attr("checked");
            }
            else {
              values[this.name] = $(this).val();
            }
          });
          $(".valid_email_error").hide();
          emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
          if(values['gamer[email]'] == '') {
            $("form#new_gamer").after('<span class="valid_email_error">Please enter your email address</span>');
            hasError = true;
          }
          else if(!emailReg.test(values['gamer[email]'])) {
            $("form#new_gamer").after('<span class="valid_email_error">Enter a valid email address</span>');
            hasError = true;
          }
          else if(values['gamer[password]'] == '') {
            $("form#new_gamer").after('<span class="valid_email_error">Please enter a password</span>');
            hasError = true;
          }
          else if(values['gamer[terms_of_service]'] == false) {
            $("form#new_gamer").after('<span class="valid_email_error">Please agree to the Terms of Service</span>');
            hasError = true;
          } 
          if(hasError != true) {
            $.ajax({
              type: 'POST',
              url: rurl,
              cache: false,
              dataType: 'json', 
              data: { 'authenticity_token': values['authenticity_token'], 'gamer[email]': values['gamer[email]'], 'gamer[password]': values['gamer[password]'], 'gamer[referrer]': values['gamer[referrer]'] },
              success: function(d) {
                var msg;
                if (d.success) {
                  hasLinked = false;
                  msg = [
                    '<div class="dialog_title">Success!</div>',
                    '<div class="dialog_header">Your Tapjoy Games account was sucessfully created</div>',
                   '<div class="dialog_content">A confirmation email has been sent to the address you entered.  Please follow the registration in the email to verify your address and complete the account registration. :)</div>'
                  ].join('');
                  $('.close_dialog').unbind('click');
                  if (d.confirm_url) {
                    $('.close_dialog').click(function(){
                      document.location.href = d.confirm_url;
                    });
                  }
                }
                else {
                  var error = 'There was an issue with registering your account';
                  if (d.error) {
                    if (d.error[0][0] && d.error[0][1]) {
                      error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                    }
                  }
                  msg = [
                    '<div class="dialog_title">Opps!</div>',
                    '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please try again.</a></span></div>',
                  ].join('');
                }
                $("#sign_up_dialog_content").html(msg);
                $('#sign_up_again').click(function(){
                  $("#sign_up_dialog_content").html(t);
                });
              },
              error: function() {
              }
            });
          }
        });
      },
      error: function() {
      }
    }); 
  }
};
  
(function(window, document) {
    TJG.ui.showLoader(0);
    /*!
     * master-class v0.1
     * http://johnboxall.github.com/master-class/
     * Copyright 2010, Mobify
     * Freely distributed under the MIT license.
     */
    var classes = [''], classReplaces = {}, device = "", orientationCompute = "";
    var ua = navigator.userAgent;
    var m = /(ip(od|ad|hone)|android)/gi.exec(ua);
    if (m) {
      var v = RegExp(/OS\s([\d+_?]*)\slike/i).exec(ua);
      TJG.vars.version = v != null ? v[1].replace(/_/g, '.') : 4;
      TJG.vars.device = m[2] ? m[1].toLowerCase() : m[1].toLowerCase();
      classReplaces['web'] = TJG.vars.device;
      classes.push('ratio-' + window.devicePixelRatio);
      classReplaces['no-os'] = m[2] ? 'ios' : m[1].toLowerCase(); 
    }
    TJG.vars.width = window.innerWidth;
    TJG.vars.height = window.innerHeight;
    classes.push(window.innerWidth + 'x' + window.innerHeight);
    if ('orientation' in window) {
      var orientationRe = new RegExp('(' + TJG.vars.orientationClasses.join('|') + ')'),
        orientationEvent = ('onorientationchange' in window) ? 'orientationchange' : 'resize',
          currentOrientationClass = classes.push(TJG.utils.getOrientation());
      if (TJG.vars.width > TJG.vars.height) {
        orientationCompute = 'landscape';
      }
      else {
          orientationCompute = 'portrait';
      }
      var isSwapped = false;
      if (TJG.utils.getOrientation() != orientationCompute) {
        classes.push('orientation-swap');
        isSwapped = true;
        TJG.vars.isSwapped = isSwapped;
      }
      if (TJG.vars.device == 'android') {
        if (TJG.vars.width <= 480 && TJG.utils.getOrientationClass() == 'portrait' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
        if (TJG.vars.width <= 800 && TJG.utils.getOrientationClass() == 'landscape' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
      }
      addEventListener(orientationEvent, function() {
          var orientationClass = getOrientationClass();
          if (currentOrientationClass != orientationClass) {
            currentOrientationClass = orientationClass;
            var className = TJG.doc.className;
            TJG.doc.className = className ? className.replace(orientationRe, currentOrientationClass) : currentOrientationClass;
            
         }
      }, false);
    }
    if ('ontouchend' in document) {
      classReplaces['no-touch'] = 'touch';
      TJG.vars.isTouch = true;
    }
    if (TJG.vars.device == 'iphone' || TJG.vars.device == 'ipod' || TJG.vars.device == 'ipad') {
      TJG.vars.isIos = true;
    }
    var test = document.createElement('div');
    test.style.display = 'none';
    test.id = 'mc-test';
    test.innerHTML = '<style type="text/css">@media(-webkit-min-device-pixel-ratio:1.5){#mc-test{color:red}}@media(-webkit-min-device-pixel-ratio:2.0){#mc-test{color:blue}}</style>';
    TJG.doc.appendChild(test);
    var color = test.ownerDocument.defaultView.getComputedStyle(test, null).getPropertyValue('color'), m = /255(\))?/gi.exec(color);
    if (m) {
        classes.push('hd' + (m[1] ? 20 : 15));
        classReplaces['no-hd'] = 'hd';
    }
    TJG.doc.removeChild(test);
    var className = TJG.doc.className;
    for (replace in classReplaces) {              
        className = className.replace(replace, classReplaces[replace]);
    }
    TJG.doc.className = className + classes.join(' ');

    TJG.onload = {
      /*
      disableScrollOnBody : function() {
        if (!TJG.vars.isTouch) return;
        document.body.addEventListener("touchmove", function(e) {
          e.preventDefault();
        }, false);
      },
      */
      loadCufon : function () {
        if (Cufon) {
          Cufon.replace('.title', { fontFamily: 'Cooper Std' });
          Cufon.replace('.title_2', { fontFamily: 'AmerType Md BT' });
        }
      },

      removeLoader : function () {
        $('#jqt').fadeTo(300, 1, function() {
          TJG.ui.hideLoader(300);
        });
      },
      
      loadEvents : function () {
        
        $('#how_works').click(function(){
        });
        
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
        });
        
        /*
        $('#how_works').bind('pageAnimationStart', function(event, info){
          TJG.onload.removeDialog();
        });
        */
        $('#sign_up').click(function(){
          TJG.ui.showRegister();
        });
        
      }
      
    };

    TJG.init = function() {  
      
      TJG.utils.hideURLBar();
      
      for (var key in TJG.onload) {
        TJG.onload[key]();
      }
       
      

    };
    window.addEventListener("load", TJG.init, false);

})(this, document);