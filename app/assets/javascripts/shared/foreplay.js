;(function(window, $){

  var supportsTouch = "ontouchstart" in window;

  var foreplay = {
    addEvent: (/msie/i).test(navigator.userAgent) ? 'attachEvent' : 'addEventListener',
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
      $t.touchTimer && clearTimeout($t.touchTimer);
      $t.pressTimer && clearTimeout($t.pressTimer);
      $t.touchTimer = $t.pressTimer = null;
    },

    end: function(e){
      var $t = this;
      // clear timers
      $t.clear();
      // set pressed state
      $t.event.pressed = false;
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
          direction: $t.swipe(),
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
        $t.touchTimer = setTimeout(function(){
          // clear
          $t.touchTimer = null;
          // trigger single tap
          $t.event.element.trigger('singleTap');
          // empty event object
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
      // check if touchstart is active, if event is swipe and if movement is swipe or scrolling
      if($t.event.pressed && $t.event.element.data('swipe') && Math.abs($t.event.y1 - $t.event.y2) > 10){
        e.preventDefault();
      }
    },

    press: function(){
      var $t = this,
          // get timestamp of touchstart from event object
          timestamp = $t.event.timestamp,
          // get current timestamp
          now = Date.now();

      // if the time between start and now exceeds our delay
      if(timestamp && (now - timestamp >= $t.delay)){
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

      // clear touch timer
      $t.touchTimer && clearTimeout($t.touchTimer);

      // create event object
      $t.event = {
        // our target element
        element: $t.supportsTouch ? $(e.touches[0].target) : $(e.target),
        // if our timestamp delta is between 0 - 250 then set doubleTap to true
        isDoubleTap: delta > 0 && delta <= 250 ? true : false,
        // set pressed state
        pressed: true,
        // store reference to timestamp
        timestamp: now,
        // x position
        x1: $t.supportsTouch ? e.touches[0].pageX : e.pageX,
        // y position
        y1: $t.supportsTouch ? e.touches[0].pageY : e.pageY
      };

      // check if press event exists
      if($t.event.element.data('press'))
        e.preventDefault();

      // start timer for press event
      $t.pressTimer = setTimeout(function(){
        // trigger press event
        $t.press();
      }, $t.delay);
    },

    swipe: function(){
      var $t = this;
      // determine if x or y movement was greater and return direction of swipe
      return Math.abs($t.event.x1 - $t.event.x2) >= Math.abs($t.event.y1 - $t.event.y2) ? ($t.event.x1 - $t.event.x2 > 0 ? 'left' : 'right') : ($t.event.y1 - $t.event.y2 > 0 ? 'up' : 'down');
    },

    touch: function(){
      var $t = this;

      // add listernes to document
      ['start', 'move', 'end', 'cancel'].forEach(function(event){
        document[$t.addEvent]($t.eventsMap[event], function(e){
          $t[event](e);
        }, false);
      });
    }
  };

  // extend jQuery.fn with touch methods
  ['swipe', 'tap', 'singleTap', 'doubleTap', 'press'].forEach(function(method){
    $.fn[method] = function(callback){
      return this.bind(method, callback).data(method, true);
    }
  });

  $(document).ready(function(){
    // let's get it on
    foreplay.touch();
  });

})(window, jQuery);
