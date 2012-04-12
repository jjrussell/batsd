(function(window, undefined){
  "use strict";

  // Thank you <cough>Microsoft</cough> Google... since older Andriod phones do not support JSON.parse or JSON.stringify
  var JSON; if(!JSON){JSON={}}(function(){function str(a,b){var c,d,e,f,g=gap,h,i=b[a];if(i&&typeof i==="object"&&typeof i.toJSON==="function"){i=i.toJSON(a)}if(typeof rep==="function"){i=rep.call(b,a,i)}switch(typeof i){case"string":return quote(i);case"number":return isFinite(i)?String(i):"null";case"boolean":case"null":return String(i);case"object":if(!i){return"null"}gap+=indent;h=[];if(Object.prototype.toString.apply(i)==="[object Array]"){f=i.length;for(c=0;c<f;c+=1){h[c]=str(c,i)||"null"}e=h.length===0?"[]":gap?"[\n"+gap+h.join(",\n"+gap)+"\n"+g+"]":"["+h.join(",")+"]";gap=g;return e}if(rep&&typeof rep==="object"){f=rep.length;for(c=0;c<f;c+=1){if(typeof rep[c]==="string"){d=rep[c];e=str(d,i);if(e){h.push(quote(d)+(gap?": ":":")+e)}}}}else{for(d in i){if(Object.prototype.hasOwnProperty.call(i,d)){e=str(d,i);if(e){h.push(quote(d)+(gap?": ":":")+e)}}}}e=h.length===0?"{}":gap?"{\n"+gap+h.join(",\n"+gap)+"\n"+g+"}":"{"+h.join(",")+"}";gap=g;return e}}function quote(a){escapable.lastIndex=0;return escapable.test(a)?'"'+a.replace(escapable,function(a){var b=meta[a];return typeof b==="string"?b:"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})+'"':'"'+a+'"'}function f(a){return a<10?"0"+a:a}"use strict";if(typeof Date.prototype.toJSON!=="function"){Date.prototype.toJSON=function(a){return isFinite(this.valueOf())?this.getUTCFullYear()+"-"+f(this.getUTCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z":null};String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(a){return this.valueOf()}}var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={"\b":"\\b","\t":"\\t","\n":"\\n","\f":"\\f","\r":"\\r",'"':'\\"',"\\":"\\\\"},rep;if(typeof JSON.stringify!=="function"){JSON.stringify=function(a,b,c){var d;gap="";indent="";if(typeof c==="number"){for(d=0;d<c;d+=1){indent+=" "}}else if(typeof c==="string"){indent=c}rep=b;if(b&&typeof b!=="function"&&(typeof b!=="object"||typeof b.length!=="number")){throw new Error("JSON.stringify")}return str("",{"":a})}}if(typeof JSON.parse!=="function"){JSON.parse=function(text,reviver){function walk(a,b){var c,d,e=a[b];if(e&&typeof e==="object"){for(c in e){if(Object.prototype.hasOwnProperty.call(e,c)){d=walk(e,c);if(d!==undefined){e[c]=d}else{delete e[c]}}}}return reviver.call(a,b,e)}var j;text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})}if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:\s*\[)+/g,""))){j=eval("("+text+")");return typeof reviver==="function"?walk({"":j},""):j}throw new SyntaxError("JSON.parse")}}})()

  var _stash = {
    callback: function(options){
      var stash = this;

      // check if complete is a valid callback
      if(Object.prototype.toString.call(options.complete) === '[object Function]'){
        options.complete.call(window, stash);
      }
    },

    each: function(array, fn){
      var stash = this;

      stash.every(array, function(item){
        return !fn(item)
      })
    },

    every: function(array, fn, i){
      for(var i = 0, k = array.length; i < k; ++i){
        if(!fn(array[i])){
          return false;
        }
      }

      return 1;
    },

    fetch: function(uri, callback){
      var xhr = new XMLHttpRequest();

      xhr.open('GET', uri, true);

      xhr.onreadystatechange = function(e){
        if(xhr.readyState === 4){
          callback(xhr.responseText, uri, xhr.status);
        }
      };

      xhr.send(null);
    },

    getKeys: function(object) {
      var keys = [],
          property;

      for(property in object){
        if(object.hasOwnProperty(property)){
          keys.push(property);
        }
      }

      return keys;
    },

    inject: function(text, extension, uri, options){
      var stash = this,
          // script check
          script = options.typesMap[extension] === 'script',
          // define tag
          file = document.createElement(uri && !script ? 'link' : options.typesMap[extension] || options.defaultType),
          // reference head
          head = document.getElementsByTagName('head')[0];

      // define content type
      file.type = script ? 'text/javascript' : 'text/css';

      // first pass we append files and fetch their contents
      if(uri){
        // determine source attribute
        file[script ? 'src' : 'href'] = uri;

        if(script){
          // defer script execution
          file.defer = false;

          // append scripts at the head of our doc
          head.insertBefore(file, head.firstChild);
        }else{
          file.rel = 'stylesheet';
          // append stylesheets to bottom of head to avoid possible css overwrites or loading sequence issues
          head.appendChild(file);
        }
      }else{
        // inject block with content - we use .text for scripts (IE8 support)
        file[script ? 'text' : 'innerHTML'] = text;

        // append block to head
        head.appendChild(file);
      }

      // adjust wait count
      --options.wait;

      // finished loading/injecting all files
      if(options.wait == 0){
        if(uri){
          file.onload = file.onerror = file.onreadystatechange = function(){
            if((file.readyState && !(/loaded|complete/.test(file.readyState))))
              return;

            file.onload = file.onerror = file.onreadystatechange = null;

            // fire callback after appending files
            stash.callback(options);
          }
        }else{
          // fire callback after injecting files
          stash.callback(options);
        }
      }
    },

    log: function(message){
      // get around YUI compressor
      var c = window.console;

      if(c && c.log){
        c.log(message);
      }
    },
    
    require: function(unknown, callback){

      var stash = this,
          // shortcut toString
          toString = Object.prototype.toString,
          // determine unknown param type
          typeCheck = toString.call(unknown) == '[object String]' || toString.call(unknown) == '[object Array]',
          // default properties
          options = {
            // complete callback function
            complete: null,
            // default file type
            defaultType: 'script',
            // the files we want to cache
            files: [],
            // default prefix for all localStorage entries
            prefix: 'tapjoy-',
            // map of extensions to file types
            typesMap: {
              'js': 'script',
              'css': 'style'
            },
            // versioning regex: [complete, name, md5 digest, extension] - ex: file-1333661824.js
            versionRegex: /(.*)-([\s\S]+).(js|css)/
          };

      // may we proceed
      if(!unknown){
        return;
      }

      // check if unknown param is an object
      if(typeof unknown === 'object'){
        // update properties
        for(var p in unknown){
          options[p] = unknown[p];
        }
      }

      // if unknown is a string or array we build a new object from param
      if(typeCheck){
        // run it back through as an object
        stash.require({
          files: toString.call(unknown) === '[object Array]' ? unknown : [unknown],
          complete: callback || null
        });
      }else{
        // store file total
        stash.files = options.wait = options.files.length;

        // internal property for validating file types
        var valid = stash.getKeys(options.typesMap).join('|');

        setTimeout(function(){
          // where the magic happens
          stash.each(options.files, function(file){

            // check if valid file
            if(String(file).match(valid) === null){
              // manage count
              options.wait--
              // print error
              stash.log('Error: File was not loaded because of structure - {filename}-{digest}.{ext}.\nResource: ' + file);
              // move to next
              return;
            }

            var regexResult = options.versionRegex.exec(file),
                logicalURI = regexResult[1] + '.' + regexResult[3],
                key = options.prefix + logicalURI,
                hash = regexResult[2],
                extension = regexResult[3],
                supportsLocalStorage = stash.supportsLocalStorage(),
                storage = supportsLocalStorage ? JSON.parse(localStorage.getItem(key)) : false;

            // check if localStorage exists, if entry exists and if hash has changed
            if(storage && storage.hash === hash){
              // load from cache
              stash.inject(storage.content, extension, null, options);
            }else{
              // fetch our file
              stash.fetch(file, function(text, uri, status){
                // check for errors
                if(status === 404){
                  stash.log('Error: 404\nCould not load resource: ' + uri);
                }else{
                  // check if we can write to localStorage
                  if(supportsLocalStorage){
                    // create new entry -> path/file + extension. We remove the digest from the filename and store it as our hash property.
                    localStorage.setItem(key,
                      // create new storage object with hash + content
                      JSON.stringify({
                        // versioning hash <- extracted from filename
                        hash: hash,
                        // file contents
                        content: text
                      })
                    );
                  }
                  stash.inject(text, extension, uri, options);
                }
              });
            }
          });
        }, 0);
      }

      // return stash object for chaining
      return stash;
    },

    supportsLocalStorage: function(){

      if(!window.localStorage)
        return false;

      var storage = window.localStorage;

      // try and catch quota exceeded errors           
      try{
        storage.setItem('tapjoy', 'dollas!'); 
        storage.removeItem(key); 
      }catch(error){
        if(error.code === DOMException.QUOTA_EXCEEDED_ERR && storage.length === 0) 
          return false;
      }

      return true;
    }    
  };

  window.stash = _stash;

})(this);
