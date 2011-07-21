/*!*
 * 
 * Add support for scrolling vertically and horizontally using jQTouch in Webkit Mobile
 * Plus support for slides
 *
 * Copyright (c) 2010 Sam Shull <http://samshull.blogspot.com/>
 * Released under MIT license
 * 
 * Based on the work of Matteo Spinelli, http://cubiq.org/
 * Released under MIT license
 * http://cubiq.org/dropbox/mit-license.txt
 *
 * Find more about the scrolling function at
 * http://cubiq.org/scrolling-div-for-mobile-webkit-turns-3/16
 *
 * 
 */
    
(function($, window, document, Number, Math, undefined) {
    if (!"WebKitCSSMatrix" in this) {
        return null;
    }
    try {
      if (!this.WebKitCSSMatrix) {
        return null;
      }
    }
    catch(e) {
      return null;
    }
    window.scrollTo(0,0);
    var supports3d = ('m11' in new WebKitCSSMatrix()),
        base = {
            attributesToOptions: attributesToOptions,
            attributes: {
                defaultDuration: "slidespeed",
                preventDefault: function(e,d){return $(e).attr("preventdefault") === "false" ? false : !!defaults[d].preventDefault;},
                bounce: function(e,d){return e.attr("bounce") === "false" ? false : defaults[d].bounce},
                scrollBar: function(e,d){return e.hasClass("with-scrollbar")},
                useSlides: function(e,d){return $(e).find(defaults[d].slides.selector).length > 0;}
            },
            ignore: "SELECT,TEXTAREA,BUTTON,INPUT",
            useSlides: false,
            slides: {
                selector: ".slide-container",
                currentClass: "jqt-slide-current",
                portion: 3,
                easing: 2,
                callback: slideTo
            },
            numberOfTouches: 1,
            divider: 6,
            touchEventList: ["touchend","touchmove","touchcancel"],
            bounceSpeed: 300,
            defaultDuration: 500,
            defaultOffset: 0,
            preventDefault: true,
            maxScrollTime: 1000,
            friction: 3,
            scrollTopOnTouchstart: true,
            bounce: true,
            scrollBar: true,
            scrollBarObject: null,
            events: {
                scrollTo: scrollTo,
                reset: reset,
                touchstart: touchStart,
                touchmove: touchMove,
                touchend: touchEnd,
                touchcancel: touchEnd,
                webkitTransitionEnd: transitionEnd
            },
            setPosition: setPosition,
            momentum: momentum
        },

        defaults = {
            vertical: $.extend({}, base, {
                direction: "vertical",
                dimension: "height",
                outerDimension: "outerHeight",
                matrixProperty: "m42",
                selector: ".vertical-scroll > div",
                eventProperty: "pageY",
                tranform: supports3d ? "translate3d(0,{0}px,0)" : "translate(0,{0}px)",
                slideProperty: "offsetTop"
            }),
            horizontal: $.extend({}, base, {
                direction: "horizontal",
                dimension: "width",
                outerDimension: "outerWidth",
                matrixProperty: "m41",
                selector: ".horizontal-scroll > table",
                eventProperty: "pageX",
                tranform: supports3d ? "translate3d({0}px,0,0)" : "translate({0}px,0)",
                slideProperty: "offsetLeft"
            })
        },
        bottomToolbar = function(vars){return (window.innerHeight - (vars.toolbarHeight * 2)) + "px !important"},
        height = function(vars){return (window.innerHeight) + "px"},
        width = function (){return window.innerWidth + "px";},
        cssRules = {
            /**
             *
             *
             *    @var Object
             */
            variables : {
                toolbarHeight: 44
            },
            defaults: {
                ".vertical-scroll": {
                    position: "relative",
                    "z-index": 1,
                    overflow: "hidden",
                    "margin-bottom": "0px",
                    height: height
                },
                ".vertical-scroll.use-bottom-toolbar": {
                    height: bottomToolbar
                },
                ".vertical-scroll > div": {
                    margin: "0 auto",
                    "padding-bottom":"30px",
                    "-webkit-transition-property": "-webkit-transform",
                    "-webkit-transition-timing-function": "cubic-bezier(0,0,.25,1)",
                    "-webkit-transform": "translate3d(0,0,0)",
                    "-webkit-transition-duration": "0s",
                },
                ".vertical-scroll.use-bottom-toolbar": {
                    "margin-bottom": "0px"
                },
                ".vertical-scroll.use-bottom-toolbar > div": {
                    "padding-bottom":"0px"
                },
                ".scrollbar": {
                    "-webkit-transition-timing-function": "cubic-bezier(0,0,.25,1)",
                    "-webkit-transform": "translate3d(0,0,0)",
                    "-webkit-transition-property": "-webkit-transform,opacity",
                    "-webkit-transition-duration": "0,0,0,1s",
                    "-webkit-border-radius": "2px",
                    "pointer-events": "none",
                    opacity: 0,
                    background:"rgba(0,0,0,.5)",
                    "-webkit-box-shadow": "0 0 2px rgba(255,255,255,.5)",
                    position: "absolute",
                    "z-index": 10,
                    width: "5px",
                    height: "5px"
                },
                ".scrollbar.vertical": {
                    top: "1px",
                    right: "1px"
                },
                ".scrollbar.horizontal": {
                    bottom: "1px",
                    left: "1px"
                },
                ".horizontal-scroll": {
                    width: width,
                    height: "100%",
                    overflow: "hidden",
                    padding: "0px",
                    position: "relative",
                    height: height,
                    "line-height":height
                },
                ".horizontal-scroll > table": {
                    height: "100%",
                    "-webkit-transition-property": "-webkit-transform",
                    "-webkit-transition-timing-function": "cubic-bezier(0,0,.25,1)",
                    "-webkit-transform": "translate3d(0,0,0)",
                    "-webkit-transition-duration": "0s",
                }
            },
            portrait: {
                ".portrait .vertical-scroll": {
                    position: "relative",
                    "z-index": 1,
                    overflow: "hidden",
                    height: height,        
                },
                ".portrait .vertical-scroll.use-bottom-toolbar,.portrait .horizontal-scroll.use-bottom-toolbar": {
                    height: bottomToolbar
                },
                ".portrait .horizontal-scroll": {
                    width: width
                },
                ".portrait .slide-container": {
                    height: height,
                    width: width
                }
            },
            landscape: {
                ".landscape .vertical-scroll": {
                    position: "relative",
                    "z-index": 1,
                    overflow: "hidden",
                    height: height,
                },
                ".landscape .vertical-scroll.use-bottom-toolbar,.landscape .horizontal-scroll.use-bottom-toolbar": {
                    height: bottomToolbar
                },
                ".landscape .horizontal-scroll": {
                    width: width
                },
                ".landscape .slide-container": {
                    height: height,
                    width: width
                }
            }
        };
    if ($.jQTouch) {
        
        $.jQTouch.addExtension(function (jQT) {
            var d = defaults;
            
            function binder (e, info) {
                var v = d.vertical, h = d.horizontal,
                    vertical = info.page.find(v.selector),
                    horizontal = info.page.find(h.selector);
                
                vertical.verticallyScroll(v.attributesToOptions(vertical, "vertical", v.attributes));
                horizontal.horizontallyScroll(h.attributesToOptions(horizontal, "horizontal", h.attributes));
            }
            
            $(document.body).bind("pageInserted", binder);
            
            $(function() {
                var v = d.vertical, 
                    h = d.horizontal;
                    
                $(v.selector)
                    .each(function() {
                        $(this).verticallyScroll(v.attributesToOptions($(this), "vertical", v.attributes));
                    });
                    
                $(h.selector)
                    .each(function() {
                        $(this).horizontallyScroll(h.attributesToOptions($(this), "horizontal", h.attributes));
                    });
            });
            
            return {};
        });
    }
    function attributesToOptions (element, direction, attributes) {
        var options = {};
        
        $.each(attributes, function(name, value) {
            if ($.isFunction(value)) {
                options[name] = value(element, direction);
                
            } else if (element.attr(value) != undefined) {
                options[name] = element.attr(value);
            }
        });
        
        return options;
    }
    $.fn.verticallyScroll = function (options) {
        return this.inertiaScroll("vertical", options);
    };
    $.fn.horizontallyScroll = function (options) {
        return this.inertiaScroll("horizontal", options);
    };
    $.fn.inertiaScroll = function (direction, options) {
        options = $.extend(true, {}, defaults[direction], options || {});
        
        return this.each(function () {
            inertiaScroll(this, options);
        });
    };
    $.inertiaScroll = {
        defaults: function (options) {
            if (options !== undefined) {
                defaults = $.extend(true, defaults, options);
            }
            
            return $.extend({}, defaults);
        },
        defaultCSS: function (options) {
            if (options !== undefined) {
                cssRules = $.extend(true, cssRules, options);
            }
            
            return $.extend({}, cssRules);
        }
    };
    function inertiaScroll (element, options) {
        var $element = $(element).data("jqt-scroll-options", options).css("webkitTransform", format(options.tranform, options.defaultOffset)), transform = $element.css("webkitTransform");
        var tMatrix = {m41:0};
        var matrix = transform ? new WebKitCSSMatrix(transform) : tMatrix;
        
        $.each(options.events, function (name, func) {
          element.addEventListener(name, func, false);
        });
        
        $element.bind("reset", options.events.reset)
                .bind("scrollTo", options.events.scrollTo);
        
        options.currentPosition = matrix[options.matrixProperty];
        options.parentWidth = $element.parent()[options.dimension]();
        
        if (options.scrollBar && options.scrollBar === true && !options.scrollBarObject) {
            options.scrollBarObject = $.isFunction(options.scrollBar) ? 
                options.scrollBar($element.parent(), options.direction) :
                Scrollbar($element.parent(), options.direction);
        }
        
        return null;
    }
    function touchStart (event) {
        var $this = $(this),
            options = $this.data("jqt-scroll-options"),
            location = event.touches[0][options.eventProperty],
            matrix, mp,
            dimension = $this[options.outerDimension](),
            parent = $this.parent()[options.dimension](),
            //maxScroll
            endPoint = -(dimension - parent),
            //a distance to stop inertia from hitting
            quarter = parent / options.divider;
            
        //ignore some stuff
        if (!!options.ignore && $(event.target).is(options.ignore) || event.targetTouches.length !== options.numberOfTouches) { 
            return null;
        }
        
        options.parentDimension = parent;
        
        if (options.scrollTopOnTouchstart) {
            window.scrollTo(0,0);
        }
        
        matrix = new WebKitCSSMatrix($this.css("webkitTransform"));
        mp = matrix[options.matrixProperty];
        
        $this.data("jqt-scroll-current-event", {
            startLocation: location,
            currentLocation: location,
            startPosition: mp,
            lastPosition: mp,
            currentPosition: mp,
            startTime: event.timeStamp,
            moved: false,
            lastMoveTime: event.timeStamp,
            parentDimension: parent,
            endPoint: endPoint,
            minScroll: !options.bounce ? 0 : quarter,
            maxScroll: !options.bounce ? endPoint : endPoint - quarter,
            end: false
        });
        
        if (options.scrollBarObject) {
            options.scrollBarObject.init(parent, dimension);
        }
        
        options.setPosition($this, options, mp, 0);
        
        if (options.preventDefault) {
            event.preventDefault();
            return false;
            
        } else {
            return true;
        }
    }
    function touchMove (event) {
        var $this = $(this),
            options = $this.data("jqt-scroll-options"),
            data = $this.data("jqt-scroll-current-event"),
            lastMoveTime = data.lastMoveTime,
            position = event.touches[0][options.eventProperty],
            distance = data.startLocation - position,
            point = data.startPosition - distance,
            duration = 0;
        
        //apply friction if past scroll points
        if (point > 5) {
            point = (point - 5) / options.friction;
            
        } else if (point < data.endPoint) {
            point = data.endPoint - ((data.endPoint - point) / options.friction);
        }
        
        data.currentPosition = data.lastPosition = Math.floor(point);
        data.moved = true;
        data.lastMoveTime = event.timeStamp;
        data.currentLocation = position;
        
        if ((data.lastMoveTime - lastMoveTime) > options.maxScrollTime) {
            data.startTime = data.lastMoveTime;
        }
        
        if (options.scrollBarObject && !options.scrollBarObject.visible) {
            options.scrollBarObject.show();
        }
        
        options.setPosition($this, options, data.currentPosition, duration);
        
        if (options.preventDefault) {
            event.preventDefault();
            return false;
            
        } else {
            return true;
        }
    }
    function touchEnd (event) {
        var $this = $(this),
            options = $this.data("jqt-scroll-options"),
            data = $this.data("jqt-scroll-current-event"),
            theTarget, theEvent;
        
        if (!data.moved) {
            if (options.scrollBarObject) {
                options.scrollBarObject.hide();
            }
            
            theTarget  = event.target;
            
            if(theTarget.nodeType == 3) {
                theTarget = theTarget.parentNode;
            }
            
            theEvent = document.createEvent("MouseEvents");
            theEvent.initEvent("click", true, true);
            theTarget.dispatchEvent(theEvent);
            
            if (options.preventDefault) {
                event.preventDefault();
                return false;
            }
        }
        
        if (options.useSlides && $.isFunction(options.slides.callback)) {
            options.slides.callback($this, options, data, event);
            
        } else {
            options.momentum($this, options, data, event);
        }
        
        options.setPosition($this, options, data.currentPosition, data.duration);
        
        if (options.preventDefault) {
            event.preventDefault();
            return false;
            
        } else {
            return true;
        }
    }
    function transitionEnd (event) {
        
        var $this = $(this),
            options = $this.data("jqt-scroll-options"),
            data = $this.data("jqt-scroll-current-event");
        
        if (data && !data.end) {
            if (data.currentPosition > 0) {
                data.currentPosition = 0;
                options.setPosition($this, options, 0, options.bounceSpeed);
                
            } else if (data.currentPosition < data.endPoint) {
                data.currentPosition = data.endPoint;
                options.setPosition($this, options, data.endPoint, options.bounceSpeed);
                
            } else if (options.scrollBarObject) {
                options.scrollBarObject.hide();
            }
            data.end = true;
        } else if (options.scrollBarObject) {
            options.scrollBarObject.hide();
        }
        
        return null;
    }
    function momentum (object, options, data, event) {
        var m = Math,
            duration = m.min(options.maxScrollTime, data.lastMoveTime - data.startTime),
            distance = data.startPosition - data.currentPosition,
            velocity = m.abs(distance) / duration,
            acceleration = duration * velocity * options.friction,
            momentum = m.round(distance * velocity),
            position = m.round(data.currentPosition - momentum);
        
        if (data.currentPosition > 0) {
            position = 0;
        } else if (data.currentPosition < data.endPoint) {
            position = data.endPoint;
        } else if (position > data.minScroll) {
            acceleration = acceleration * m.abs(data.minScroll / position);
            position = data.minScroll;
        } else if (position < data.maxScroll) {
            acceleration = acceleration * m.abs(data.maxScroll / position);
            position = data.maxScroll;
        }
        
        data.momentum = m.abs(momentum);
        data.currentPosition = position;
        data.duration = acceleration;
        
        return null;
    }
    function slideTo (container, options, data, event) {
        var slides = container.find(options.slides.selector),
            current = slides.filter("."+options.slides.currentClass).eq(0),
            index,
            distance = data.startPosition - data.currentPosition,
            difference = current[options.dimension]() / options.slides.portion,
            duration;
        
        if (!current.length) {
            current = slides.eq(0);
        }
        
        index = slides.index(current[0]);
        slides.removeClass(options.slides.currentClass);
        
        if (data.currentPosition > 0) {
            position = 0;
            slides.eq(0).addClass(options.slides.currentClass);
        } else if (data.currentPosition < data.endPoint) {
            position = data.endPoint;
            slides.eq(slides.length-1).addClass(options.slides.currentClass);
        } else if (distance < -difference) {
            position = -slides.eq(index > 0 ? index - 1 : 0)
                            .addClass(options.slides.currentClass).parent().attr(options.slideProperty);
        } else if (distance > difference) {
            position = -slides.eq(index < slides.length-1 ? index + 1 : slides.length-1)
                            .addClass(options.slides.currentClass).parent().attr(options.slideProperty);
        } else {
            position = -current.addClass(options.slides.currentClass).parent().attr(options.slideProperty);
        }
        
        duration = Math.abs(data.currentPosition - position) * options.slides.easing;
        
        data.momentum = duration;
        data.currentPosition = position;
        data.duration = duration;
        
        return null;
    }
    function reset (event, offset, duration) {
        var $this = $(this), data,
            options = $this.data("jqt-scroll-options");
		
		offset = offset !== undefined ? offset : options.defaultOffset;
			
        if (options.useSlides && $.isFunction(options.slides.callback)) {
			var matrix, mp,
				dimension = $this[options.outerDimension](),
				parent = $this.parent()[options.dimension](),
				//maxScroll
				endPoint = -(dimension - parent),
				//a distance to stop inertia from hitting
				quarter = parent / options.divider;
			
			options.parentDimension = parent;
			
			matrix = new WebKitCSSMatrix($this.css("webkitTransform"));
			mp = matrix[options.matrixProperty];
			
			data = $this.data("jqt-scroll-current-event", {
				startLocation: 0,
				currentLocation: 0,
				startPosition: mp,
				lastPosition: mp,
				currentPosition: offset,
				startTime: event && event.timeStamp,
				moved: true,
				lastMoveTime: event && event.timeStamp,
				parentDimension: parent,
				endPoint: endPoint,
				minScroll: !options.bounce ? 0 : quarter,
				maxScroll: !options.bounce ? endPoint : endPoint - quarter,
				end: true
			}).data("jqt-scroll-current-event");
		
		
            options.slides.callback($this, options, data, event);
            
        } else {
			data = {
				currentPosition: offset 
			};
		}
		
        return options.setPosition($this, options, data.currentPosition, duration || options.defaultDuration);
    }
    function scrollTo (event, offset, duration) {
        var $this = $(this),
            options = $this.data("jqt-scroll-options");
            
        return options.setPosition($this, 
                                   options, 
                                   offset !== undefined ? offset : (event.detail || options.currentPosition), 
                                   duration !== undefined ? duration : options.defaultDuration);
    }
    function setPosition (object, options, position, duration, timing) {
        
        if (options.scrollBarObject) {
            var dimension = (object.parent()[options.dimension]() - object[options.dimension]());
            
            if (position > 0) {
                dimension += Number(position);
            }
            
            options.scrollBarObject.scrollTo(options.scrollBarObject.maxScroll / dimension * position, 
                                              format("{0}ms", duration !== undefined ? duration : options.defaultDuration));
        }
        
        if (duration !== undefined) {
            object.css("webkitTransitionDuration", format("{0}ms", duration));
        }
        
        if (timing !== undefined) {
            object.css("webkitTransitionTimingFunction", timing);
        }
        
        options.currentPosition = position || 0;
        
        return object.css("webkitTransform", format(options.tranform, options.currentPosition));
    }
    function format (s) {
        var args = arguments;
        return s.replace(/\{(\d+)\}/g, function(a,b){return args[Number(b)+1] + ""});
    }
    function Scrollbar (object, direction) {
        if (!(this instanceof Scrollbar)) {
            return new Scrollbar(object, direction);
        }
        
        this.direction = direction;
        this.bar = $(document.createElement("div"))
            .addClass("scrollbar " + direction)
            .appendTo(object)[0];
    }
    
    Scrollbar.prototype = {
            direction: "vertical",
            transform: supports3d ? "translate3d({0}px,{1}px,0)" : "translate({0}px,{1}px)",
            size: 0,
            maxSize: 0,
            maxScroll: 0,
            visible: false,
            offset: 0,
            
            init: function (scroll, size) {
                this.offset = this.direction == "horizontal" ? 
                                this.bar.offsetWidth - this.bar.clientWidth : 
                                this.bar.offsetHeight - this.bar.clientHeight;
                                
                this.maxSize = scroll - 8;        // 8 = distance from top + distance from bottom
                this.size = Math.round(this.maxSize * this.maxSize / size) + this.offset;
                this.maxScroll = this.maxSize - this.size;
                this.bar.style[this.direction == "horizontal" ? "width" : "height"] = (this.size - this.offset) + "px";
            },
            
            setPosition: function (pos) {
                this.bar.style.webkitTransform = format(this.transform, 
                                                        this.direction == "horizontal" ? 
                                                        Math.round(pos) : 
                                                        0, 
                                                        this.direction == "horizontal" ? 
                                                        0 : 
                                                        Math.round(pos)
                                                        );
            },
            
            scrollTo: function (pos, runtime) {
                this.bar.style.webkitTransitionDuration = (runtime || "400ms") + ",300ms";
                this.setPosition(pos);
            },
            
            show: function () {
                this.visible = true;
                this.bar.style.opacity = "1";
            },
        
            hide: function () {
                this.visible = false;
                this.bar.style.opacity = "0";
            },
            
            remove: function () {
                this.bar.parentNode.removeChild(this.bar);
                return null;
            }
    };
        
    $(function() {
        var stringRules = "", 
            rules = cssRules, 
            o = window.innerHeight > window.innerWidth ? "portrait" : "landscape",
            buildProperties = function (name, value) {
                stringRules += name + ":" + ($.isFunction(value) ? value(rules.variables) : value) + ";";
            },
            buildRules = function (name, properties) {
                stringRules += name + "{";
                
                $.each(properties, buildProperties);
                
                stringRules += "}";
            };
        
        $.each(rules.defaults, buildRules);
        $.each(rules[o], buildRules);
        
        
        $(document.createElement("style"))
            .attr({type:"text/css",media:"screen"})
            .html(stringRules)
            .appendTo("head");
        
        $(window).one("orientationchange", function () {
            setTimeout(function () {
                window.scrollTo(0,0);
                stringRules = "";
                o = window.innerHeight > window.innerWidth ? "portrait" : "landscape";
                
                $.each(rules[o], buildRules);
                
                $(document.createElement("style"))
                    .attr({type:"text/css",media:"screen"})
                    .html(stringRules)
                    .appendTo("head");
            },30)
        });
    });
    
})(this.jQuery, this, this.document, this.Number, this.Math);
