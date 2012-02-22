(function(Tap, $){

  $.fn.Carousel = function(config){
    
    config = Tap.extend({}, Tap.Components.Elements, {
      direction: 'horizontal'
    }, config || {});
    
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
    $t.createDirectionArrows();
    
    if($t.config.hasPager)
      $t.createJumper();
    
    $t.updateControls();
      
    $(window).bind('orientationchange', function(){
      $t.setupSlideDeck();
    });   
  
    if($t.length < $t.innerWidth){
      $('.back, .forward').hide();
    }

    $.data(container, 'carousel', $t);  
  };

  Tap.extend(Carousel.prototype, {
    current: 0,
    last: null,
    containerWidth: 0,
    containerHeight: 0,
    create : function(){
      var $t = this
          wrap = $(document.createElement('div')),
          html = $t.container.html();
      
      $t.innerWidth = $t.container.width();
      $t.innerHeight = $t.container.outerHeight(true);
          
      $t.container.addClass('ui-joy-carousel')
      .empty();
      
      wrap.addClass('wrapper')
      .append(html)
      .preventHighlight()
      .appendTo($t.container);

      $t.slides = wrap.children();
			
      $t.wrap = wrap;
    },
    
    setupSlideDeck: function(){
      this.length = this.slides.length * this.slides.outerWidth(true);
		  this.dots = Math.round(this.length / this.innerWidth);
    },
    
    createJumper: function(){
      var $t = this,
          wrap = $(document.createElement('div')),
					length = Math.abs($t.length / $t.innerWidth);
      
      for(var i = 0, k = length; i < k; i++){
        var div = $(document.createElement('div'));
      
        div.addClass('dot ' + (i == this.current ? 'active': '' ))
        .html('<a href="#">&nbsp;</a>')
        .bind('click', function(){
          var circle = $(this),
              position = 0;
          
          $t.current = circle.index();
          
          position = $t.container.width() * $t.current;
          $t.wrap.css('-'+Tap.browser +'-transform', 'translate(-'+ position +'px, 0px)');
              
          $t.updateControls();

          $('.dot', wrap).removeClass('active');
          circle.addClass('active');
        })
        .appendTo(wrap);  
      }   
      
      $t.jumpContainer = $t.config.pagerContainer || $t.container;
      
      wrap.addClass('jump-to-slide')
      .appendTo($t.jumpContainer)
      
			
      $t.jumpTo = wrap;
    },
    createDirectionArrows : function(){
      var $t = this,
          left = $(document.createElement('div')),
          right = $(document.createElement('div')),
          arrow = $(document.createElement('img')),
          arrow_ = $(document.createElement('img'));
          
      arrow.attr('src', Tap.blankIMG);    
      
      left.addClass('back')
      .append(arrow)
      .appendTo($t.container);
      
      arrow_.attr('src', Tap.blankIMG);
      
      right.addClass('forward')   
      .append(arrow_)     
      .appendTo($t.container);
      
      $('.back, .forward', $t.container).css('top', ($t.innerHeight - left.height()) / 2)
      
      $('.back', $t.container).bind('click', function(){
				var position = 0;
				
        if($t.current > 0){
          $t.current--
          var position = $t.container.width() * $t.current;
        }else{
          position = 0;               
        }
        
        $t.updateControls();
        
        $t.wrap.css('-'+Tap.browser +'-transform', 'translate(-'+ position +'px, 0px)');
      });

      $('.forward', $t.container).bind('click', function(){
				$t.current++

        var screenWidth = $t.container.outerWidth(true) * $t.current,
				    position = 0;

        if(screenWidth > $t.length || $t.dots === $t.current){
          $t.current--;
          return;
        }else{
          position = screenWidth - ($t.current * 2);    
        }
				
        $t.updateControls();
        
        $t.wrap.css('-'+Tap.browser +'-transform', 'translate(-'+ position +'px, 0px)');
      });
    },
    updateControls: function(){
      var $t = this;

      if($t.config.hasPager){
        $('.dot', $t.jumpContainer).removeClass('active');
        $('.dot:eq(' + $t.current + ')', $t.jumpContainer).addClass('active');
      }
			
      if($t.container.width() * ($t.current + 1) > $t.length || $t.dots - 1 === $t.current){
        $('.back', $t.container).removeClass('disabled');
        $('.forward', $t.container).addClass('disabled');
      }
      else if($t.current <= 0){
        $('.back', $t.container).addClass('disabled');
        $('.forward', $t.container).removeClass('disabled');
      }else if($t.current > 0 && $t.container.width()*$t.current < $t.length){
        $('.back', $t.container).removeClass('disabled');
        $('.forward', $t.container).removeClass('disabled');
      }
    }
  });

  Tap.apply(Tap, {
    Carousel : function(config){
  
      var $t = $(config.container),
          config = Tap.extend(this, {}, config || {});
          
      return $t.Carousel(config);
    }
  });
  
})(Tapjoy, jQuery);
