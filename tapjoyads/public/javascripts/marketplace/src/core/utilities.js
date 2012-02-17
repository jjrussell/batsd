(function(Tap, $){
  
  Tap.extend({
    Utils: {
      /**
       * Prints to the window console
       * @param {mixed} result Can be elements, functions, arrays, objects, you name it
       * @param {mixed} message Can be elements, functions, arrays, objects, you name it
       */
      log : function(result, message){
        if(window.console && window.console.log){
          window.console.log(result +' :: '+ message);
        }
      }
    }
  });
  
  Tap.log = Tap.alias(Tap.Utils, 'log');

  $.fn.extend({
    preventHighlight: function(){
      return this.each(function(){
        this.onselectstart = function(){
          return false;
        };
	      
        this.unselectable = 'on';
        $(this).css({
          '-moz-user-select': 'none',
          '-khtml-user-select': 'none',
          'user-select': 'none',
          '-webkit-user-select': 'none'
        });
      });
    }
  });  

})(Tapjoy, jQuery);


