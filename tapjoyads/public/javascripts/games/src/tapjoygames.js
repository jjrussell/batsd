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

        TJG.ui.showRegister();

        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
          TJG.repositionDialog = [];
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
          $('form#new_gamer_session input').focus(function() {
            $('form#new_gamer_session .login_error').empty();
          });
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
              if (email == '' || email == 'Email') {
                $(".login_error").html('Please enter your email address');
                $(".formError").show();
                e.preventDefault();
              }
              else if (pass == '' || pass == 'Password') {
                $(".login_error").html('Please enter your password');
                $(".formError").show();
                e.preventDefault();
              }
            });
          });
        }
        var w = $('.device_info').width();
        w = w + 24;
        if (w < 60) {
          w = 60;
        }
        $('.device_info').fadeOut(50, function(){ 
          $('.device_info').animate({width:"0px"}, 250);
        });
        TJG.animating = false;
        TJG.deviceInfoOpen = false;
        function selectDevice(){
          if (TJG.animating) {
            return;
          }
          TJG.animating = true;
          if (TJG.deviceInfoOpen == false) {
            $('.device_info').animate({width:w+"px"}, 250, function(){
              $('.device_info').fadeIn(50);
              $('.plus').addClass('close');
            });
            TJG.deviceInfoOpen = true;
            TJG.animating = false;
          }
          else {
            $('.device_info').fadeOut(50, function() {
              $('.device_info').animate({width:"0px"}, 250);
              $('.plus').removeClass('close');
            });
            TJG.deviceInfoOpen = false;
            TJG.animating = false;
          }
        }
        $('.plus, .mobile_icon').click(function() {
          selectDevice();
        });
        // Placeholder support for non-supported browsers
        var input = document.createElement("input");
        if (('placeholder' in input) == false) {
          $('[placeholder]').focus(function() {
            var me = $(this);
            if (me.val() == '' || me.val() == me.attr('placeholder')) {
              me.val('').removeClass('placeholder');
              if (me.hasClass('password')) {
                me.removeClass('password');
                if ($.browser.msie) { // IE doesn't support changing input type
                  me.prev().hide(); // Hide label
                }
                else {
                  this.type = 'password';
                }
              }
            }
          }).blur(function() {
            var me = $(this);
            if (me.val() == '' || me.val() == me.attr('placeholder')) {
              if (this.type == 'password') {
                me.addClass('password');
                me.addClass('placeholder').val('');
                if ($.browser.msie) { // IE doesn't support changing input type
                  me.prev().show(); // Show label
                }
                else {
                  this.type = 'text';
                }
              }
              else {
                me.addClass('placeholder').val(me.attr('placeholder'));
              }
            }
          }).blur();
          $('label[for=password]').click(function() {
            $(this).hide();
          });
        }
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
    TJG.init();

})(this, document);
