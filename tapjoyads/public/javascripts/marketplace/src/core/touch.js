(function(Tapjoy, $){

  var config = {
    moveThreshold: 10,
    hoverDelay: 50,
    pressDelay: 750
  };
            
  function _eventStart(e){
        
    var target = $(e.target);
    
    if(!Tapjoy.supportsTouch || !target.length)
      return;

    var timestamp = new Date().getTime(),
        hover = null,
        press = null,
        touch,
        startX,
        startY,
        deltaX = 0,
        deltaY = 0,
        deltaT = 0,
        touch = Tapjoy.supportsTouch ? e.originalEvent.changedTouches[0] : e,
        startX = touch.pageX,
        startY = touch.pageY;

    bindEvents(target);

    hover = setTimeout(function(){
      target.applyActive();
    }, 50);
    
    press = setTimeout(function(){
      unbindEvents(target);
      target.removeActive();
      clearTimeout(hover);
      target.trigger('press');
    }, 750);
    
    function _eventCancel(e){
      clearTimeout(hover);
      target.removeActive();
      unbindEvents(target);
    }

    function _eventEnd(e) {
      unbindEvents(target);
      clearTimeout(hover);
      clearTimeout(press);

      if(Math.abs(deltaX) < config.moveThreshold && Math.abs(deltaY) < config.moveThreshold && deltaT < config.pressDelay){
        if(Tapjoy.supportsTouch){
          target.trigger('tap', e);
        }
      }else{
        target.removeActive();
      }
    }
    
    function _eventMove(e) {
      _eventUpdate(e);

      var absX = Math.abs(deltaX),
          absY = Math.abs(deltaY),
          direction;

      if(absX > absY && (absX > 30) && deltaT < 1000){
        if(deltaX < 0){
          direction = 'left';
        }else{
          direction = 'right';
        }

        unbindEvents(target);

        target.trigger('swipe', {
          direction: direction, 
          deltaX: deltaX, 
          deltaY: deltaY
        });
      }

      target.removeActive();

      clearTimeout(hover);

      if(absX > config.moveThreshold || absY > config.moveThreshold){
        clearTimeout(press);
      }
    }

    function _eventUpdate(e){
      var _touch = Tapjoy.supportsTouch ? e.originalEvent.changedTouches[0]: e;

      deltaX = _touch.pageX - startX;
      deltaY = _touch.pageY - startY;
      deltaT = new Date().getTime() - timestamp;
    }

    function bindEvents(element){
      element.bind(Tapjoy.EventsMap.move, _eventMove)
      .bind(Tapjoy.EventsMap.end, _eventEnd);

      if(Tapjoy.supportsTouch){
        element.bind(Tapjoy.EventsMap.cancel, _eventCancel);
      }else{
        $(document).bind(Tapjoy.EventsMap.cancel, _eventCancel);
      }
    }
        
    function unbindEvents(element){
      if(!element)
        return;
    
      element.unbind(Tapjoy.EventsMap.move, _eventMove)
      .unbind(Tapjoy.EventsMap.end, _eventEnd);

      if(Tapjoy.supportsTouch){
        element.unbind(Tapjoy.EventsMap.cancel, _eventCancel);
      }else{
        $(document).unbind(Tapjoy.EventsMap.end, _eventCancel);
      }
    }
  }

  $.fn.press = function(fn) {
    return this.each(function(){
      if($.isFunction(fn)){
        return $(this).live('press', fn);
      }else{
        return $(this).trigger('press');
      }
    });
  };

  $.fn.swipe = function(fn){
    return this.each(function(){
      if($.isFunction(fn)){
        return $(this).live('swipe', fn);
      }else{
        return $(this).trigger('swipe');
      }
    });
  };

  $.fn.tap = function(fn) {
    return this.each(function(){
      if($.isFunction(fn)){
        return $(this).live('tap', fn);
      }else{
        return $(this).trigger('tap');
      }
    });
  };

  $.fn.applyActive = function() {
    return $(this).addClass('ui-joy-touch-active');
  };

  $.fn.removeActive = function(obj) {
    if(obj){
      obj.removeClass('ui-joy-touch-active');
    }else{
      $('.ui-joy-touch-active').removeClass('ui-joy-touch-active');
    }
  };    

  $(document).ready(function(){
    $(document).bind(Tapjoy.EventsMap.start, _eventStart);    
  });

})(Tapjoy, jQuery);
