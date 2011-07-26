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
   },   false);
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
    $.each(o, function(i,v){
      t.push('<li class="offer_item clearfix">'); 
        t.push('<div class="offer_image">');
          t.push('<img src="' + v.IconURL + '">');
        t.push('</div>');
        t.push('<div class="offer_text">');
          t.push('<div class="offer_title title">');
            t.push(v.Name);
          t.push('</div>');
          t.push('<div class="offer_info">');
            t.push('<a href="' + v.RedirectURL + '">');
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
    $.ajax({
      url: path + "/register",
      cache: false,
      timeout: 15000,
      success: function(t){
        $("#sign_up_dialog_content").html(t);
        TJG.onload.loadCufon();
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
            $(".email_error").html('Please agree to the Terms of Service');
            hasError = true;
          }
          if(hasError != true) {
            var loader = [
              '<div id="dialog_title title_2">Registering</div>',
              '<div class="dialog_image"></div>'
            ].join('');
            $("#sign_up_dialog_content").html(loader);
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
                   '<div class="dialog_content">A confirmation email has been sent to the address you entered.  Please follow the registration in the email to verify your address and complete the account registration. :)</div>'
                  ].join('');
                  $('.close_dialog').unbind('click');
                  if (d.redirect_url) {
                    $('.close_dialog').click(function(){
                      document.location.href = d.redirect_url;
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
                    '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Opps!</div></div>',
                    '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
                  ].join('');
                }
                $("#sign_up_dialog_content").html(msg);
                TJG.onload.loadCufon();
                $('#sign_up_again').click(function(){
                  $("#sign_up_dialog_content").html(t);
                  TJG.onload.loadCufon();
                });
              },
              error: function() {
                var error = 'There was an issue'; 
                msg = [
                  '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Opps!</div></div>',
                  '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
                ].join('');
                $("#sign_up_dialog_content").html(msg);
                TJG.onload.loadCufon();
                $('#sign_up_again').click(function(){
                  $("#sign_up_dialog_content").html(t);
                  TJG.onload.loadCufon();
                });
              }
            });
          }
        });
      },
      error: function() {
        $("#sign_up_dialog").fadeIn();
        var error = 'There was an issue'; 
        msg = [
          '<div class="dialog_title title">Opps!</div>',
          '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
        ].join('');
        $("#sign_up_dialog_content").html(msg);
        TJG.onload.loadCufon();
        $('#sign_up_again').click(function(){
          TJG.ui.showRegister();
        });
      }
    }); 
  }
};
  
(function(window, document) {

    TJG.onload = {

      loadCufon : function () {
        if (Cufon) {
          Cufon.replace('.title', { fontFamily: 'Cooper Std' });
          Cufon.replace('.title_2', { fontFamily: 'AmerType Md BT' });
        }
      },

      removeLoader : function () {
        TJG.ui.hideLoader(250,function(){
           $('#jqt').fadeTo(250,1);
        });   
      },
      
      loadEvents : function () {
        
        $('#how_works').click(function(){
        });
        
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
        });
        
        $('#sign_up, #sign_up_form').click(function(){
          TJG.utils.centerDialog("#sign_up_dialog");
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