(function(window, undefined){
  "use strict";

  var toString = Object.prototype.toString;

  var preload = function(array, fn){
    var images = [];

    for(var i = 0, k = array.length; i < k; i++){
      images[i] = new Image();
      images[i].src = array[i];
    }

    if(toString.call(fn) === '[object Function]'){
      fn.call();
    }
  }

  var load = function(fn){
    var onload = window.onload;

    if(toString.call(window.onload) !== '[object Function]'){
      window.onload = fn;
    }else{
      window.onload = function(){
        if(onload){
          onload();
        }

        fn();
      }
    }
  };

  // extend window with load
  window.load = load;

  // extend window with preload
  window.preload = preload;

})(window);
