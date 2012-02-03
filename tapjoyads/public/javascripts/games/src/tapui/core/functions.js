(function(Tap){
	
  var functionPrototype = Function.prototype;
	
  Tap.Function = {
		/**
     * 
     * @param {Object} obj
     */
    isFunction: function( obj ) {
      return Tap.type(obj) === "function";
    },
    /**
     * Delay the execution of code 
     * @param {Object} callback Can be a string of executable code, or a call to a function
     * @param {Object} ms The timeout in milliseconds
     */
    delay: function(callback, ms){
      var timer = 0;
      
      clearTimeout(timer);
      timer = setTimeout(callback, ms);
    }		
	};
	
	Tap.isFunction = Tap.alias(Tap.Function, 'isFunction'); 
  Tap.delay = Tap.alias(Tap.Function, 'delay');
	
})(Tapjoy);