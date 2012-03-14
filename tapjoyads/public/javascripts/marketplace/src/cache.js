(function(window, undefined){
  "use strict";

  // if browser does not support localStorage object, imitate it.
  if(!window.localStorage){
    window.localStorage = {
      length: 0,
      getItem: function(sKey){
        if(!sKey || !this.hasOwnProperty(sKey)){
          return null;
        }

        return unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1"));
      },

      key: function(nKeyId){
        return unescape(document.cookie.replace(/\s*\=(?:.(?!;))*$/, "").split(/\s*\=(?:[^;](?!;))*[^;]?;\s*/)[nKeyId]);
      },

      setItem: function (sKey, sValue) {
        if(!sKey){
          return;
        }

        document.cookie = escape(sKey) + "=" + escape(sValue) + "; path=/";

        this.length = document.cookie.match(/\=/g).length;
      },

      removeItem: function(sKey){
        if(!sKey || !this.hasOwnProperty(sKey)){
          return;
        }

        var sExpDate = new Date();
        sExpDate.setDate(sExpDate.getDate() - 1);
        document.cookie = escape(sKey) + "=; expires=" + sExpDate.toGMTString() + "; path=/";
        this.length--;
      },

      hasOwnProperty: function(sKey){
        return (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie);
      }

    };

    window.localStorage.length = (document.cookie.match(/\=/g) || window.localStorage).length;
  }

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

        cache.files[index] = null;
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

      if(cache.typesMap[extension] === 'script'){
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
