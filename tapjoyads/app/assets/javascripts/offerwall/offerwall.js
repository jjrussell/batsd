(function(window, data, undefined){

  // Thank you <cough>Microsoft</cough> Google... since older Andriod phones do not support JSON.parse or JSON.stringify
  var JSON; if(!JSON){JSON={}}(function(){function str(a,b){var c,d,e,f,g=gap,h,i=b[a];if(i&&typeof i==="object"&&typeof i.toJSON==="function"){i=i.toJSON(a)}if(typeof rep==="function"){i=rep.call(b,a,i)}switch(typeof i){case"string":return quote(i);case"number":return isFinite(i)?String(i):"null";case"boolean":case"null":return String(i);case"object":if(!i){return"null"}gap+=indent;h=[];if(Object.prototype.toString.apply(i)==="[object Array]"){f=i.length;for(c=0;c<f;c+=1){h[c]=str(c,i)||"null"}e=h.length===0?"[]":gap?"[\n"+gap+h.join(",\n"+gap)+"\n"+g+"]":"["+h.join(",")+"]";gap=g;return e}if(rep&&typeof rep==="object"){f=rep.length;for(c=0;c<f;c+=1){if(typeof rep[c]==="string"){d=rep[c];e=str(d,i);if(e){h.push(quote(d)+(gap?": ":":")+e)}}}}else{for(d in i){if(Object.prototype.hasOwnProperty.call(i,d)){e=str(d,i);if(e){h.push(quote(d)+(gap?": ":":")+e)}}}}e=h.length===0?"{}":gap?"{\n"+gap+h.join(",\n"+gap)+"\n"+g+"}":"{"+h.join(",")+"}";gap=g;return e}}function quote(a){escapable.lastIndex=0;return escapable.test(a)?'"'+a.replace(escapable,function(a){var b=meta[a];return typeof b==="string"?b:"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})+'"':'"'+a+'"'}function f(a){return a<10?"0"+a:a}"use strict";if(typeof Date.prototype.toJSON!=="function"){Date.prototype.toJSON=function(a){return isFinite(this.valueOf())?this.getUTCFullYear()+"-"+f(this.getUTCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z":null};String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(a){return this.valueOf()}}var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={"\b":"\\b","\t":"\\t","\n":"\\n","\f":"\\f","\r":"\\r",'"':'\\"',"\\":"\\\\"},rep;if(typeof JSON.stringify!=="function"){JSON.stringify=function(a,b,c){var d;gap="";indent="";if(typeof c==="number"){for(d=0;d<c;d+=1){indent+=" "}}else if(typeof c==="string"){indent=c}rep=b;if(b&&typeof b!=="function"&&(typeof b!=="object"||typeof b.length!=="number")){throw new Error("JSON.stringify")}return str("",{"":a})}}if(typeof JSON.parse!=="function"){JSON.parse=function(text,reviver){function walk(a,b){var c,d,e=a[b];if(e&&typeof e==="object"){for(c in e){if(Object.prototype.hasOwnProperty.call(e,c)){d=walk(e,c);if(d!==undefined){e[c]=d}else{delete e[c]}}}}return reviver.call(a,b,e)}var j;text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})}if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:\s*\[)+/g,""))){j=eval("("+text+")");return typeof reviver==="function"?walk({"":j},""):j}throw new SyntaxError("JSON.parse")}}})()

  var global = window,
      document = global.document,
      navigator = global.navigator,
      appversion = navigator.appVersion,
      agent = navigator.userAgent,
      arrayPrototype = Array.prototype,
      objectPrototype = Object.prototype,
      toString = objectPrototype.toString,
      slice = arrayPrototype.slice,
      start = 25,
      url = fetchURL;

console.log(i18n)
  var $ = {
    blank: 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
    addEvent: (/msie/i).test(agent) ? 'attachEvent' : 'addEventListener',
    empty: function(){},
    fetched: 1,
    labels: {
      actions:{
        download: i18n.t("actions.download"),
        series: i18n.t("actions.steps"),
        video: i18n.t("actions.video")
      },
      text: {
        offersby: i18n.t("offers_by"),
        earn: i18n.t("earn"),
        error: i18n.t("load_error"),
        free: i18n.t("free"),
        points: i18n.t("points")
      }
    },
    tpl: {
      header: [
        "<div class='app-icon'>"+
          "<div class='overlay'></div>"+
          "<img src='{currentIconURL}' />"+
        "</div>"+
        "<div class='app-desc'><h1>{currentAppName}</h1>{message}</div>",
        "<div>{banner}</div>"
      ],
      offers: [
        "<div class='reward'>"+
          "<span class='earn'>{earn}</span>"+
          "<span class='big'>{payout}</span>"+
          "<span class='points'>{points}</span>"+
          "<span class='free'>{cost}</span>"+
        "</div>",
        "<div class='offer'>"+
          "<div class='icon'>"+
            "{pricetag}"+
            "{cover}"+
            "{wifi}"+
          "</div>"+
          "<div class='about'>"+
            "<div class='title'>{title}</div>"+
            "{action}"+
          "</div>"+
        "</div>"
      ]
    },

    /**
     * Initialize offerwall
     */
    init: function(){

      $.data = data;
      $.header = document.getElementById('header');
      $.banner = document.getElementById('branding');
      $.loader = document.getElementById('loading');
      $.loadMore = document.getElementById('more');
      $.offersContainer = document.getElementById('offers');
      $.visit = document.getElementById('visit');

      $.header.innerHTML = $.format($.tpl.header[0], data);
      $.load(data.offers);
      $.configLayout();
      $.initEvents();
    },

    /**
     * Attach events events
     */
    initEvents: function(){

      if($.data.autoload){
        window[$.addEvent]('scroll', function(){
          if($.fetched < 3){
            if($.endOfTheLine() && !$.fetching){
             $.fetch();
             $.fetched++;
             if($.fetched === 3){
               $.loadMore.parentNode.style.display = 'block'; 
             }
            }
          }
        });
      }

      $.visit[$.addEvent]('click', function(){
        window.location = page;
      });

      $.loadMore[$.addEvent]('click', function(){
        $.fetch();
      }, false);
    },

    /**
     * AJAX - it's magical
     */
    ajax: function(config){

      var defaults = {
        type: 'GET',
        contentType: 'application/x-www-form-urlencoded',
        dataType: 'text/html',
        headers: {
          'X-Requested-With': 'XMLHttpRequest'
        },
        beforeSend: $.empty,
        success: $.empty,
        error: $.empty,
        complete: $.empty,
        scope: undefined,
        timeout: 0
      };

      var config = $.apply(defaults, config);

      if(!config.url){
        config.url = toString.call(window.location);
      }

      switch(config.dataType){
        case 'json':
          config.dataType = 'application/json';
          break;
        case 'html':
          config.dataType = 'text/html';
          break;
        case 'text':
          config.dataType = 'text/plain';
          break;
        default:
          config.dataType = 'text/html';
          break;
      };

      if(config.contentType){
        config.headers['Content-Type'] = config.contentType;
      }

      $.fetching = true;

      var xhr = new window.XMLHttpRequest();

      xhr.onreadystatechange = function(){

        var error = false,
            result,
            abort,
            mime = config.dataType,
            protocol = /^([\w-]+:)\/\//.test(config.url) ? RegExp.$1 : window.location.protocol;

        if(xhr.readyState === 4){

          if(config.timeout > 0){
            abort = setTimeout(function() {
              xhr.onreadystatechange = $.empty;
              xhr.abort();
              config.error.call(config.scope, xhr, 'timeout');
              $.fetching = false;
            }, config.timeout);
          }

          if((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304 || (xhr.status == 0 && protocol == 'file:')){
            if(mime === 'application/json' && !(/^\s*$/.test(xhr.responseText))){
              try {
                result = JSON.parse(xhr.responseText);
              }catch(err){
                error = err;
              }
            }else{
              result = xhr.responseText;
            }

            if(error){
              config.error.call(config.scope, xhr, 'parsererror', error);
            }else{
              config.success.call(config.scope, result, 'success', xhr);
              $.fetching = false;
            }
          }else{
            error = true;
            config.error.call(config.scope, xhr, 'error');
          }

          config.complete.call(config.scope, xhr, error ? 'error' : 'success');

          $.fetching = false;

          clearTimeout(abort);
        }
      }

      xhr.open(config.type, config.url, config.async || true);

      for(var header in config.headers){
        xhr.setRequestHeader(header, config.headers[header]);
      }

      if(config.beforeSend.call(config.scope, xhr, config) === false){
        xhr.abort();
        return false;
      }

      xhr.send(null);

      return xhr;
    },

    /**
     * Extends a specific object with new or updated properties
     */
    apply: function(object, config, defaults){
      if(defaults){
        $.apply(object, defaults);
      }

      if(object && config && $.type(config) === 'object'){
        for(var i in config){
          object[i] = config[i];
        }
      }
      return object;
    },

    /**
     * Configure layout for A/B testing
     */
    configLayout: function(){

      $.banner.innerHTML = '<div class="text">' + $.labels.text.offersby + '&nbsp;</div><div class="logo"><img src="' + $.blank + '" /></div>'; 
        
      $.offersContainer.className += ' action-' + $.data.actionLocation + '-side';
      !$.data.showActionLine ? $.offersContainer.className += ' no-action-line' : '';
      !$.data.showCurrentApp ? $.header.className += ' hide-current-app' : '';

      if(!$.data.showBanner){
        $.header.style.display = 'none';
      }

      if($.data.autoload){
        $.loadMore.parentNode.style.display = 'none';
      }
    },

    /**
     * ForEach method
     * @param {array} collection
     * @param {function} callback
     */
    each: function(array, fn){
      $.every(array, function(item){
        return !fn(item)
      });
    },

    /**
     * @return {string} Returns the formatted string
     */
    ellipsis: function(str, len){
      return str ? str.substr(0, len - 3) + (str.length < len ? "" : "...") : false;
    },

    /**
     * Checks to see if you have reached the bottom of the page
     * @return {boolean} True or false depending on scroll position
     */
    endOfTheLine: function(){
      return document.body.clientHeight <= window.innerHeight + window.pageYOffset;
    },

    /**
     *
     */
    every: function(array, fn, i){
      for(var i = 0, k = array.length; i < k; ++i){
        if(!fn(array[i])){
          return false;
        }
      }

      return 1;
    },

    /**
     * Get some!
     */
    fetch: function(){
      $.loader.style.display = 'block';

      $.ajax({
        url: url + '&limit=50&start=' + start,
        dataType: 'json',
        timeout: 15000,
        success: function(data, status){
          $.loader.style.display = 'none';

          $.load(data.offers);

          start = start + 25;

          if(data.records <= 0 || !data.records){
            if($.loadMore){
              document.removeChild($.loadMore);
            }
          }
        },
        error: function(xhr, response){
          $.loader.style.display = 'none';

          if(!$.emptyEl){
            $.showLoadingError();
          }
        }
      });
    },

    /**
     * Query string for traversing the DOM
     * @param {string} The selector - what to find - e.g. '#hello' or '.hello' or '#hell .hello'
     * @param {element} The context or scope (containing element, defaults to document) to execute the query within
     * @return {array} Returns a collection of elements matching the given selctor
     */
    find: function(selector, context){
      var query,
          context = context || document;

      try {
        if(selector[0] === '#' && !(/\s/.test(selector)) && context === document){
          query = context.getElementById(selector.replace('#', ''));
        }else{
          query = slice.call(context.querySelectorAll(selector));
        }
      }catch(err){
        console.log(err);
      }

      return query;
    },

    /**
     * Simple HTML/text keyed template formatting method
     * @param {string} The template or string containing object keys - e.g. '{boobies}'
     * @param {object} The object containing the keys to replace with their property value
     * @return {string}
     */
    format: function(tpl, object){
      object = object || {};

      return tpl.replace(/{(.+?)}/g, function(pattern, key){
        return object[key] || '';
      });
    },

    /**
     * Iterates through offers list and appends them to the offer wall
     */
    load: function(data){

      if(data && data.length === 0 && !$.emptyEl){
        $.showLoadingError();
        return;
      }

      if($.emptyEl){
        $.offersContainer.removeChild($.emptyEl);
        $.emptyEl = null;
      }

      for(var i = 0, k = data.length; i < k; i++){
        var li = document.createElement('li'),
            item = data[i],
            type = item.type.toLowerCase();

        item.free = $.labels.text.free;
        item.points = $.labels.text.points;
        item.earn = $.labels.text.earn;

        item.wifi =  item.requiresWifi ? '<div class="wifi">WiFi</div>' : '';
        item.action = '<div class="action ' + type + '">'+ ($.labels.actions[type] || '') +'</div>';
        item.cover = type === 'video' ? '<div class="play"></div><img class="frame" src="' + item.iconURL + '" />' : '<div class="' + ($.data.squircles ? 'overlay' : 'rounded') +'"></div><img class="cover" src="' + item.iconURL + '" />';
        
        if($.data.showCostBalloon){
          item.pricetag = item.cost !== 'Free' ? '<div class="action-item">'+item.cost+'</div>' : '';
        }

        li.innerHTML = '<a href="' + item.redirectURL + '?viewID=' + $.data.viewID + '">' + $.format($.tpl.offers[0], item) + $.format($.tpl.offers[1], item) + '</a>';

        $.offersContainer.appendChild(li);
        
        if(item.wifi.length != 0){
          $.each($.find('.icon', li), function(el){
            el.className += ' mtn';
          });
        }
      }

      $.truncate('.title', $.data.maxlength);
    },

    /**
     * Display error messaging on failed requests
     */
    showLoadingError: function(){
      var li = document.createElement('li');

      li.id = 'empty';
      li.innerHTML = '<div class="error">' + $.labels.text.error + '</div>';

      $.offersContainer.appendChild(li);

      $.emptyEl = li;
    },

    /**
     * DOM ready method
     * @param {function} Callback function to execute after DOMContentLoaded
     */
    ready: function(fn){
      if((/complete|loaded/).test(document.readyState)){
        fn.call();
      }

      document[this.addEvent]('DOMContentLoaded', fn, false);
    },

    /**
     * Truncates a string based on defined length and appends ellipsis
     */
    truncate: function(selector, len){
      var query = $.find(selector, document);

      $.each(query, function(el){
        var str = el.innerHTML;
        el.innerHTML = $.ellipsis(str, len || 70);
      });
    },

    /**
     * Returns the type of object that has been passed
     * @param {mixed} Anything
     * @return {string} Returns object type in string format
     */
    type: function(obj){
      return !obj || obj == null ? 'null' : toString.call(obj).split(' ').pop().replace(']', '').toLowerCase();
    }
  };

  $.ready(function(){
    $.init();
  });
})(window, data);
