(function(Tap){

  Tap.Html5 = {
    reverseGradient: function(value){
      var array = [],
          lng = value.length;

      for(var i = lng--; i--;){
        array.push([value[i][0], value[lng-i][1]]);
      }
      
		  value = Tap.Html5.gradient(array);
			
      return value;
    },
  
    gradient: function(value){
      var css = '',
          obj = {};
    
      if(!value && !value.length)
        return;
      
      for(var i = 0, k = value.length; i < k; i++){
        css += value[i].join(' ') + '% ,'
      }
   
      css = css.substr(0, css.length - 2);
   
      obj['background'] = Tap.cssPrefix[Tap.browser] + 'linear-gradient(top, ' + css + ')';
    
      return obj;
    },

    borderRadius : function(value){
      var args = Tap.Array.toArray(arguments)[0],
          obj = {};
          
      if(!Tap.Array.isArray(args)){
        value = String(value).replace(Tap.RegEx.numbers, '').split(' ');
        args = Tap.Array.toArray(value);
      }
			
      obj['border-radius'] = args.join('px ') + 'px';
			
			return obj;
    }     
  };
  
  Tap.cssReverseGradient = Tap.Html5.reverseGradient;
  Tap.cssGradient = Tap.Html5.gradient;
  Tap.cssBorderRadius = Tap.Html5.borderRadius;

})(Tapjoy);