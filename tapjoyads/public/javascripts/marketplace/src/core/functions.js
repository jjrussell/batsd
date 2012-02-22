(function(Tap){
	
  Tap.extend({
    Function: {

      delay: function(callback, ms){
        var timer = 0;

        clearTimeout(timer);
        timer = setTimeout(callback, ms);
      }
    }
  });

  Tap.delay = Tap.alias(Tap.Function, 'delay');
	
})(Tapjoy);