(function(Tap, $){
  
  Tap.Components = {
    Elements: {
      attr: {},
			borderRadius: 22,
      borderRadius: 4,			
      classes: {
        active: 'active',
				blur: 'blur',
				focus: 'focus',
        hover: 'hover'
      },
      click: function(event, ui){},
      clickEvent: 'click',			
      container: $(document),
      containerCSS : {},
      containerCls: '',
			css: {},
      cssCls: '',
      disabled: false,
      emptyText: '',
			gradient: null,        
      height: 'auto',
      hidden: false,
      iconCls: null,
      id: null,
      mousedownEvent: 'mousedown',
      mouseupEvent: 'mouseup',
      mousemoveEvent: 'mousemove',
      mouseoutEvent: 'mouseout',
      name: null,
			tap: function(event, ui){},
      text: '',
      theme: 'tapped',
      tooltip: null,
      vtype: null,
      width: null
    },
    Button: {
			enableToggle: false,
      flush: false,
      handleMouseEvents: true,
      iconPosition: 'left',
      textAlign: 'left',                
      toggle: function(event, ui, state){},
      type: 'button'        
    }
  };
	
	/**
	 * swap web events for touch events 
	 */
  if(Tap.supportsTouch){
    Tap.apply(Tap.Components.Elements, {
      clickEvent: 'touchstart',
      mousedownEvent: 'touchstart',
      mouseupEvent: 'touchend',
      mousemoveEvent: 'touchmove'
		});
	};
	
  // shared methods
  $.fn.extend({
    disableComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          disabled: true
        });
      });
    }, 

    enableComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          disabled: false
        });
      });
    }, 

    hideComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          hidden: true
        });
      });
    }, 

    showComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          hidden: false
        });
      });
    }, 

    setValue : function(val){
      return this.each(function(){
        $(this).setProperty({
          value: val
        });
      });
    },

    getValue : function(val){
      for(i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Builder.xtypes[i].toLowerCase());
         
        if(instance){
          return instance.config.value || '';
          break;
        }
      }
    },        

    isHidden : function(){
      for(i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Tap.xtypes[i].toLowerCase());
         
        if(instance){
          return instance.config.hidden || false;
          break;
        }
      }
    },

    isDisabled : function(){
      for(i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Tap.xtypes[i].toLowerCase());
         
        if(instance){
          return instance.config.disabled || false;
          break;
        }
      }
    },

    removeComponent : function(){
      return this.each(function(){
        
        for(i = Tap.xtypes.length; i--;){
          var instance = $.data(this, Tap.xtypes[i].toLowerCase());
             
          if(instance){
            $(this)['remove'+Tap.xtypes[i]]();
            break;
          }
        }
      });
    }, 

    setProperty : function(obj){
      var el = this;
      
      for(var i = 0, k = Tap.xtypes.length; i < k; i++){
        var instance = $.data(el[0], Tap.xtypes[i].toLowerCase());
           
        if(instance){
          $(this)['set'+Tap.xtypes[i]+'Property'](obj);
          break;
        }
      }
    },
    
    Tapified: function(type){
      var instance = $.data(this[0], type);
      
      if(instance)
        return true;
        
      return false;
    }      
  });
})(Tapjoy, jQuery);
