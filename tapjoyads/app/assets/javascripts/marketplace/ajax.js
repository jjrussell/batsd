(function (Tap, $, preload) {
  "use strict";

  var me = {},
      _t = window.i18n.t,
      notify = function (message) {
        Tap.Utils.notification({
          message: message
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
        getSome;

      getSome = function () {
        me.fetchData(options, function success(data) {
          $target.append(template(data));
          $$.trigger(options.success_event, arguments);
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

  $(function () {
    me.fillElements();
    me.ajaxForms();

    $(document).bind("ajax-success", function (ev, form, data, status, xhr) {
      notify(_t('shared.success'));
    });

    $(document).bind("ajax-error", function (ev, form, data, status, xhr) {
      notify(_t('games.generic_issue'));
    });
  });
}(window.Tapjoy, window.jQuery, window.jsonp_preloaded));
