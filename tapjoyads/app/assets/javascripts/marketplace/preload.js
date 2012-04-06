(function(){

  window.preload = function(){
    var images = [];

    for(i = 0, k = arguments[0].length; i < k; i++){
      images[i] = new Image()
      images[i].src = arguments[0][i];
    }
  }

  window.load = function(fn){
    var onload = window.onload;

    typeof(window.onload) != 'function' ? window.onload = fn : window.onload = function(){
      if(onload){
        onload();
      }

      fn();
    }
  };

})();
