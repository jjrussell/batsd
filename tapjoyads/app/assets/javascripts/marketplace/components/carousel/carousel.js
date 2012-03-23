(function(Tap, $){

  $.fn.Carousel = function(config){

    config = Tap.extend({}, Tap.Components.Elements, Tap.Components.Carousel, config || {});

    return this.each(function(){

      var $t = $(this);

      if($t.Tapified('carousel'))
        return;

      new Carousel($t.get(0), config);
    });
  };

  var Carousel = function(container, config){

    var $t = this;
 
    $t.config = config;
    $t.prefix = '-' + Tap.browser.prefix;

    $t.container = $t.config.container = $(container);

    $t.create();
    $t.setupSlideDeck();
    $t.createNavigation();

    if($t.config.hasPager)
      $t.createPager();

    $t.updateNavigation();

    $t.applyListeners();

    $t.container.addClass($t.config.cssClass);

    $.data(container, 'carousel', $t);
  };

  Tap.extend(Carousel.prototype, {
    create : function(){
      var $t = this,
          wrap = $(document.createElement('div')),
          html = $t.container.html();

      $t.container.empty().addClass('ui-joy-carousel');

      wrap.addClass('wrapper')
      .append(html)
      .preventHighlight()
      .appendTo($t.container);

      $t.wrap = wrap;
    },

    turn : function(){
      var $t = this;

      $t.wrap.css($t.prefix +'-transform', 'translate(0px, 0px)');
      $t.current = 0;
      $t.setupSlideDeck();
      $t.updateNavigation();

    },

    setupSlideDeck: function(){
      var $t = this;

      $t.current = 0;

      $t.innerWidth = $t.container.width();
      $t.innerHeight = $t.container.height() > 0 ? $t.container.outerHeight(true) : $t.config.minHeight;

      $t.container.css('height', $t.innerHeight + 'px');

      $t.innerWidth = $t.container.outerWidth(true);
      $t.innerHeight = $t.config.minHeight ? $t.config.minHeight : $t.container.outerHeight(true);
      $t.slides = $t.wrap.children();

      if($t.config.forceSlideWidth)
        $t.slides.css('width', $t.innerWidth + 'px');

      $t.length = $t.slides.length * $t.slides.outerWidth(true);
      $t.pages = Math.round($t.length / $t.innerWidth);
    },

    createPager: function(){
      var $t = this,
          wrap = $(document.createElement('div')),
          length = Math.abs($t.length / $t.innerWidth);

      if($t.pagingContainer && $t.pagingContainer.length !== 0)
        $('.jump-to-slide', $t.pagingContainer).empty();

      for(var i = 0, k = length; i < k; i++){
        var div = $(document.createElement('div'));

        div.addClass('ui-joy-carousel-index ' + (i == this.current ? 'highlight': '' ))
        .html('<a href="#">&nbsp;</a>')
        .unbind('click')
        .bind('click', function(){
          var circle = $(this),
              index = circle.index();

          $t.current = index;

          $t.wrap.css($t.prefix + '-transition', $t.config.animation)
          .css($.browser.safari ? 'webkitTransform' : $t.prefix + '-transform', 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)');

          $t.updateNavigation();

          $('.ui-joy-carousel-index', wrap).removeClass('highlight');
          circle.addClass('highlight');
        })
        .appendTo(wrap);
      }

      $t.pagingContainer = $t.config.pagerContainer || $t.container;

      wrap.addClass('jump-to-slide')
      .appendTo($t.pagingContainer)

      $t.pager = wrap;
    },

    createNavigation : function(){
      var $t = this,
          back = $(document.createElement('div')),
          forward = $(document.createElement('div')),
          arrow = $(document.createElement('img')),
          arrow_ = $(document.createElement('img'));

      arrow.attr('src', Tap.blankIMG);

      back.addClass('back')
      .append(arrow)
      .appendTo($t.container);

      arrow_.attr('src', Tap.blankIMG);

      forward.addClass('forward')
      .append(arrow_)
      .appendTo($t.container);

      $('.back, .forward', $t.container).css('top', ($t.innerHeight - back.height()) / 2);

      $('.back', $t.container).bind(Tapjoy.EventsMap.start, function(){
        $t.transition('right');
      });

      $('.forward', $t.container).bind(Tapjoy.EventsMap.start, function(){
        $t.transition('left');
      });

      $t.back = back;
      $t.forward = forward;
    },

    updateNavigation: function(){
      var $t = this,
          next = ($t.container.width() * ($t.current + 1)),
          back = $('.back', $t.container),
          forward = $('.forward', $t.container);

      if($t.config.hasPager){
        $('.ui-joy-carousel-index', $t.pagingContainer).removeClass('highlight');
        $('.ui-joy-carousel-index:eq(' + $t.current + ')', $t.pagingContainer).addClass('highlight');
      }
      if(next > $t.length || $t.config.forceSlideWidth && $t.pages == ($t.current + 1)){
        back.removeClass('disabled');
        forward.addClass('disabled');
      }else if($t.current > 0 && next < $t.length){
        back.removeClass('disabled');
        forward.removeClass('disabled');
      }else if($t.current === 0){
        back.addClass('disabled');
        forward.removeClass('disabled');
      }

      if(next > $t.length && next < window.innerWidth){
        back.addClass('disabled');
      }

      if($t.length < $t.innerWidth)
        $('.back, .forward', $t.container).hide();

    },

    applyListeners: function(){
      var $t = this;

      // bind to window.resize to adjust carousel
      $(window).bind('resize', Tap.Utils.debounce($t.resize, 100, false, $t));

      // touch related events
      if(Tapjoy.supportsTouch){
        $(window).bind('orientationchange', function(){
          $t.turn();
        });

        // if device supports touch and swipe has been enabled
        if($t.config.enableSwipe){
          $t.wrap.bind(Tapjoy.EventsMap.start, function(e){
            $t.touchStart(e)
          });
        }
      }
    },

    touchStart: function(e){
      var $t = this;

      $.extend($t, {
        timestamp: new Date().getTime(),
        startX: 0,
        startY: 0,
        deltaX: 0,
        deltaY: 0,
        deltaT: 0
      });

      var touch = e.originalEvent.changedTouches[0];

      // ignore gestures or multiple touches
      if(e.originalEvent.changedTouches.length > 1)
        return;

      // store x/y
      $t.startX = touch.pageX,
      $t.startY = touch.pageY;

      // bind to touch events
      $t.wrap.bind(Tapjoy.EventsMap.move, function(e){
        if($t.config.enableSwipe)
          $t.touchMove(e);
      })
      .bind(Tapjoy.EventsMap.end, function(e){
        $t.touchEnd(e);
      })
      // remove css transition stylings for when we drag
      .css($t.prefix +'-transition', 'none');

    },

    touchMove: function(e){
      var $t = this;

       // update event details
      $t.updateTouch(e);

      // determine new position of wrapper
      var position = ($t.current * $t.container.width()) - $t.deltaX;

      // apply styling to wrapper to mimic drag
      $t.wrap.css($.browser.safari ? 'webkitTransform' : $t.prefix + '-transform', 'translate3d(-' + position + 'px, 0, 0)');
    },

    touchEnd: function(e){
      var $t = this;

      // update event details
      $t.updateTouch(e);

      var absX = Math.abs($t.deltaX),
          absY = Math.abs($t.deltaY),
          direction;

      // unbind wrap events
      $t.wrap.unbind(Tapjoy.EventsMap.move)
      .unbind(Tapjoy.EventsMap.end);

      // check if move was a valid one
      if(absX > absY && (absX > 10) && $t.deltaT < 1000){
        // determine movement direction
        if($t.deltaX < 0){
          direction = 'left';
        }else{
          direction = 'right';
        }
      }

      // reset element position and apply transition animation styling
      $t.wrap.css($.browser.safari ? 'webkitTransform' : $t.prefix + '-transform', 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)')
      .css($t.prefix + '-transition', $t.config.animation)

      // move threshold, was it great enough to merit a scroll
      if(absX < ($t.config.moveThreshold || ($t.container.width() / 3))){
        // animate carousel to new position
        $t.wrap.css($.browser.safari ? 'webkitTransform' : $t.prefix + '-transform', 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)');
      }else{
        // execute transition
        $t.transition(direction);
      }
    },

    transition: function(direction){
      var $t = this;

      $t.wrap.css($t.prefix + '-transition', $t.config.animation);

      if(direction == 'left'){
        // check if forward action has been disabled
        if($t.forward.hasClass('disabled'))
          return;

        //updated our index
        $t.current++;
      }else{
        // check if back action has been disabled
        if($t.back.hasClass('disabled'))
          return;

        // update our index
        $t.current--;
      }

      // animate carousel to new position
      $t.wrap.css($.browser.safari ? 'webkitTransform' : $t.prefix + '-transform', 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)');

      // update navigation
      $t.updateNavigation();
    },
    updateTouch: function(e){
      var $t = this,
          _touch = Tapjoy.supportsTouch ? e.originalEvent.changedTouches[0] : e;

      $t.deltaX = _touch.pageX - $t.startX;
      $t.deltaY = _touch.pageY - $t.startY;
      $t.deltaT = new Date().getTime() - $t.timestamp;
    },

    resize: function(){
      var $t = this;

      // recalculate slides
      $t.setupSlideDeck();

      // rebuild pager based on new width
      if($t.config.hasPager)
        $t.createPager();

      // if container element is less than viewport
      if($t.length < $t.innerWidth){
        // and navigation controls are visible
        if($t.back.is(':visible')){
          // hide both
          $t.back.hide();
          $t.forward.hide();
        }
      }else{
        // if hidden
        if($t.back.is(':hidden')){
          // show both
          $t.back.show();
          $t.forward.show();
        }
      }
      // updated navigation to reflect changes in viewport resize
      $t.updateNavigation();
    },

    setCarouselProperty : function(config){
      try{
        var $t = this;

        // loop through config
        for(var prop in $t.config){
          // loop through config object
          for(var option in config){
            // if props match
            if(option === prop){
              // update visual stuff
              $t.updateProperty(option, config[option]);
              // update carousel config
              $t.config[prop] = config[option];
            }
          }
        }
      }
      catch(exception){
        Tap.log('There was an exception: ' + exception, 'Tapjoy.Carousel');
      }
    },

    updateProperty : function(key, val){

      var $t = this;

      switch(key){
        case 'hidden':
          val ? $t.container.hide() : $t.container.show();
          break;

        case 'disabled':
          break;

        default:
          return;
      }
    }
  });

  $.fn.extend({

    disableCarouselSwipe: function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.config.enableSwipe = false;
      });
    },

    enableCarouselSwipe: function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;
        
        $t.config.enableSwipe = true;
        $t.applyListeners();
      });
    },

    disableCarousel : function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.setCarouselProperty({disabled: true});
      });
    },

    enableCarousel : function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.setCarouselProperty({disabled: false});
      });
    },

    hideCarousel : function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.setCarouselProperty({hidden: true});
      });
    },

    showCarousel : function(){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.setCarouselProperty({hidden: false});
      });
    },
    setCarouselProperty : function(config){
      return this.each(function(){
        var $t = $.data(this, 'carousel');

        if(!$t)
          return;

        $t.setCarouselProperty(config);
      });
    }
  });

  Tap.apply(Tap, {
    Carousel : function(config){

      var $t = $(config.container),
          config = Tap.extend(this, Tap.Components.Elements, Tap.Components.Carousel, config || {});

      return $t.Carousel(config);
    }
  });

})(Tapjoy, jQuery);
