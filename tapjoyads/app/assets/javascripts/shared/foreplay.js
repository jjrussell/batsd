;(function($){

  var supportsTouch = (!!window.Touch) && (typeof window.TouchEvent != 'undefined');

  var foreplay = {
    event: {},
    delay: 800,
    timestamp: null,
    supportsTouch: supportsTouch,
    eventsMap: {
      start: supportsTouch ? 'touchstart' : 'mousedown',
      move: supportsTouch ? 'touchmove' : 'mousemove',
      end: supportsTouch ? 'touchend' : 'mouseup',
      cancel: supportsTouch ? 'touchcancel' : 'mouseout'
    },

    init: function(){
      var $t = this;
      // addlistener to touchstart/mousedown
      document.addEventListener($t.eventsMap.start, function(e){
        $t.start(e);
      }, false);

      // addlistener to touchmove/mousemove
      document.addEventListener($t.eventsMap.move, function(e){
        $t.move(e);
      }, false);

      // addlistener to touchend/mouseup
      document.addEventListener($t.eventsMap.end, function(e){
        $t.end(e);
      }, false);

      // addlistener to touchcancel/mouseout
      document.addEventListener($t.eventsMap.cancel, function(e){
        $t.cancel(e);
      }, false);

      // extend jQuery.fn with touch methods
      ['swipe', 'tap', 'singleTap', 'doubleTap', 'press'].forEach(function(method){
        $.fn[method] = function(callback){
          return this.bind(method, callback);
        }
      });
    },

    cancel: function(){
      var $t = this;
      // clear timers
      $t.clear();
      // empty event object
      $t.event = {};
    },

    clear: function(){
      var $t = this;

      // reset all
      $t.touchTimeout && clearTimeout($t.touchTimeout);
      $t.pressTimeout && clearTimeout($t.pressTimeout);
      $t.touchTimeout = $t.pressTimeout = null;
    },

    end: function(e){
      var $t = this;

      // clear timers
      $t.clear();
      // check if doubleTap flag
      if($t.event.isDoubleTap){
        // trigger event
        $t.event.element.trigger('doubleTap');
        // empty event object
        $t.event = {};
      } 
      else if(($t.event.x2 && Math.abs($t.event.x1 - $t.event.x2) > 30) || ($t.event.y2 && Math.abs($t.event.y1 - $t.event.y2) > 30)){
        // trigger swipe, pass swipe object back
        $t.event.element.trigger('swipe', {
          direction: $t.swipe($t.event.x1, $t.event.x2, $t.event.y1, $t.event.y2),
          x: $t.event.x1 - $t.event.x2,
          y: $t.event.y1 - $t.event.y2
        });

        // empty event object
        $t.event = {};
      }
      else if($t.event.timestamp > 0){
        // trigger fast tap
        $t.event.element.trigger('tap');
        // set timer for tap event
        $t.touchTimeout = setTimeout(function(){
          $t.touchTimeout = null;
          $t.event.element.trigger('singleTap');
          $t.event = {};
        }, 250);
      }
    },

    move: function(e){
      var $t = this;

      // clear timers
      $t.clear();
      // store x position
      $t.event.x2 = $t.supportsTouch ? e.touches[0].pageX : e.pageX;
      // store y position
      $t.event.y2 = $t.supportsTouch ? e.touches[0].pageY : e.pageY;
    },

    press: function(){
      var $t = this,
          // get timestamp of touchstart from event object
          timestamp = $t.event.timestamp;

      // if the time between start and now exceeds our delay
      if(timestamp && (Date.now() - timestamp >= $t.delay)){
        // trigger press event
        $t.event.element.trigger('press');
        // empty event object
        $t.event = {};
      }
    },

    start: function(e){
      var $t = this,
          // get current timestamp
          now = Date.now(),
          // compare against last timestamp
          delta = now - ($t.event.timestamp || now);

      e.preventDefault();

      // clear touch timer
      $t.touchTimeout && clearTimeout($t.touchTimeout)

      // create event object
      $t.event = {
        // our target element
        element: $t.supportsTouch ? $(e.touches[0].target) : $(e.target),
        // x position
        x1: $t.supportsTouch ? e.touches[0].pageX : e.pageX,
        // y position
        y1: $t.supportsTouch ? e.touches[0].pageY : e.pageY
      };

      // if our timestamp delta is between 0 - 250 then set doubleTap to true
      $t.event.isDoubleTap = delta > 0 && delta <= 250 ? true : false;

      // store reference to timestamp
      $t.event.timestamp = now;

      // start timer for press event
      $t.pressTimeout = setTimeout(function(){
        $t.press();
      }, $t.delay);
    },

    swipe: function(startX, endX, startY, endY){
      // determine if x or y movement was greater and return direction of swipe
      return Math.abs(startX - endX) >= Math.abs(startY - endY) ? (startX - endX > 0 ? 'left' : 'right') : (startY - endY > 0 ? 'up' : 'down');
    }
  };

  $(document).ready(function(){
    foreplay.init();
  });

})(jQuery);