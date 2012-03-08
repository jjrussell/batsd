(function(window, undefined){
  "use strict";

  var _cache = {
      complete: 0,
      prefix: 'tapjoy-',
      files: [],
      defaultType: 'script',
      typesMap: {
        '.js': 'script',
        '.css': 'style'
      },
      add: function(uri, overwrite){

        var cache = this,
            toString = Object.prototype.toString,
            key = cache.prefix + uri,
            index = cache.files.length,
            storage = localStorage.getItem(key),
            extension = null;

        if(toString.call(uri) === '[object Array]'){
          for(var i = 0, k = uri.length; i < k; i++){
            cache.add(uri[i]);
          }
        }else{

          extension = uri.match(/\.[0-9a-z]+$/i)[0];

          if(storage && !overwrite){
            cache.files[index] = storage;
            cache.execute(extension);
          }else{
            cache.fetch(uri, function(text){
              localStorage.setItem(key, text);
              cache.files[index] = text;
              cache.execute(extension);
            });
          }
        }

        return cache;
      },

      execute: function(extension){
        var cache = this;

        for(var i = 0, k = cache.files.length; i < k; i++){
          var file = cache.files[i];

          if(!file){
            continue;
          }

          cache.files[i] = null;
          cache.inject(extension, file);
          cache.complete++;
        }
      },

      fetch: function(url, callback){
        var xhr = new XMLHttpRequest();
    
        xhr.open('GET', url, true);
        
        xhr.onreadystatechange = function(e){
          if(xhr.readyState === 4){
            callback(xhr.responseText);
          }
        };

        xhr.send();
      },

      inject: function(extension, text){
        var cache = this,
            file = document.createElement(cache.typesMap[extension] || cache.defaultType),
            head = document.getElementsByTagName('head')[0],
            contents = document.createTextNode(text);

         
        if(cache.map[extension] === 'script'){
          file.defer = true;
        }else{
          file.type = 'text/css';
        }

        file.appendChild(contents);
        head.appendChild(file);
      },

      remove: function(uri){
        var cache = this,
            key = cache.prefix + uri;
 
        localStorage.removeItem(key);

        return cache;
      }
  };

  if(!window.cache)
    window.cache = _cache;

})(this);