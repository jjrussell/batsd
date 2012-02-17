(function(Tap){

  var objectPrototype = Object.prototype,
      hasOwn = objectPrototype.hasOwnProperty;

  Tap.extend({
    Object: {

      alias: function(object, method){
        return function(){
          return object[method].apply(object, Tap.Array.toArray(arguments));
        };
      },

      format: function(tpl, object){
        object = object || {};

        return tpl.replace(/%{(.+?)}/g, function(pattern, key) {
          return !object[key] ? '' : object[key];
        });
      },

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

      removeKey: function(object, key){

        for(var property in object){
          if(object.hasOwnProperty(property) && property === key){
            delete object[property];
          }
        }
        return object;
      },

      removeKeyWhere: function(object, prop, value){
				
        for(var property in object){
          if(object.hasOwnProperty(property) && property === prop && object[property] === value){
            delete object[property];
          }
        }

        return object;
      },

      getKey: function(object, value){
        for(var property in object){
          if(object.hasOwnProperty(property) && object[property] === value){
            return property;
          }
        }

        return null;
      },

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

      getValues: function(object) {
        var values = [],
            property;

        for(property in object){
          if(object.hasOwnProperty(property)) {
            values.push(object[property]);
          }
        }

        return values;
      }
    }	
  });

  Tap.alias = Tap.Object.alias(Tap.Object, 'alias');

})(Tapjoy);
