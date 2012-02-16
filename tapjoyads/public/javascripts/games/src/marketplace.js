/*jshint evil:true, regexp:false*/
(function () {
  "use strict";

  var me = {};

  // Underscore.js template code
  me.template = function (str, data) {
    var c = {
      evaluate    : /<%([\s\S]+?)%>/g,
      interpolate : /<%=([\s\S]+?)%>/g,
      escape      : /<%-([\s\S]+?)%>/g
    }
      , noMatch = /.^/
      , tmpl
      , unescape = function (code) {
        return code.replace(/\\\\/g, '\\').replace(/\\'/g, "'");
      }
      ;
    tmpl = 'var __p=[],print=function(){__p.push.apply(__p,arguments);};' +
      'with(obj||{}){__p.push(\'' +
      str.replace(/\\/g, '\\\\')
         .replace(/'/g, "\\'")
         .replace(c.escape || noMatch, function (match, code) {
          return "',_.escape(" + unescape(code) + "),'";
        })
         .replace(c.interpolate || noMatch, function (match, code) {
          return "'," + unescape(code) + ",'";
        })
         .replace(c.evaluate || noMatch, function (match, code) {
          return "');" + unescape(code).replace(/[\r\n\t]/g, ' ') + ";__p.push('";
        })
         .replace(/\r/g, '\\r')
         .replace(/\n/g, '\\n')
         .replace(/\t/g, '\\t') +
         "');}return __p.join('');";
    var func = new Function('obj', tmpl);
    if (data) { return func(data); }
    return function (data) {
      return func.call(this, data);
    };
  };

  $(function () {
    // keyboard keys 1,2,3... etc change the media queries
    var responsive_keys = function () {
      var response_iframe = $("<iframe style='display:none; height:2000px; border:0px;' src='" + document.location.href + "'/>")
        , initial_title = $("title").html()
        , ZERO = 48
        , NINE = 57
        ;
      $("body").append(response_iframe);

      $(window).keydown(function (e) {
        var code = parseInt(e.keyCode, 10)
          , breakpoints = [null, 320, 480, 768, 1024, 1200]
          , breakpoint
          ;
        // 48 is keycode for 0 key, 57 is keycode for 9
        code = code < NINE && code > ZERO ? code - ZERO : false;
        breakpoint = breakpoints[code] || "";
        
        if (!breakpoint) {
          response_iframe.hide();
          $(".main").show();
        } else {
          response_iframe.show();
          $(".main").hide();
          response_iframe.css("width", breakpoint);
        }
        $("title").html(breakpoint || initial_title);
      });
    };

    // recursive iframes are bad, m'kay
    if (window.self === window.top) {
      responsive_keys();
    }


    $("[data-jsonp-url]").each(function () {
      var $$ = $(this)
        , url = $$.data("jsonp-url")
        , template = me.template($$.next("script").html())
        ;

      $.ajax({
        url: url,
        dataType: "jsonp",
        success: function (data) {
          $$.html(template(data));
        }
      });
    });
  });
}());
