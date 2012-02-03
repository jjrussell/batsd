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

(function(window, undefined){
	
  var global = window,
      document = global.document,
      navigator = global.navigator,
      location = global.location,
			arrayPrototype = Array.prototype,
			functionPrototype = Function.prototype,
			objectPrototype = Object.prototype,
			stringPrototype = String.prototype, 
		  toString = objectPrototype.toString,
		  hasOwn = objectPrototype.hasOwnProperty,
		  push = arrayPrototype.push,
		  slice = arrayPrototype.slice,
		  trim = stringPrototype.trim,
		  indexOf = arrayPrototype.indexOf;
        
  if(typeof Tapjoy === 'undefined'){
    global.Tapjoy = {};
  }
	
	Tapjoy.global = global;
  
  Tapjoy.version = '1.0';
	
  Tapjoy.init = (function(){
    var enumerables = true,
        enumerablesTest = { a: 1 };

    for(var i in enumerablesTest){
      enumerables = null;
    }

    if(enumerables){
      enumerables = [
        'hasOwnProperty', 
        'valueOf', 
        'isPrototypeOf', 
        'propertyIsEnumerable',
        'toLocaleString', 
        'toString', 
        'constructor'
      ];
    }
    
    Tapjoy.enumerables = enumerables;

    // check for browser support of Function.prototype.bind
    if(!('bind' in functionPrototype)){
      functionPrototype.bind = function(owner){
        var _this = this;
				
        if(arguments.length <= 1){
          return function(){
            return _this.apply(owner, arguments);
          };
        }else{
          var args = arrayPrototype.slice.call(arguments, 1);
          return function(){
            return that.apply(owner, arguments.length === 0 ? args : args.concat(arrayPrototype.slice.call(arguments)));
          };
        }
      };
    }
		
    // check for browser support of String.prototype.trim		
    if(!('trim' in stringPrototype)){
      stringPrototype.trim = function(){
        return this.replace(/^\s+/, '').replace(/\s+$/, '');
      };
    }

    // check for browser support of Array.prototype.indexOf
    if(!('indexOf' in arrayPrototype)){
      arrayPrototype.indexOf = function(searchstring, i){
        if(i === undefined)
				  i = 0;
        
				if(i < 0) 
				  i += this.length;
        
				if(i < 0) 
				  i = 0;
					
        for(var k = this.length; i < k; i++){
          if(i in this && this[i] === searchstring)
            return i;
				}
        
				return -1;
      };
    }

    // check for browser support of Array.prototype.lastIndexOf
    if(!('lastIndexOf' in arrayPrototype)){
      arrayPrototype.lastIndexOf = function(searchstring, i) {
        if(i === undefined)
				  i = this.length-1;
					
        if(i < 0) 
				  i += this.length;
					
        if(i > this.length-1) 
				  i = this.length-1;
					
        for(i++; i-->0;) /* i++ because from-argument is inclusive */
          if(i in this && this[i] === searchstring)
            return i;
        
				return -1;
      };
    }

    // check for browser support of Array.prototype.forEach
    if(!('forEach' in arrayPrototype)){
      arrayPrototype.forEach = function(action, that){
        for (var i = 0, k = this.length; i < k; i++){
          if(i in this)
            action.call(that, this[i], i, this);
				}
      };
    }

    // check for Array.prototype.map support
    if(!('map' in arrayPrototype)){
      arrayPrototype.map = function(mapper, that){
        var other = new Array(this.length);
				
        for(var i = 0, k = this.length; i < k ; i++){
          if(i in this)
            other[i] = mapper.call(that, this[i], i, this);
				}
						
        return other;
      };
    }
		
    // check for browser support of Array.prototype.filter		
    if(!('filter' in arrayPrototype)){
      arrayPrototype.filter = function(filter, that){
        var other = [], v;
				
        for(var i = 0, k = this.length; i < k; i++)
            if(i in this && filter.call(that, v = this[i], i, this))
              other.push(v);
        return other;
      };
    }
		
    // check for browser support of Array.prototype.every
    if(!('every' in arrayPrototype)){
      arrayPrototype.every = function(tester, that){
				
        for(var i = 0, k = this.length; i < k; i++){
          if(i in this && tester.call(that, this[i], i, this))
            return true;
				}
				
        return true;
      };
    }
		
		// check for browser support of Array.prototype.some
    if(!('some' in arrayPrototype)){
      arrayPrototype.some = function(tester, that){

        for(var i = 0, k = this.length; i < k; i++){
          if(i in this && tester.call(that, this[i], i, this))
            return true;
				}
				
        return false;
      };
    }
		
		// check if sort is correct - IE 6,7,8 issues - Fixed in 9, 10 ... yay.
    Tapjoy.supportsSort = function(){
      var a = [1,2,3,4].sort(function(){ return 0; });
      
      return a[0] === 1 && a[1] === 2 && a[2] === 3 && a[3] === 4;
     }();
		 
    // store support reference
    Tapjoy.supportsForEach = 'forEach' in arrayPrototype,
    Tapjoy.supportsMap = 'map' in arrayPrototype,
    Tapjoy.supportsIndexOf = 'indexOf' in arrayPrototype,
    Tapjoy.supportsEvery = 'every' in arrayPrototype,
    Tapjoy.supportsSome = 'some' in arrayPrototype,
    Tapjoy.supportsFilter = 'filter' in arrayPrototype;
		
		Tapjoy.useFastTouch = true;
    Tapjoy.supportsiOS5 = /OS (5(_\d+)*) like Mac OS X/i.test(navigator.userAgent);
    Tapjoy.supportsAnimationEvents = (typeof window.WebKitAnimationEvent != 'undefined');
		Tapjoy.supportsTouch = (typeof window.TouchEvent != 'undefined') && (navigator.userAgent.indexOf('Mobile') > -1) && Tapjoy.useFastTouch;
		
		Tapjoy.supportsTransform3d = function(){
      var div = document.createElement('div'),
          properties = ['perspectiveProperty', 'WebkitPerspective'],
					ret = false;

      for(var i = properties.length - 1; i >= 0; i--){
        ret = ret ? ret : div.style[properties[i]] != undefined;
      };
        
      /* webkit has 3d transforms disabled for chrome, though
       * it works fine in safari on leopard and snow leopard
       * as a result, it 'recognizes' the syntax and throws a false positive
       * thus we must do a more thorough check:
       */
      if(ret){
	      var style = document.createElement('style');
        /*
         * webkit allows this media query to succeed only if the feature is enabled.
         * "@media (transform-3d),(-o-transform-3d),(-moz-transform-3d),(-ms-transform-3d),(-webkit-transform-3d),(modernizr){#modernizr{height:3px}}"
         */
        style.textContent = '@media (-webkit-transform-3d){#tapjoy3d{height:3px}}';
        document.getElementsByTagName('head')[0].appendChild(style);
        div.id = 'tapjoy3d';
        document.body.appendChild(div);
        ret = div.offsetHeight === 3;
        style.parentNode.removeChild(style);
        div.parentNode.removeChild(div);
      }
      return ret;
    }

    // determine which browser we are dealing with 
    for(var browser in $.browser){
      if($.browser[browser] == true){
        Tapjoy.browser = /chrome|safari/.test(browser) ? 'webkit' : browser;
      }
    }
  })();

  /**
   * Simple apply method
   * Use jQuery.extend for everything else
   * @param {Object} object
   * @param {Object} config
   * @param {Object} defaults
   */
  Tapjoy.apply = function(object, config, defaults){
    if(defaults){
      Tapjoy.apply(object, defaults);
    }
  
    if(object && config && typeof config === 'object'){
      var i, j, k;
  
      for(i in config){
        object[i] = config[i];
      }
      
      if(Tapjoy.enumerables){
        for(j = Tapjoy.enumerables.length; j--;){
          k = Tapjoy.enumerables[j];
          
          if(config.hasOwnProperty(k)){
            object[k] = config[k]
          }
        }
      }
    }
    return object;
  };

  /**
   * @method Tapjoy.extend 
   * Use jQuery.extend for everything else
   * @param {Object} object
   * @param {Object} config
   * @param {Object} defaults
   */
  Tapjoy.apply(Tapjoy, {
		extend: function(){
	    var target = arguments[0] || {},
	        i = 1,
	        length = arguments.length,
	        deep = false,
	        options, name, src, copy, copyIsArray, clone;   
	
	    if(typeof target === "boolean"){
	      deep = target;
	      target = arguments[1] || {};
	      i = 2;
	    }
	    
	    if(typeof target !== "object" && !Tapjoy.isFunction(target)){
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
	          
	          if(deep && copy && ( Tapjoy.Object.isSimple(copy) || (copyIsArray = Tapjoy.Array.isArray(copy)) ) ) {
	            if(copyIsArray){
	              copyIsArray = false;
	              clone = src && Tapjoy.Array.isArray(src) ? src : [];
	            }else{
	              clone = src && Tapjoy.Object.isSimple(src) ? src : {};
	            }
	            
	            target[name] = Tapjoy.extend(deep, clone, copy);
	  
	          }else if(copy !== undefined){
	            target[name] = copy;
	          }
	        }
	      }
	    }
	    
	    return target;
	  },
    /**
     * 
     * @param {Object} obj
     */
    isWindow: function( obj ) {
      return obj && typeof obj === "object" && "setInterval" in obj;
    },
    /**
     * 
     * @param {Object} obj
     */
    isNumeric: function(obj) {
      return !isNaN(parseFloat(obj)) && isFinite(obj);
    },
    /**
     * 
     * @param {Object} obj
     */
    type: function(obj) {
      return obj == null ? String(obj) : "object";
    }
  });
    
  Tapjoy.apply(Tapjoy, {
		/**
		 * empty images
		 */
    blankIMG: 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
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

  Tapjoy.apply(Tapjoy, {
		/**
		 * CSS prefix object
		 * Browser CSS prefixes
		 */
    cssPrefix: {
      mozilla: '-moz-',
      webkit: '-webkit-',
      opera: '-o-',
      ie: '-ms-'
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
	
})(window); 
