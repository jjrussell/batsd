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
  me.template = function (str, data) {
    var config = {
      evaluate    : /<%([\s\S]+?)%>/g,
      interpolate : /<%=([\s\S]+?)%>/g,
      escape      : /<%-([\s\S]+?)%>/g
    },
    noMatch = /.^/,
    tmpl,
    func,
    unescape = function (code) {
      return code.replace(/\\\\/g, '\\').replace(/\\'/g, "'");
    };

    tmpl = 'var __p=[],print=function(){__p.push.apply(__p,arguments);};' +
      'with(obj||{}){__p.push(\'' +
      str.replace(/\\/g, '\\\\')
         .replace(/'/g, "\\'")
         .replace(config.escape || noMatch, function (match, code) {
          return "',_.escape(" + unescape(code) + "),'";
        })
         .replace(config.interpolate || noMatch, function (match, code) {
          return "'," + unescape(code) + ",'";
        })
         .replace(config.evaluate || noMatch, function (match, code) {
          return "');" + unescape(code).replace(/[\r\n\t]/g, ' ') + ";__p.push('";
        })
         .replace(/\r/g, '\\r')
         .replace(/\n/g, '\\n')
         .replace(/\t/g, '\\t') +
         "');}return __p.join('');";
    func = new Function('obj', tmpl);
    if (data) { return func(data); }
    return function (data) {
      return func.call(this, data);
    };
  };

  me.fetchData = function ($container, url, params) {
    var jsonp = $container.data("is-jsonp");

    return $.ajax({
      url: url,
      dataType: jsonp ? "jsonp" : undefined,
      data: params
    });
  };

  me.fillElements = function () {
    $(".ajax-loader").each(function () {
      var $$ = $(this),
        $target = $(".ajax-target", $$),
        $placeholder = $(".ajax-placeholder", $$),
        $load_more = $(".ajax-load-more", $$),
        template = me.template($("script", $$).html()),
        url = $$.data("url"),
        immediate = $$.data("immediate-load"),
        params = $$.data("params") || {},
        preloaded = false,
        getSome;

      getSome = function () {
        if (preload && !preloaded) {
          preload.ready(function (data) {
            $target.append(template(data));
            $placeholder.hide();
            return data.MoreDataAvailable ? $load_more.show() : $load_more.hide();
          });

          preloaded = true;
        } else {
          me.fetchData($$, url, params).then(function (data) {
            $target.append(template(data));
          }).fail(function () {
            $(".ajax-error", $$).show();
          }).always(function (data) {
            $placeholder.hide();
            return data.MoreDataAvailable ? $load_more.show() : $load_more.hide();
          });
        }

        $$.unbind("ajax-initiate", getSome);
      };
      $$.bind("ajax-initiate", getSome);

      $load_more.click(function () {
        $placeholder.show();
        $load_more.hide();

        if (me.isNumber(params.start) && me.isNumber(params.max)) {
          params.start += params.max;
        }

        getSome();
      });

      if (immediate) { getSome(); }
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
