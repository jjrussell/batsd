TJG.utils = {

  slidePage : function(el,dir) {
    if (TJG.ui.jQT === undefined) {
      return;
    }
    if (dir == 'right') {
      dir = 'slideright'
    }
    else {
      dir = 'slideleft'
    }
    TJG.ui.jQT.goTo(el, dir);
  },

  genSym : function() {
    var res = '' + TJG.vars.autoKey;
    TJG.vars.autoKey++;
    return res;
  },

  isNull : function(v) {
    if (typeof v == 'boolean') {
      return false;
    } else if (typeof v == 'number') {
      return false;
    }
    else {
      return v == undefined || v == null || v == '';
    }
  },

  or : function (v, defval) {
    if (this.isNull(v)) {
      return defval;
    }
    return v;
  },

  isArguments : function (obj) {
    return Object.prototype.toString.call(obj) == '[object Arguments]';
  },

  isArray : function (obj) {
    return Object.prototype.toString.call(obj) == '[object Array]';
  },

  hideURLBar : function() {
    setTimeout(function() {
      window.scrollTo(0, 1);
    }, 0);
  },

  getOrientation : function() {
    return TJG.vars.orientationClasses[window.orientation % 180 ? 0 : 1];
  },

  updateOrientation : function() {
    var orientation = this.getOrientation();
    TJG.doc.setAttribute("orient", orientation);
  },

  centerDialog : function(el) {
    var h = parseInt(($(window).height()/2)-($(el).outerHeight()+16/2));
    var w = parseInt(($(window).width()/2)-($(el).outerWidth()/2));
    if (h <= 0) {
      h = 36;
    }
    $(el).css('top',  h + "px");
    $(el).css('left', w + "px");
  },

  getParam : function(name) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( window.location.href );
    if( results == null ) return "";
    else return results[1];
  },

  setLocalStorage: function(k,v) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    else {
      try {
        localStorage[k] = v;
      } catch (e) {
        localStorage.clear();
      }
    }
  },

  unsetLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    localStorage.removeItem(k);
  },

  getLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    return localStorage[k];
  },

  setCookie: function(name, value, days, years) {
    if (days) {
      var date = new Date();
      var time = 0;
      if (years) {
        time = years*365*24*60*60*1000;
      }
      else {
        time = days*24*60*60*1000;
      }
      date.setTime(date.getTime()+(time));
      var expires = "; expires=" + date.toGMTString();
    }
    else var expires = "";
    document.cookie = name + "=" + value+ expires + "; path=/";
  },

  getCookie: function(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
  },

  deleteCookie: function(name) {
    this.setCookie(name, "", -1);
  },

  scrollTop : function (delay){
    if (delay == null) {
      delay = "slow";
    }
    $("html, body").animate({scrollTop:0}, delay);
  },

  loadImages: function (el) {
    TJG.vars.scrolling = false;
    var preLoad = 0, padSpace = 0;
    if (TJG.vars.isIos) {
      preLoad = 60;
      padSpace = 80;
    }
    $(el).each(function (n,o) {
      if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
        var img = $(o).children("img:first");
        if ($(img).attr("loaded") == "true") {
          return;
        }
        $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
        $(img).error(function() {
          $(img).attr("src", TJG.blank_img);
        });
      }
    });

    if (!TJG.vars.imageLoaderInit) {
      $(window).scroll( function() {
        if (!TJG.vars.scrolling) {
          TJG.vars.scrolling = true;
          setTimeout( function() {
            $(el).each(function (n,o) {
              var id = $(o).attr("id");
              if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
                var img = $(o).children("img:first");
                if ($(img).attr("loaded") == "true") {
                  return;
                }
                $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
                $(img).error(function() {
                  $(img).attr("src", TJG.blank_img);
                });
              }
            });
            TJG.vars.scrolling = false;
          }, 150);
        }
      });
      $(window).trigger('scroll');
      TJG.vars.imageLoaderInit = true;
    }
  },

  toArray: function(iterable) {
    var i, res = [];

    if (!iterable) {
      return res;
    } 

    if (typeof iterable.toArray === "function") {
      return iterable.toArray();
    }

    if (this.isArray(iterable) || this.isArguments(iterable)) {
      return Array.prototype.slice.call(iterable);
    }

    for(i in iterable) { 
      if(iterable.hasOwnProperty(i)) {
        res.push(iterable[i]);
      }
    }
    
    return res;
  },

  basicTemplate: function(tpl, object) {
    object = object || {};
    return tpl.replace(/%{(.+?)}/g, function(pattern, key) {
      // undefined is bad m'kay
      if(object[key] === undefined) {
        throw TJG.utils.customError("No matching arg for template: ", {key: key, template: tpl, props: object});
      }
      return object[key];
    });
  },

  sprintf: function(text) {
    var i=1, args=arguments;
    return text.replace(/%s/g, function(pattern){
      return (i < args.length) ? args[i++] : "";
    });
  },

  sprintfTemplate: function(text) {
    var that = this;
    text = [text];
    return function() {
      var args = that.toArray(arguments);
      args = text.concat(args);
      return that.sprintf.apply(this, args);
    };
  },

  customError: function(msg, options, name) {
    var info="", 
        i,
        options = options || {},
        TapjoyCustomError
        stringify = (window.JSON && window.JSON.stringify) || function(t) { return t; };

    name = name || "TapjoyCustomError";

    TapjoyCustomError = function(n,m) {
      this.name = n;
      this.message = m;
    };
    TapjoyCustomError.prototype = Error.prototype;
    
    for(i in options) {
      if(options.hasOwnProperty(i)) {
        info += "\n[ "+i + ": " + stringify( options[i] ) + " ]";
      }
    }

    msg = info ? msg+info : msg;

    return new TapjoyCustomError(name, msg);
  }
};
