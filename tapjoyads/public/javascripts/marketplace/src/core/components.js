(function(Tap, $){
  
  Tap.Components = {
    Elements: {
      activeCls: 'active',
      attr: {},
      borderRadius: 0,
      click: function(event, ui){},
      clickEvent: Tap.supportsTouch ? 'tap' : 'click',    
      container: $(document),
      containerCSS : {},
      containerCls: '',
      css: {},
      cssCls: '',
      disabled: false,
      disabledCls: 'disabled',
      emptyText: '',
      height: 'auto',
      hidden: false,
      hoverCls: 'hover',      
      iconCls: null,
      id: null,
      mousedown: Tap.EventsMap.start,
      mouseup: Tap.EventsMap.end,
      mousemove:  Tap.EventsMap.move,
      mouseout: Tap.EventsMap.cancel,
      name: null,
      tap: function(event, ui){},
      text: '',
      theme: 'tapped',
      transition: 'fade',     
      tooltip: null,
      width: null
    },
    Button: {
      enableToggle: false,
      handleMouseEvents: true,
      target: '',
      textAlign: 'left',
      toggle: function(event, ui, state){},
      touch: function(event, ui){},
      type: 'button'      
    }
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
