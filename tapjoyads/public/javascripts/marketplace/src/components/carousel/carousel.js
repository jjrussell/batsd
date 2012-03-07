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

    $t.container = $t.config.container = $(container);

    $t.create();
    $t.setupSlideDeck();
    $t.createNavigation();

    if($t.config.hasPager)
      $t.createPager();

    $t.updateNavigation();

    if($t.length < $t.innerWidth)
      $('.back, .forward', $t.container).hide();

    $(window).bind('orientationchange', function(){
      $t.turn();
    });

    $(window).bind('resize', Tap.Utils.debounce($t.resize, 100, false, $t));

    if(Tap.supportsTouch){
      $t.container.live('swipe', function(e, data){

        if(data.direction === 'left'){
          if($t.forward.hasClass('disabled'))
            return;

          $t.current++;
          $t.wrap[0].style.webkitTransform = 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)';
        }else{

          if($t.back.hasClass('disabled'))
            return;        

          $t.current--;
          $t.wrap[0].style.webkitTransform = 'translate3d(-' + ($t.current * $t.container.width()) + 'px, 0, 0)';
        }
				
        $t.updateNavigation();
      });
    }

    $t.container.addClass($t.config.cssClass);

    $.data(container, 'carousel', $t);
  };

  Tap.extend(Carousel.prototype, {
    current: 0,
    create : function(){
      var $t = this,
          wrap = $(document.createElement('div')),
          html = $t.container.html();

      $t.container.empty().addClass('ui-joy-carousel');

      wrap.addClass('wrapper')
      .append(html)
      .preventHighlight()
      .appendTo($t.container);

      $t.current = 0;
      $t.wrap = wrap;
    },

    turn : function(){
      var $t = this;

      $t.wrap.css('-'+Tap.browser.prefix +'-transform', 'translate(0px, 0px)');
      $t.current = 0;
      $t.setupSlideDeck();
      $t.updateNavigation();

    },
    setupSlideDeck: function(){
      var $t = this;

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
        .unbind(Tapjoy.EventsMap.start)
        .bind(Tapjoy.EventsMap.start, function(){
          var circle = $(this),
              position = 0;

          $t.current = circle.index();

          position = $t.container.width() * $t.current;
          $t.wrap.css('-' + Tap.browser.prefix + '-transform', 'translate(-'+ position +'px, 0px)');

          $t.updateNavigation();

          $('.ui-joy-carousel-index', wrap).removeClass('highlight');
          circle.addClass('active');
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
        var position = 0;

        if($(this).hasClass('disabled'))
          return;

        if($t.current > 0){
          $t.current--
          var position = $t.container.width() * $t.current;
        }else{
          position = 0;
        }

        $t.updateNavigation();

        $t.wrap.css('-'+Tap.browser.prefix +'-transform', 'translate(-'+ position +'px, 0px)');
      });

      $('.forward', $t.container).bind(Tapjoy.EventsMap.start, function(){

        var position = 0;

        if($(this).hasClass('disabled') || $t.pages === $t.current)
          return;

        $t.current++;

        position = $t.container.outerWidth(true) * $t.current;

        $t.updateNavigation();

        $t.wrap.css('-'+Tap.browser.prefix +'-transform', 'translate(-'+ position +'px, 0px)');
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
    },

    resize: function(){
      var $t = this;

      $t.setupSlideDeck();

      if($t.config.hasPager)
        $t.createPager();

      if($t.length < $t.innerWidth){
        if($t.back.is(':visible')){
          $t.back.hide();
          $t.forward.hide();
        }
      }else{
        if($t.back.is(':hidden')){
          $t.back.show();
          $t.forward.show();
        }
      }

      $t.updateNavigation();
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
