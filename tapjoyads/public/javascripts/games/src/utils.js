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
    setCookie(name, "", -1);
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
  }

};