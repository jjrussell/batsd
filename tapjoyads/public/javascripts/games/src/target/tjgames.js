var TJG = {}; TJG.vars = {};
TJG.doc = document.documentElement;
TJG.vars.orientationClasses = ['landscape', 'portrait'];
TJG.vars.isIos = false;
TJG.vars.isTouch = false;
TJG.vars.imageLoaderInit = false;
TJG.vars.autoKey = 0;  
TJG.appOfferWall = {};
TJG.loadedImages = {};
(function(window, document) {
    var winH, winW;
    function centerDialog (el) {
      winH = $(window).height();
      winW = $(window).width();
      $(el).css('top',  winH/2-$().height()/2);
      $(el).css('left', winW/2-$(el).width()/2);
      $(el).show();    
    }
    centerDialog("#loader");
     var nav = navigator, classes = [''], classReplaces = {}, device = "", orientationCompute = "";
     TJG.vars.isIos = (/iphone|ipod|ipad/gi).test(nav.platform);
     TJG.vars.isAndroid = (/android/gi).test(nav.platform);
     TJG.vars.isMobile = /(ip(od|ad|hone)|android)/gi.test(nav.userAgent);
     TJG.vars.isIPad = (/ipad/gi).test(nav.platform);
     TJG.vars.isRetina = 'devicePixelRatio' in window && window.devicePixelRatio > 1;
     TJG.vars.isSafari = nav.appVersion.match(/Safari/gi);
     TJG.vars.hasHomescreen = 'standalone' in nav && TJG.vars.isIos;
     TJG.vars.isStandalone = TJG.vars.hasHomescreen && nav.standalone;
     TJG.vars.version = nav.appVersion.match(/OS \d+_\d+/g);
     TJG.vars.platform = nav.platform.split(' ')[0];
     TJG.vars.language = nav.language.replace('-', '_');
     if (TJG.vars.isIos || TJG.vars.isMobile) {
       if (TJG.vars.isIPad) {
         classReplaces['mobile'] = 'ipad';
       }
    }
    else {
      classReplaces['mobile'] = 'web';
    }
    classes.push(winW + 'x' + winH);
    if ('ontouchend' in document) {
      classReplaces['no-touch'] = 'touch';
      TJG.vars.isTouch = true;
    }
    if (TJG.vars.isRetina) {
        classReplaces['no-hd'] = 'hd';
    } 
    function getOrientationClass() {
      return TJG.vars.orientationClasses[window.orientation % 180 ? 0 : 1];
    }
    if ('orientation' in window) {
      var orientationRe = new RegExp('(' + TJG.vars.orientationClasses.join('|') + ')'),
        orientationEvent = ('onorientationchange' in window) ? 'orientationchange' : 'resize',
          currentOrientationClass = classes.push(getOrientationClass());
      addEventListener(orientationEvent, function() {
          var orientationClass = getOrientationClass();
          if (currentOrientationClass != orientationClass) {
            currentOrientationClass = orientationClass;
            var className = TJG.doc.className;
            TJG.doc.className = className ? className.replace(orientationRe, currentOrientationClass) : currentOrientationClass;
            if (TJG.repositionDialog.length > 0) {
              for (var i = 0; i < TJG.repositionDialog.length; i++) {
                centerDialog(TJG.repositionDialog[i]);
              }
            }
         }
      }, false);
    }
    var className = TJG.doc.className;
    for (replace in classReplaces) {              
        className = className.replace(replace, classReplaces[replace]);
    }
    TJG.doc.className = className + classes.join(' ');
})(this, document);/*

            _/    _/_/    _/_/_/_/_/                              _/
               _/    _/      _/      _/_/    _/    _/    _/_/_/  _/_/_/
          _/  _/  _/_/      _/    _/    _/  _/    _/  _/        _/    _/
         _/  _/    _/      _/    _/    _/  _/    _/  _/        _/    _/
        _/    _/_/  _/    _/      _/_/      _/_/_/    _/_/_/  _/    _/
       _/
    _/

    Created by David Kaneda <http://www.davidkaneda.com>
    Documentation and issue tracking on GitHub <http://wiki.github.com/senchalabs/jQTouch/>

    Special thanks to Jonathan Stark <http://jonathanstark.com/>
    and pinch/zoom <http://www.pinchzoom.com/>

    (c) 2010 by jQTouch project members.
    See LICENSE.txt for license.

    $Revision: 166 $
    $Date: Tue Mar 29 01:24:46 EDT 2011 $
    $LastChangedBy: jonathanstark $


*/
(function($) {
    $.jQTouch = function(options) {
        var $body,
            $head=$('head'),
            initialPageId='',
            hist=[],
            newPageCount=0,
            jQTSettings={},
            currentPage='',
            orientation='portrait',
            tapReady=true,
            lastTime=0,
            lastAnimationTime=0,
            touchSelectors=[],
            publicObj={},
            tapBuffer=351,
            extensions=$.jQTouch.prototype.extensions,
            animations=[],
            hairExtensions='',
            defaults = {
                addGlossToIcon: true,
                backSelector: '.back, .cancel, .goback',
                cacheGetRequests: true,
                debug: false,
                fallback2dAnimation: 'fade',
                fixedViewport: true,
                formSelector: 'form',
                fullScreen: true,
                fullScreenClass: 'fullscreen',
                hoverDelay: 50,
                icon: null,
                icon4: null,
                moveThreshold: 10,
                preloadImages: false,
                pressDelay: 1000,
                startupScreen: null,
                statusBar: 'default',
                submitSelector: '.submit',
                touchSelector: 'a, .touch',
                useAnimations: true,
                useFastTouch: true,
                animations: [
                    {selector:'.cube', name:'cubeleft', is3d:true},
                    {selector:'.cubeleft', name:'cubeleft', is3d:true},
                    {selector:'.cuberight', name:'cuberight', is3d:true},
                    {selector:'.dissolve', name:'dissolve', is3d:false},
                    {selector:'.fade', name:'fade', is3d:false},
                    {selector:'.flip', name:'flipleft', is3d:true},
                    {selector:'.flipleft', name:'flipleft', is3d:true},
                    {selector:'.flipright', name:'flipright', is3d:true},
                    {selector:'.pop', name:'pop', is3d:true},
                    {selector:'.slide', name:'slideleft', is3d:false},
                    {selector:'.slidedown', name:'slidedown', is3d:false},
                    {selector:'.slideleft', name:'slideleft', is3d:false},
                    {selector:'.slideright', name:'slideright', is3d:false},
                    {selector:'.slideup', name:'slideup', is3d:false},
                    {selector:'.swap', name:'swapleft', is3d:true},
                    {selector:'#jqt > * > ul li a', name:'slideleft', is3d:false}
                ]
            };
            
        function addAnimation(animation) {
            if (typeof(animation.selector) === 'string' && typeof(animation.name) === 'string') {
                animations.push(animation);
            }
        }
        function addPageToHistory(page, animation) {
            hist.unshift({
                page: page,
                animation: animation,
                hash: '#' + page.attr('id'),
                id: page.attr('id')
            });
        }
        function clickHandler(e) {
            if (!tapReady) {
                e.preventDefault();
                return false;
            }
            var $el = $(e.target);
            if (!$el.is(touchSelectors.join(', '))) {
                var $el = $(e.target).closest(touchSelectors.join(', '));
            }
            if ($el && $el.attr('href') && !$el.isExternalLink()) {
                e.preventDefault();
            }

            if ($.support.touch) {
            } else {
                $(e.target).trigger('tap', e);
            }

        }
        function doNavigation(fromPage, toPage, animation, goingBack) {
            if (toPage.length === 0) {
                $.fn.unselect();
                return false;
            }

            if (toPage.hasClass('current')) {
                $.fn.unselect();
                return false;
            }

            $(':focus').blur();
            fromPage.trigger('pageAnimationStart', { direction: 'out' });
            toPage.trigger('pageAnimationStart', { direction: 'in' });

            if ($.support.animationEvents && animation && jQTSettings.useAnimations) {
                tapReady = false;
                if (!$.support.transform3d && animation.is3d) {
                    animation.name = jQTSettings.fallback2dAnimation;
                }
                var finalAnimationName;
                if (goingBack) {
                    if (animation.name.indexOf('left') > 0) {
                        finalAnimationName = animation.name.replace(/left/, 'right');
                    } else if (animation.name.indexOf('right') > 0) {
                        finalAnimationName = animation.name.replace(/right/, 'left');
                    } else if (animation.name.indexOf('up') > 0) {
                        finalAnimationName = animation.name.replace(/up/, 'down');
                    } else if (animation.name.indexOf('down') > 0) {
                        finalAnimationName = animation.name.replace(/down/, 'up');
                    } else {
                        finalAnimationName = animation.name;
                    }
                } else {
                    finalAnimationName = animation.name;
                }

                fromPage.bind('webkitAnimationEnd', navigationEndHandler);
                fromPage.bind('webkitTransitionEnd', navigationEndHandler);

                scrollTo(0, 0);
                toPage.addClass(finalAnimationName + ' in current');
                fromPage.addClass(finalAnimationName + ' out');

            } else {
                toPage.addClass('current');
                navigationEndHandler();
            }

            function navigationEndHandler(event) {
                if ($.support.animationEvents && animation && jQTSettings.useAnimations) {
                    fromPage.unbind('webkitAnimationEnd', navigationEndHandler);
                    fromPage.unbind('webkitTransitionEnd', navigationEndHandler);
                    fromPage.removeClass(finalAnimationName + ' out current');
                    toPage.removeClass(finalAnimationName + ' in');
                } else {
                    fromPage.removeClass(finalAnimationName + ' out current');
                }

                currentPage = toPage;
                if (goingBack) {
                    hist.shift();
                } else {
                    addPageToHistory(currentPage, animation);
                }

                fromPage.unselect();
                lastAnimationTime = (new Date()).getTime();
                setHash(currentPage.attr('id'));
                tapReady = true;
                toPage.trigger('pageAnimationEnd', {direction:'in', animation:animation});
                fromPage.trigger('pageAnimationEnd', {direction:'out', animation:animation});
            }
            return true;
        }
        function getOrientation() {
            return orientation;
        }
        function goBack() {
            if (hist.length < 1 ) {
            }

            if (hist.length === 1 ) {
            }

            var from = hist[0], to = hist[1];
            if (doNavigation(from.page, to.page, from.animation, true)) {
                return publicObj;
            } else {
                return false;
            }

        }
        function goTo(toPage, animation, reverse) {
            var fromPage = hist[0].page;
            if (typeof animation === 'string') {
                for (var i=0, max=animations.length; i < max; i++) {
                    if (animations[i].name === animation) {
                        animation = animations[i];
                        break;
                    }
                }
            }
            if (typeof(toPage) === 'string') {
                var nextPage = $(toPage);
                if (nextPage.length < 1) {
                    showPageByHref(toPage, {
                        'animation': animation
                    });
                    return;
                } else {
                    toPage = nextPage;
                }

            }
            if (doNavigation(fromPage, toPage, animation)) {
                return publicObj;
            } else {
                return false;
            }
        }
        function hashChangeHandler(e) {
            if (location.hash === hist[0].hash) {
            } else {
                if(location.hash === hist[1].hash) {
                    goBack();
                }
            }
        }
        function init(options) {
            jQTSettings = $.extend({}, defaults, options);
        }
        function insertPages(nodes, animation) {
            var targetPage = null;
            $(nodes).each(function(index, node) {
                var $node = $(this);
                if (!$node.attr('id')) {
                    $node.attr('id', 'page-' + (++newPageCount));
                }
                $('#' + $node.attr('id')).remove();
                $body.trigger('pageInserted', {page: $node.appendTo($body)});
                if ($node.hasClass('current') || !targetPage) {
                    targetPage = $node;
                }
            });
            if (targetPage !== null) {
                goTo(targetPage, animation);
                return targetPage;
            } else {
                return false;
            }
        }
        function mousedownHandler(e) {
            var timeDiff = (new Date()).getTime() - lastAnimationTime;
            if (timeDiff < tapBuffer) {
                return false;
            }
        }
        function orientationChangeHandler() {
            orientation = Math.abs(window.orientation) == 90 ? 'landscape' : 'portrait';
            $body.removeClass('portrait landscape').addClass(orientation).trigger('turn', {orientation: orientation});
        }
        function setHash(hash) {
            hash = hash.replace(/^#/, ''),
            location.hash = '#' + hash;
        }
        function showPageByHref(href, options) {
            var defaults = {
                data: null,
                method: 'GET',
                animation: null,
                callback: null,
                $referrer: null
            };
            var settings = $.extend({}, defaults, options);
            if (href != '#') {
                $.ajax({
                    url: href,
                    data: settings.data,
                    type: settings.method,
                    success: function (data, textStatus) {
                        var firstPage = insertPages(data, settings.animation);
                        if (firstPage) {
                            if (settings.method == 'GET' && jQTSettings.cacheGetRequests === true && settings.$referrer) {
                                settings.$referrer.attr('href', '#' + firstPage.attr('id'));
                            }
                            if (settings.callback) {
                                settings.callback(true);
                            }
                        }
                    },
                    error: function (data) {
                        if (settings.$referrer) {
                            settings.$referrer.unselect();
                        }
                        if (settings.callback) {
                            settings.callback(false);
                        }
                    }
                });
            } else if (settings.$referrer) {
                settings.$referrer.unselect();
            }
        }
        function submitHandler(e, callback) {
            $(':focus').blur();
            e.preventDefault();
            var $form = (typeof(e)==='string') ? $(e).eq(0) : (e.target ? $(e.target) : $(e));
            if ($form.length && $form.is(jQTSettings.formSelector) && $form.attr('action')) {
                showPageByHref($form.attr('action'), {
                    data: $form.serialize(),
                    method: $form.attr('method') || "POST",
                    animation: animations[0] || null,
                    callback: callback
                });
                return false;
            }
            return false;
        }
        function submitParentForm($el) {
            var $form = $el.closest('form');
            if ($form.length === 0) {
            } else {
                var evt = $.Event('submit');
                evt.preventDefault();
                $form.trigger(evt);
                return false;
            }
            return true;
        }
        function supportForAnimationEvents() {
            return (typeof WebKitAnimationEvent != 'undefined');
        }
        function supportForCssMatrix() {
            return (typeof WebKitCSSMatrix != 'undefined');
        }
        function supportForTouchEvents() {
            if (typeof TouchEvent != 'undefined') {
                if (window.navigator.userAgent.indexOf('Mobile') > -1) { // Grrrr...
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        };
        function supportForTransform3d() {
            var head, body, style, div, result;
            head = document.getElementsByTagName('head')[0];
            body = document.body;
            style = document.createElement('style');
            style.textContent = '@media (transform-3d),(-o-transform-3d),(-moz-transform-3d),(-ms-transform-3d),(-webkit-transform-3d),(modernizr){#jqtTestFor3dSupport{height:3px}}';
            div = document.createElement('div');
            div.id = 'jqtTestFor3dSupport';
            head.appendChild(style);
            body.appendChild(div);
            result = div.offsetHeight === 3;
            style.parentNode.removeChild(style);
            div.parentNode.removeChild(div);
            return result;
        };
        function tapHandler(e){
            if (!tapReady) {
                return false;
            }
            var $el = $(e.target);
            if (!$el.is(touchSelectors.join(', '))) {
                var $el = $(e.target).closest(touchSelectors.join(', '));
            }
            
            if (!$el.length || !$el.attr('href')) {
                return false;
            }
            var target = $el.attr('target'),
                hash = $el.attr('hash'),
                animation = null;

            if ($el.isExternalLink()) {
                $el.unselect();
                return true;
            } else if ($el.is(jQTSettings.backSelector)) {
                goBack(hash);
            } else if ($el.is(jQTSettings.submitSelector)) {
                submitParentForm($el);
            } else if (target === '_webapp' || target === 'internal' || target === 'no-ajax') {
                window.location = $el.attr('href');
                return false;
            } else if ($el.attr('href') === '#') {
                $el.unselect();
                return true;
            } else {
                for (var i=0, max=animations.length; i < max; i++) {
                    if ($el.is(animations[i].selector)) {
                        animation = animations[i];
                        break;
                    }
                };
                if (!animation) {
                    animation = 'slideleft';
                }
                if (hash && hash !== '#') {
                    $el.addClass('active');
                    goTo($(hash).data('referrer', $el), animation, $el.hasClass('reverse'));
                    return false;
                } else if (target === 'ajax') {
                    $el.addClass('loading active');
                    showPageByHref($el.attr('href'), {
                        animation: animation,
                        callback: function() {
                            $el.removeClass('loading');
                            setTimeout($.fn.unselect, 250, $el);
                        },
                        $referrer: $el
                    });
                    return false;
                }
                else {
                  window.location = $el.attr('href');
                  return false;
                }
            }
        }
        function touchStartHandler(e) {            
            if (!tapReady) {
                e.preventDefault();
                return false;
            }

            var $el = $(e.target);
            if (!$el.length) {
                return;
            }
            var startTime = (new Date).getTime(),
                hoverTimeout = null,
                pressTimeout = null,
                touch,
                startX,
                startY,
                deltaX = 0,
                deltaY = 0,
                deltaT = 0;

            if (event.changedTouches && event.changedTouches.length) {
                touch = event.changedTouches[0];
                startX = touch.pageX;
                startY = touch.pageY;
            }
            $el.bind('touchmove',touchMoveHandler).bind('touchend',touchEndHandler).bind('touchcancel',touchCancelHandler);
            hoverTimeout = setTimeout(function() {
                $el.makeActive();
            }, jQTSettings.hoverDelay);
            pressTimeout = setTimeout(function() {
                $el.unbind('touchmove',touchMoveHandler).unbind('touchend',touchEndHandler).unbind('touchcancel',touchCancelHandler);
                $el.unselect();
                clearTimeout(hoverTimeout);
                $el.trigger('press');
            }, jQTSettings.pressDelay);
            function touchCancelHandler(e) {
                clearTimeout(hoverTimeout);
                $el.unselect();
                $el.unbind('touchmove',touchMoveHandler).unbind('touchend',touchEndHandler).unbind('touchcancel',touchCancelHandler);
            }

            function touchEndHandler(e) {
                // updateChanges();
                $el.unbind('touchend',touchEndHandler).unbind('touchcancel',touchCancelHandler);
                clearTimeout(hoverTimeout);
                clearTimeout(pressTimeout);
                if (Math.abs(deltaX) < jQTSettings.moveThreshold && Math.abs(deltaY) < jQTSettings.moveThreshold && deltaT < jQTSettings.pressDelay) {
                    $el.trigger('tap', e);
                } else {
                    $el.unselect();
                }
            }

            function touchMoveHandler(e) {
                updateChanges();
                var absX = Math.abs(deltaX);
                var absY = Math.abs(deltaY);
                var direction;
                if (absX > absY && (absX > 35) && deltaT < 1000) {
                    if (deltaX < 0) {
                        direction = 'left';
                    } else {
                        direction = 'right';
                    }
                    $el.unbind('touchmove',touchMoveHandler).unbind('touchend',touchEndHandler).unbind('touchcancel',touchCancelHandler);
                    $el.trigger('swipe', {direction:direction, deltaX:deltaX, deltaY: deltaY});
                }
                $el.unselect();
                clearTimeout(hoverTimeout);
                if (absX > jQTSettings.moveThreshold || absY > jQTSettings.moveThreshold) {
                    clearTimeout(pressTimeout);
                }
            }

            function updateChanges() {
                var firstFinger = event.changedTouches[0] || null;
                deltaX = firstFinger.pageX - startX;
                deltaY = firstFinger.pageY - startY;
                deltaT = (new Date).getTime() - startTime;
            }

        }
        function useFastTouch(setting) {
            if (setting !== undefined) {
                if (setting === true) {
                    if (supportForTouchEvents()) {
                        $.support.touch = true;
                    }
                } else {
                    $.support.touch = false;
                }
            }

            return $.support.touch;

        }

        init(options);

        $(document).ready(function() {
            $.support.animationEvents = supportForAnimationEvents();
            $.support.cssMatrix = supportForCssMatrix();
            $.support.touch = supportForTouchEvents() && jQTSettings.useFastTouch;
            $.support.transform3d = supportForTransform3d();

            $.fn.isExternalLink = function() {
                var $el = $(this);
                return ($el.attr('target') == '_blank' || $el.attr('rel') == 'external' || $el.is('a[href^="http://maps.google.com"], a[href^="mailto:"], a[href^="tel:"], a[href^="javascript:"], a[href*="youtube.com/v"], a[href*="youtube.com/watch"]'));
            }
            $.fn.makeActive = function() {
                return $(this).addClass('active');
            }
            $.fn.press = function(fn) {
                if ($.isFunction(fn)) {
                    return $(this).live('press', fn);
                } else {
                    return $(this).trigger('press');
                }
            }
            $.fn.swipe = function(fn) {
                if ($.isFunction(fn)) {
                    return $(this).live('swipe', fn);
                } else {
                    return $(this).trigger('swipe');
                }
            }
            $.fn.tap = function(fn) {
                if ($.isFunction(fn)) {
                    return $(this).live('tap', fn);
                } else {
                    return $(this).trigger('tap');
                }
            }
            $.fn.unselect = function(obj) {
                if (obj) {
                    obj.removeClass('active');
                } else {
                    $('.active').removeClass('active');
                }
            }

            for (var i=0, max=extensions.length; i < max; i++) {
                var fn = extensions[i];
                if ($.isFunction(fn)) {
                    $.extend(publicObj, fn(publicObj));
                }
            }
            if (jQTSettings['cubeSelector']) {
                jQTSettings['cubeleftSelector'] = jQTSettings['cubeSelector'];
            }
            if (jQTSettings['flipSelector']) {
                jQTSettings['flipleftSelector'] = jQTSettings['flipSelector'];
            }
            if (jQTSettings['slideSelector']) {
                jQTSettings['slideleftSelector'] = jQTSettings['slideSelector'];
            }
            for (var i=0, max=defaults.animations.length; i < max; i++) {
                var animation = defaults.animations[i];
                if(jQTSettings[animation.name + 'Selector'] !== undefined){
                    animation.selector = jQTSettings[animation.name + 'Selector'];
                }
                addAnimation(animation);
            }

            touchSelectors.push('input');
            touchSelectors.push(jQTSettings.touchSelector);
            touchSelectors.push(jQTSettings.backSelector);
            touchSelectors.push(jQTSettings.submitSelector);
            $(touchSelectors.join(', ')).css('-webkit-touch-callout', 'none');

            $body = $('#jqt');
            if ($body.length === 0) {
                $body = $('body').attr('id', 'jqt');
            }

            if ($.support.transform3d) {
                $body.addClass('supports3d');
            }
            if (jQTSettings.fullScreenClass && window.navigator.standalone == true) {
                $body.addClass(jQTSettings.fullScreenClass + ' ' + jQTSettings.statusBar);
            }
            if (window.navigator.userAgent.match(/Android/ig)) {
                $body.addClass('android');
            }

            $(window).bind('hashchange', hashChangeHandler);
            $body.bind('touchstart', touchStartHandler)
                .bind('click', clickHandler)
                .bind('mousedown', mousedownHandler)
                .bind('orientationchange', orientationChangeHandler)
                .bind('submit', submitHandler)
                .bind('tap', tapHandler)
                .trigger('orientationchange');
            
            
            if ($('#jqt > .current').length == 0) {
                currentPage = $('#jqt > *:first');
            } else {
                currentPage = $('#jqt > .current:first');
                $('#jqt > .current').removeClass('current');
            }

            $(currentPage).addClass('current');
            initialPageId = $(currentPage).attr('id');
            setHash(initialPageId);
            addPageToHistory(currentPage);
            scrollTo(0, 0);
            
            $('#jqt > *').css('minHeight', window.innerHeight);

        });
        publicObj = {
            addAnimation: addAnimation,
            animations: animations,
            getOrientation: getOrientation,
            goBack: goBack,
            goTo: goTo,
            hist: hist,
            settings: jQTSettings,
            submitForm: submitHandler,
            support: $.support,
            useFastTouch: useFastTouch
        }
        return publicObj;
    }
    $.jQTouch.prototype.extensions = [];
    $.jQTouch.addExtension = function(extension) {
        $.jQTouch.prototype.extensions.push(extension);
    }

})(jQuery);TJG.utils = {
  
  genSym : function() {
    var res = '' + TJG.vars.autoKey;
    TJG.vars.autoKey++;
    return res;
  },
  
  isNull : function(v) {
    if (typeof v == 'boolean') {
      return false;
    } else if (typeof v == 'number') {
      return false;
    }
    else {
      return v == undefined || v == null || v == '';
    }
  },
  
  or : function (v, defval) {
    if (this.isNull(v)) {
      return defval;
    }
    return v;
  },

  hideURLBar : function() {
    setTimeout(function() { 
      window.scrollTo(0, 1);
    }, 0);
  },

  getOrientation : function() {
    return TJG.vars.orientationClasses[window.orientation % 180 ? 0 : 1];
  },

  updateOrientation : function() {
    var orientation = this.getOrientation();
    TJG.doc.setAttribute("orient", orientation); 
  },
  
  centerDialog : function(el) {
    var winH = $(window).height();
    var winW = $(window).width();
    $(el).css('top',  winH/2-$(el).height()/2);
    $(el).css('left', winW/2-$(el).width()/2); 
  },
  
  disableScrollOnBody : function() {
    if (!TJG.vars.isTouch) return;
    document.body.addEventListener("touchmove", function(e) {
      e.preventDefault();
    }, false);
  },
  
  getParam : function(name) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]"); 
    var regexS = "[\\?&]"+name+"=([^&]*)"; 
    var regex = new RegExp( regexS ); 
    var results = regex.exec( window.location.href ); 
    if( results == null ) return ""; 
    else return results[1];
  },
  
  setLocalStorage: function(k,v) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    } 
    else {
      try {
        localStorage[k] = v;
      } catch (e) {
      }
    }
  },
  
  unsetLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    localStorage.removeItem(k);
  },
  
  getLocalStorage: function(k) {
    if (typeof(localStorage) == 'undefined' ) {
      return;
    }
    return localStorage[k];
  },
  
  scrollTop : function (delay){
    if (delay == null) {
      delay = "slow";
    } 
    $("html, body").animate({scrollTop:0}, delay);
  },
  
  loadImages: function (el) {
    TJG.vars.scrolling = false;
    var preLoad = 0, padSpace = 0;
    if (TJG.vars.isIos) {
      preLoad = 60;
      padSpace = 80;
    }
    $(el).each(function (n,o) { 
      if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
        var img = $(o).children("img:first");
        if ($(img).attr("loaded") == "true") {
          return;
        }
        $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
        $(img).error(function() {
          $(img).attr("src", TJG.blank_img);
        });          
      }
    }); 
    
    if (!TJG.vars.imageLoaderInit) {
      $(window).scroll( function() {
        if (!TJG.vars.scrolling) {
          TJG.vars.scrolling = true;
          setTimeout( function() {
            $(el).each(function (n,o) {
              var id = $(o).attr("id");
              if ( this && $.inviewport( this, { padding: padSpace, threshold:preLoad } ) ) {
                var img = $(o).children("img:first");
                if ($(img).attr("loaded") == "true") {
                  return;
                }   
                $(img).attr("src", $(img).attr("s")).attr("loaded", "true");
                $(img).error(function() {
                  $(img).attr("src", TJG.blank_img);
                });
              }
            }); 
            TJG.vars.scrolling = false;
          }, 150);
        }
      });
      $(window).trigger('scroll');
      TJG.vars.imageLoaderInit = true;
    }
  }
  
};
$.utils = TJG.utils;

