var TJG = {}; TJG.vars = {};
TJG.doc = document.documentElement;
TJG.vars.orientationClasses = ['landscape', 'portrait'];
TJG.vars.headerContainer = '#nav_bar';
TJG.vars.contentContainer = '#container';
TJG.vars.scrollContainer = '#scroller';
TJG.vars.isSwapped = false;
TJG.vars.isIos = false;
TJG.vars.isTouch = false;
TJG.utils = {

  addClass : function(element, elClass) {
    var curr = element.className;
    if (!new RegExp(("(^|\\s)" + elClass + "(\\s|$)"), "i").test(curr)) {
      element.className = curr + ((curr.length > 0) ? " " : "") + elClass;
    }
    return element;
  },

  removeClass : function(element, elClass) {
    if (elClass) {
      element.className = element.className.replace(elClass, "");
    } else {
      element.className = "";
      element.removeAttribute("class");
    }
    return element;
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

  getTranslateY : function(element) {
    var transform = element.style.webkitTransform;
    if (transform && transform !== "") {
      var translateY = parseFloat((/translateY\((\-?.*)px\)/).exec(transform)[1]);
    }
    return translateY;
  },

  setTranslateY : function(element, value) {
    element.style.webkitTransform = "translateY(" + value + "px)";
  },

  scrollToY : function(y) {
    var ms = 150;
    var content = document.querySelector(TJG.vars.scrollContainer);
    var top = TJG.utils.getTranslateY(content);
    var currentTop = (top < 0) ? -(top) : top;
    var chunks = (currentTop / 100);
    var totalTime = (ms * chunks);
    totalTime = (totalTime > 750) ? 750 : totalTime;
    content.style.webkitTransition = "-webkit-transform " + totalTime + "ms cubic-bezier(0.1, 0.25, 0.1, 1.0)";
    TJG.utils.setTranslateY(content, y);
    setTimeout(function() {
      content.style.webkitTransition = "none";
    }, totalTime);
  }
};
  
(function(window, document) {
    var classes = [''], classReplaces = {}, device = "", orientationCompute = "";
    var ua = navigator.userAgent;
    var m = /(ip(od|ad|hone)|android)/gi.exec(ua);
    if (m) {
      var v = RegExp(/OS\s([\d+_?]*)\slike/i).exec(ua);
      TJG.vars.version = v != null ? v[1].replace(/_/g, '.') : 4;
      TJG.vars.device = m[2] ? m[1].toLowerCase() : m[1].toLowerCase();
      classReplaces['web'] = TJG.vars.device;
      classes.push('ratio-' + window.devicePixelRatio);
      classReplaces['no-os'] = m[2] ? 'ios' : m[1].toLowerCase(); 
    }
    TJG.vars.width = window.innerWidth;
    TJG.vars.height = window.innerHeight;
    classes.push(window.innerWidth + 'x' + window.innerHeight);
    if ('orientation' in window) {
      var orientationRe = new RegExp('(' + TJG.vars.orientationClasses.join('|') + ')'),
        orientationEvent = ('onorientationchange' in window) ? 'orientationchange' : 'resize',
          currentOrientationClass = classes.push(TJG.utils.getOrientation());
      if (TJG.vars.width > TJG.vars.height) {
        orientationCompute = 'landscape';
      }
      else {
          orientationCompute = 'portrait';
      }
      var isSwapped = false;
      if (TJG.utils.getOrientation() != orientationCompute) {
        classes.push('orientation-swap');
        isSwapped = true;
        TJG.vars.isSwapped = isSwapped;
      }
      if (TJG.vars.device == 'android') {
        if (TJG.vars.width <= 480 && TJG.utils.getOrientationClass() == 'portrait' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
        if (TJG.vars.width <= 800 && TJG.utils.getOrientationClass() == 'landscape' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
      }
      addEventListener(orientationEvent, function() {
          var orientationClass = getOrientationClass();
          if (currentOrientationClass != orientationClass) {
            currentOrientationClass = orientationClass;
            var className = TJG.doc.className;
            
            TJG.doc.className = className ? className.replace(orientationRe, currentOrientationClass) : currentOrientationClass;
            
         }
      }, false);
    }
    if ('ontouchend' in document) {
      classReplaces['no-touch'] = 'touch';
      TJG.vars.isTouch = true;
    }
    else if (TJG.vars.device == 'iphone' || TJG.vars.device == 'ipod' || TJG.vars.device == 'ipad') {
      TJG.vars.isIos = true;
    }
    var test = document.createElement('div');  // Retina Test
    test.style.display = 'none';
    test.id = 'mc-test';
    test.innerHTML = '<style type="text/css">@media(-webkit-min-device-pixel-ratio:1.5){#mc-test{color:red}}@media(-webkit-min-device-pixel-ratio:2.0){#mc-test{color:blue}}</style>';
    TJG.doc.appendChild(test);
    var color = test.ownerDocument.defaultView.getComputedStyle(test, null).getPropertyValue('color'), m = /255(\))?/gi.exec(color);
    if (m) {
        classes.push('hd' + (m[1] ? 20 : 15));
        classReplaces['no-hd'] = 'hd';
    }
    TJG.doc.removeChild(test);
    var className = TJG.doc.className;
    for (replace in classReplaces) {              
        className = className.replace(replace, classReplaces[replace]);
    }
    TJG.doc.className = className + classes.join(' ');
    
    TJG.onload = {

      disableScrollOnBody : function() {
        if (!TJG.vars.isTouch) return;
        document.body.addEventListener("touchmove", function(e) {
          //e.preventDefault();
        }, false);
      },

      scrollToTop : function(element) {  // Scrolls to top 
        if (!TJG.vars.isTouch) return;
        var o = document.querySelector(element);
        if (o) {
          o.addEventListener("touchmove", function() {
            this.cancel = true;
          }, false);

          o.addEventListener("touchend", function() {
            if (!this.cancel) {
              TJG.utils.scrollToY(0);
            }

            this.cancel = false;
          }, false);
        }
      },
      
      loadCufon : function () {  // Fonts
        if (Cufon) {
          Cufon.replace('.title');
        }         
      }

    };

    TJG.init = function() {  

      for (var key in TJG.onload) {
        TJG.onload[key]();
      }

      TJG.utils.hideURLBar();
      var myScroll;
      function loaded() {
        myScroll = new iScroll('container');
      }

document.addEventListener('touchmove', function (e) { e.preventDefault(); }, false);

document.addEventListener('DOMContentLoaded', loaded, false);
    };
    window.addEventListener("load", TJG.init, false);

})(this, document);