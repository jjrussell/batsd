/*jshint evil:true, regexp:false*/
(function () {
  "use strict";

  var me = {};

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

  me.afterAjax = function (data, $container) {
    var $load = $(".ajax-load-more", $container);

    $(".ajax-placeholder", $container).hide();

    $load.attr("disabled", false);

    return data.MoreDataAvailable ? $load.show() : $load.hide();
  };

  me.fetchOffers = function ($container, url, params) {
    return $.ajax({
      url: url,
      data: params,
      dataType: "jsonp",
      error: function () {
        $(".ajax-error", $container).show();
        me.afterAjax({}, $container);
      }
    });
  };

  me.fetchMore = function ($container, url, params) {
    var $load_more = $(".ajax-load-more", $container);

    if ($load_more.attr("disabled")) {
      return;
    }

    $load_more.attr("disabled", "disabled");

    if (me.isNumber(params.start) && me.isNumber(params.max)) {
      params.start += params.max;
    }

    return me.fetchOffers($container, url, params);
  };

  me.fillElements = function () {
    $(".ajax-loader").each(function () {
      var $$ = $(this),
        $target = $(".ajax-target", $$),
        $placeholder = $(".ajax-placeholder", $$),
        $load_more = $(".ajax-load-more", $$),
        template = me.template($$.next("script").html()),
        url = $$.data("jsonp-url"),
        params = $$.data("params") || {};

      $load_more.click(function () {
        $placeholder.show();
        $load_more.hide();
        me.fetchMore($$, url, params).then(function (data) {
          $target.append(template(data));
          me.afterAjax(data, $$);
        });
      });

      me.fetchOffers($$, url, params).then(function (data) {
        $target.append(template(data));
        me.afterAjax(data, $$);
      });
    });
  };


  $(function () {
    me.fillElements();
  });
}());
