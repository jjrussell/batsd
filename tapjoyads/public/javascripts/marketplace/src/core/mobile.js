(function(Tap, $){
	
  Tapjoy.Mobile = function(config){

    var config = Tap.extend({}, {
      useFastTouch: true,
      moveThreshold: 10,
      hoverDelay: 50,
      pressDelay: 750
    }, config);

    $.fn.press = function(fn){
      if($.isFunction(fn)){
        return $(this).live('press', fn);
      }else{
        return $(this).trigger('press');
      }
    };

    $.fn.swipe = function(fn){
      if($.isFunction(fn)){
        return $(this).live('swipe', fn);
      }else{
        return $(this).trigger('swipe');
      }
    };

    $.fn.tap = function(fn){
      if($.isFunction(fn)){
        return $(this).live('tap', fn);
      }else{
        return $(this).trigger('tap');
      }
    };

    var core = mobile(config);

    return core;
  };

  var mobile = function(config){
    var config = Tap.extend({}, {
      backSelector: '.back, .cancel, .goback',
      submitSelector: '.submit',
      touchSelector: 'a, .touch, li',
      defaultAnimation: 'fade',
      fullScreen: true,
      fullScreenClass: 'fullscreen',
      trackScrollPositions: true,
      useAnimations: true,
      useFastTouch: true,
      useTouchScroll: true,
      cacheGetRequests: true,
      animations: [{
        name: 'fade', 
        selector: '.fade'
      },{
        name: 'flipleft', 
        selector: '.flipleft, .flip', 
        is3d: true
      },{
        name: 'flipright', 
        selector:'.flipright', 
        is3d: true
      },{
        name:'pop', 
        selector:'.pop', 
        is3d: true
      },{
        name:'swapleft', 
        selector:'.swap', 
        is3d: true
      },{
        name:'slidedown', 
        selector:'.slidedown'
      },{
        name:'slideright', 
        selector:'.slideright'
      },{
        name:'slideup', 
        selector:'.slideup'
      },{
        name:'slideleft', 
        selector:'.slideleft, .slide'
      }]
    }, config || {});
    
    Tap.mobile = {
      animations: [],
      history: [],
      selectors: [],
      layout: [],
      init: function(config){
        var $t = this;
      
        $t.head = $('head:eq(0)'),
        $t.body = $('body:eq(0)'),
        $t.tapBuffer = 150,
        $t.currentPage = '';
        $t.orientation = 'portrait',
        $t.config = config;

        for(var j = 0, k = $t.config.animations.length; j < k; j++){
          var animation = $t.config.animations[j];

          if($t.config[animation.name + 'Selector'] !== undefined){
            animation.selector = $t.config[animation.name + 'Selector'];
          }

          $t.addAnimation(animation);
        }

        $t.selectors.push($t.config.touchSelector);
        $t.selectors.push($t.config.backSelector);
        $t.selectors.push($t.config.submitSelector);
        $t.selectors = $t.selectors.join(', ');
        
        $($t.selectors).css('-webkit-touch-callout', 'none');
					
        $t.layout.push(Tap.browser);
        
        if(Tap.supportsTransform3d){
          $t.layout.push('supports3d');
        }
        
        if(Tap.supportsiOS5 && $t.config.useTouchScroll){
          $t.layout.push('touchscroll');
        }

        if($t.config.fullScreenClass && window.navigator.standalone === true) {
          $t.layout.push($t.config.fullScreenClass, $t.config.statusBar);
        }
				
        $t.body.addClass($t.layout.join(' '))
        .bind('click', function(e){
          $t.click(e);
        })
        .bind(Tap.EventsMap.start, function(e){
          $t.touch(e);
        })
        .bind('tap click', function(e){
          $t.tap(e);
        })
        .bind('orientationchange', function(e){
          $t.turn(e);
        })
        .trigger('orientationchange');
          
         $(window).bind('hashchange', function(e){
           $t.hashChange(e);
         });
        
         var page = location.hash;
         
         if($('body > div.page.current').length === 0){
           $t.currentPage = $t.config.defaultPage ? $($t.config.defaultPage).addClass('current') : $('body div.page:eq(0)').addClass('current');
         }else{
           $t.currentPage = $('body > div.page.current');
         }
       
         $t.historySetHash($t.currentPage.attr('id'));
         $t.addPageToHistory($t.currentPage);

         if($(page).length === 1){
           $t.historyGoTo(page);
        }
      },
      
      getAnimation: function(el){
        var $t = this,
            animation;

        for(var i = 0, k = $t.animations.length; i < k; i++){
          if(el.is($t.animations[i].selector)){
            animation = $t.animations[i];
            break;
          }
        }

        if(!animation){
          animation = $t.config.defaultAnimation;
        }
        
        return animation;
      },
     
      reverseAnimation: function(animation){
        var map = {
          'up' : 'down',
          'down' : 'up',
          'left' : 'right',
          'right' : 'left',
          'in' : 'out',
          'out' : 'in'
        };

        return map[animation] || animation;
      },
      
      addAnimation: function(animation){
        var $t = this;
        
        if(Tap.type(animation.selector) === 'string' && Tap.type(animation.name) === 'string'){
          $t.animations.push(animation);
        }
      },
      
      addPageToHistory: function(page, animation){
        var $t = this;
        
        $t.history.unshift({
          page: page,
          animation: animation,
          hash: '#' + page.attr('id'),
          id: page.attr('id')
        });
      },

      historyGoBack: function(){
        var $t = this;

        if(history.length === 1){
          window.history.go(-1);
        }

        var from = $t.history[0],
            to = $t.history[1];

        if($t.historyNavigate(from.page, to.page, from.animation, true)) {
          return $t;
        }else {
          return false;
        }
      },
      
      historyGoTo: function(to, animation){

        var $t = this,
            from = $t.history[0].page;
        
        if(Tap.type(animation) === 'string'){
          for(var i = 0, k = $t.animations.length; i < k; i++){
            if($t.animations[i].name === animation){
              animation = $t.animations[i];
              break;
            }
          }
        }
        
        if(Tap.type(to) === 'string'){
          var next = $(to);
          to = next;
        }
   
        if($t.historyNavigate(from, to, animation)){
          return $t;
        }else{
          return false;
        }
      },
      
      historySetHash: function(hash){
        location.hash = '#' + hash.replace(/^#/, '');
      },
      
     historyNavigate: function(from, to, animation, goBack){

       var $t = this;
           goBack = goBack ? goBack : false,
					 top = 0;

      if(to === undefined || to.length === 0){
        $.fn.unselect();
        return false;
      }

      if(to.hasClass('current')){
        $.fn.unselect();
        return false;
      }

      $(':focus').trigger('blur');

      from.trigger('animationbegin', { direction: 'out', back: goBack });
      to.trigger('animationbegin', { direction: 'in', back: goBack });

      if(Tap.supportsAnimationEvents && animation && $t.config.useAnimations){
        if(!Tap.supportsTransform3d && animation.is3d){
          animation.name = $t.config.defaultAnimation;
        }      
				
				var finalAnimationName = animation.name,
            is3d = animation.is3d ? 'animating3d' : '';

        if(goBack){
          finalAnimationName = finalAnimationName.replace(/left|right|up|down|in|out/, $t.reverseAnimation);
        }

        from.bind('webkitAnimationEnd', navigationEndHandler);

        $t.body.addClass('animating ' + is3d);

        var lastScroll = window.pageYOffset;

        if($t.config.trackScrollPositions === true){
          to.css('top', window.pageYOffset - (to.data('lastScroll') || 0))
	       }

        to.addClass(finalAnimationName + ' in current');
        from.addClass(finalAnimationName + ' out');

        if($t.config.trackScrollPositions === true){
          from.data('lastScroll', lastScroll);
          
          $('.scroll', from).each(function(){
            $(this).data('lastScroll', this.scrollTop);
          });
        }
      }else{
        to.addClass('current in');
        navigationEndHandler();
      }

      function navigationEndHandler(event){
        var bufferTime = $t.tapBuffer;

        if(Tap.supportsAnimationEvents && animation && $t.config.useAnimations){
          
          from.unbind('webkitAnimationEnd', navigationEndHandler)
          .removeClass('current ' + finalAnimationName + ' out');

          to.removeClass(finalAnimationName);
          
          $t.body.removeClass('animating animating3d');

          if($t.config.trackScrollPositions === true){
            to.css('top', -to.data('lastScroll'));

            setTimeout(function(){
              to.css('top', 0);
              
              window.scroll(0, to.data('lastScroll'));
              
              $('.scroll', to).each(function(){
                this.scrollTop = - $(this).data('lastScroll');
              });
            }, 0);

          }
        }else{
          from.removeClass(finalAnimationName + ' out current');
          $t.tapBuffer += 201;
        }

        setTimeout(function(){
          to.removeClass('in');

	        from.trigger('afterAnimation');
	        to.trigger('afterAnimation');
					
        }, $t.tapBuffer);

        $t.currentPage = to;
      
        if(goBack){
          $t.history.shift();
        }else{
          $t.addPageToHistory($t.currentPage, animation);
        }

        from.unselect();
 
        $t.historySetHash($t.currentPage.attr('id'));

        to.trigger('animationend', { direction:'in', animation: animation});
        from.trigger('animationend', { direction:'out', animation: animation});
  
      }
      
      return true;
    },      
      getOrientation: function(){
        return orientation;
      },

      click: function(e) {

        var $t = this,
            el = $(e.target);

        if(!el.is($t.selectors)) {
          el = $(e.target).closest($t.selectors);
        }

        if(el && el.attr('href') && !el.isExternalLink()){
          e.preventDefault();
        }
      
        if(Tapjoy.supportsTouch){
          $(e.target).trigger('tap', e);
        }
      },   
      
      touch: function(e){
        
        var $t = this, 
            el = $(e.target);

        if(!el.is($t.selectors)){
          el = el.closest($t.selectors);
        }

        if(el.length && el.attr('href')){
          el.addClass('active');
        }

        el.on(Tap.EventsMap.move, function(){
          el.removeClass('active');
        });

        el.on('touchend', function(){
          el.unbind('touchmove mousemove');
        });
      },
      
      tap: function(e){

        var $t = this,
            el = $(e.target);

        if(!el.is($t.selectors)){
          el = el.closest($t.selectors);
        }

        if(!el.length || !el.attr('href')){
          return false;
        }

        var target = el.attr('target'),
            hash = el.prop('hash'),
            href = el.attr('href'),
            animation = null;

        if(el.isExternalLink()){
          el.unselect();
          return true;
        }
        else if(el.is($t.config.backSelector)){
          $t.historyGoBack(hash);
        }
        else if (el.is($t.config.submitSelector)){
          $t.submitParentForm(el);
        }
        else if(href === '#'){
          el.unselect();
          return true;
        }
        else{
          animation = $t.getAnimation(el);

          if(hash && hash !== '#'){
            el.addClass('active');
            $t.historyGoTo($(hash).data('referrer', el), animation, el.hasClass('reverse'));
            return false;
          }else{
            el.addClass('loading active');

            
            return false;
          }
        }
      },

      hashChange: function(e){
        var $t = this;
        
        if(location.hash === $t.history[0].hash)
          return true;
        
        if(location.hash === ''){
          $t.historyGoBack();
          return true;
        }
        
        if(($t.history[1] && location.hash === $t.history[1].hash)){
          $t.historyGoBack();
          return true;
        }
        
        $t.historyGoTo($(location.hash), $t.config.defaultAnimation);
      },
  
      turn: function(e) {
        var $t = this;
        
        $('body').css('minHeight', 1000);
         
        scrollTo(0,0);
        
        var bodyHeight = window.innerHeight;
        $('body').css('minHeight', bodyHeight);
  
        $t.orientation = Math.abs(window.orientation) == 90 ? 'landscape' : 'portrait';
        $('body').removeClass('portrait landscape').addClass($t.orientation).trigger('turn', {orientation: $t.orientation});
      }
    };
    
    $(document).ready(function(){
      Tap.mobile.init(config);
    });
          
  };

  $.fn.isExternalLink = function() {
    var $el = $(this);
    return ($el.attr('target') == '_blank' || $el.attr('rel') == 'external' || $el.is('a[href^="http://maps.google.com"], a[href^="mailto:"], a[href^="tel:"], a[href^="javascript:"], a[href*="youtube.com/v"], a[href*="youtube.com/watch"]'));
  };

  $.fn.makeActive = function() {
    return $(this).addClass('active');
  };

  $.fn.unselect = function(obj) {
    if(obj){
      obj.removeClass('active');
    }else{
      $('.active').removeClass('active');
    }
  };
})(Tapjoy, jQuery);