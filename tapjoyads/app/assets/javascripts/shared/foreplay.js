(function(Tap, $){
  var touch = {},
      touchTimeout,
      pressDelay = 750;      

  function swipeDirection(x1, x2, y1, y2) {
    var xDelta = Math.abs(x1 - x2), 
        yDelta = Math.abs(y1 - y2);

    if(xDelta >= yDelta){
      return (x1 - x2 > 0 ? 'Left' : 'Right');
    }else{
      return (y1 - y2 > 0 ? 'Up' : 'Down');
    }
  }

  function press(){
    if(touch.last && (Date.now() - touch.last >= pressDelay)){
      touch.el.trigger('press');
      touch = {};
    }
  }

  $(document).ready(function(){

    document.addEventListener(Tap.EventsMap.start, function(e){
      e.preventDefault();
      
      var now = Date.now(), 
          delta = now - (touch.last || now);

      touch = {
        el:  Tap.supportsTouch ? $(e.touches[0].target) : $(e.target),
        target: Tap.supportsTouch ? e.touches[0].target : e.target,
        x1: Tap.supportsTouch ? e.touches[0].pageX : e.pageX,
        y1: Tap.supportsTouch ? e.touches[0].pageY : e.pageY
      };

      touchTimeout && clearTimeout(touchTimeout);

      if(delta > 0 && delta <= 250){
        touch.isDoubleTap = true;
      }
 
      touch.last = now;

      setTimeout(press, pressDelay);
    }, false);


    document.addEventListener(Tap.EventsMap.move, function(e){
      touch.x2 = Tap.supportsTouch ? e.touches[0].pageX : e.pageX;
      touch.y2 = Tap.supportsTouch ? e.touches[0].pageY : e.pageY;
    });

    document.addEventListener(Tap.EventsMap.end, function(){
      if(touch.isDoubleTap){
        touch.el.trigger('doubleTap');
        touch = {};
      }else if(touch.x2 > 0 || touch.y2 > 0){
        (Math.abs(touch.x1 - touch.x2) > 30 || Math.abs(touch.y1 - touch.y2) > 30) && 
        touch.el.trigger('swipe', {
          direction: swipeDirection(touch.x1, touch.x2, touch.y1, touch.y2),
          x: touch.x1 - touch.x2,
          y: touch.y1 - touch.y2
        });
        
        touch.x1 = touch.x2 = touch.y1 = touch.y2 = touch.last = 0;

      }else if('last' in touch){
        touch.el.trigger('tap');

        touchTimeout = setTimeout(function() {
          touchTimeout = null;
          touch.el.trigger('singleTap');
          touch = {};
        }, 250);
      }
    });
  });


  ['swipe', 'tap', 'singleTap', 'doubleTap', 'press'].forEach(function(m) {
      $.fn[m] = function(callback){
        return this.bind(m, callback)
      }
  });

})(Tapjoy, jQuery);
