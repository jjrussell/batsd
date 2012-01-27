(function(TJG, me) {
  var NUM_MAP = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
  me = me || {};

  me.pluralize = function(words, count) {
    var result;

    if(!words || typeof words === "string") { return words; }

    count = count !== null ? count : 1;

    result = words[NUM_MAP[count]] || words["other"];

    return result;
  };

  me.query = function(key, locale, def_locale) {
    var outer_scope = key.split("."),
        recurse, 
        result;

    // deal with dot notation strings
    recurse = function(scope, current_level) {
      if(!current_level) { return null; }
      if(scope.length === 1) { return current_level[scope[0]]; }

      return recurse(scope.slice(1), current_level[scope[0]]);
    };

    result = recurse(outer_scope, me[locale]);
    result = result || recurse(outer_scope, me[def_locale]);

    return result;
  };

  me.t = function(key, args, opt) {
    var result,
        scope;

    opt = $.extend({
      locale: me.locale,
      count: null 
    }, opt);

    result = me.query(key, opt.locale, me.default_locale);

    result = me.pluralize(result, opt.count);

    if(typeof result !== "string") {
      throw TJG.utils.customError("Did not find translation string: ",
        {key: key, locale: opt.locale, default_locale: me.default_locale}, 
        "Tapjoyi18nError");
    }
    return TJG.utils.basicTemplate(result, args);
  };

  TJG.i18n = me;
}( (typeof TJG === "object" ? TJG : window), 
   (typeof TJG === "object" && TJG.i18n ? TJG.i18n : {}) ));
