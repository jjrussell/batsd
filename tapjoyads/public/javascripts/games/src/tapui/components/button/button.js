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
	
	  // replace button element with div element
	  if(container.tagName == 'BUTTON')
	    container = $t.convertToDiv(container);
	      
	  // set container property if instance was created using jQuery selector
	  $t.container = $t.config.container = $(container);
	
	  // apply jqext class + any additional stylings
	  $t.container.addClass('tapped')
	  .css($t.config.containerCSS)
		.addClass($t.config.containerCls);
	  
		// switch click to tap event  
		if(Tap.supportsTouch){
			$t.pressCallback =  'tap';
		}else{
			$t.pressCallback =  'click'
		}	
		
	  // create button markup  
	  $t.createButton();
	  
	  // attach button events
	  $t.initEvents();
	  
	  // attach data to DOM element - safe and free from memory leaks
	  $.data(container, 'button', $t);  
	};

  Tap.extend(Button.prototype, {
	  /**
	   * Replace button element with div
	   * @param {Html element} container
	   */
	  convertToDiv : function(container){
	    var container = $(container),
	        id = container.attr('id'),
	        css = container.attr('class'), 
	        div = $(document.createElement('div')); 
	
	    // apply attributes from button element    
	    div.attr({
	      'id': id,
	      'class': css
	    });
	    
	    // replace button element with div
	    container.replaceWith(div);
	    
	    // return new div element
	    return div[0];
	  },
	  /**
	   * Create the HTML markup of the button
	   */
	  createButton : function(){
	    var $t = this,
	        button = $(document.createElement('div')),
	        radius = Tap.cssBorderRadius($t.config.borderRadius);
					
	    // apply theme and text alignment 
	    button.addClass('ui-tap-button ' + $t.config.theme + ' text-' + $t.config.textAlign)
	    .appendTo($t.container);
	
	    // create button icon div
	    if($t.config.iconCls){
	      button.addClass('pt')
	      .append($t.createIcon());
	    }
	
	    // create text div         
	    if($t.config.text){
	      var text = $(document.createElement('div'));
	      
	      text.addClass('text')
	      .html($t.config.text)
	      .appendTo(button);
	    }
	
	    if($t.config.text.length == 0 && $t.config.iconCls){
	      $t.iconOnly = true
				$t.container.addClass('iconOnly');			
			}
	
	    // apply radius and any additional styling
	    button.css(radius)
	    .css($t.config.css)
			.addClass($t.config.cssCls);
				    
	    // prevent text selection
	    button.preventHighlight();
			
	    // force width
	    if($t.config.width && !$t.iconOnly){
	      $t.container.css({
	        'width': parseInt($t.config.width, 0)
	      });
	    }else if($t.iconOnly){
				 $t.container.css({
	        'width': '30px'
	      });
			}
	    
	    // store reference 
	    $t.button = button;
	
	    // return button
	    return button;
	  },
	  /**
	   * Creates the buttons icon
	   * @return The new button Html markup
	   */
	  createIcon : function(){
	    var $t = this,
	        icon = $(document.createElement('div')),
	        img = $(document.createElement('img'));
	
	    // add icon class
	    icon.addClass('icon');
	    
	    // apply icon style and append to icon container    
	    img.attr('src', Tap.blankIMG)
	    .addClass($t.config.iconCls)
	    .appendTo(icon);
	
	    // return icon
	    return icon;
	  },
	  
	  initEvents : function(){
	    var $t = this;
	    
	    // set toggle state to inactive
	    $t.config.pressed = false;
	        
	    // bind clickEvent to element
	    $t.container.bind($t.config.clickEvent, function(e){
	      // create UI object
	      var props = {
	        button : $t.button,
	        container : this,
	        config : $t.config
	      };
	      
	      // is button a normal button or toggle button
	      if(!$t.config.enableToggle){
	         // check if button is disabled
	         if(!$t.config.disabled){
	          // check whether click is a function
	          if($.isFunction($t.config[$t.pressCallback]))
	            // fire in the hole!
	            $t.config[$t.pressCallback].apply($t.container, [e, props]);
	         }
	      }else{
	        // is toggle disabled 
	        if(!$t.config.disabled){
	          // is toggle active (pressed)
	          if(!$t.config.pressed){
	            $t.config.pressed = true;
							
	            $t.button.addClass($t.config.classes.active);
							
							if($t.reverseGradient)
	  						$t.button.css($t.reverseGradient); 
	          }else{ 
	            $t.config.pressed = false;
	            $t.button.removeClass($t.config.classes.active);
	          }
	          // check whether toggle is a function
	          if($.isFunction($t.config.toggle))
	            $t.config.toggle.apply($t.container, [e, props, $t.config.pressed]);
	        }
	      }
	    })
			.bind($t.config.mousedownEvent, function(){
				
        if($t.config.disabled)
          return;

        $t.button.addClass($t.config.classes.active);
      })
      .bind($t.config.mouseupEvent, function(){
				
        if($t.config.disabled)
          return;

        $t.button.removeClass($t.config.classes.hover)
				.removeClass($t.config.classes.active);
      })			
			.bind('mouseout mouseover', function(e){
				var which = e.type;
				
				if($t.config.disabled)
				  return;
					
			  if(which === 'mouseout' && !$t.config.pressed){
					$t.button.removeClass($t.config.classes.active)
					.removeClass($t.config.classes.hover);
				}
				else if(which === 'mouseover'){
					if(!$t.button.hasClass($t.config.classes.active) && !$t.config.pressed)
					  $t.button.addClass($t.config.classes.hover)
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
          // property match->update object->update checkbox UI
          for(var option in config){
            if(option === prop){
              // extend visual changes
              $t.updateProperty(option, config[option]);
              // update object property
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
          $t.button.css(val || {});
          break;

        case 'containerCSS':
          $t.container.css(val || {});
          break;

        case 'hidden' :
          val ? $t.container.hide() : $t.container.show();
          break;
  
        case 'disabled' :
          val ? $t.button.addClass('disabled') : $t.button.removeClass('disabled');
          break;
  
        case 'pressed' :
          val ? $t.button.addClass('active') : $t.button.removeClass('active');
          break;
			  
				case 'textAlign':
				  $t.button.removeClass('text-' + $t.config.textAlign).addClass('text-'+ val); 
          break;
					
        case 'text' :
          $('.text', $t.container).html(val);
  
          if($t.config.width){
	          $t.container.css({
	            'width': parseInt($t.config.width, 0)
	          });
          }
          break;
  
        case 'theme' :
            $t.button.removeClass($t.config.theme).addClass(val);
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

  /**
   * Tap.Button
   * @param {Object} config The button properties
   */
  Tap.apply(Tap, {
    Button : function(config){
  
      var $t = $(config.container),
          config = Tap.extend(this, Tap.Components.Elements, Tap.Components.Button, config || {});
					
      return $t.Button(config);
    }  
  });
})(Tapjoy, jQuery);