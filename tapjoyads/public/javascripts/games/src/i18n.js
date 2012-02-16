(function (w, $) {
  "use strict";
  var NUM_MAP = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    , me = w.i18n || {}
    , env = $("body").data("env")
    ;
    

  me.customError = function (msg, options, name) {
    var info = ""
      , i
      , TapjoyCustomError
      , stringify = (window.JSON && window.JSON.stringify) || function (t) { return t; }
      ;

    options = options || {};
    name = name || "TapjoyCustomError";

    me.TapjoyCustomError = function (n, m) {
      this.name = n;
      this.message = m;
    };
    TapjoyCustomError.prototype = Error.prototype;
    
    for (i in options) {
      if (options.hasOwnProperty(i)) {
        info += "\n[ " + i + ": " + stringify(options[i]) + " ]";
      }
    }

    msg = info ? msg + info : msg;

    return new TapjoyCustomError(name, msg);
  };

  me.basicTemplate = function (tpl, object) {
    object = object || {};
    return tpl.replace(/%{(.+?)}/g, function (pattern, key) {
      // undefined is bad m'kay
      if (object[key] === undefined) {
        throw me.customError("No matching arg for template: ", {key: key, template: tpl, props: object});
      }
      return object[key];
    });
  };

  me.pluralize = function (words, count) {
    var result;

    if (!words || typeof words === "string") { return words; }

    count = count !== null ? count : 1;

    result = words[NUM_MAP[count]] || words.other;

    return result;
  };

  me.query = function (key, locale, def_locale) {
    var outer_scope = key.split("."),
        recurse, 
        result;

    // deal with dot notation strings
    recurse = function (scope, current_level) {
      if (!current_level) { return null; }
      if (scope.length === 1) { return current_level[scope[0]]; }

      return recurse(scope.slice(1), current_level[scope[0]]);
    };

    result = recurse(outer_scope, me[locale]);
    result = result || recurse(outer_scope, me[def_locale]);

    return result;
  };

  me.t = function (key, args, opt) {
    var result,
        scope;

    opt = $.extend({
      locale: me.locale,
      count: null 
    }, opt);

    result = me.query(key, opt.locale, me.default_locale);

    result = me.pluralize(result, opt.count);

    if (typeof result !== "string") {
      if (env === "development") {
        throw me.customError("Did not find translation string: ",
          {key: key, locale: opt.locale, default_locale: me.default_locale, result: result}, 
          "Tapjoyi18nError");
      }

      result = "";
    }
    return me.basicTemplate(result, args);
  };

  w.i18n = me;
}(this, jQuery));
