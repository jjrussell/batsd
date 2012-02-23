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
			dialog: function(msg, container, delay){
				var wrap = $(document.createElement('div')),
				    container = $(container || document.body);
				
				if($('#ui-notification').length == 0){
	        wrap.attr('id', 'ui-notification')
	        .addClass('ui-notification')
	        .html(msg)
	        .appendTo(container);
				}else{
					wrap = $('#ui-notification');
					
					wrap.html(msg);
				}
				
        var width = wrap.outerWidth(true);
        
        wrap.css({
          width: width + 'px',
          left: ((container.outerWidth(true) - width) / 2) + 'px'
        });
				
				this.dialogbox = wrap;
				
				$(window).resize(function(){
	        wrap.css('left', ((container.outerWidth(true) - width) / 2) + 'px')
				});
				
				Tap.delay(function(){
					Tap.Utils.destroyDialog();
				}, delay || 10000);
			},
			destroyDialog: function(){
				if(this.dialogbox)
				  this.dialogbox.empty().remove();
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


