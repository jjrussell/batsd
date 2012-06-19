$(document).ready(function(){

  var _t = window.i18n.t,
      debounce,
      tjmViewMenu = $('#viewSelectMenu'),
      tjmViewContainer = $('#viewSelect').closest('.select-container'),
      selectTrigger = $('#viewSelect'),
      notify = function (message) {
        Tapjoy.Utils.notification({
          message: message
        });
      };

  // Dynamic table content width
  function adjustWidth() {
    if ($('.home .games').length > 0) {
      var width = window.innerWidth;
      if (width <= 480) {
        var imgWidth = $('.app-icon:first').outerWidth(true);
        var btnWidth = $('.myapps-earn:first').outerWidth(true);
        var contentWidth = width - imgWidth - btnWidth - 24;
        $('.details').each(function(){
          $(this).width(contentWidth);
        });
      }
    }
  }
  $(window).bind('resize orientationchange', Tapjoy.Utils.debounce(adjustWidth));

  // Menu Grid
    $('.menu-grid').on('menu-close', function () {
        $(this).removeClass('active');
        $('.menu-dropdown').removeClass('open').addClass('close');
    });
    $('.menu-grid').on('menu-open', function () {
        $(this).addClass('active');
        $('.menu-dropdown').removeClass('close').addClass('open');
    });
    $('.menu-grid').on('click', function () {
        if ($(this).hasClass('active')) {
            $(this).trigger('menu-close');
        }
        else {
            $(this).trigger('menu-open');
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
    if ($('#device-select').hasClass('open')) {
      $('#device-select').removeClass('open').addClass('closed');
      $('.device-change').html('(' + _t('games.change') + ')');
    }
    else {
      $('#device-select').removeClass('closed').addClass('open');
      $('.device-change').html('(' + _t('games.close') + ')');
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

  $('.list-button, .btn, .greenblock, #signup, #login').live("mousedown mouseup mouseout", function(e){
    var el = $(this),
        target = $(e.target),
        which = e.type;

     if(el.hasClass('ui-no-action'))
      return;

    if(which === "mousedown"){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }
  });

  $('.ui-joy-button').bind(Tapjoy.EventsMap.start + ' ' + Tapjoy.EventsMap.end + ' ' + Tapjoy.EventsMap.cancel, function(e){
    var el = $(this),
        which = e.type;

     if(el.hasClass('disabled'))
      return;

    if(which === Tapjoy.EventsMap.start){
      el.addClass('active');
    }else{
      el.removeClass('active');
    }

  });

  (function () {
    var showSuccessMessage = function (gamers, non_gamers) {
      var msg = _t("shared.success"),
          template = function (txt) {
            return "<div>"+txt+"</div>";
          };

      if (gamers.length !== 0) {
        msg += template(_t("games.already_registered",
          { name: gamers.toString().replace(/\,/g, ", ") },
          { count: gamers.length }
        ));
      }
      if (non_gamers.length !== 0) {
        msg += template(_t("games.invites_sent_to",
          { name: non_gamers.toString().replace(/\,/g, ", ") },
          { count: non_gamers.length }
        ));
      }

      notify(msg);
    };

    $('#email-invites-form').on("ajax-success", function (ev, form, data) {
      if (data.success === true) {
        if (data.gamers.length === 0 && data.non_gamers.length === 0) {
          notify(_t('games.provide_other_email'));
        } else {
          showSuccessMessage(data.gamers, data.non_gamers);
          $("#recipients", form).val('');
        }
      } else if (typeof data.error === "string") {
        notify(data.error);
      } else {
        notify(_t('shared.generic_issue'));
      }
    });

  }());

  $('.button-bar').each(function(){
    var $t = $(this),
      radios = $(':radio', $t),
      buttons = $('.ui-joy-button', $t),
      value = $(":checked", $t).val(),
      render;

    render = function(){
      $('.primary', $t).removeClass('primary').addClass('secondary');
      $(':checked', $t).attr('checked', false);

      $('.ui-joy-button[value="' + value + '"]', $t).removeClass('secondary').addClass('primary');
      $('[value="' + value + '"]:radio', $t).attr('checked', 'checked');
    };

    $('.ui-joy-button', $t).click(function(){
      value = $(this).attr("value");

      render();
    });

    render();
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

  $(".submit-child-form").click(function () {
    $("form", this).submit();
    return false;
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


  (function () {
    var $flash = $('#flash-notice, #flash-error');
    if ($flash.length === 0) { return; }

    $flash.each(function () {
      Tapjoy.Utils.notification({
        message: $(this).html(),
        type: $(this).attr("id").match(/error/) ? "error" : "normal"
      });
    });
  }());

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

      heading.text(_t('games.choose_section'));

      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px')
      .css('position', 'absolute')

      fix.css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }
  });

  function handleTabs($anchor) {
    if (!$anchor) { return; }

    var targetSelector = $anchor.attr("href"),
        $target = $(targetSelector);
    $(".buffer").hide();
    $target.show();
    $(".ajax-loader", $target).trigger("ajax-initiate");
  }

  $('li', tjmViewMenu).each(function(){
    var li = $(this);

    li.bind('click', function(){
      $('li', tjmViewMenu).removeClass('active');
      li.addClass('active');
      tjmViewContainer.removeClass('active');
      tjmViewMenu.addClass('hide');
      Tapjoy.Utils.removeMask();

      if(li.hasClass('showAll')){
        $('.row').show().addClass('view-all');
        $('#recommendationsRow').removeClass('nbb');
      }else{
        $('.row').hide().removeClass('view-all');
        if(li.hasClass('showRecommendations')){
          $('#recommendationsRow').show().addClass('nbb');
        }else if(li.hasClass('showGames')){
          $('#gamesRow').show();
        }else if(li.hasClass('showFavorites')){
          $('#favoritesRow').show();
        }
      }

      handleTabs($("a.ui-joy-reveal", li));
      $('.heading', tjmViewContainer).text(li.text());
      return false;
    });
  });

  function manageResize(){
    var recommendationsRow = $('#recommendationsRow');

    if(tjmViewContainer.length != 0 && window.innerWidth < 480){
      tjmViewMenu.css('top', tjmViewContainer.offset().top + (tjmViewContainer.outerHeight(true) - 4) + 'px');

      $('.fix', tjmViewContainer).css({
        width: tjmViewContainer.width() - 4 + 'px'
      });
    }
    if(window.innerWidth > 500){
      $('#recommendations').enableCarouselSwipe();
    }else{
      $('#recommendations').disableCarouselSwipe();
    }

    var rows = $('#content .row');
    if(window.innerWidth > 480){
      if(rows.is(':hidden'))
        rows.show();
    }else{
      if(recommendationsRow.hasClass('nbb'))
        recommendationsRow.show().removeClass('nbb');

      if(!$('#gamesRow').is(':hidden')){
        rows.hide();
        $('li.showGames', tjmViewMenu).trigger('click');
      }
    }
  }

  $(window).bind('resize orientationchange', debounce(manageResize));

  setTimeout(function(){
    // Hide the ios address bar!
    window.scrollTo(0, 1);
  }, 0);

  Tapjoy.delay(function(){
    $('#recommendations').Carousel({
      cssClass : 'complete',
      minHeight: 175
    });

    if(window.innerWidth > 500){
      $('#recommendations').enableCarouselSwipe();
    }else{
      $('#recommendations').disableCarouselSwipe();
    }
  }, 50);

  // Device Switcher
  // Built when menu is opened the first time
  function buildDeviceSwitcher() {
    $("#device-select").each(function () {
      var $this = $(this),
          deviceList = $this.data('list'),
          selectPath = $this.data('select-path'),
          possibleLinks = $this.data('links');

      if (deviceList) {
        var path, device_found = false, device_count = 0, device_data, matched_data;
        var d = [], a = [], m = [];
        if (selectPath) {
          path = selectPath;
        }
        else {
          path = '/switch_device';
        }
        $.each(deviceList, function(i,v){
          var device_type = v.device_type;
          if (!Tapjoy.Utils.isEmpty(device_type) && Tapjoy.device.name && (device_type.toLowerCase() == Tapjoy.device.name.toLowerCase().replace(/simulator/,'').replace(/ /,''))) {
            device_count++;
            device_found = true;
            d.push('<a href="', path ,'?data=', v.data ,'">');
              d.push('<li class="device-item">');
                d.push(v.name);
              d.push('</li>');
            d.push('</a>');
          }
          else if (!Tapjoy.supportsTouch) { // Web
            a.push('<a href="', path ,'?data=', v.data ,'">');
              a.push('<li class="device-item">');
                a.push(v.name);
              a.push('</li>');
            a.push('</a>');
          }
        });
        if (!device_found) {
          if (Tapjoy.device.idevice && possibleLinks.ios) {
            link_device = '<a href="' + possibleLinks.ios + '"><li class="device-item">'+_t('games.connect_my_device')+'</li></a>';
            m =  [
              '<ul>',
                link_device,
              '</ul>'
            ].join('');
          }
          else if (Tapjoy.device.android &&  possibleLinks.android) {
            link_device = '<a href="' + possibleLinks.android + '"><li class="device-item">'+_t('games.connect_my_device')+'</li></a>';
            m =  [
              '<ul>',
                link_device,
              '</ul>'
            ].join('');
          }
          else if (!Tapjoy.supportsTouch) { // Web - Allow user to select device
            m =  [
              '<ul>',
                a.join(''),
              '</ul>'
            ].join('');
          }
        }
        else {
          var other = "";
          if (Tapjoy.device.android &&  possibleLinks.android) {
            other = '<a href="' +  possibleLinks.android + '"><li class="device-item add">'+_t('shared.other')+'</li></a>';
          }
          else if (Tapjoy.device.idevice && possibleLinks.ios) {
            other = '<a href="' +  possibleLinks.ios + '"><li class="device-item add">'+_t('shared.other')+'</li></a>';
          }
          m =  [
            '<ul>',
              d.join(''),
              other,
            '</ul>',
          ].join('');
        }
        $('#device-select-list', $this).html(m);
      }
      $('.menu-grid').off('click', buildDeviceSwitcher);
    });
  }
  $('.menu-grid').on('click', buildDeviceSwitcher);

  if (($('.home').length >0) && Tapjoy.device.idevice) {
    Tapjoy.Plugins.showAddHomeDialog();
  }

  (function () {
    if (window._tjHtmlDone && window._tjStartTime) {
      Tapjoy.Utils.googleLog("Page Html", "load", "Time in ms", (_tjHtmlDone - _tjStartTime));
      Tapjoy.Utils.googleLog("Main.js", "load", "Time in ms", (new Date().getTime() - _tjStartTime));
    }
  }());
});
