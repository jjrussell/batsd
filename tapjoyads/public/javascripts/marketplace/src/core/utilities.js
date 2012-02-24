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
      },
			notification: function(config){
				
				config = Tap.extend({}, {
          container: $(document.body),
					delay: 10000,
          message: '',
					type: 'normal'
				}, config || {});
				
				var wrap = $(document.createElement('div'));
				
				if($('#ui-notification').length == 0){
	        wrap.attr('id', 'ui-notification')
	        .addClass('ui-notification')
	        .appendTo(config.container);
				}else{
					wrap = $('#ui-notification');
				}

        wrap.html(config.message)
				
        var width = wrap.outerWidth(true);
        
        wrap.css({
          width: width + 'px',
          left: ((config.container.outerWidth(true) - width) / 2) + 'px'
        });
				
				$(window).resize(function(){
	        wrap.css('left', ((config.container.outerWidth(true) - width) / 2) + 'px')
				});
				
				Tap.delay(function(){
					if(wrap.length > 0)
            wrap.empty().remove();
				}, config.delay);
			},
			
			or: function(v,d) {
			  console.log(this);
        if (this.isEmpty(v)) {
          return d;
        }
        return v;
			},
			
			isEmpty: function(v) {
        return v == undefined || v == null || v == '';
			},
			
      Storage: {
        set: function(k) {
          try {
            localStorage[k] = v;
            return true;
          } catch (e) {
            return false;
          }
        },
      
        get: function(k) {
          return localStorage[k];
        },
      
        remove: function(k) {
          localStorage.removeItem(k);
        },
      
        reset: function() {
          localStorage.clear();
        }
      }
    }
  });
  
  Tap.log = Tap.alias(Tap.Utils, 'log');
  Tap.ls = Tap.alias(Tap.Utils.Storage, 'ls');

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


