/*
 jQuery delayed observer
 (c) 2007 - Maxime Haineault (max@centdessin.com)
 http://www.studio-cdd.com:8080/haineault/blog/17/
*/

// Delays actions that occur after 'keyup' event
jQuery.fn.extend({
  delayedObserver : function(delay, callback) {
    $this = $(this);
    if (typeof window.delayedObserverStack == 'undefined') {
      window.delayedObserverStack = [];
    }
    if (typeof window.delayedObserverCallback == 'undefined') {
      window.delayedObserverCallback = function(stackPos) {
        var observed = window.delayedObserverStack[stackPos];
        if (observed.timer) clearTimeout(observed.timer);
        observed.timer = setTimeout(function(){
          observed.timer = null;
          observed.callback(observed.obj.val(), observed.obj);
        }, observed.delay * 1000);

        observed.oldVal = observed.obj.val();
      }
    }
    window.delayedObserverStack.push({
      obj: $this, timer: null, delay: delay,
      oldVal: $this.val(), callback: callback });

    var stackPos = window.delayedObserverStack.length - 1;

    $this.keyup(function(){
      var observed = window.delayedObserverStack[stackPos];
      if (observed.obj.val() == observed.obj.oldVal) {
        return;
      } else {
        window.delayedObserverCallback(stackPos);
      }
    });
  }
});
