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
