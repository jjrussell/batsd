(function (Tap, $, preload) {
  "use strict";

  Tap.offerClicked = false;
  var me = {},
      _t = window.i18n.t,
      notify = function (message) {
        Tap.Utils.notification({
          message: message
        });
      };

  me.bindOfferClick = function() {
    $('a.offer-link').unbind('click');
    $('a.offer-link').click(function(){
      Tap.offerClicked = true;
    });
  };

  me.isNumber = function (value) {
    return Object.prototype.toString.call(value) === "[object Number]";
  };
  // Underscore.js template code
  me.template = Tap.Utils.underscoreTemplate;

  me.processPreload = function (options, success, error, always) {
    var timeoutTimer = window.setTimeout(function () {
      error({});
      always({});
    }, options.timeout);
    preload.ready(function (data) {
      window.clearTimeout(timeoutTimer);
      success(data);
      always(data);
    });
    preload.consumed = true;
  };

  me.fetchData = function (options, success, error, always) {
    if (preload && !preload.consumed) {
      return me.processPreload.apply(this, arguments);
    }

    $.ajax({
      url: options.url,
      dataType: options.is_jsonp ? "jsonp" : undefined,
      data: options.params,
      timeout: options.timeout
    }).done(success).fail(error).always(always);
  };

  me.fillElements = function () {
    $(".ajax-loader").each(function () {
      var $$ = $(this),
        options = {
          url: $$.data("url"),
          params: $$.data("params") || {},
          is_jsonp: $$.data("is-jsonp"),
          immediate: $$.data("immediate-load"),
          success_event: $$.data("success-event") || "ajax-loader-success",
          error_event: $$.data("error-event") || "ajax-loader-error",
          complete_event: $$.data("complete-event") || "ajax-loader-complete",
          timeout: $$.data("timeout") || 15000
        },
        $target = $(".ajax-target", $$),
        $placeholder = $(".ajax-placeholder", $$),
        $load_more = $(".ajax-load-more", $$),
        $script_tag = $("script", $$),
        template = $script_tag.length > 0 ? me.template($script_tag.html()) : function () {},
        getSome,
        refreshOffers;

      getSome = function () {
        me.fetchData(options, function success(data) {
          $target.append(template(data));
          $$.trigger(options.success_event, arguments);
          me.bindOfferClick();
        }, function fail() {
          $(".ajax-error", $$).show();
          $$.trigger(options.error_event, arguments);
        }, function always(data) {
          $placeholder.hide();
          $$.trigger(options.complete_event, arguments);
          return data.MoreDataAvailable ? $load_more.show() : $load_more.hide();
        });

        $$.unbind("ajax-initiate", getSome);
      };
      $$.bind("ajax-initiate", getSome);

      $load_more.click(function () {
        $placeholder.show();
        $load_more.hide();

        if (me.isNumber(options.params.start) && me.isNumber(options.params.max)) {
          options.params.start += options.params.max;
        }
        getSome();
      });

      if (options.immediate) { getSome(); }

      refreshOffers = function() {
        var oldMax = options.params.max, oldStart = options.params.start;
        $target.empty();
        $placeholder.show();
        $load_more.hide();

        options.params.max = oldStart + oldMax;
        options.params.start = 0;

        getSome();

        options.params.max = oldMax;
        options.params.start = oldStart;
      };

      if (Tapjoy.device.idevice || Tapjoy.device.android) {
        window.addEventListener("pageshow", function(){
          if (Tap.offerClicked) {
            Tap.offerClicked = false;
            refreshOffers();
          }
        }, false);
      }

    });
  };

  me.argsToArray = function (args) {
    return Array.prototype.slice.call(args);
  };

  me.ajaxForms = function () {
    $("form.ajax-submit").each(function () {
      var $$ = $(this),
          type = $$.attr("method") || "GET",
          url = $$.attr("action"),
          success_event = $$.data("success-event") || "ajax-success",
          error_event = $$.data("error-event") || "ajax-error",
          complete_event = $$.data("complete-event") || "ajax-complete";

      $$.submit(function (e) {
        var data = $$.serialize();
        e.preventDefault();
        notify(_t("games.loading"));

        $.ajax({
          type: type,
          url: url,
          data: data,
          success: function () {
            var args = me.argsToArray(arguments);
            args.unshift($$);
            $(document).trigger(success_event, args);
          },
          error: function () {
            var args = me.argsToArray(arguments);
            args.unshift($$);
            $(document).trigger(error_event, args);
          },
          complete: function () {
            var args = me.argsToArray(arguments);
            args.unshift($$);
            $(document).trigger(complete_event, args);
          }
        });
      });
    });
  };

  me.fetchImages = function() {
    var width = window.innerWidth;
    var preLoad = 320, padSpace = 320;
    $('#earn .earn-app-icon img').each(function(n, o){
      if (this && Tapjoy.Utils.ViewPort.aboveInView(this, { padding: padSpace, threshold: preLoad })) {
        var el = $(o);
        if (el.attr('loaded')) {
          return true;
        }
        if (width <= 480 && el.attr("source_sm")) {
          el.attr("src", el.attr("source_sm"));
        }
        else if (el.attr("source_med")) {
          el.attr("src", el.attr("source_med"));
        }
        el.load(function(){
          $(this).fadeIn('slow').attr('loaded','true');
        });
        el.error(function(){
          el.attr("src", "data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==");
        });
      }
    });
  };

  $(function () {
    me.fillElements();
    me.ajaxForms();
    me.fetchImages();

    $(document).bind("ajax-success", function (ev, form, data, status, xhr) {
      notify(_t('shared.success'));
    });

    $(document).bind("ajax-error", function (ev, form, data, status, xhr) {
      notify(_t('games.generic_issue'));
    });

    $(window).scroll(Tapjoy.Utils.debounce(me.fetchImages));
    $('.lazy-image-loader').on('ajax-loader-success', me.fetchImages);

  });
}(window.Tapjoy, window.jQuery, window.jsonp_preloaded));
