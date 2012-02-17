(function(Tap, $){

  $.fn.Button = function(config){
    
    config = Tap.extend({}, Tap.Components.Elements, Tap.Components.Button, config || {});
    
    return this.each(function(){

      // cache reference to Html element
      var $t = $(this);
      
      // check if instance exists   
      if($t.Tapified('button'))
        return;
        
      // create new button         
      new Button($t.get(0), config);
    });
  };
    
  var Button = function(container, config){
    // store this
    var $t = this;
  
    // create store of properties
    $t.config = config;
          
    // set container property
    $t.container = $t.config.container = $(container);
  
    // create button markup  
    $t.createButton();
    
    // attach button events
    $t.initEvents();
    
    // use $.data to store button instance data - avoids memory leak issues
    $.data(container, 'button', $t);  
  };

  Tap.extend(Button.prototype, {
    
    createButton : function(){
      var $t = this,
          anchor = $(document.createElement('a')),
          button = $(document.createElement('input')),
          radius = Tap.cssBorderRadius($t.config.borderRadius);

      // apply theme and text alignment 
      $t.container.addClass('ui-joy-button ' + $t.config.theme)
      .append(anchor);
      
      // set button type and append to our anchor element
      button.attr('type', $t.config.type)
      .appendTo(anchor);
      
      // create icon and append to our anchor
      if($t.config.iconCls && $t.config.type !== 'image'){
        anchor.addClass('icon')
        .append($t.createIcon());
      }
      else if($t.config.iconCls && $t.config.type === 'image'){
        // attach pixel gif as source and add icon class
        button.attr('src', Tap.blankIMG)
        .addClass($t.config.iconCls);
        
        // removes the padding we have setup for normal buttons
        anchor.addClass('image')
      }

      // add buttons text  
      if($t.config.text && $t.config.type !== 'image'){
        button.val($t.config.text)
      }
      
      // check if our button contains a hash '#page', if so, set href on anchor and apply transition class
      if($t.config.target){
        anchor.attr('href', ($t.config.disabled ? 'javascript:void(0);' : $t.config.target))
        .addClass($t.config.transition);
      }
  
      // apply css stylings, radius, text alignment and additional classes
      anchor.css($t.config.css)
      .addClass('text-' + $t.config.textAlign + ' ' + $t.config.cssCls);
      
      // check for disabled property
      if($t.config.disabled){
        $t.container.addClass($t.config.disabledCls); 
      }
      
      // apply radius to all elements for mobile outline
      $([$t.container, anchor, button]).css(radius);
      
      // apply radius, container css stylings and classes that have been defined
      $t.container.css($t.config.containerCSS)
      .addClass($t.config.containerCls);

      if($.browser.mozilla)
        $t.container.addClass('padfix');
        
      // set button width if defined
      if($t.config.width){
        $t.container.css({
          'width': parseInt($t.config.width, 0) + 'px'
        });
      }
           
      // prevent text selection
      $t.container.preventHighlight();
      
      // store reference 
      $t.anchor = anchor;
        
      // return button
      return $t.container;
    },
    
    createIcon : function(){
      var $t = this,
          icon = $(document.createElement('div')),
          img = $(document.createElement('img'));
  
      // add icon class
      icon.addClass('img')
      .append(img);
      
      // apply icon style and append to icon container    
      img.attr('src', Tap.blankIMG)
      .addClass($t.config.iconCls);
  
      // return icon
      return icon;
    },
    
    initEvents : function(){
      var $t = this;
      
      // set toggle state to inactive
      $t.config.pressed = false;
          
      // bind clickEvent to element
      $t.container.bind($t.config.clickEvent, function(e){
        
        if($t.config.disabled)
          return;
            
        // expose container and properties on click
        var props = {
          container : $t.container,
          config : $t.config
        };
        
        // is button a normal button or toggle button
        if(!$t.config.enableToggle){
          if($.isFunction($t.config.touch))
            // fire in the hole!
            $t.config.touch.apply($t.container, [e, props]);
        }else{
            // is toggle active (pressed)
            if(!$t.config.pressed){
              $t.config.pressed = true;
              
              $t.container.addClass($t.config.activeCls);
              
              if($t.reverseGradient)
                $t.container.css($t.reverseGradient); 
            }else{ 
              $t.config.pressed = false;
              $t.container.removeClass($t.config.activeCls);
            }
            // check whether toggle is a function
            if($.isFunction($t.config.toggle))
              $t.config.toggle.apply($t.container, [e, props, $t.config.pressed]);
        }
      })
      .bind('mouseover ' + 
         $t.config.mouseout + ' ' + 
         $t.config.mousedown + ' ' + 
         $t.config.mouseup, function(e){
        
        var event = e.type;
        
        if($t.config.disabled)
          return;

        if(event === $t.config.mousedown){
          $t.container.addClass($t.config.activeCls);
        }
        else if(event === $t.config.mouseup && !$t.config.pressed){
          $t.container.removeClass($t.config.hoverCls)
          .removeClass($t.config.activeCls);
        }
        else if(event === $t.config.mouseout && !$t.config.pressed){
          $t.container.removeClass($t.config.activeCls)
          .removeClass($t.config.hoverCls);
        }
        else if(event === 'mouseover'){
          if(!$t.container.hasClass($t.config.activeCls) && !$t.config.pressed)
            $t.container.addClass($t.config.hoverCls)
        }
      });
    },
  
 /**
     * setButtonProperty updates any set of properties passed (key/value pairs)
     * @param {Object} el The button instance
     * @param {Object} config The config properties to update
     */
    setButtonProperty : function(config){
      try{
        var $t = this;
          
        // loop through button config properties
        for(var prop in $t.config){
          for(var option in config){
            if(option === prop){
              // make visual changes
              $t.updateProperty(option, config[option]);
              // update components configuration
              $t.config[prop] = config[option];
            }
          }
        }
      }
      catch(exception){
        Tap.log('There was an error:' + exception, 'Tap.Button');
      }
    },
  
    /**
     * Updates the button UI to reflect property changes
     * @method Button.updateProperty
     * @param {Object} type Property key value
     * @param {Object} val Value of the new property
     */  
    updateProperty : function(key, val){
      
      var $t = this;
      
      switch(key){
        case 'css':
          $t.anchor.css(val || {});
          break;

        case 'containerCSS':
          $t.container.css(val || {});
          break;

        case 'hidden' :
          val ? $t.container.hide() : $t.container.show();
          break;
  
        case 'disabled' :
          if(val){
            $t.container.addClass('disabled')
            if($t.config.target.length)
              $t.anchor.attr('href', 'javascript:void(0);');
          }else{
            $t.container.removeClass('disabled');
            if($t.config.target.length)
              $t.anchor.attr('href', $t.config.target);
          }
          break;
  
        case 'pressed' :
          val ? $t.container.addClass('active') : $t.container.removeClass('active');
          break;
        
        case 'textAlign':
          $t.anchor.removeClass('text-' + $t.config.textAlign).addClass('text-'+ val); 
          break;
          
        case 'text' :
          $t.button.val(val);
  
          if($t.config.width){
            $t.container.css({
              'width': parseInt($t.config.width, 0)
            });
          }
          break;
  
        case 'theme' :
            $t.container.removeClass($t.config.theme).addClass(val);
          break;
          
        case 'width' :
          $t.container.css({
            'width': parseInt(val, 0)
          });
          
          break;

        default:
          return;   
      }
    },
  
    /**
     * Remove the button object from the DOM
     * @param {Object} el The button
     */
    removeButton : function(){
      var $t = this;
      
      // empty HTML container element and then remove
      $t.container.empty().remove();
  
      // remove object data    
      $.data($t.container, 'button', null);
      
      // null out obj
      $t = null;
    }
  });
  
  $.fn.extend({
    /**
     * @method removeButton Removes a button from the DOM
     */
    removeButton : function(){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.removeButton();
      });
    },
    /**
     * @method disableButton Disables a button 
     */
    disableButton : function(){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.setButtonProperty({disabled: true});
      });
    },
    /**
     * @method enableButton Enables a button
     */
    enableButton : function(){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.setButtonProperty({disabled: false});
      });
    },
    /**
     * @method hideButton Hides a button
     */
    hideButton : function(){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.setButtonProperty({hidden: true});
      });
    },
    /**
     * @method showButton Shows a button
     */
    showButton : function(){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.setButtonProperty({hidden: false});
      });
    },
    /**
     * @method setButtonProperty Updates any defined properties for an object
     * @param {Object} config Key/Value pairs
     * @example
     * 
     * $(this).setButtonProperty({ hidden: true });
     */
    setButtonProperty : function(config){
      return this.each(function(){
        var $t = $.data(this, 'button');
             
        if(!$t)
          return;
          
        $t.setButtonProperty(config);
      });
    }  
  });
  
  Tap.apply(Tap, {
    Button : function(config){
  
      var $t = $(config.container),
          config = Tap.extend(this, Tap.Components.Elements, Tap.Components.Button, config || {});
          
      return $t.Button(config);
    }  
  });
})(Tapjoy, jQuery);