TJG.ui = { 
  
  hideLoader : function(delay,fn) {
    TJG.repositionDialog = [];
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('#loader').fadeOut(delay,fn);
    });
  },
  
  showLoader : function(delay,fn) {
    $.utils.centerDialog("#loader");
    TJG.repositionDialog = ["#loader"];
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('#loader').fadeIn(delay,fn);
    });
  },
  
  removeDialogs : function (delay) {
    delay = $.utils.or(delay, "fast");
    setTimeout(function() {
      $('.dialog_wrapper').fadeOut(delay); 
    });
    TJG.repositionDialog = [];
  },
  
  getOfferRow : function (obj,currency,i,hidden) {
    var t = [], clsId = "", style = "";
    if (i) {
      clsId = "offer_item_" + i;
    }
    if (hidden) {
      style = 'style="display:none;"';
    }
    $.each(obj, function(i,v){
      var freeCls = "";
      if (v.Cost == "Free") {
        freeCls = "free";
      }
      t.push('<a href="' + v.RedirectURL + '">'); 
        t.push('<li class="offer_item clearfix '+ clsId +'" '+ style +'>');
          t.push('<a href="' + v.RedirectURL + '">');
            t.push('<div class="offer_image">');
              t.push('<div id="'+ TJG.utils.genSym() +'" class="offer_image_loader_wrapper"><img src="' + TJG.blank_img + '" s="' + v.IconURL + '"></div>');
            t.push('</div>'); 
          t.push('</a>');
          t.push('<div class="offer_text">');
            t.push('<div class="offer_title title">');
              t.push(v.Name);
            t.push('</div>'); 
            t.push('<div class="offer_install">');
              t.push('Install and run ' + v.Name);
            t.push('</div>');  
            t.push('<div class="offer_info">');
                t.push('<a href="' + v.RedirectURL + '">');
                  t.push('<div class="offer_button my_apps">');
                    t.push('<div class="button grey">');
                      t.push('<span class="amount">');
                        t.push(v.Amount);
                      t.push('</span>');
                      t.push(' ');
                      t.push('<span class="currency">');
                        t.push(currency);
                      t.push('</span>');
                      t.push('<span class="cost '+ freeCls +'">');
                        t.push(v.Cost);
                      t.push('</span>'); 
                    t.push('</div>');
                  t.push('</div>');  
                t.push('</a>'); 
            t.push('</div>');
          t.push('</div>');
        t.push('</li>');
      t.push('</a>');
    });
    return t.join('');
  },
  
  showRegister : function () {
    var hasLinked = true, path, animateSpd = "fast";
    if (TJG.path) {
       path = TJG.path;
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    TJG.repositionDialog = ["#sign_up_dialog"];
    $("#sign_up_dialog_content").html($('#sign_up_dialog_content_placeholder').html());
    $(".close_dialog").show();
    $("#sign_up_dialog_content").parent().animate({ height: "270px", }, animateSpd);
    $("#sign_up_dialog").fadeIn();
    $('form#new_gamer').submit(function(e){
      e.preventDefault();
      var rurl, inputs, values = {}, data, hasError = false, emailReg;
      rurl = $(this).attr('action');
      inputs = $('form#new_gamer :input');
      inputs.each(function() {
        if (this.type == 'checkbox' || this.type == 'radio') {
          values[this.name] = $(this).attr("checked");
        }
        else {
          values[this.name] = $(this).val();
        }
      });
      $(".email_error").hide();
      emailReg = /^([\w-\.+]+@([\w-]+\.)+[\w-]{2,4})?$/;
      if(values['gamer[email]'] == '') {
        $(".email_error").html('Please enter your email address');
        hasError = true;
      }
      else if(!emailReg.test(values['gamer[email]'])) {
        $(".email_error").html('Enter a valid email address');
        hasError = true;
      }
      else if(values['gamer[password]'] == '') {
        $(".email_error").html('Please enter a password');
        hasError = true;
      }
      else if(values['gamer[terms_of_service]'] == false) {
        $(".email_error").html('Please agree to the terms and conditions above');
        hasError = true;
      }
      if (hasError) {
        $(".email_error").show();
      }
      else if (hasError != true) {
        var loader = [
          '<div id="dialog_title title_2">Registering</div>',
          '<div class="dialog_image"></div>'
        ].join('');
        $("#sign_up_dialog_content").html(loader);
        $("#sign_up_dialog_content").parent().animate({ height: "120px", }, animateSpd);
        $.ajax({
          type: 'POST',
          url: rurl,
          cache: false,
          timeout: 15000,
          dataType: 'json', 
          data: { 'authenticity_token': values['authenticity_token'], 'gamer[email]': values['gamer[email]'], 'gamer[password]': values['gamer[password]'], 'gamer[referrer]': values['gamer[referrer]'] },
          success: function(d) {
            var msg;
            if (d.success) {
              hasLinked = false;
              msg = [
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Success!</div></div>',
                '<div class="dialog_header">Your Tapjoy Games account was sucessfully created</div>',
               '<div class="dialog_content">A confirmation email has been sent to the address you entered.  Please follow the registration in the email to verify your address and complete the account registration. :)</div>',
               '<div class="dialog_content"><div class="continue_link_device"><div class="button dialog_button">Continue</div></div></div>'
              ].join('');
              $('.close_dialog').unbind('click');
              $("#sign_up_dialog_content").parent().animate({ height: "230px", }, animateSpd);
              $("#sign_up_dialog_content").html(msg);
              if (d.linked) { 
                $('.close_dialog,.continue_link_device').click(function(){
                  if (TJG.path) {
                    document.location.href = TG.path;
                  }
                  else {
                    document.location.href = document.domain;
                  }
                });
              }
              else if (d.link_device_url) {
                $('.close_dialog,.continue_link_device').click(function(){
                  $('.close_dialog').unbind('click');
                  msg = [
                    '<div id="link_device" class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Link Device</div></div>',
                    '<div class="dialog_header">The final step is to link your device to your Tapjoy Games account.  Please continue and click install on the next screen.</div>',
                    '<div class="dialog_content"><div class="link_device_url"><div class="button dialog_button">Link Device</div></div></div>'
                  ].join('');
                  $("#sign_up_dialog_content").parent().animate({ height: "170px", }, animateSpd);
                  $("#sign_up_dialog_content").html(msg);
                  $('.close_dialog,.link_device_url').click(function(){
                    document.location.href = d.link_device_url;
                  });
                }); 
              }
              else {
                $('.close_dialog,.continue_link_device').click(function(){
                  document.location.href = location.protocol + '//' + location.host;
                });
              } 
            }
            else {
              var error = 'There was an issue with registering your account';
              if (d.error) {
                if (d.error[0][0] && d.error[0][1]) {
                  error = 'The ' + d.error[0][0] + ' ' + d.error[0][1];
                }
              }
              msg = [
                '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
                '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
              ].join('');
              $("#sign_up_dialog_content").html(msg);
              $(".close_dialog").hide();
            }
            $('#sign_up_again').click(function(){
              TJG.ui.showRegister();
              $("#sign_up_dialog_content").parent().animate({ height: "270px", }, animateSpd);
            });
          },
          error: function() {
            var error = 'There was an issue'; 
            msg = [
              '<div class="dialog_header_wrapper"><div class="dialog_header_right"></div><div class="dialog_header_left"></div><div class="dialog_title title_2">Oops!</div></div>',
              '<div class="dialog_content">', error ,'. <span id="sign_up_again"><a href="#">Please click here to try again.</a></span></div>',
            ].join('');
            $(".close_dialog").hide(); 
            $("#sign_up_dialog_content").html(msg);
            $('#sign_up_again').click(function(){
               TJG.ui.showRegister();
              $("#sign_up_dialog_content").parent().animate({ height: "270px", }, animateSpd);
            });
          }
        });
      }
    });
  },
  
  showAddHomeDialog : function() {
    var startY = startX = 0,
    options = {
      message: 'Add <span class="bold">Tapjoy Games</span> to your home screen.',
      animationIn: 'fade',
      animationOut: 'fade',
      startDelay: 2000,
      lifespan: 10000,
      bottomOffset: 14,
      expire: 0,
      arrow: true,
      iterations: 5
    },
    theInterval, closeTimeout, el, i, l,
    expired = TJG.utils.getLocalStorage("tjg.bookmark.expired"),
    shown = TJG.utils.getLocalStorage("tjg.bookmark.shown");
    if (TJG.utils.isNull(shown)) {
      shown = 0;
    }
    shown = parseInt(shown);
    if (expired == "true") {
      return;
    }
    if (shown >= 4) {
      TJG.utils.setLocalStorage("tjg.bookmark.expired", true);
    }
    TJG.vars.version =  TJG.vars.version ?  TJG.vars.version[0].replace(/[^\d_]/g,'').replace('_','.')*1 : 0;
    expired = expired == 'null' ? 0 : expired*1;
    var div = document.createElement('div'), close;
    div.id = 'addToHome';
    div.style.cssText += 'position:absolute;-webkit-transition-property:-webkit-transform,opacity;-webkit-transition-duration:0;-webkit-transform:translate3d(0,0,0);';
    div.style.left = '-9999px';
    div.className = (TJG.vars.isIPad ? 'ipad wide' : 'iphone');
    var m =  options.message;
    var a = (options.arrow ? '<span class="arrow"></span>' : '');
    var t = [
      m,
      a
    ].join('');
    div.innerHTML = t;
    document.body.appendChild(div);
    el = div;
    
    function transitionEnd () {
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      el.style.webkitTransitionProperty = '-webkit-transform';
      el.style.webkitTransitionDuration = '0.2s';
      if (closeTimeout) {
        clearInterval(theInterval);
        theInterval = setInterval(setPosition, options.iterations);
      } 
      else {
        el.parentNode.removeChild(el);
      }   
    }
    function setPosition () {
      var matrix = new WebKitCSSMatrix(window.getComputedStyle(el, null).webkitTransform),
      posY = TJG.vars.isIPad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
      posX = TJG.vars.isIPad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX;
      if (posY == matrix.m42 && posX == matrix.m41) return;
      clearInterval(theInterval);
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      setTimeout(function () {
        el.addEventListener('webkitTransitionEnd', transitionEnd, false);
        el.style.webkitTransform = 'translate3d(' + posX + 'px,' + posY + 'px,0)';
      }, 0);
    }
    function addToHomeClose () {
      clearInterval(theInterval);
      clearTimeout(closeTimeout);
      closeTimeout = null;
      el.removeEventListener('webkitTransitionEnd', transitionEnd, false);
      var posY = TJG.vars.isIPad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
      posX = TJG.vars.isIPad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX,
      opacity = '0.95',
      duration = '0';
      el.style.webkitTransitionProperty = '-webkit-transform,opacity';
      switch (options.animationOut) {
        case 'drop':
        if (TJG.vars.isIPad) {
          duration = '0.4s';
          opacity = '0';
          posY = posY + 50;
        } else {
          duration = '0.6s';
          posY = posY + el.offsetHeight + options.bottomOffset + 50;
        }
        break;
        case 'bubble':
        if (TJG.vars.isIPad) {
          duration = '0.8s';
          posY = posY - el.offsetHeight - options.bottomOffset - 50;
        } 
        else {
          duration = '0.4s';
          opacity = '0';
          posY = posY - 50;
        }
        break;
        default:
        duration = '0.8s';
        opacity = '0';
      }
      el.addEventListener('webkitTransitionEnd', transitionEnd, false);
      el.style.opacity = opacity;
      el.style.webkitTransitionDuration = duration;
      el.style.webkitTransform = 'translate3d(' + posX + 'px,' + posY + 'px,0)';
    }
    setTimeout(function () {
      var duration;
      startY = TJG.vars.isIPad  ? window.scrollY : window.innerHeight + window.scrollY;
      startX = TJG.vars.isIPad  ? window.scrollX : Math.round((window.innerWidth - el.offsetWidth)/2) + window.scrollX;
      el.style.top = TJG.vars.isIPad ? startY + options.bottomOffset + 'px' : startY - el.offsetHeight - options.bottomOffset + 'px';
      el.style.left = TJG.vars.isIPad ? startX + (TJG.vars.version >=5 ? 160 : 208) - Math.round(el.offsetWidth/2) + 'px' : startX + 'px';
      switch (options.animationIn) {
        case 'drop':
        if (TJG.vars.isIPad) {
          duration = '0.6s';
          el.style.webkitTransform = 'translate3d(0,' + -(window.scrollY + options.bottomOffset + el.offsetHeight) + 'px,0)';
        } 
        else {
          duration = '0.9s';
          el.style.webkitTransform = 'translate3d(0,' + -(startY + options.bottomOffset) + 'px,0)';
        }
        break;
        case 'bubble':
        if (TJG.vars.isIPad) {
          duration = '0.6s';
          el.style.opacity = '0'
          el.style.webkitTransform = 'translate3d(0,' + (startY + 50) + 'px,0)';
        } 
        else {
          duration = '0.6s';
          el.style.webkitTransform = 'translate3d(0,' + (el.offsetHeight + options.bottomOffset + 50) + 'px,0)';
        }
        break;
        default:
        duration = '1s';
        el.style.opacity = '0';
      }
      setTimeout(function () {
        el.style.webkitTransitionDuration = duration;
        el.style.opacity = '0.95';
        shown = shown + 1;
        TJG.utils.setLocalStorage("tjg.bookmark.shown", shown);
        el.style.webkitTransform = 'translate3d(0,0,0)';
        el.addEventListener('webkitTransitionEnd', transitionEnd, false);
        }, 0);
        closeTimeout = setTimeout(addToHomeClose, options.lifespan);
    }, options.startDelay);
    window.addToHomeClose = addToHomeClose;
  },
  
  homeInit : function () {
    var jQT = new $.jQTouch({
      slideSelector: '#jqt',
    });
    var fadeSpd = 350, fadeSpdFast = 250, fadeSpdSlow = 700;
    var install = TJG.utils.getParam("register_device");
    if (TJG.vars.isIos || TJG.vars.isSafari) {
      TJG.ui.showAddHomeDialog();
    }
    var expand = TJG.utils.getLocalStorage("tjg.feat_review.expand");
    if (expand == "true") {
      $(".feat_toggle").removeClass('collaspe');
      $(".feat_review").removeClass('min');
      $(".app_review").show(); 
    }
    var repeat = TJG.utils.getLocalStorage("tjg.repeat_visit");
    if (install.indexOf("true") != -1) {
      TJG.utils.centerDialog("#register_device");
      $("#register_device").fadeIn(fadeSpd); 
    } 
    else if (repeat != "true") {
      /*
      var div = document.createElement('div'), close;
      div.id = 'firstTime';
      div.style.cssText += 'position:absolute;-webkit-transition-property:-webkit-transform,opacity;-webkit-transition-duration:0;-webkit-transform:translate3d(0,0,0);';
      div.style.left = '-9999px';
      var m =  "message";
      var a = '<span class="arrow"></span>';
      var t = [
        m,
        a
      ].join('');
      div.innerHTML = t;
      document.body.appendChild(div);
      */                                        
    }   
    TJG.ui.loadRatings();
    
    function slidePage(el,dir) {
      if (dir == 'right') {
        dir = 'slideright'
      }
      else {
        dir = 'slideleft'
      }
      jQT.goTo(el, dir);
    }
    
    function getOfferWalls() {
      $("#home").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#home .content_wrapper").fadeOut("fast");
        }
      });
      $("#earn").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#earn .content_wrapper").fadeOut("fast");
        }     
      });
      $("#more_games").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#more_games .content_wrapper").fadeOut("fast");
        }
      });
      $("#feat_app").bind('pageAnimationStart', function(e, info){
        if (info.direction == "out") {
          $("#feat_app .content_wrapper").fadeOut("fast");
        }
      }); 
      $("#home").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#home .content_wrapper").fadeIn("fast");
        }
      });
      $("#earn").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#earn .content_wrapper").fadeIn("fast");
        }       
      });
      $("#more_games").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#more_games .content_wrapper").fadeIn("fast");
        }
      });
      $("#feat_app").bind('pageAnimationEnd', function(e, info){
        if (info.direction == "in") {
          $("#feat_app .content_wrapper").fadeIn("fast");
        }
      });  
      $(".get_offerwall_jsonp").each(function() {
        var i = 0;
        $(this).click(function(){
          slidePage("#earn", "left");
          $("#earn_content").empty();
          var url = $(this).attr("jsonp_url"), appId = $(this).attr("id"), appName = $(this).attr("app_name"), currencyName = $(this).attr("currency");
          if (!TJG.appOfferWall[appId]) {
            TJG.appOfferWall[appId] = {};
          }
          TJG.appOfferWall[appId]['jsonp_url'] = url;
          var title = 'Complete any of the offers below to earn <span class="bold">' + currencyName + '</span> for <span class="bold">' + appName + '</span>';
          $("#app_title").html(title).show();
          if (url) {
            TJG.ui.showLoader();
            $.ajax({
              url: url+"&callback=?",
              dataType: 'json',
              timeout: 15000,
              success: function(data) {
                TJG.ui.hideLoader();
                if (data.OfferArray) {
                  var offers = data.OfferArray;
                  offerOffset = offers.length;
                  if (data.MoreDataAvailable) {
                    TJG.appOfferWall[appId]['offers_left'] = data.MoreDataAvailable;
                  }
                  else {
                    TJG.appOfferWall[appId]['offers_left'] = 0;
                  }
                  TJG.appOfferWall[appId]['offset'] = offerOffset;
                  var offerRows = TJG.ui.getOfferRow(offers, currencyName);
                  var t = [
                    '<ul id="offerwall_id-', appId ,'">',
                      offerRows,
                    '</ul>',
                  ];
                  if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                    t.push('<div class="more_button_wrapper"><div class="get_more_apps" app_id="' + appId + '"><div class="get_more_apps_content">Load More</div></div></div>');
                  }
                  else {
                    t.push('<div class="more_button_wrapper"><div class="back_to_top grey_button"><div class="grey_button_content">Back to Top</div></div></div>');
                    $(".back_to_top").click(function(){
                      TJG.utils.scrollTop();
                    });
                  }
                  t = t.join('');
                  $("#earn_content").html(t).fadeIn(fadeSpd, function(){
                    TJG.utils.loadImages(".offer_image_loader_wrapper");
                  });
                  var isLoading = false;
                  var hasFailed = false;
                  $(".get_more_apps").click(function(){
                    if (isLoading) { return; }
                    $(".get_more_apps_content").html('<div class="image_loader"></div>');
                    var appId = $(this).attr("app_id");
                    $(".load_more_loader").show();
                    if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                      var url = TJG.appOfferWall[appId]['jsonp_url'];
                      url = url + "&start=" + TJG.appOfferWall[appId]['offset'] + "&max=25&callback=?";
                      isLoading = true;
                      $.ajax({
                        url: url,
                        dataType: 'json',
                        timeout: 15000,
                        success: function(data) {
                          if (data.OfferArray) {
                            var offers = data.OfferArray;
                            if (data.MoreDataAvailable) {
                              TJG.appOfferWall[appId]['offers_left'] = data.MoreDataAvailable;
                            }
                            else {
                              TJG.appOfferWall[appId]['offers_left'] = 0;
                            }
                            TJG.appOfferWall[appId]['offset'] = TJG.appOfferWall[appId]['offset'] + 25;
                            var moreOfferRows = TJG.ui.getOfferRow(offers, currencyName, i, true);
                            $("#offerwall_id-" + appId).append(moreOfferRows);
                            var el = ".offer_item_" + i;
                            $.each($(el), function(n,o) {
                              $(o).fadeIn(fadeSpd);
                            });
                            TJG.utils.loadImages(".offer_image_loader_wrapper");
                            if (TJG.appOfferWall[appId]['offers_left'] > 0) {
                              $(".get_more_apps_content").html("Load More");
                            }
                            else {
                              $(".more_button_wrapper").html('<div class="back_to_top grey_button"><div class="grey_button_content">Back to Top</div></div>');
                              $(".back_to_top").click(function(){
                                TJG.utils.scrollTop();
                              }); 
                            }
                          }
                          isLoading = false;
                        },
                        error: function () {
                          var m = [
                            '<div class="center">There was an issue fetching more offers. Please try again.</div>'
                          ].join('');
                          if (!hasFailed) {
                            $("#offerwall_id-" + appId).append(m).fadeIn(fadeSpd);
                          }
                          hasFailed = true;
                          $(".get_more_apps_content").html("Load More");
                          $(".load_more_loader").hide();
                          isLoading = false;
                        }
                      });
                      i++;
                    }
                  });
                }
              },
              error: function() {
                TJG.ui.hideLoader();
                var m = [
                 '<div class="center">There was an issue. Please try again</div>'
                ].join('');
                $("#earn_content").html(m).fadeIn(fadeSpd);
                TJG.utils.scrollTop();
              }
            });
          }
          else {
            var m = [
              '<div class="center">There was an issue. Please try again</div>'
            ].join('');
            $("#earn_content").html(m).fadeIn(fadeSpd);
            TJG.utils.scrollTop();
         }
        });
      }); 
    }

    function reloadOfferWalls () {
      $(".get_offerwall_jsonp").unbind("click");
      getOfferWalls();
    }

    function getMoreGames() {
      $(".more_games_url").click(function() {
        slidePage("#more_games", "left");
        $("#recommended_games_button").addClass("dark_grey").removeClass("grey");
        $("#top_grossing_games_button").addClass("grey").removeClass("dark_grey");
        $("#top_grossing_games_button_arrow").hide();
        $("#recommended_games_button_arrow").show();
        if (TJG.moreAppOfferWall) {
          $("#more_games_content").html(TJG.moreAppOfferWall).fadeIn(fadeSpdSlow, function() {
            TJG.utils.loadImages(".offer_image_loader_wrapper");
            TJG.ui.loadRatings();
          });
        }
        else {
          TJG.ui.showLoader();
          $.ajax({ 
            url: TJG.more_games_editor_picks,
            timeout: 15000,
            success: function(c) {
              TJG.moreAppOfferWall = c;
              TJG.ui.hideLoader();
              $("#more_games_content").html(c).fadeIn(fadeSpd, function(){
                TJG.utils.loadImages(".offer_image_loader_wrapper");
                TJG.ui.loadRatings();
              });
            },
            error: function() {
              var m = [
                '<div>There was an issue. Please try again</div>'
              ].join('');
              $("#more_games_content").html(m).fadeIn(fadeSpd);
            }
          });
        }
      });
    }

    function getTopGames() {
      $("#top_grossing_games_tab").click(function() {
        $("#top_grossing_games_button").addClass("dark_grey").removeClass("grey");
        $("#recommended_games_button").addClass("grey").removeClass("dark_grey");
        $("#recommended_games_button_arrow").hide();
        $("#top_grossing_games_button_arrow").show();
        $("#recommended_games_tab").unbind("click");
        $("#recommended_games_tab").click(function() {
          $("#recommended_games_button").addClass("dark_grey").removeClass("grey");
          $("#top_grossing_games_button").addClass("grey").removeClass("dark_grey");
          $("#top_grossing_games_button_arrow").hide();
          $("#recommended_games_button_arrow").show();
          if (TJG.moreAppOfferWall) {
            $("#more_games_content").fadeOut(fadeSpdFast, function () {
              $("#more_games_content").html(TJG.moreAppOfferWall).fadeIn(fadeSpdFast, function(){
                TJG.utils.loadImages(".offer_image_loader_wrapper");
                TJG.ui.loadRatings(); 
              });
            });
          }
        });
        if (TJG.topAppOfferWall) {
          $("#more_games_content").fadeOut(fadeSpdFast, function () {
            $("#more_games_content").html(TJG.topAppOfferWall).fadeIn(fadeSpdSlow, function() {
              TJG.utils.loadImages(".offer_image_loader_wrapper");
              TJG.ui.loadRatings();
            });
          });
        }
        else {
          TJG.ui.showLoader();
          $.ajax({ 
            url: TJG.more_games_popular,
            timeout: 15000,
            success: function(c) {
              TJG.topAppOfferWall = c;
              TJG.ui.hideLoader();
              $("#more_games_content").fadeOut(fadeSpdFast, function () {
                $("#more_games_content").html(c).fadeIn(fadeSpdFast, function() {
                  TJG.utils.loadImages(".offer_image_loader_wrapper");
                  TJG.ui.loadRatings();
                });
              });
            },
            error: function () {
              var m = [
                '<div>There was an issue. Please try again</div>'
              ].join('');
              $("#more_games_content").fadeOut(fadeSpdFast, function () {
                $("#more_games_content").html(m).fadeIn(fadeSpdFast);
              });
            }
          });
        }
      });
    }
    function featuredReview() {
      $(".feat_app_url").click(function() { 
         slidePage("#feat_app", "left");
      });
    }
    getOfferWalls();
    getMoreGames();
    getTopGames();
    featuredReview();
  },

  loadRatings : function () {
    $(".offer_rating, .app_rating").each(function (n,o) {
      var rating = $(this).attr("rating");
      var t = [], max = 5, start = 0;
      if (rating) {
        rating = parseFloat(rating);
      }
      for (var i = 1; i <= 5; i++) {
        var starcls = "star off";
        if (rating >= i) {
          starcls = "star on";
          start++;
        }
        else if (rating > start){ 
          starcls = "star half";
          start++;
        }
        t.push('<span class="', starcls ,'"></span>');
      }
      $(this).html(t.join('')).fadeIn("slow");
    });
  }
  
};
  
