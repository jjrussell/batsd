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
      limit = 25,
      start = 25,
      autoLoadLimit = 3,
      pagesFetched = 0,
      msie = (/msie/i).test(agent),
      url = fetchURL;

 var $ = {
    blank: 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
    empty: function(){},
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
    cls: {
      "6":"six",
      "7":"seven",
      "8":"eight",
      "9":"nine",
      "10":"ten"
    },
    tpl: {
      banner: ['<div class="clearfix">'+
                '<div class="left"><div class="earn text mt8">{earn} {currency}</div></div>'+
                  '<div class="right"><div class="text">{offers}&nbsp;</div><div class="logo mr5"><img src="{blank}" /></div></div>'+
                '</div>',
                '<div class="text">{offers}&nbsp;</div><div class="logo"><img src="{blank}" /></div>'
              ],
      cover: ['<div class="play"></div><img class="frame" src="{icon}" />',
              '<div class="rounded"></div><img class="cover" src="{icon}" />'],
      offersReward: [
        "<div class='reward gradientfix clearfix'>"+
         "<span class='earn {hide_earn} {earn_margin}'>{earn}</span>"+
          "<span class='big {payout_margin}'>{payout}</span>"+
          "<span class='points {points_long}'>{points}</span>"+
          "<span class='free'>{cost}</span>"+
        "</div>"
      ],
      offersNonReward: [
        "<div class='reward gradientfix'>"+
          "<span class='big mt10'>"+ i18n.t("tap_here") +"</span>"+
          "<span class='free'>{cost}</span>"+
        "</div>"
      ],
      offers: [
        "<div class='offer clearfix{offer_extra_classes}'>"+
          "<div class='icon'>"+
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

      var config = $.extend(defaults, config);

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

    extend: function(object, config, defaults){
      if(defaults){
        $.extend(object, defaults);
      }

      if(object && config && $.type(config) === 'object'){
        for(var i in config){
          object[i] = config[i];
        }
      }
      return object;
    },

    build: function(){

      var tpl = $.tpl.banner[($.data.currencyName.length < 100  && $.data.rewarded) ? 0 : 1];

      $.banner.innerHTML = $.format(
        tpl, {
          blank: $.blank,
          earn: $.labels.text.earn,
          currency: $.data.currencyName,
          offers: $.labels.text.offersby
        }
      );

      $.offersContainer.className += ' action-' + $.data.actionLocation + '-side';
      !$.data.showActionLine ? $.offersContainer.className += ' no-action-line' : '';

      if($.data.autoload && $.loadMore){
        try {
          $.loadMore.parentNode.style.display = 'none';
        }catch(err){}
      }
    },

    each: function(array, fn){
      $.every(array, function(item){
        return !fn(item)
      });
    },

    ellipsis: function(str, len){
      return str ? str.substr(0, len - 3) + (str.length < len ? '' : '...') : false;
    },

    endOfTheLine: function(){
      return document.body.clientHeight <= window.innerHeight + window.pageYOffset;
    },

    error: function(){
      var li = document.createElement('li');

      li.id = 'empty';
      li.innerHTML = '<div class="error">' + $.labels.text.error + '</div>';

      $.offersContainer.appendChild(li);

      $.emptyEl = li;
    },

    every: function(array, fn, i){
      for(var i = 0, k = array.length; i < k; ++i){
        if(!fn(array[i])){
          return false;
        }
      }

      return 1;
    },

    fetch: function(){
      if (!data.records || data.records == 0) {
        $.loadMore.parentNode.style.display = 'none';
        return;
      }
      $.loader.style.display = 'block';

      $.ajax({
        url: url + '&limit='+ limit +'&start=' + start,
        dataType: 'json',
        timeout: 15000,
        success: function(data, status){
          $.loader.style.display = 'none';

          if(data.offers.length > 0){
            $.load(data.offers);
            start = start + limit + 1;

            if(pagesFetched == autoLoadLimit){
              if($.loadMore){
                try {
                  $.loadMore.parentNode.style.display = 'block';
                }catch(err){}
              }
            }
            if(data.records == 0){
              try{
                $.loadMore.parentNode.style.display = 'none';
              }
              catch(err){}
            }

          }else{
            try {
              $.loadMore.parentNode.style.display = 'none';
            }catch(err){}
          }
        },
        error: function(xhr, response){
          $.loader.style.display = 'none';

          if(!$.emptyEl){
            $.error();
          }
        }
      });
    },

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

    format: function(tpl, object){
      object = object || {};

      return tpl.replace(/{(.+?)}/g, function(pattern, key){
        return object[key] || '';
      });
    },

    init: function(){

      $.data = data;
      $.banner = document.getElementById('branding');
      $.loader = document.getElementById('loading');
      $.loadMore = document.getElementById('more');
      $.offersContainer = document.getElementById('offers');
      $.visit = document.getElementById('visit');

      $.load(data.offers);
      $.build();
      $.listen();
    },

    listen: function(){
      if($.data.autoload){
        $.on(window, 'scroll', function(){
          if(pagesFetched < autoLoadLimit){
            if($.endOfTheLine() && !$.fetching){
              $.fetch();
              pagesFetched++;
            }
          }
        });
      }

      $.on($.loadMore, 'click', function(){
        $.fetch();
      });
    },

    load: function(data){

      if(data && data.length === 0 && !$.emptyEl){
        $.error();
        return;
      }

      if($.emptyEl){
        $.offersContainer.removeChild($.emptyEl);
        $.emptyEl = null;
      }

      for(var i = 0, k = data.length; i < k; i++){
        var li = document.createElement('li'),
            item = data[i],
            type = item.type.toLowerCase(),
            connector = item.redirectURL.match(/\?/) ? '&' : '?',
            offerType = !$.data.rewarded ? 'offersNonReward' : 'offersReward',
            len = $.data.currencyName.length,
            offer,
            size;

        item.free = $.labels.text.free;
        item.points = $.data.currencyName;
        item.earn = $.labels.text.earn;

        if (len >= 20) {
          item.hide_earn = 'hide';
          item.payout_margin = 'mt5';
          item.earn_margin = 'mt3';
          item.points_long = 'long';
        }
        else if (len >= 10) {
          item.hide_earn = 'hide';
          item.payout_margin = 'mt10';
          item.earn_margin = 'mt3';
          item.points_long = 'long';
        }

        item.wifi =  item.requiresWifi ? '<div class="wifi">WiFi</div>' : '';
        item.action = '<div class="action ' + type + '">'+ ($.labels.actions[type] || '') +'</div>';
        item.cover = $.format($.tpl.cover[type === 'video' ? 0 : 1], { icon: item.iconURL });

        if($.data.showActionArrow) item.offer_extra_classes = ' with-arrow';

        offer = $.format($.tpl[offerType][0], item) + $.format($.tpl.offers[0], item);

        li.className = 'offer-item clearfix';
        li.innerHTML = '<a href="' + item.redirectURL + connector + 'viewID=' + $.data.viewID + '">' + offer + '</a>';

        $.offersContainer.appendChild(li);

        size = item.payout.length;

        if(size > 5){
          $.each($.find('.big', li), function(el){
            el.className += ' ' + (size > 5 && size < 9 ? $.cls[size] : size > 9 ? 'large' : 'large');
          });
        }

        if(item.wifi.length != 0){
          $.each($.find('.icon', li), function(el){
            el.className += ' mtn';
          });
        }
      }

      $.truncate('.title', $.data.maxlength);
    },

    on: function(el, event, fn){
      var evt;

      if(!msie){
        evt = el.addEventListener(event, fn, false);
      }else{
        evt = el.attachEvent("on" + event, fn);
      }
      return evt;
    },

    ready: function(fn){
      if(!msie){
        if((/complete|loaded/).test(document.readyState)){
          fn.call();
        }

        document.addEventListener('DOMContentLoaded', fn, false);
      }else{
        window.onload = fn;
      }
    },

    truncate: function(selector, len){
      var query = $.find(selector, document);

      $.each(query, function(el){
        var str = el.innerHTML;
        el.innerHTML = $.ellipsis(str, len || 70);
      });
    },

    type: function(obj){
      return !obj || obj == null ? 'null' : toString.call(obj).split(' ').pop().replace(']', '').toLowerCase();
    }
  };

  $.ready(function(){
    $.init();
  });
})(window, data);
