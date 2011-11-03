/*

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

})(jQuery);
