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
  } 
  
};
TJG.ui = { 
  
  hideLoader : function(delay,fn) {
    TJG.repositionDialog = [];
    if (delay == null) {
      delay = 300;
    }
    setTimeout(function() {
      $('#loader').fadeOut(delay,fn);
    });
  },
  
  showLoader : function(delay,fn) {
    TJG.utils.centerDialog("#loader");
    TJG.repositionDialog = ["#loader"];
    if (delay == null) {
      delay = 300;
    } 
    setTimeout(function() {
      $('#loader').fadeIn(delay,fn);
    });
  },
  
  removeDialogs : function () {
    $('.dialog_wrapper').fadeOut();
    TJG.repositionDialog = [];
  },
  
  getOffferRow : function (obj,currency,i,hidden) {
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
              t.push('<img src="' + v.IconURL + '">');
              //t.push('<div class="image_loader"></div>');
            t.push('</div>'); 
          t.push('</a>');
          t.push('<div class="offer_text">');
            t.push('<div class="offer_title title">');
              t.push(v.Name);
            t.push('</div>');
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
    var hasLinked = true, path;
    if (TJG.path) {
       path = TJG.path;
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    TJG.repositionDialog = ["#sign_up_dialog"];
    $("#sign_up_dialog_content").html($('#sign_up_dialog_content_placeholder').html());
    TJG.onload.loadCufon();
    $(".close_dialog").show();
    $("#sign_up_dialog_content").parent().animate({ height: "270px", }, 250);
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
      $(".email_error").hide();
      emailReg = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
      if(values['gamer[email]'] == '') {
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
          '<div id="dialog_title title_2">Registering</div>',
          '<div class="dialog_image"></div>'
        ].join('');
        $("#sign_up_dialog_content").html(loader);
        $("#sign_up_dialog_content").parent().animate({ height: "120px", }, 250);
        TJG.onload.loadCufon();
        $.ajax({
          type: 'POST',
          url: rurl,
          cache: false,
          timeout: 15000,
          dataType: 'json', 
          data: { 'authenticity_token': values['authenticity_token'], 'gamer[email]': values['gamer[email]'], 'gamer[password]': values['gamer[password]'], 'gamer[referrer]': values['gamer[referrer]'] },
          success: function(d) {
            var msg;
            if (d.success) {
              hasLinked = false;
              msg = [
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Success!</div></div>',
                '<div class="dialog_header">Your Tapjoy Games account was sucessfully created</div>',
               '<div class="dialog_content">A confirmation email has been sent to the address you entered.  Please follow the registration in the email to verify your address and complete the account registration. :)</div>',
               '<div class="dialog_content"><div class="continue_link_device"><div class="button dialog_button">Continue</div></div></div>'
              ].join('');
              $('.close_dialog').unbind('click');
              $("#sign_up_dialog_content").parent().animate({ height: "230px", }, 250);
              $("#sign_up_dialog_content").html(msg);
              TJG.onload.loadCufon(); 
              if (TJG.vars.isIos == false) {
                  if (d.more_games_url) {
                    $('.close_dialog,.continue_link_device').click(function(){
                      document.location.href = d.more_games_url;
                    });                    
                  }
                  else {
                    document.location.href = location.protocol + '//' + location.host;
                  }
              }
              else if (d.link_device_url) {
                $('.close_dialog,.continue_link_device').click(function(){
                  $('.close_dialog').unbind('click');
                  msg = [
                    '<div id="link_device" class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Link Device</div></div>',
                    '<div class="dialog_header">The final step is to link your device to your Tapjoy Games account.  Please continue and click install on the next screen.</div>',
                    '<div class="dialog_content"><div class="link_device_url"><div class="button dialog_button">Link Device</div></div></div>'
                  ].join('');
                  $("#sign_up_dialog_content").parent().animate({ height: "170px", }, 250);
                  $("#sign_up_dialog_content").html(msg);
                  TJG.onload.loadCufon();
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
              if (d.error) {
                if (d.error[0][0] && d.error[0][1]) {
                  error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
                '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
              ].join('');
              $("#sign_up_dialog_content").html(msg);
              $(".close_dialog").hide();
            }
            $('#sign_up_again').click(function(){
              TJG.ui.showRegister();
              $("#sign_up_dialog_content").parent().animate({ height: "270px", }, 250);
              TJG.onload.loadCufon();
            });
          },
          error: function() {
            var error = 'There was an issue'; 
            msg = [
              '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
              '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
            ].join('');
            $(".close_dialog").hide(); 
            $("#sign_up_dialog_content").html(msg);
            TJG.onload.loadCufon();
            $('#sign_up_again').click(function(){
               TJG.ui.showRegister();
              $("#sign_up_dialog_content").parent().animate({ height: "270px", }, 250);
              TJG.onload.loadCufon();
            });
          }
        });
      }
    });
  }
};
  
(function(window, document) {

    TJG.onload = {
      loadCufon : function (fn,delay) {
        if (!delay) {
          delay = 1;
        }
        if (Cufon) {
          Cufon.replace('.title', { fontFamily: 'Cooper Std' });
          Cufon.replace('.title_2', { fontFamily: 'AmerType Md BT' });
        }
        if (fn) {
          setTimeout(function() { 
            fn;
            }, delay);
        }
      },

      removeLoader : function () {
        TJG.ui.hideLoader(250,function(){
           $('#jqt').fadeTo(250,1);
        });
      },
      
      loadEvents : function () {
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
          TJG.repositionDialog = [];
        });
        $('#sign_up, #sign_up_form').click(function(){
          TJG.utils.centerDialog("#sign_up_dialog");
          TJG.repositionDialog = ["#sign_up_dialog"];
          TJG.ui.showRegister();
        });
        $('#how_works').click(function(){
          TJG.utils.centerDialog("#how_works_dialog");
          TJG.repositionDialog = ["#how_works_dialog"];
          $("#how_works_dialog").fadeIn(350);
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
      
      TJG.utils.hideURLBar();
      for (var key in TJG.onload) {
        TJG.onload[key]();
      }
    };
    window.addEventListener("load", TJG.init, false);

})(this, document);
