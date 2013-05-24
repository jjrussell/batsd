      /*!
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
 * @author    Kieran Boyle (github.com/dysfunc)
 * @author    Van Pham (github.com/vanner)
 *
 * @copyright 2012, Tapjoy, Inc.
 * @license   http://www.github.com/Tapjoy
 * @version   1.0
 * @link      https://github.com/Tapjoy
 *
 */

(function(window, undefined){
  "use strict";

  var global = window,
      document = global.document,
      navigator = global.navigator,
      location = global.location,
      language = navigator.language,
      version = navigator.appVersion,
      platform = navigator.platform,
      agent = navigator.userAgent,
      arrayPrototype = Array.prototype,
      functionPrototype = Function.prototype,
      objectPrototype = Object.prototype,
      stringPrototype = String.prototype,
      toString = objectPrototype.toString,
      hasOwn = objectPrototype.hasOwnProperty,
      push = arrayPrototype.push,
      concat = arrayPrototype.concat,
      _filter = arrayPrototype.filter,
      reduce = arrayPrototype.reduce,
      slice = arrayPrototype.slice,
      each = arrayPrototype.forEach,
      indexOf = arrayPrototype.indexOf,
      trim = stringPrototype.trim,
      cache = {},
      uid = 0;

  var Tapjoy = (function(){
    /**
     * Define a local copy of Tapjoy (internally $ = Tapjoy)
     * @param  {Mixed} selector The thing we are looking for
     * @param  {Mixed} context The context in which to perform the search
     * @return {Object} returns Tapjoy object collection
     */
    var $ = function(selector, context){
      return new $.fn.init(selector, context);
    };

    $.fn = $.prototype = {
      constructor: $,
      version: '1.0',
      init: function(selector, context){

        if(!selector){
          return this;
        }
        else if($.isFunction(selector)){
          return $(document).ready(selector)
        }
        else if(selector instanceof $){
          return selector;
        }else{
          this.length = 0;
          this.selector = selector;
          this.context = context;

          if(($.patterns.nodes).test(selector.nodeType) || selector === window){
            this[this.length++] = this.selector = this.context = selector;
            return this;
          }
          else if(selector instanceof Array && selector.length !== undefined){
            for(var i = 0, k = selector.length; i < k; i++){
              this[this.length++] = selector[i];
            }
            return this;
          }else{
            context = this.context = context || document;
            return context !== document ? $(context).find(selector) : $.merge(this, $.processing(selector, context));
          }
        }
      }
    };

    /**
     * Determine if our selector contains any CSS expressions, if not, query
     * @param  {Mixed} selector The thing we are looking for in the query
     * @param  {Mixed} context The context in which to perform the query
     * @return {Mixed} returns Tapjoy collection of matched elements or expression result
     */
    $.processing = function(selector, context){
      var match = selector.match(this.patterns.expressions);

      return !match || match && !$.filters[match[2]] ?
        $.query(selector, context) :
        $.expressionizer(match, selector, function(selector_, fn, args){
          !selector_ && fn && (selector_ = '*');

          var collection = $.query(selector_, context);

          return !fn ? collection :
            $.unique(
              $.map(collection, function(element, index){
                return fn.call(element, index, collection, args);
              })
            );
        });
    };

    /**
     * CSS Selector implementation borrowed from Zepto
     * @param  {Mixed} selector The selector we are looking for
     * @param  {Mixed} context The context in which to perform the query
     * @return {Array} returns Array of matched elements
     */
    $.query = function(selector, context){
      var query;

      return (context === document && (this.patterns.ids).test(selector)) ?
        ((query = context.getElementById(RegExp.$1)) ? [query] : []) :
        (context.nodeType !== 1 && context.nodeType !== 9) ? [] :
         slice.call(
          (this.patterns.classes).test(selector) ? context.getElementsByClassName(RegExp.$1) :
          (this.patterns.tags).test(selector) ? context.getElementsByTagName(selector) :
          context.querySelectorAll(selector)
        )
    };

    /**
     * Determines whether the passed selector expression is supported
     * @param  {Array} bits The array of splits from our expressions regex
     * @param  {String} selector The original selector
     * @param  {Function} fn The callback function
     * @return {Function} returns the selector, filter function and any arguments like -> ":eq(0)" -> 0
     */
    $.expressionizer = function(bits, selector, fn){
      if(bits && bits[2] in $.filters){
        var filter = $.filters[bits[2]],
            args = bits[3];

        selector = bits[1];

        if(args){
          var num = Number(args);
          args = isNaN(num) && args.replace(/^["']|["']$/g, '') || num;
        }
      }

      return fn(selector, filter, args);
    };

    /**
     * Copies all the properties of config to object
     * @param  {Object} object The receiving object you want to apply the config properties to
     * @param  {Object} config The source object containing the new or updated default properties
     * @param  {Object} defaults The default values object (optional)
     * @return {Object} returns object;
     */
    $.apply = function(object, config, defaults){

      defaults && $.apply(object, defaults);

      if(object && config && toString.call(config) === '[object Object]'){
        for(var i in config){
          object[i] = config[i];
        }
      }
      return object;
    };

    $.apply($, {
      /**
       * Converts a string containing dashes to camelCase
       * @param  {String} str The string to format
       * @return {String} returns the formatted string
       */
      camelcase: function(str){
        return str.replace(/-+(.)?/g, function(match, chr){
          return chr ? chr.toUpperCase() : '';
        });
      },
      /**
       * Combines the second array into the first
       * @param  {Array} first The array to add values to
       * @param  {Array} second The array to merge into the first
       * @return {Array} returns The first array with merged contents
       */
      combine: function(first, second){
        return $.isArray(first) && $.isArray(second) ? first.concat(second) : first;
      },
      /**
       * Determine whether the string/array contains a specific value
       * @param  {Mixed} obj The string or array to check
       * @param  {String} item The value to look for
       * @param  {Boolean} index Set true to return the index of the matched item or -1
       * @return {Mixed} returns the value of true or false, or the index at which the value can be found
       */
      contains: function(obj, item, index){
        return !index ? !!~obj.indexOf(item) : obj.indexOf(item);
      },
      /**
       * Store arbitrary data associated with the specified element
       * @param  {DOM Element} The DOM element to associate with the data
       * @param  {String} key A string naming the property of data to set
       * @param  {Mixed} value The data value
       * @return {Mixed} Returns the value that was set
       */
      data: function(element, key, value){
       !element && (element = this);
       element = $(element);
       return !key && !value ? element.attr('data') : element.attr('data-' + key, value);
      },
      /**
       * Iterates over a collection, executing a function for each matched item
       * @param  {Array|Object|Function} collection The object or array to iterate over
       * @param  {Function} fn The function to execute on each item
       * @return {Object} return Tapjoy object
       */
      each: function(collection, fn){
        if($.isFunction(collection)){
          fn = collection;
          collection = this;
        }

        if($.isNumber(collection.length)){
          collection.forEach(function(item, index){
            fn.call(item, index, item);
          });
        }else if($.isObject(collection)){
          for(var key in collection){
            fn.call(collection[key], key, collection[key]);
          }
        }

        return this;
      },
      /**
       * Merge the contents of two or more objects into the target object
       * @param  {Object} target The object receiving the new properties
       * @param  {Object} arguments One or more additional objects to merge with the first
       * @return {Object} returns the target object with the new contents
       */
      extend: function(target){
        if(target === undefined){
          target = this;
        }

        if(arguments.length == 1){
          for(var key in target){
            this[key] = target[key];
          }
          return this;
        }else{
          slice.call(arguments, 1).forEach(function(obj){
            for(var key in obj){
              target[key] = obj[key];
            }
          });
        }

        return target;
      },
      /**
       * Returns a "flat" one-dimensional array
       * @param  {Array} array The multidimensional array to flatten
       * @return {Array} returns The flattened array
       */
      flatten: function(array){
        return array.length > 0 ? concat.apply([], array) : array;
      },
      /**
       * Returns a formatted string template from the values of the passed argument
       * @param  {String} tpl The string template containing the place-holders
       * @param  {Array|Object} values The argument containing the indexed values or property keys
       * @return {String} returns The formatted string
       */
      format: function(tpl, values){
        var valid = $.isObject(values) || $.isArray(values);

        if(!values || !valid)
          return undefined;

        var match = $.isObject(values) ? 'keys' : 'indexed';

        return tpl.replace($.patterns.templates[match], function(match, key){
          return values[key] || '';
        });
      },
      /**
       * Determine whether the argument is an Array
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isArray: function(obj){
        return $.type(obj) === 'array';
      },
      /**
       * Determine whether the argument is a Date
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isDate: function(obj){
        return $.type(obj) === 'date';
      },
      /**
       * Determine whether the argument is a a Function
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isFunction: function(obj){
        return $.type(obj) === 'function';
      },
      /**
       * Determine whether the argument is a NodeList or HTMLCollection (IE)
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isNodeList: function(obj){
        return $.type(obj) === 'nodelist' || $.type(obj) === 'htmlcollection';
      },
      /**
       * Determine whether the argument is a Number
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isNumber: function(obj){
        return !isNaN(parseFloat(obj)) && isFinite(obj);
      },
      /**
       * Determine whether the argument is an Object
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isObject: function(obj){
        return $.type(obj) === 'object';
      },
      /**
       * Determine whether the argument is a RegEx
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isRegEx: function(obj){
        return $.type(obj) === 'regex';
      },
      /**
       * Determine whether the argument is a String
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isString: function(obj){
        return $.type(obj) === 'string';
      },
      /**
       * Determine whether the argument is a simple object
       * @param  {Object}  obj The object
       * @return {Boolean} returns The value of true or false
       */
      isSimple: function(obj){
        return (!obj || $.type(obj) !== 'object' || obj.nodeType || $.isWindow(obj));
      },
      /**
       * Determine whether the argument is a Window
       * @param  {Object}  obj The object to type check
       * @return {Boolean} returns The value of true or false
       */
      isWindow: function(obj){
        return obj != null && obj == obj.window;
      },
      /**
       * Execute a function after a threshold of time has elapsed
       * @param  {Function} fn The function to execute
       * @param  {Number} delay The delay before executing the function (Defaults to 100)
       * @param  {Boolean} now Execute the function immediately -> overrides delay
       * @param  {Object} context The object that will set the context (this) of the function
       * @return {Function}
       */
      lazy: function(fn, delay, now, context){
        var timer;

        return function smart(){
          context = context || this;

          function dispatch(){
            !now && fn.apply(context, arguments);
            timer = null;
          }

          if(timer){
            clearTimeout(timer);
          }else if(now){
            fn.apply(context, arguments);
          }

          timer = setTimeout(dispatch, delay || 100);
        };
      },
      /**
       * Internal logging
       * @param  {Mixed} result
       * @param  {String} message
       * @return {}
       */
      log: function(result, message){
        var cnsl = window.console;

        return cnsl && cnsl.log && window.ENVIRONMENT === 'development' && cnsl.log(result +' -> '+ message);
      },
      /**
       * Creates a new array from the results of executing the callback function on
       * each element of the passed array
       * @param  {Array} elements The array to map
       * @param  {Function} fn The callback to execute on every element in the array
       * @return {Array} returns The newly flattened array
       */
      map: function(elements, fn){
        var total = elements.length,
            value,
            values = [];

        if($.isNumber(total)){
          for(var i = 0, k = total; i < k; i++){
            value = fn(elements[i], i);

            if(value != null){
              values.push(value);
            }
          }
        }else{
          for(var key in elements){
            value = fn(elements[key], key);

            if(value != null){
              values.push(value);
            }
          }
        }

        return $.flatten(values);
      },
      /**
       * Determines if the element would be selected by the specified selector
       * @param  {DOM Element} element The DOM element to perform the test on
       * @param  {String} selector The selector to test
       * @return {Boolean} retuns the value true or false
       */
      match: function(element, selector){

        var helper = function(el, sel){
          var parent, temp, tempParent, nativeSelector =
            el.webkitMatchesSelector ||
            el.mozMatchesSelector ||
            el.oMatchesSelector ||
            el.matchesSelector;

          return !el || el.nodeType !== 1 ? false :
                 (nativeSelector ? nativeSelector.call(el, sel) :
                 (el.parentNode && (parent = el.parentNode) && (parent = tempParent).appendChild(el) ||
                 (parent = el.parentNode)) &&
                 ~$.query(sel, parent).indexOf(el) && temp && tempParent.removeChild(el));
        };

        var bits = selector.match(this.patterns.expressions);

        return $.expressionizer(bits, selector, function(select, fn, args){
          return (!select || helper(element, select || document)) && (!fn || fn.call(element, null, args) === element);
        });
      },
      /**
       * Merge two arrays together into the first array
       * @param  {Array} first The array to to add the values to
       * @param  {Array} second The second array to merge into the first - unaltered
       * @return {Array} returns The first array with merged values from the second
       */
      merge: function(first, second){
        var total = second.length,
            length = first.length,
            count = 0;

        if($.isNumber(total)){
          for(; count < total; count++){
            first[length++] = second[count];
          }
        }else{
          while(second[count] !== undefined){
            first[length++] = second[count++];
          }
        }

        first.length = length;

        return first;
      },
      /**
       * Parse a string as JSON
       * @param  {String} string The string to parse as JSON
       * @return {Object} The JSON Object
       */
      parseJSON: function(string){
        return JSON.parse(string);
      },
      /**
       * Parse a string as XML
       * @param  {String} string The string to parse as XML
       * @return {Object} The DOM XML Object
       */
      parseXML: function(string){
        return (new DOMParser).parseFromString(string, 'text/xml');
      },
      /**
       * Checks if the defined method is natively supported, if not, applies the polyfill
       * @param  {String} type The type ('array', 'function')
       * @param  {String} name The method name ('indexOf', 'reduce')
       * @param  {Function} fn The polyfill method
       * @return {Object} returns this
       */
      polyfill: function(type, name, fn){
        var types = {
              'array': arrayPrototype,
              'string': stringPrototype,
              'object': objectPrototype,
              'function': functionPrototype
            };

        type && name && $.isFunction(fn) && !types[type][name] && (types[type][name] = fn);

        return this;
      },
      /**
       * Returns a function with a specific context
       * @param  {Function} fn The function whose context will change
       * @param  {Object}   context The object that will set the context (this) of the function
       * @return {Function} returns The function with the modified context
       */
      proxy: function(fn, context){
        return function(){
          return $.isFunction(fn) && fn.apply(context, slice.call(arguments, 2).concat(slice.call(arguments)));
        };
      },
      /**
       * Get the siblings of each element
       * @param  {[type]} nodes
       * @param  {DOM Element} element The sibling to exclude from the collection
       * @return {Array} returns The collection of siblings
       */
      siblings: function(nodes, element){
        var collection = [];

        if(nodes == undefined)
          return collection;

        for(; nodes; nodes = nodes.nextSibling){
          if(nodes.nodeType == 1 && nodes !== element){
            collection.push(nodes);
          }
        }

        return collection;
      },
      /**
       * Converts the argument being passed to a JSON String
       * @param  {Mixed} value The value to convert
       * @return {String} The JSON string
       */
      stringify: function(value){
        return JSON.stringify(value);
      },
      /**
       * Converts anything that can be iterated over into a real Array
       * @param  {Mixed} item Can be a string, array or arugments object
       * @param  {Number} start Zero-based index to start the array at (optional)
       * @param  {Number} end Zero-based index to end the array at (optional)
       * @return {Array} returns the new Array
       */
      toArray: function(item, start, end){
        var array = [];

        if(!item || !item.length)
          return array;

        $.isString(item) && (item = item.split(''))

        end = (end && end < 0 && item.length + end || end) || item.length;

        for(var i = (start || 0); i < end; i++){
          array.push(item[i]);
        }

        return array;
      },
      /**
       * Returns the internal JavaScript ES5 spec [[Class]] of an object
       * @param  {Object} obj The object to check the class property of
       * @return {String} returns Only the class property of the object
       */
      type: function(obj){
        return !obj ? null : toString.call(obj).replace('[object ', '').replace(']', '').toLowerCase();
      },
      /**
       * [unique description]
       * @param  {[type]} array [description]
       * @return {[type]}       [description]
       */
      unique: function(array){
        return array.filter(function(item, index){
          return array.indexOf(item) === index;
        });
      }
    });

    /**
     * Stores a reference to RegEx'd class names for faster lookups
     * @type {Object}
     */
    var cssClassCache = {},
    /**
     * CSS properties that do not allow pixels. Used for .css() and .data() methods
     * @type {Object}
     */
    cssNumbersOnly = {'columns': 1, 'columnsCount': 1, 'fontWeight': 1, 'lineHeight': 1, 'zIndex': 1, 'zoom': 1},
    /**
     * Creates a RegEx of the class name stores it in cache
     * @param  {String} cls The CSS class
     * @return {RegEx} returns The class name RegEx
     */
    cssClass = function(cls){
      return cls in cssClassCache ? cssClassCache[cls] : (cssClassCache[cls] = new RegExp('(^|\\s)' + cls + '(\\s|$)'));
    },
    /**
     * Helper function for creating data object for elements
     * @param  {DOM Element} element The element we are creating
     * @return {Object} returns The data object
     */
    dataCache = function(element){
      var data = cache[(element.uid || (element.uid = uid++))] = {};

      for(var i = 0, k = element.attributes.length; i < k; i++){
        var item = element.attributes[i],
            prop = item.name,
            val = item.value;

       ~prop.indexOf('data') && (data[prop.substr(5)] = ($.patterns.numbers).test(val) && parseInt(val) || val);
      }
      return data;
    };

    $.fn.init.prototype = $.fn;

    $.apply($.fn, {
      concat: concat,
      forEach: each,
      indexOf: indexOf,
      push: push,
      reduce: reduce,
      each: $.each,
      extend: $.extend,
      /**
       * Adds one or more CSS classes to one or more elements
       * @param  {String|Function} cls The CSS class  to add or the function to execute
       * @return {Object} returns this
       */
      addClass: function(cls){
        return this.each(function(index){
          var $t = $(this);

          if($.isFunction(cls)){
            $t.addClass(cls.call(this, index, this.className));
          }else{
            var list = this.className + ' ',
                add = [];

            cls.split($.patterns.space).forEach(function(name){
              !$t.hasClass(name) && add.push(name);
            });

            this.className = (list += add.join(' ')).trim();
          }
        });
      },
      /**
       * Get or set the value of an attribute for the first element in the set of matched elements
       * @param  {String} name  The name of the attribute to get or set
       * @param  {Mixed} value The value to set
       * @return {Mixed} returns The value of the attribute/data object or sets the value and return this
       */
      attr: function(name, value){

        if(this.length === 0 || this[0].nodeType !== 1)
          return;

        if(typeof name == 'string' && value === undefined){
          if(this[0][name]){
            return this[0].getAttribute(name);
          }else if(~name.indexOf('data-')){
            return this[0].getAttribute(name) || (cache[this[0].uid] && cache[this[0].uid][name.substr(5)] || dataCache(this[0])[name.substr(5)]);
          }else if(name === 'data'){
            return cache[this[0].uid] || dataCache(this[0]);
          }else{
            return false;
          }
        }else{
          return this.each(function(){
            if(this.nodeType !== 1)
              return;

            if($.isObject(name)){
              for(key in name){
                this.setAttribute(key, name[key]);
              }
            }
            else if(value !== undefined){
              if(~name.indexOf('data-')){
                var data = cache[this.uid];

                !data && (data = dataCache(this));

                data[name.substr(5)] = value;
              }else{
                this.setAttribute(name, value);
              }
            }
          });
        }
      },
      /**
       * Creates a reference to the original matched elements for chain breaking
       * @param  {Object} collection The
       * @return {Object} returns The collection
       */
      chain: function(collection){
        return (collection.origin = this) && collection || $();
      },
      /**
       * Get the child elements of each element in the set of matched elements
       * @param  {String} selector Filter by a selector (optional)
       * @return {Object} returns The collection of child elements
       */
      children: function(selector){
        var collection = [];

        if(this.length === 0)
          return undefined;

        for(var i = 0, k = this.length; i < k; i++){
          collection = collection.concat($.siblings(this[i].firstChild));
        }

        return this.chain($(collection).filter(selector || '*'));
      },
      /**
       * Get the value of a style property for the first element in the set of matched
       * elements or set the style property value for one or more elements
       * @param  {String/Object} property The style property to set or get
       * @param  {Mixed} value The value to set for the given property
       * @return {Mixed} returns the style property value or this
       */
      css: function(property, value){
        var isString = typeof(property) === 'string';

        if(this.length === 0 || this.length === 1 && this[0].nodeType !== 1)
          return undefined;

        if(isString && value === undefined){
          var prop = $.camelcase(property);
          return this[0].style[prop] || window.getComputedStyle(this[0])[prop];
        }else{
          for(var i = 0, k = this.length; i < k; i++){
            var isNumber = typeof(value) === 'number';

            if(isString){
              var prop = $.camelcase(property);
              this[i].style[prop] = isNumber && !cssNumbersOnly[prop] && (parseInt(value) + 'px') || value;
            }else{
              for(var key in property){
                var prop = $.camelcase(key);
                this[i].style[prop] = typeof(property[key]) === 'number' && !cssNumbersOnly[prop] && (parseInt(property[key]) + 'px') || property[key];
              }
            }
          }
        }

        return this;
      },
      /**
       * Store arbitrary data associated with the specified element
       * @param  {String} key A string naming the property of data to set
       * @param  {Mixed} value The data value
       * @return {Mixed} Returns The value of the data- attribute or the data object
       */
      data: function(key, value){
       return $.data(this, key, value);
      },
      /**
       * Removes the contents of an element
       * @return {Object} returns this
       */
      empty: function(){
        return this.each(function(){
          this.innerHTML = '';
        });
      },
      /**
       * Ends the last filtering operation in the chain and returns the original matched set
       * @return {Object} returns The original set of matched elements to its previous state
       */
      end: function(){
        return this.origin || $();
      },
      /**
       * Reduce the set of matched elements to the one at a specified index
       * @param  {Number} index Zero-based index of the element to match
       * @return {Object} returns The matched element in specified index of the collection
       */
      eq: function(index){
        return $(index === -1 ? this.slice(index) : this.slice(index, + index + 1));
      },
      /**
       * Search descendants of an element and returns matches
       * @param  {String} selector The element(s) to search for
       * @return {Object} returns The matched set of elements
       */
      find: function(selector){
        var search;

        if(this.length == 1){
          search = $.processing(selector, this[0]);
        }else{
          search = $.map(function(){
            return $.processing(selector, this);
          });
        }

        return this.chain($(search));
      },
      /**
       * Returns the first matched element in the collection
       * @return {Object} returns The first matched element
       */
      first: function(){
        return this.eq(0);
      },
      /**
       * Reduce the collection of matched elements to that of the passed selector
       * @param  {String} selector A string containing a selector to match the current set of elements against
       * @return {Object} returns The matached elements object
       */
      filter: function(selector){
        return this.chain(
          $(_filter.call(this, function(element){
            return $.match(element, selector);
          }))
        );
      },
      /**
       * Retrieve the DOM element at the specified index the Tapjoy object collection
       * @param  {Number} index A zero-based index indicating which element to retrieve
       * @return {String/Array} returns A matched DOM element. If no index is specified all of the matched DOM elements are returned.
       */
      get: function(index){
        return this[index] || slice.call(this);
      },
      /**
       * Determines whether an element has a specific CSS class
       * @param  {String}  cls The CSS class name to check for
       * @return {Boolean} returns the value of true or false
       */
      hasClass: function(cls){
        return cssClass(cls).test(this[0].className);
      },
      /**
       * Returns the HTML contents of the first element in a matched set or updates the contents of one or more elements
       * @param  {String} html The HTML string to replace the contents with
       * @return {Mixed} returns The contents of an element or sets the contents and returns this
       */
      html: function(html){
        return !html ? this[0].innerHTML :
        this.empty().each(function(){
          this.innerHTML = html;
        });
      },
      /**
       * Determines the passed argument is valid or not
       * @param  {String} selector The selector to test
       * @return {Boolean} returns The value of true or false
       */
      is: function(selector){
        return !!selector && this.filter(selector).length > 0;
      },
      /**
       * Returns the last matched element in the collection
       * @return {Object} returns The last matched element
       */
      last: function(){
        return this.eq(-1);
      },
      /**
       * Returns a new Tapjoy object containing the values for each of the matched
       * element passed through the callback function
       * @param  {Function} fn A function executed for each element in the current set
       * @return {Object} returns The new Tapjoy collection of values
       */
      map: function(fn){
        return $.map(this, function(element, index){
          return fn.call(element, index, element);
        });
      },
      /**
       * Returns the offset object for the first matched element in a collection
       * @return {Object} returns The offset object: height, left, top, width
       */
      offset: function(){

        if(this.length === 0 || this[0].nodeType !== 1)
          return null;

        var element = this[0].getBoundingClientRect();

        return {
          height: element.height,
          left: element.left + window.pageXOffset,
          top: element.top + window.pageYOffset,
          width: element.width
        };
      },
      /**
       * Return the parent element of the first matched element
       * @return {Object} returns The parent element object
       */
      parent: function(){
        return this[0].parentNode && this.chain($(this[0].parentNode));
      },
      /**
       * Get the ancestors of each element in the set of matched elements
       * @param  {String} selector The selector to filter by (optional)
       * @return {Object} returns The collection of parent elements
       */
      parents: function(selector){
        var collection = []

        if(this.length === 0)
          return undefined;

        for(var i = 0, k = this.length; i < k; i++){
          this[i].parentNode && collection.push(this[i].parentNode);
        }

        return this.chain($(collection).filter(selector || '*'));
      },
      /**
       * Removes an element from the DOM
       * @return {Object} returns this
       */
      remove: function(){
        return this.each(function(){
          (this.parentNode !== null) && this.parentNode.removeChild(this);
        });
      },
      /**
       * Removes a specific CSS class from one or more elements
       * @param  {String|Function} cls The CSS class to remove or the function to execute
       * @return {Object} returns this
       */
      removeClass: function(cls){
        var str = cssClass(cls);

        return this.each(function(index){
          var list = this.className;

          if($.isFunction(cls)){
            $(this).removeClass(cls.call(this, index, this.className));
          }else{
            this.className = list.replace(str, ' ');
          }
        });
      },
      /**
       * Executes a function when the DOM is ready
       * @param  {Function} fn The function to execute
       * @return {Object} returns this
       */
      ready: function(fn){
        if(($.patterns.ready).test(document.readyState)){
          fn.call();
        }else{
          document.addEventListener('DOMContentLoaded', fn, false);
        }

        return this;
      },
      /**
       * [scrollTop description]
       * @return {[type]} [description]
       */
      scrollTop: function(val){

        if(this.length === 0)
          return undefined;

        var element = this[0],
            isWindow = $.isWindow(element);

        return val === undefined ? isWindow ? element.pageYOffset : element.scrollTop : element.scrollTo(0, val);
      },
      /**
       * Get the siblings of each element in the set of matched elements
       * @param  {String} selector Selector to filter by (optional)
       * @return {Object} returns The collection of siblings from the matched elements
       */
      siblings: function(selector){
        var collection = [];

        if(this.length === 0)
          return undefined;

        for(var i = 0, k = this.length; i < k; i++){
          this[i].parentNode && (collection = collection.concat($.siblings(this[i].parentNode.firstChild, this[i])));
        }

        return this.chain($(collection).filter(selector));
      },
      /**
       * Returns the length of the matched elements in the colection
       * @return {Number} returns The length of a collection
       */
      size: function(){
        return this.length;
      },
      /**
       * [slice description]
       * @return {[type]} [description]
       */
      slice: function(){
        return $(slice.apply(this, arguments));
      },
      /**
       * Gets the text from the first element in the collection or sets the
       * inner text value for one or more elements
       * @param {String} text The text to set
       * @return {Mixed} returns The inner text of the element or sets the text and returns this
       */
      text: function(text){
        return !text ? this[0].textContent :
        this.empty().each(function(){
          this.textContent = text;
        });
      },
      /**
       * Toggles a specific class on one or more elements
       * @param  {String|Function} cls The CSS class to toggle or the function to execute
       * @return {Object} returns this
       */
      toggleClass: function(cls){
        return this.each(function(index){
          var $t = $(this);

          if($.isFunction(cls)){
            $t.toggleClass(cls.call(this, index, this.className));
          }else{
            $t[($t.hasClass(cls) ? 'removeClass' : 'addClass')](cls);
          }
        });
      },
      /**
       * Gets the value for the first element in the matched set or sets a value for one or more elements
       * @param  {Mixed} value The value to set
       * @return {Mixed} returns The value property of the element or sets the value and returns this
       */
      val: function(value){

        if(this.length === 0 || this[0].nodeType !== 1)
          return;

        if(value === undefined)
          return this[0].value;

        for(var i = 0, k = this.length; i < k; i++){
          if(this[i].nodeType !== 1)
            continue;

          this[i].value = value
        }

        return this;
      }
    });
    /**
     * .width() and .height() methods; Returns the width or height of the
     * matched element or set the height and width of one or more elements
     * @param  {Mixed} value If passed true, it will return the width/height including margins, otherwise, sets the value
     * @return {Mixed} returns The width/height value or sets the value and returns this
     */
    $.each({ Width: 'width', Height: 'height'}, function(property, method){
      $.fn[method] = function(value){
        var element = this[0], offset;

        if($.isWindow(element)){
          return element['inner' + property];
        }

        if(element.nodeType === 9){
          var doc = element.documentElement;

          return Math.max(
            element.body['scroll' + property],
            element.body['offset' + property],
            doc['scroll' + property],
            doc['offset' + property],
            doc['client' + property]
          );
        }

        return value === undefined ?
          (offset = this.offset()) && offset[method] :
          (value === true ?
            (offset = this.offset()) && (offset[method] +
              (method === 'width' ?
                parseInt(this.css('marginLeft')) +   parseInt(this.css('marginRight')) :
                parseInt(this.css('marginTop')) +  parseInt(this.css('marginBottom'))
              )
            ) :
            this.css(method, value)
          )
      };
    });

    // bind to event methods
    $.each(['blur', 'change', 'click', 'dblclick', 'error', 'focus', 'hashchange', 'keydown', 'keypress', 'keyup', 'load',
            'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'resize', 'scroll', 'select', 'turn', 'unload'], function(index, event){
      $.fn[event] = function(fn){
        return this.on(event, fn);
      }
    });

    /*------------------------------------
     * Event binding
     ------------------------------------*/

    $.apply($.fn, {
      /**
       * Removes one or more previously-attached event handlers
       * @param  {String} event The string containing the event type(s)
       * @param  {Function} fn The callback function
       * @return {Object} returns this
       */
      off: function(event, fn){
        return this.each(function(index, element){
          $.events.remove(element, event, fn);
        });
      },
      /**
       * Attach one or more event handlers to one or more elements
       * @param  {String|Object} event The string or object containing the event type
       * @param  {Function} fn The callback function
       * @return {Object} returns this
       */
      on: function(event, fn){
        return this.each(function(index, element){
          $.events.add(element, event, fn);
        });
      },
      /**
       * Attach one or more event handlers that will be executed only once
       * @param  {String|Object} event The string or object containing the event type
       * @param  {Function} fn The callback function
       * @return {Object} returns this
       */
      one: function(event, fn){
        return this.each(function(index, element){
          $.events.add(element, event, fn, function(callback, type){
            return function(){
              var result = callback.apply(element, arguments);
              $.events.remove(element, type, callback);
              return result;
            }
          });
        });
      },
      /**
       * Triggers an event on more or more elements
       * @param  {String} event The event to trigger
       * @param  {Object} data The event data
       * @return {Object} returns this
       */
      trigger: function(event, data){

        $.isString(event) && (event = $.events.create(event, data));

        return this.each(function(index){
          ('dispatchEvent' in this) && this.dispatchEvent(event, data);
        });
      }
    });

    var special = {},
    /**
     * Event handlers cache
     * @type {Object}
     */
    handlers = {};
    /**
     * event types
     * @type {String}
     */
    special.click = special.mousedown = special.mouseup = special.mousemove = 'MouseEvents';

    $.events = {
      /**
       * Store reference to special events
       * @type {Object}
       */
      special: special,
      /**
       * Helper method for binding events to elements
       * @param {DOM Element} element  The DOM element to bind the event to
       * @param {String} events The event
       * @param {Function} fn The function to execute
       * @param {Function} getDelegate
       */
      add: function(element, events, fn, getDelegate){
        var id = !element.uid ? (element.uid = uid++) : element.uid,
            set = (handlers[id] || (handlers[id] = []));

        $.events.each(events, fn, function(event, fn){
          var  delegate = getDelegate && getDelegate(fn, event),
               callback = delegate || fn,

          proxy = function(event){
            var result = callback.apply(element, [event].concat(event.data));

            if(result === false)
             event.preventDefault();

            return result;
          },

          handler = $.extend($.events.parse(event), {
            fn: fn,
            proxy: proxy,
            del: delegate,
            i: set.length
          });

          set.push(handler);

          element.addEventListener(handler.e, proxy, false);
        });
      },
      /**
       * Creates a new event
       * @param  {String} type The type of event to create (will map either to a mousevent or events)
       * @param  {Object} props The event data
       * @return {Object} returns The new event object
       */
      create: function(type, props) {
        var event = document.createEvent($.events.special[type] || 'Events'),
            bubbles = true;

        if(props){
          for(var name in props){
            (name == 'bubbles') ? (bubbles = !!props[name]) : (event[name] = props[name])
          }
        }

        event.initEvent(type, bubbles, true, null, null, null, null, null, null, null, null, null, null, null, null);

        return event;
      },
      /**
       * Iterates over a collection of events, executing a function for each item
       * @param  {String} The string or object containing the events
       * @param  {Function} fn the function to execute on each event type
       * @param  {Function} iterator The function to execute on each item
       */
      each: function(events, fn, iterator){
        if($.isObject(events)){
          $.each(events, iterator);
        }else{
          events.split(/\s/).forEach(function(event){
            iterator(event, fn);
          });
        }
      },
      /**
       * Finds and returns a specific event handler from handlers cache
       * @param  {DOM Element} element The DOM element the event has been bound to
       * @param  {Object} event The event object
       * @param  {Function} fn The function to execute on each event
       * @return {Object} returns The matching event handler
       */
      find: function(element, event, fn){
        event = $.events.parse(event);

        if(event.ns){
          var matcher = $.events.match(event.ns);
        }

        return (handlers[element.uid] || []).filter(function(handler){
          return handler
            && (!event.e  || handler.e == event.e)
            && (!event.ns || matcher.test(handler.ns))
            && (!fn       || handler.fn.uid == fn.uid)
        });
      },
      /**
       * Creates a regular expression with the defined namespace
       * @param  {String} namespace The event namespace
       * @return {RegEx} returns The regular expression
       */
      match: function(namespace){
        return new RegExp('(?:^| )' + namespace.replace(' ', ' .* ?') + '(?: |$)');
      },
      /**
       * Parse event string for type and any namespaced events
       * @param  {String} event The string which contains the event type and any namespaces
       * @return {Object} returns An object with parsed values for type and namespace properties
       */
      parse: function(event){
        var parts = ('' + event).split('.');

        return {
          e: parts[0],
          ns: parts.slice(1).sort().join(' ')
        }
      },
      /**
       * Helper method for unbinding events to elements
       * @param {DOM Element} element  The DOM element
       * @param {String} events The event to unbind
       * @param {Function} fn The function that maps to the event
       */
      remove: function(element, events, fn){
        $.events.each(events || '', fn, function(event, fn){
          $.events.find(element, event, fn).forEach(function(handler){
            delete handlers[element.uid][handler.i];
            element.removeEventListener(handler.e, handler.proxy, false);
          });
        });
      }
    };

    /*------------------------------------
     * Pub/Sub
     ------------------------------------*/

    $.apply($, {
      stack: {},
      publish: function(channel, args){
        $.stack[channel] && $.each($.stack[channel], function(){
          this.apply($, args || []);
        });
      },
      subscribe: function(channel, fn){
        if(!$.stack[channel]){
          $.stack[channel] = [];
        }

        $.stack[channel].push(fn);

        return [channel, fn];
      },
      unsubscribe: function(channel, subs){
        $.stack[channel] && $.each($.stack[channel], function(index, fn){

          if(subs && subs.length > 0){
            var fn = this;

            $.each(subs, function(){
              if(this == fn){
                $.stack[channel].splice(index, 1);
              }
            });
          }else{
            delete $.stack[channel];
          }
        });
      }
    });

    /*------------------------------------
     * Common RegEx patterns
     ------------------------------------*/

    $.patterns = {
      alpha: /[A-Za-z]/,
      classes: /^\.([\w-]+)$/,
      escape: /('|\\)/g,
      escapeRegex: /([-.*+?^${}()|[\]\/\\])/g,
      expressions: '(.*):(\\w+)(?:\\(([^)]+)\\))?$\\s*',
      ids: /^#([\w-]+)$/,
      nodes: /1|3|8|9|11/,
      numbers: /^(0|[1-9][0-9]*)$/i,
      ready: /complete|loaded|interactive/i,
      space: /\s+/g,
      tags: /^[\w-]+$/,
      templates: {
        keys: /\{(.+?)}/g,
        indexed:/\{(\d+)\}/g
      },
      trim: /^\s+|\s+$/g
    };

    /*------------------------------------
     * Browser detection
     ------------------------------------*/

    $.browser = {
      chrome: (/chrome/i).test(agent),
      firefox: (/firefox/i).test(agent),
      language: language && language.toLowerCase(),
      msie: (/msie/i).test(agent),
      opera: (/opera/i).test(agent),
      prefix: (/webkit/i).test(agent) ? '-webkit-' : (/firefox/i).test(agent) ? '-moz-' : (/opera/i).test(agent) ? '-o-' : (/msie/i).test(agent) ? '-ms-' : '',
      safari: (/safari/i).test(agent) && !window.v8Locale,
      version: version.match(/OS \d+_\d+/g) || version,
      webkit: (/webkit/i).test(agent)
    };

    /*------------------------------------
     * Device detection
     ------------------------------------*/

    $.device = {
      idevice: (/iphone|ipad|ipod/i).test(agent),
      ipad: (/ipad/i).test(agent),
      iphone: (/iphone/i).test(agent),
      ipod: (/ipod/i).test(agent),
      name: platform && platform.toLowerCase(),
      playbook: (/playbook/i).test(agent),
      touchpad: (/hp-tablet/i).test(agent)
    };

    /*------------------------------------
     * OS detection
     ------------------------------------*/

    $.os = {
      android: (/android/i).test(agent),
      blackberry: (/blackberry/i).test(agent),
      ios: $.device.ipad || $.device.iphone || $.device.ipad,
      mac: (/macintosh/i).test(agent),
      webos: (/webos/i).test(agent),
      windows: (/windows/i).test(agent)
    };

    /*------------------------------------
     * Feature detection
     ------------------------------------*/

    $.supports = {
      cssTransform: $.browser.prefix.replace('-', '') + 'Transform' in document.documentElement.style,
      cssTransitionEnd: $.device.idevice || $.device.playbook,
      cssTransform3d: 'WebKitCSSMatrix' in window && 'm11' in new WebKitCSSMatrix(),
      cssAnimationEvents: (typeof window.WebKitAnimationEvent != 'undefined'),
      homescreen: ('standalone' in navigator),
      iOS5: (/OS (5(_\d+)*) like Mac OS X/i).test(agent),
      localStorage: typeof(localStorage) !== undefined,
      retina: ('devicePixelRatio' in window && window.devicePixelRatio > 1),
      touch: 'ontouchstart' in window
    };

    /*------------------------------------
     * Events map
     ------------------------------------*/

    $.eventsMap = {
      cancel: $.supports.touch ? 'touchcancel' : 'mouseout',
      end:    $.supports.touch ? 'touchend' : 'mouseup',
      move:   $.supports.touch ? 'touchmove' : 'mousemove',
      resize: $.supports.touch ? 'orientationchange' : 'resize',
      start:  $.supports.touch ? 'touchstart' : 'mousedown',
      touch:  $.supports.touch ? 'tap' : 'click',
      scroll: 'scroll'
    };

    /*------------------------------------
     * CSS filters
     ------------------------------------*/

    $.filters = {
      checked: function(){
        if(this.checked)
          return this;
      },
      contains: function(index, nodes, text){
        if($.contains($(this).text(), text))
          return this;
      },
      eq: function(index, nodes, value){
        if(index === value);
          return nodes[value];
      },
      first: function(index){
        if(index === 0)
          return this;
      },
      hidden: function(){
        if(!$.filters.visible(this))
          return this;
      },
      last: function(index, nodes){
        if(index === nodes.length - 1)
          return this;
      },
      selected: function(){
        if(this.selected)
          return this;
      },
      visible: function(element){
        !element && (element = this);
        if(element.style.display !== 'none' && element.style.visibility !== 'hidden')
          return element;
      }
    };

    /*------------------------------------
     * Misc helpers
     ------------------------------------*/

    $.helpers = {
      blankIMG: 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
      emptyFn: function(){},
      loaderIMG: 'data:image/gif;base64,R0lGODlhEAAQAMQAAP%2F%2F%2F%2B7u7t3d3bu7u6qqqpmZmYiIiHd3d2ZmZlVVVURERDMzMyIiIhEREQARAAAAAP%2F%2F%2FwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH%2FC05FVFNDQVBFMi4wAwEAAAAh%2BQQFBwAQACwAAAAAEAAQAAAFdyAkQgGJJOWoQgIjBM8jkKsoPEzgyMGsCjPDw7ADpkQBxRDmSCRetpRA6Rj4kFBkgLC4IlUGhbNQIwXOYYWCXDufzYPDMaoKGBoKb886OjAKdgZAAgQkfCwzAgsDBAUCgl8jAQkHEAVkAoA1AgczlyIDczUDA2UhACH5BAUHABAALAAAAAAPABAAAAVjICSO0IGIATkqIiMKDaGKC8Q49jPMYsE0hQdrlABCGgvT45FKiRKQhWA0mPKGPAgBcTjsspBCAoH4gl%2BFmXNEUEBVAYHToJAVZK%2FXWoQQDAgBZioHaX8igigFKYYQVlkCjiMhACH5BAUHABAALAAAAAAQAA8AAAVgICSOUGGQqIiIChMESyo6CdQGdRqUENESI8FAdFgAFwqDISYwPB4CVSMnEhSej%2BFogNhtHyfRQFmIol5owmEta%2FfcKITB6y4choMBmk7yGgSAEAJ8JAVDgQFmKUCCZnwhACH5BAUHABAALAAAAAAQABAAAAViICSOYkGe4hFAiSImAwotB%2Bsi6Co2QxvjAYHIgBAqDoWCK2Bq6A40iA4yYMggNZKwGFgVCAQZotFwwJIF4QnxaC9IsZNgLtAJDKbraJCGzPVSIgEDXVNXA0JdgH6ChoCKKCEAIfkEBQcAEAAsAAAAABAADgAABUkgJI7QcZComIjPw6bs2kINLB5uW9Bo0gyQx8LkKgVHiccKVdyRlqjFSAApOKOtR810StVeU9RAmLqOxi0qRG3LptikAVQEh4UAACH5BAUHABAALAAAAAAQABAAAAVxICSO0DCQKBQQonGIh5AGB2sYkMHIqYAIN0EDRxoQZIaC6bAoMRSiwMAwCIwCggRkwRMJWKSAomBVCc5lUiGRUBjO6FSBwWggwijBooDCdiFfIlBRAlYBZQ0PWRANaSkED1oQYHgjDA8nM3kPfCmejiEAIfkEBQcAEAAsAAAAABAAEAAABWAgJI6QIJCoOIhFwabsSbiFAotGMEMKgZoB3cBUQIgURpFgmEI0EqjACYXwiYJBGAGBgGIDWsVicbiNEgSsGbKCIMCwA4IBCRgXt8bDACkvYQF6U1OADg8mDlaACQtwJCEAIfkEBQcAEAAsAAABABAADwAABV4gJEKCOAwiMa4Q2qIDwq4wiriBmItCCREHUsIwCgh2q8MiyEKODK7ZbHCoqqSjWGKI1d2kRp%2BRAWGyHg%2BDQUEmKliGx4HBKECIMwG61AgssAQPKA19EAxRKz4QCVIhACH5BAUHABAALAAAAAAQABAAAAVjICSOUBCQqHhCgiAOKyqcLVvEZOC2geGiK5NpQBAZCilgAYFMogo%2FJ0lgqEpHgoO2%2BGIMUL6p4vFojhQNg8rxWLgYBQJCASkwEKLC17hYFJtRIwwBfRAJDk4ObwsidEkrWkkhACH5BAUHABAALAAAAQAQAA8AAAVcICSOUGAGAqmKpjis6vmuqSrUxQyPhDEEtpUOgmgYETCCcrB4OBWwQsGHEhQatVFhB%2FmNAojFVsQgBhgKpSHRTRxEhGwhoRg0CCXYAkKHHPZCZRAKUERZMAYGMCEAIfkEBQcAEAAsAAABABAADwAABV0gJI4kFJToGAilwKLCST6PUcrB8A70844CXenwILRkIoYyBRk4BQlHo3FIOQmvAEGBMpYSop%2FIgPBCFpCqIuEsIESHgkgoJxwQAjSzwb1DClwwgQhgAVVMIgVyKCEAIfkECQcAEAAsAAAAABAAEAAABWQgJI5kSQ6NYK7Dw6xr8hCw%2BELC85hCIAq3Am0U6JUKjkHJNzIsFAqDqShQHRhY6bKqgvgGCZOSFDhAUiWCYQwJSxGHKqGAE%2F5EqIHBjOgyRQELCBB7EAQHfySDhGYQdDWGQyUhADs%3D',
      vars: {}
    };

    /*------------------------------------
     * Touch event binding
     ------------------------------------*/

    $.touch = function(){
      var event = {},
          touch = {},
          pressTimer = null,
          touchTimer = null,
          pressDelay = 500,

      touch = {
        cancel: function(e){
          touch.reset(true);
        },

        reset: function(deep){
          if(deep === true){
            event = {};
            touchTimer && clearTimeout(touchTimer) && (touchTimer  = null);
          }

          pressTimer && clearTimeout(pressTimer) && (pressTimer = null);
        },

        end: function(e){
          var time = Date.now();

          if(event.pressed && (time - event.timestamp >= pressDelay)){
            event.element.trigger('press');
            touch.reset(true);
          }else{
            touch.reset();

            if(event.delta){
              event.element.trigger('doubleTap');
              touch.reset(true);
            }
            else if((event.x2 && Math.abs(event.x1 - event.x2) > 20) || (event.y2 && Math.abs(event.y1 - event.y2) > 20)){
              var direction = Math.abs(event.x1 - event.x2) >= Math.abs(event.y1 - event.y2) ? (event.x1 - event.x2 > 0 ? 'Left' : 'Right') : (event.y1 - event.y2 > 0 ? 'Up' : 'Down'),
                  data = {
                    direction: direction.toLowerCase(),
                    x: event.x1 - event.x2,
                    y: event.y1 - event.y2
                  };

              event.element.trigger('swipe', data).trigger('swipe' + direction, data);
              event = {};
            }else if(event.timestamp > 0){
              event.element.trigger('tap');

              touchTimer = setTimeout(function(){
                event.element.trigger('singleTap');
                touch.reset(true);
              }, 250);
            }
          }
        },

        move: function(e){
          var evt = $.supports.touch ? e.touches[0] : e;

          touch.reset();

          event.x2 = evt.pageX;
          event.y2 = evt.pageY;
        },

        start: function(e){
          var time = Date.now(),
              evt = $.supports.touch ? e.touches[0] : e,
              delta = time - (event.timestamp || time);

          touchTimer && clearTimeout(touchTimer);

          event = {
            element: $(evt.target),
            delta: (delta > 0 && delta <= 200),
            pressed: true,
            timestamp: time,
            x1: evt.pageX,
            y1: evt.pageY
          };

          pressTimer = setTimeout(function(){
            e.preventDefault();
            touch.end(e);
          }, pressDelay);
        }
      };

      // bind start, move, end and cancel events to document.body (mobile = touch, desktop = mouse)
      $.each(['start', 'move', 'end', 'cancel'], function(index, method){
        $(document.body).on($.eventsMap[method], $.proxy(touch[method], touch));
      });

      $(window).on('scroll', $.proxy(touch.cancel, touch));

      return touch;

    }();

    // bind to touch event methods
    $.each(['tap', 'singleTap', 'doubleTap', 'press', 'swipe', 'swipeDown', 'swipeLeft', 'swipeRight', 'swipeUp'], function(index, event){
      $.fn[event] = function(fn){
        return this.on(event, fn);
      }
    });

    return $;

  })();

  window.Tapjoy = Tapjoy;

  '$' in window || (window.$ = Tapjoy);

})(window);