(function(window, document) {

    TJG.onload = {

      removeLoader : function () {
        TJG.ui.hideLoader(250,function(){
           $('#jqt').fadeTo(250,1);
        });
      },

      loadEvents : function () {
        $('.close_dialog').click(function(){
          TJG.ui.removeDialogs();
          TJG.repositionDialog = [];
        });
        $('#sign_up, #sign_up_form').click(function() {
            TJG.utils.centerDialog("#sign_up_dialog");
            TJG.repositionDialog = ["#sign_up_dialog"];
            TJG.ui.showRegister();  
        });
        $('#how_works').click(function(){
          TJG.utils.centerDialog("#how_works_dialog");
          TJG.repositionDialog = ["#how_works_dialog"];
          $("#how_works_dialog").fadeIn(350);
        });
        $('.top_nav_bar').click(function(){
           TJG.utils.centerDialog("#my_account_dialog");
           TJG.repositionDialog = ["#my_account_dialog"];
           $("#my_account_dialog").fadeIn(350);
        });
        $('.my_account_url').click(function(){
          $("#my_account_dialog").fadeOut(350, function() {
            TJG.utils.centerDialog("#my_account_dialog_content");
            TJG.repositionDialog = ["#my_account_dialog_content"];
            $("#my_account_dialog_content").fadeIn(350);     
          });
        });
        $('.feat_toggle').click(function(){
          if ($(this).hasClass('collaspe')) {
            $(this).removeClass('collaspe');
            $(".feat_review").removeClass('min');
            $(".app_review").show();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", true);
          }
          else {
            $(this).addClass('collaspe');
            $(".feat_review").addClass('min');
            $(".app_review").hide();
            TJG.utils.setLocalStorage("tjg.feat_review.expand", false);
          }
        });
      },
      
      checkFlashMessages: function () {
        if($('#flash_error').length > 0) {
          TJG.utils.centerDialog("#flash_error");
          $("#flash_error").fadeIn();
          TJG.repositionDialog = ["#flash_error"];
        }
      }
    };

    TJG.init = function() {  
      if (TJG.vars.isIos) {
        TJG.utils.hideURLBar();
      }
      for (var key in TJG.onload) {
        TJG.onload[key]();
      }
    };
    window.addEventListener("load", TJG.init, false);
   

})(this, document);
