/*!
 * 
 *  Tapjoy Mobile JS Framework v1.0
 *  
 *    _______________________________                                           
 *   /\____  ________________________\                    
 *   \/___/\ \_______________________/   ___   __  __    
 *        \ \ \  / __ \  /\  __ \ /\ \  / __`\/\ \/\ \   
 *         \ \ \/\ \_\ \_\ \ \_\ \\ \ \/\ \_\ \ \ \_\ \  
 *          \ \_\ \__/.\_\\ \  __/_\ \ \ \____/\/`____ \ 
 *           \/_/\/__/\/_/ \ \ \//\ \_\ \/___/  `/___/> \
 *                          \ \_\\ \____/          /\___/
 *                           \/_/ \/___/           \/__/ 
 *                                
 * @copyright 2012, Tapjoy, Inc.
 * @license   http://www.github.com/Tapjoy
 * @version   1.0
 * @link      https://github.com/Tapjoy
 *
 * @author   Kieran Boyle <kieran.boyle@tapjoy.com>
 * @author   Van Pham <van.pham@tapjoy.com>
 * @author   Mike Wheeler <mike.wheeler@tapjoy.com>
 * 
 */
(function(window, $, undefined){
  "use strict";
  
  var global = window,
      document = global.document,
      navigator = global.navigator,
      location = global.location,
      appversion = navigator.appVersion,
      agent = navigator.userAgent,
      arrayPrototype = Array.prototype,
      functionPrototype = Function.prototype,
      objectPrototype = Object.prototype,
      stringPrototype = String.prototype, 
      toString = objectPrototype.toString,
      hasOwn = objectPrototype.hasOwnProperty,
      push = arrayPrototype.push,
      slice = arrayPrototype.slice,
      each = arrayPrototype.forEach,
      trim = stringPrototype.trim,
      indexOf = arrayPrototype.indexOf;

  var Tapjoy = (function(){

    var _Tapjoy = function(selector, context){
      var $t = this,
          selector_;
    
      if(!selector)
        return $t;
      
      if(selector instanceof _Tapjoy && context == undefined){
        return selector;
      }
      
      if(Tap.isFunction(selector)){
        return Tap(document).ready(selector);
      }

      $t.length = 0;

      if(Tap.isArray(selector) && selector.length != undefined){
        for(var i = 0, k = selector.length; i < k; i++)
          $t[$t.length++] = selector[i];

        return $t;
      }
      
      if(Tap.isObject(selector) && Tap.isObject(context)){
        if(selector.length == undefined){
          if(selector.parentNode == context)
            $t[$t.length++] = selector;
        }else{
          for(var i = 0, k = selector.length; i < k; i++){
            if(selector[i].parentNode == context)
              $t[$t.length++] = selector[i];
          }
        }
        return $t;
      }
      
      if(Tap.isObject(selector) && context == undefined){
        $t[$t.length++] = selector;
        return $t;
      }
      
      if(context !== undefined){
        if(context instanceof _Tapjoy){
          return context.find(selector);
        }
      }else{
        context = document;
      }
      
      selector_ = $t.selector(selector, context);
      
      if(!selector_){
        return $t;
      }
      else if(Tap.isArray(selector_)){
        for(var j = 0, l = selector_.length; j < l; j++){
          $t[$t.length++] = selector_[j];
        }
      }else{
        $t[$t.length++] = selector_;
        return $t;
      }
      return $t;
    };

    var Tap = function(selector, context) {
      return new _Tapjoy(selector, context);
    }; 

    Tap.apply = function(object, config, defaults){
      if(defaults){
        Tap.apply(object, defaults);
      }

      if(object && config && typeof config === 'object'){
        for(var i in config){
          object[i] = config[i];
        }
      }
      return object;
    };

    Tap.apply(Tap, {
      version: '1.0',
      extend: function(){
        var target = arguments[0] || {},
            i = 1,
            length = arguments.length,
            deep = false,
            options, name, src, copy, copyIsArray, clone;   

        if(Tap.type(target) === 'boolean'){
          deep = target;
          target = arguments[1] || {};
          i = 2;
        }

        if(Tap.type(target) !== 'object' && !Tap.isFunction(target)){
          target = {};
        }

        if(length === i){
          target = this;
          --i;
        }
    
        for(;i < length; i++){
          if((options = arguments[i]) != null){
            for(name in options){
              src = target[name];
              copy = options[name];
              
              if(target === copy){
                continue;
              }
              
              if(deep && copy && (Tap.isSimple(copy) || (copyIsArray = Tap.isArray(copy)))){
                if(copyIsArray){
                  copyIsArray = false;
                  clone = src && Tap.isArray(src) ? src : [];
                }else{
                  clone = src && Tap.isSimple(src) ? src : {};
                }
                
                target[name] = Tap.extend(deep, clone, copy);
      
              }else if(copy !== undefined){
                target[name] = copy;
              }
            }
          }
        }
        
        return target;
      },
      type: function(value){

        if(!value || value == null)
          return 'null';
        
        var type = typeof(value),
            types = [
              'undefined', 
              'string', 
              'number', 
              'boolean', 
              'function',
              'object'
            ];
            
        if(type.match(types.join('|'))){
          return type;
        }
      },
      isArray: function(obj){
        return Tap.type(obj) === 'array';
      },
      isFunction: function(obj){
        return Tap.type(obj) === 'function';
      },
      isNumeric: function(obj){
        return !isNaN(parseFloat(obj)) && isFinite(obj);
      },
      isObject: function(obj){
        return Tap.type(obj) === 'object';
      },
      isString: function(obj){
        return Tap.type(obj) === 'string';
      },      
      isWindow: function(obj){
        return obj && Tap.type(obj) === 'object' && 'setInterval' in obj;
      },
      isSimple: function(obj){
        if(!obj || Tap.type(obj) !== 'object' || obj.nodeType || Tap.isWindow(obj)){
          return false;
        }else{
          return true;
        }
      },
      isUnique: function(array){
        for(var i = 0, k = array.length; i < k; i++){
          if(array.indexOf(array[i]) != i){
            array.splice(i, 1);
            continue;
          }
        }
        return array;
      }      
    });

    Tap.fn = _Tapjoy.prototype;
    
    Tap.apply(Tap.fn, {
      constructor: _Tapjoy,
      extend: Tap.extend,
      foreach: arrayPrototype.forEach,
      selector: function(selector, context){
        var query;
        
        try{  
          if(selector[0] === '#' && selector.indexOf(" ") === -1){
            if(context === document)
              query = context.getElementById(selector.replace('#', ''));
            else
              query = slice.call(context.querySelectorAll(selector));
            }else{
              query = slice.call(context.querySelectorAll(selector));
          }
        }catch(error){}

        return query;
      },
      
      ready: function(fn){
        if((/complete|loaded/).test(document.readyState))
          fn.call();
          
        document.addEventListener('DOMContentLoaded', fn, false);
        
        return this;
      },
      each: function(fn){
        this.foreach(function(obj, index) {
          fn.call(obj, index, obj);
        });
        
        return this;
      },
      find: function(el){
        var collection = [],
            temp;
            
        if($t.length === 0)
          return null;
          
        for(var i = 0, k = this.length; i < k; i++){
          temp = Tap(el, this[i]);
          for(var j = 0, l = temp.length; j < l; j++){
            collection.push(temp[j]);
          }
        }
        
        return Tap(Tap.isUnique(collection));
      }
    });

    Tap.apply(Tap, {
      browser: (/webkit/i).test(appversion) ? 'webkit' : (/firefox/i).test(agent) ? 'moz' : 'opera' in window ? 'o' : (/msie/i).test(agent) ? 'ms' : ''
    });
    
    Tap.apply(Tap, {
      supportsTouch: (!!global.Touch) && (typeof window.TouchEvent != 'undefined') && (agent.indexOf('Mobile') > -1),
      supportsiOS5: /OS (5(_\d+)*) like Mac OS X/i.test(agent),
      supportsTransform: Tap.browser + 'Transform' in document.documentElement.style,
      supportsTransitionEnd: (/iphone|ipad|playbook/gi).test(appversion),
      supportsTransform3d: 'WebKitCSSMatrix' in window && 'm11' in new WebKitCSSMatrix(),
      supportsAnimationEvents: (typeof window.WebKitAnimationEvent != 'undefined')
    });
    
    Tap.apply(Tap, {
      device: {
        android: (/android/gi).test(appversion),
        idevice: (/iphone|ipad/gi).test(appversion),
        iphone: (/iphone/gi).test(appversion),
        ipad: (/ipad/gi).test(appversion),
        playbook: (/playbook/gi).test(appversion),
        touchpad: (/hp-tablet/gi).test(appversion)
      }
    });

    Tap.apply(Tap, {
      /**
       * empty images
       */
      blankIMG: 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
      /**
       * loader image
       */
      loaderIMG: 'data:image/gif;base64,R0lGODlhEAAQAMQAAP%2F%2F%2F%2B7u7t3d3bu7u6qqqpmZmYiIiHd3d2ZmZlVVVURERDMzMyIiIhEREQARAAAAAP%2F%2F%2FwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH%2FC05FVFNDQVBFMi4wAwEAAAAh%2BQQFBwAQACwAAAAAEAAQAAAFdyAkQgGJJOWoQgIjBM8jkKsoPEzgyMGsCjPDw7ADpkQBxRDmSCRetpRA6Rj4kFBkgLC4IlUGhbNQIwXOYYWCXDufzYPDMaoKGBoKb886OjAKdgZAAgQkfCwzAgsDBAUCgl8jAQkHEAVkAoA1AgczlyIDczUDA2UhACH5BAUHABAALAAAAAAPABAAAAVjICSO0IGIATkqIiMKDaGKC8Q49jPMYsE0hQdrlABCGgvT45FKiRKQhWA0mPKGPAgBcTjsspBCAoH4gl%2BFmXNEUEBVAYHToJAVZK%2FXWoQQDAgBZioHaX8igigFKYYQVlkCjiMhACH5BAUHABAALAAAAAAQAA8AAAVgICSOUGGQqIiIChMESyo6CdQGdRqUENESI8FAdFgAFwqDISYwPB4CVSMnEhSej%2BFogNhtHyfRQFmIol5owmEta%2FfcKITB6y4choMBmk7yGgSAEAJ8JAVDgQFmKUCCZnwhACH5BAUHABAALAAAAAAQABAAAAViICSOYkGe4hFAiSImAwotB%2Bsi6Co2QxvjAYHIgBAqDoWCK2Bq6A40iA4yYMggNZKwGFgVCAQZotFwwJIF4QnxaC9IsZNgLtAJDKbraJCGzPVSIgEDXVNXA0JdgH6ChoCKKCEAIfkEBQcAEAAsAAAAABAADgAABUkgJI7QcZComIjPw6bs2kINLB5uW9Bo0gyQx8LkKgVHiccKVdyRlqjFSAApOKOtR810StVeU9RAmLqOxi0qRG3LptikAVQEh4UAACH5BAUHABAALAAAAAAQABAAAAVxICSO0DCQKBQQonGIh5AGB2sYkMHIqYAIN0EDRxoQZIaC6bAoMRSiwMAwCIwCggRkwRMJWKSAomBVCc5lUiGRUBjO6FSBwWggwijBooDCdiFfIlBRAlYBZQ0PWRANaSkED1oQYHgjDA8nM3kPfCmejiEAIfkEBQcAEAAsAAAAABAAEAAABWAgJI6QIJCoOIhFwabsSbiFAotGMEMKgZoB3cBUQIgURpFgmEI0EqjACYXwiYJBGAGBgGIDWsVicbiNEgSsGbKCIMCwA4IBCRgXt8bDACkvYQF6U1OADg8mDlaACQtwJCEAIfkEBQcAEAAsAAABABAADwAABV4gJEKCOAwiMa4Q2qIDwq4wiriBmItCCREHUsIwCgh2q8MiyEKODK7ZbHCoqqSjWGKI1d2kRp%2BRAWGyHg%2BDQUEmKliGx4HBKECIMwG61AgssAQPKA19EAxRKz4QCVIhACH5BAUHABAALAAAAAAQABAAAAVjICSOUBCQqHhCgiAOKyqcLVvEZOC2geGiK5NpQBAZCilgAYFMogo%2FJ0lgqEpHgoO2%2BGIMUL6p4vFojhQNg8rxWLgYBQJCASkwEKLC17hYFJtRIwwBfRAJDk4ObwsidEkrWkkhACH5BAUHABAALAAAAQAQAA8AAAVcICSOUGAGAqmKpjis6vmuqSrUxQyPhDEEtpUOgmgYETCCcrB4OBWwQsGHEhQatVFhB%2FmNAojFVsQgBhgKpSHRTRxEhGwhoRg0CCXYAkKHHPZCZRAKUERZMAYGMCEAIfkEBQcAEAAsAAABABAADwAABV0gJI4kFJToGAilwKLCST6PUcrB8A70844CXenwILRkIoYyBRk4BQlHo3FIOQmvAEGBMpYSop%2FIgPBCFpCqIuEsIESHgkgoJxwQAjSzwb1DClwwgQhgAVVMIgVyKCEAIfkECQcAEAAsAAAAABAAEAAABWQgJI5kSQ6NYK7Dw6xr8hCw%2BELC85hCIAq3Am0U6JUKjkHJNzIsFAqDqShQHRhY6bKqgvgGCZOSFDhAUiWCYQwJSxGHKqGAE%2F5EqIHBjOgyRQELCBB7EAQHfySDhGYQdDWGQyUhADs%3D',
      /**
       * Component types, I refer to them as xtypes.
       */
      xtypes: ['Button'],
      /**
       * input placeholders bucket
       * Manage place-holder text of inputs on browsers which do not support the placeholder attributes.
       * Used for form validation purposes.
       */
      placeholders: []
    });

    Tap.apply(Tap, {
      /**
       * CSS prefix object
       * Browser CSS prefixes
       */
      cssPrefix: {
        moz: '-moz-',
        webkit: '-webkit-',
        o: '-o-',
        ms: '-ms-'
      },
      /**
       * RegEx object
       * Commonly used Regular Expressions 
       */   
      RegEx: {
        escape: /('|\\)/g,
        format: /\{(\d+)\}/g,
        tags: /<.*?>/g,
        escapeRegex: /([-.*+?^${}()|[\]\/\\])/g,
        numbers: /[A-Za-z$-]/g
      }
    });
    
    Tap.apply(Tap, {
      EventsMap: {
        resize: 'onorientationchange' in window ? 'orientationchange' : 'resize',
        start: Tap.supportsTouch ? 'touchstart' : 'mousedown',
        move: Tap.supportsTouch ? 'touchmove' : 'mousemove',
        end: Tap.supportsTouch ? 'touchend' : 'mouseup',
        cancel: Tap.supportsTouch ? 'touchcancel' : 'mouseout'
      }
    });
    
    Tap(document).ready(function(){
      if(!Tap.supportsTouch)
        $('body:eq(0)').addClass('desktop');

      // add DOM ready stuff here
    });

    return Tap;
  })();
  
  window.Tapjoy = Tapjoy;

})(window, jQuery);
