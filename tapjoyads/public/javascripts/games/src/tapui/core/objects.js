(function(Tap){
  var objectPrototype = Object.prototype,
      hasOwn = objectPrototype.hasOwnProperty;
  
  Tap.Object = {
    /**
     * 
     * @param {Object} object
     * @param {Object} method
     */
		alias: function(object, method) {
      return function(){
        return object[method].apply(object, Tap.toArray(arguments));
      };
    },
		/**
		 * 
		 * @param {Object} tpl
		 * @param {Object} object
		 */
    format: function(tpl, object){
      var $t = this;

      for(var property in object){
        if(object.hasOwnProperty(property)){
          var regex = new RegExp('{' + property + '}', 'g'),
              val = object[property];
  
          tpl = tpl.replace(regex, val);
        }
      }
      
      return tpl;
    },
		/**
		 * 
		 * @param {Object} object
		 */
    sortObject: function(object){
      var sorted = {},
          array = [];

      for(var property in object){
        if(object.hasOwnProperty(property)){
          array.push(property);
        }
      }
      
      array.sort();
      
      for(var key = 0; key < array.length; key++){
        sorted[array[key]] = object[array[key]];
      }
      
      return sorted;
    },
    /**
     * 
     * @param {Object} object
     * @param {Object} key
     * @param {Object} returnObj
     */
    removeKey: function(object, key, returnObj){
      var obj = {};
      
      for(var property in object){
        if(object.hasOwnProperty(property) && property === key){
          
          if(returnObj)
            obj[property] = object[property];
            
          delete object[property];
          
          if(returnObj)
            return obj;
        }
      }
      
      return object;
    },
    /**
     * 
     * @param {Object} object
     * @param {Object} prop
     * @param {Object} value
     * @param {Object} returnObj
     */
    removeKeyWhere: function(object, prop, value, returnObj){
      var obj = {};
      
      for(var property in object){
        if(object.hasOwnProperty(property) && property === prop && object[property] === value){
          
          if(returnObj)
            obj[property] = object[property];
            
          delete object[property];
          
          if(returnObj)
            return obj;
        }
      }
      
      return object;
    },    
    /**
     * 
     * @param {Object} object
     * @param {Object} value
     */
    getKey: function(object, value) {
      for(var property in object){
        if(object.hasOwnProperty(property) && object[property] === value){
          return property;
        }
      }

      return null;
    },
    /**
     * 
     * @param {Object} object
     */
    getKeys: function(object) {
      var keys = [],
          property;

      for(property in object){
        if(object.hasOwnProperty(property)){
          keys.push(property);
        }
      }
      
      return keys;
    },
    /**
     * 
     * @param {Object} object
     */
    getValues: function(object) {
      var values = [],
          property;

      for(property in object){
        if(object.hasOwnProperty(property)) {
          values.push(object[property]);
        }
      }

      return values;
    },
    /**
     * 
     * @param {Object} obj
     */
    isSimple: function(obj){
      if(!obj || Tap.type(obj) !== "object" || obj.nodeType || Tap.isWindow(obj)){
        return false;
      }

      try{
        // Not own constructor property must be Object
        if(obj.constructor && !hasOwn.call(obj, "constructor") && !hasOwn.call(obj.constructor.prototype, "isPrototypeOf")){
          return false;
        }
      }catch(e){
        // IE 8, 9 Will throw exceptions on certain host objects #9897
        return false;
      }

	    // Own properties are enumerated firstly, so to speed up,
	    // if last one is own, then all properties are own.
	
	    var key;
	      for( key in obj ){}
	        return key === undefined || hasOwn.call( obj, key );
	    } 		
  };
  
	// create alias to alias :-x
	Tap.alias = Tap.Object.alias;
	
})(Tapjoy);
