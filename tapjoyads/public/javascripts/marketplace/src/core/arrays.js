(function(Tap){
	
  Tap.extend({
    Array: {

      toArray: function(item, start, end){
        if(!item || !item.length)
          return [];

        var array = [];

        if(Tap.type(item) === 'string'){
          item = item.split('');
        }

        end = end ? ((end < 0) ? item.length + end : end) : item.length;

        for(var i = (start || 0); i < end; i++){
          array.push(item[i]);
        }

        return array;
      },

      normalizeArray: function(array){
        if(!array || !array.length)
          return [];

        var result = [];

        for(var i = 0, k = array.length; i < k; ++i){
          if(array[i] !== ''){
            result.push(array[i]);
          }
        }

        return result;
      },

      inArray: function(array, item){
        return array.indexOf(item) !== -1;
      },

      spliceArray: function(value, array){
        if(Tap.inArray(value, array)){
          for (var i = 0, k = array.length; i < k; i++) {
            if(array[i] === value){
              array.splice(i, 1);
              return array;
            }
          }
        }
      }
    }  
  });
  
  Tap.toArray = Tap.alias(Tap.Array, 'toArray');
  Tap.inArray = Tap.contains = Tap.alias(Tap.Array, 'inArray');
  Tap.spliceArray = Tap.alias(Tap.Array, 'spliceArray');

})(Tapjoy);
