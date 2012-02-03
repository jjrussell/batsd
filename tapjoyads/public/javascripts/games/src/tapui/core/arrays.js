(function(Tap){
  
  Tap.Array = {
    toArray: function(iterable, start, end){
      if(!iterable || !iterable.length){
        return [];
      }

      if(typeof iterable === 'string'){
        iterable = iterable.split('');
      }

      var array = [], i;
          start = start || 0;
          end = end ? ((end < 0) ? iterable.length + end : end) : iterable.length;

      for(i = start; i < end; i++){
        array.push(iterable[i]);
      }

      return array;
    },
    /**
     * 
     * @param {Object} array
     */
    isArray: function(array){
      return (/array/i).test(array.constructor) ? true : false;
    },
    /**
     * Normalize array
     * @param {object} array
     */
    normalizeArray: function(array){
    
      if(!array || !array.length){
        return [];
      }
      
      var result = [];
      
      for(var i = 0, k = array.length; i < k; ++i){
        if(array[i] !== ''){
          result.push(array[i]);
        }
      }
      
      return result;
    },
    
    /**
     * Check if array contains a given value
     * @param {object} value
     * @param {object} array
     */
    inArray: function(array, item) {
      return array.indexOf(item) !== -1;
    },
    /**
     * Remove a specific value from an array
     * @param {object} value
     * @param {object} array
     */
    spliceArray: function(value, array){
      if(Tap.inArray(value, array)){
        for(var i = 0, k = array.length; i < k; i++){
          if(array[i] === value){
            array.splice(i, 1);
            return array;
          }
        }
      }
    }    
  };
  
  Tap.toArray = Tap.alias(Tap.Array, 'toArray');
  Tap.isArray = Tap.alias(Tap.Array, 'isArray');
  Tap.inArray = Tap.contains = Tap.alias(Tap.Array, 'inArray');
  Tap.spliceArray = Tap.alias(Tap.Array, 'spliceArray');
  
})(Tapjoy);
