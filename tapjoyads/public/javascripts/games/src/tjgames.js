/*!
 * jQuery JavaScript Library v1.4.2
 * http://jquery.com/
 *
 * Copyright 2010, John Resig
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * Includes Sizzle.js
 * http://sizzlejs.com/
 * Copyright 2010, The Dojo Foundation
 * Released under the MIT, BSD, and GPL Licenses.
 *
 * Date: Sat Feb 13 22:33:48 2010 -0500
 */
(function( window, undefined ) {

// Define a local copy of jQuery
var jQuery = function( selector, context ) {
		// The jQuery object is actually just the init constructor 'enhanced'
		return new jQuery.fn.init( selector, context );
	},

	// Map over jQuery in case of overwrite
	_jQuery = window.jQuery,

	// Map over the $ in case of overwrite
	_$ = window.$,

	// Use the correct document accordingly with window argument (sandbox)
	document = window.document,

	// A central reference to the root jQuery(document)
	rootjQuery,

	// A simple way to check for HTML strings or ID strings
	// (both of which we optimize for)
	quickExpr = /^[^<]*(<[\w\W]+>)[^>]*$|^#([\w-]+)$/,

	// Is it a simple selector
	isSimple = /^.[^:#\[\.,]*$/,

	// Check if a string has a non-whitespace character in it
	rnotwhite = /\S/,

	// Used for trimming whitespace
	rtrim = /^(\s|\u00A0)+|(\s|\u00A0)+$/g,

	// Match a standalone tag
	rsingleTag = /^<(\w+)\s*\/?>(?:<\/\1>)?$/,

	// Keep a UserAgent string for use with jQuery.browser
	userAgent = navigator.userAgent,

	// For matching the engine and version of the browser
	browserMatch,
	
	// Has the ready events already been bound?
	readyBound = false,
	
	// The functions to execute on DOM ready
	readyList = [],

	// The ready event handler
	DOMContentLoaded,

	// Save a reference to some core methods
	toString = Object.prototype.toString,
	hasOwnProperty = Object.prototype.hasOwnProperty,
	push = Array.prototype.push,
	slice = Array.prototype.slice,
	indexOf = Array.prototype.indexOf;

jQuery.fn = jQuery.prototype = {
	init: function( selector, context ) {
		var match, elem, ret, doc;

		// Handle $(""), $(null), or $(undefined)
		if ( !selector ) {
			return this;
		}

		// Handle $(DOMElement)
		if ( selector.nodeType ) {
			this.context = this[0] = selector;
			this.length = 1;
			return this;
		}
		
		// The body element only exists once, optimize finding it
		if ( selector === "body" && !context ) {
			this.context = document;
			this[0] = document.body;
			this.selector = "body";
			this.length = 1;
			return this;
		}

		// Handle HTML strings
		if ( typeof selector === "string" ) {
			// Are we dealing with HTML string or an ID?
			match = quickExpr.exec( selector );

			// Verify a match, and that no context was specified for #id
			if ( match && (match[1] || !context) ) {

				// HANDLE: $(html) -> $(array)
				if ( match[1] ) {
					doc = (context ? context.ownerDocument || context : document);

					// If a single string is passed in and it's a single tag
					// just do a createElement and skip the rest
					ret = rsingleTag.exec( selector );

					if ( ret ) {
						if ( jQuery.isPlainObject( context ) ) {
							selector = [ document.createElement( ret[1] ) ];
							jQuery.fn.attr.call( selector, context, true );

						} else {
							selector = [ doc.createElement( ret[1] ) ];
						}

					} else {
						ret = buildFragment( [ match[1] ], [ doc ] );
						selector = (ret.cacheable ? ret.fragment.cloneNode(true) : ret.fragment).childNodes;
					}
					
					return jQuery.merge( this, selector );
					
				// HANDLE: $("#id")
				} else {
					elem = document.getElementById( match[2] );

					if ( elem ) {
						// Handle the case where IE and Opera return items
						// by name instead of ID
						if ( elem.id !== match[2] ) {
							return rootjQuery.find( selector );
						}

						// Otherwise, we inject the element directly into the jQuery object
						this.length = 1;
						this[0] = elem;
					}

					this.context = document;
					this.selector = selector;
					return this;
				}

			// HANDLE: $("TAG")
			} else if ( !context && /^\w+$/.test( selector ) ) {
				this.selector = selector;
				this.context = document;
				selector = document.getElementsByTagName( selector );
				return jQuery.merge( this, selector );

			// HANDLE: $(expr, $(...))
			} else if ( !context || context.jquery ) {
				return (context || rootjQuery).find( selector );

			// HANDLE: $(expr, context)
			// (which is just equivalent to: $(context).find(expr)
			} else {
				return jQuery( context ).find( selector );
			}

		// HANDLE: $(function)
		// Shortcut for document ready
		} else if ( jQuery.isFunction( selector ) ) {
			return rootjQuery.ready( selector );
		}

		if (selector.selector !== undefined) {
			this.selector = selector.selector;
			this.context = selector.context;
		}

		return jQuery.makeArray( selector, this );
	},

	// Start with an empty selector
	selector: "",

	// The current version of jQuery being used
	jquery: "1.4.2",

	// The default length of a jQuery object is 0
	length: 0,

	// The number of elements contained in the matched element set
	size: function() {
		return this.length;
	},

	toArray: function() {
		return slice.call( this, 0 );
	},

	// Get the Nth element in the matched element set OR
	// Get the whole matched element set as a clean array
	get: function( num ) {
		return num == null ?

			// Return a 'clean' array
			this.toArray() :

			// Return just the object
			( num < 0 ? this.slice(num)[ 0 ] : this[ num ] );
	},

	// Take an array of elements and push it onto the stack
	// (returning the new matched element set)
	pushStack: function( elems, name, selector ) {
		// Build a new jQuery matched element set
		var ret = jQuery();

		if ( jQuery.isArray( elems ) ) {
			push.apply( ret, elems );
		
		} else {
			jQuery.merge( ret, elems );
		}

		// Add the old object onto the stack (as a reference)
		ret.prevObject = this;

		ret.context = this.context;

		if ( name === "find" ) {
			ret.selector = this.selector + (this.selector ? " " : "") + selector;
		} else if ( name ) {
			ret.selector = this.selector + "." + name + "(" + selector + ")";
		}

		// Return the newly-formed element set
		return ret;
	},

	// Execute a callback for every element in the matched set.
	// (You can seed the arguments with an array of args, but this is
	// only used internally.)
	each: function( callback, args ) {
		return jQuery.each( this, callback, args );
	},
	
	ready: function( fn ) {
		// Attach the listeners
		jQuery.bindReady();

		// If the DOM is already ready
		if ( jQuery.isReady ) {
			// Execute the function immediately
			fn.call( document, jQuery );

		// Otherwise, remember the function for later
		} else if ( readyList ) {
			// Add the function to the wait list
			readyList.push( fn );
		}

		return this;
	},
	
	eq: function( i ) {
		return i === -1 ?
			this.slice( i ) :
			this.slice( i, +i + 1 );
	},

	first: function() {
		return this.eq( 0 );
	},

	last: function() {
		return this.eq( -1 );
	},

	slice: function() {
		return this.pushStack( slice.apply( this, arguments ),
			"slice", slice.call(arguments).join(",") );
	},

	map: function( callback ) {
		return this.pushStack( jQuery.map(this, function( elem, i ) {
			return callback.call( elem, i, elem );
		}));
	},
	
	end: function() {
		return this.prevObject || jQuery(null);
	},

	// For internal use only.
	// Behaves like an Array's method, not like a jQuery method.
	push: push,
	sort: [].sort,
	splice: [].splice
};

// Give the init function the jQuery prototype for later instantiation
jQuery.fn.init.prototype = jQuery.fn;

jQuery.extend = jQuery.fn.extend = function() {
	// copy reference to target object
	var target = arguments[0] || {}, i = 1, length = arguments.length, deep = false, options, name, src, copy;

	// Handle a deep copy situation
	if ( typeof target === "boolean" ) {
		deep = target;
		target = arguments[1] || {};
		// skip the boolean and the target
		i = 2;
	}

	// Handle case when target is a string or something (possible in deep copy)
	if ( typeof target !== "object" && !jQuery.isFunction(target) ) {
		target = {};
	}

	// extend jQuery itself if only one argument is passed
	if ( length === i ) {
		target = this;
		--i;
	}

	for ( ; i < length; i++ ) {
		// Only deal with non-null/undefined values
		if ( (options = arguments[ i ]) != null ) {
			// Extend the base object
			for ( name in options ) {
				src = target[ name ];
				copy = options[ name ];

				// Prevent never-ending loop
				if ( target === copy ) {
					continue;
				}

				// Recurse if we're merging object literal values or arrays
				if ( deep && copy && ( jQuery.isPlainObject(copy) || jQuery.isArray(copy) ) ) {
					var clone = src && ( jQuery.isPlainObject(src) || jQuery.isArray(src) ) ? src
						: jQuery.isArray(copy) ? [] : {};

					// Never move original objects, clone them
					target[ name ] = jQuery.extend( deep, clone, copy );

				// Don't bring in undefined values
				} else if ( copy !== undefined ) {
					target[ name ] = copy;
				}
			}
		}
	}

	// Return the modified object
	return target;
};

jQuery.extend({
	noConflict: function( deep ) {
		window.$ = _$;

		if ( deep ) {
			window.jQuery = _jQuery;
		}

		return jQuery;
	},
	
	// Is the DOM ready to be used? Set to true once it occurs.
	isReady: false,
	
	// Handle when the DOM is ready
	ready: function() {
		// Make sure that the DOM is not already loaded
		if ( !jQuery.isReady ) {
			// Make sure body exists, at least, in case IE gets a little overzealous (ticket #5443).
			if ( !document.body ) {
				return setTimeout( jQuery.ready, 13 );
			}

			// Remember that the DOM is ready
			jQuery.isReady = true;

			// If there are functions bound, to execute
			if ( readyList ) {
				// Execute all of them
				var fn, i = 0;
				while ( (fn = readyList[ i++ ]) ) {
					fn.call( document, jQuery );
				}

				// Reset the list of functions
				readyList = null;
			}

			// Trigger any bound ready events
			if ( jQuery.fn.triggerHandler ) {
				jQuery( document ).triggerHandler( "ready" );
			}
		}
	},
	
	bindReady: function() {
		if ( readyBound ) {
			return;
		}

		readyBound = true;

		// Catch cases where $(document).ready() is called after the
		// browser event has already occurred.
		if ( document.readyState === "complete" ) {
			return jQuery.ready();
		}

		// Mozilla, Opera and webkit nightlies currently support this event
		if ( document.addEventListener ) {
			// Use the handy event callback
			document.addEventListener( "DOMContentLoaded", DOMContentLoaded, false );
			
			// A fallback to window.onload, that will always work
			window.addEventListener( "load", jQuery.ready, false );

		// If IE event model is used
		} else if ( document.attachEvent ) {
			// ensure firing before onload,
			// maybe late but safe also for iframes
			document.attachEvent("onreadystatechange", DOMContentLoaded);
			
			// A fallback to window.onload, that will always work
			window.attachEvent( "onload", jQuery.ready );

			// If IE and not a frame
			// continually check to see if the document is ready
			var toplevel = false;

			try {
				toplevel = window.frameElement == null;
			} catch(e) {}

			if ( document.documentElement.doScroll && toplevel ) {
				doScrollCheck();
			}
		}
	},

	// See test/unit/core.js for details concerning isFunction.
	// Since version 1.3, DOM methods and functions like alert
	// aren't supported. They return false on IE (#2968).
	isFunction: function( obj ) {
		return toString.call(obj) === "[object Function]";
	},

	isArray: function( obj ) {
		return toString.call(obj) === "[object Array]";
	},

	isPlainObject: function( obj ) {
		// Must be an Object.
		// Because of IE, we also have to check the presence of the constructor property.
		// Make sure that DOM nodes and window objects don't pass through, as well
		if ( !obj || toString.call(obj) !== "[object Object]" || obj.nodeType || obj.setInterval ) {
			return false;
		}
		
		// Not own constructor property must be Object
		if ( obj.constructor
			&& !hasOwnProperty.call(obj, "constructor")
			&& !hasOwnProperty.call(obj.constructor.prototype, "isPrototypeOf") ) {
			return false;
		}
		
		// Own properties are enumerated firstly, so to speed up,
		// if last one is own, then all properties are own.
	
		var key;
		for ( key in obj ) {}
		
		return key === undefined || hasOwnProperty.call( obj, key );
	},

	isEmptyObject: function( obj ) {
		for ( var name in obj ) {
			return false;
		}
		return true;
	},
	
	error: function( msg ) {
		throw msg;
	},
	
	parseJSON: function( data ) {
		if ( typeof data !== "string" || !data ) {
			return null;
		}

		// Make sure leading/trailing whitespace is removed (IE can't handle it)
		data = jQuery.trim( data );
		
		// Make sure the incoming data is actual JSON
		// Logic borrowed from http://json.org/json2.js
		if ( /^[\],:{}\s]*$/.test(data.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, "@")
			.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, "]")
			.replace(/(?:^|:|,)(?:\s*\[)+/g, "")) ) {

			// Try to use the native JSON parser first
			return window.JSON && window.JSON.parse ?
				window.JSON.parse( data ) :
				(new Function("return " + data))();

		} else {
			jQuery.error( "Invalid JSON: " + data );
		}
	},

	noop: function() {},

	// Evalulates a script in a global context
	globalEval: function( data ) {
		if ( data && rnotwhite.test(data) ) {
			// Inspired by code by Andrea Giammarchi
			// http://webreflection.blogspot.com/2007/08/global-scope-evaluation-and-dom.html
			var head = document.getElementsByTagName("head")[0] || document.documentElement,
				script = document.createElement("script");

			script.type = "text/javascript";

			if ( jQuery.support.scriptEval ) {
				script.appendChild( document.createTextNode( data ) );
			} else {
				script.text = data;
			}

			// Use insertBefore instead of appendChild to circumvent an IE6 bug.
			// This arises when a base node is used (#2709).
			head.insertBefore( script, head.firstChild );
			head.removeChild( script );
		}
	},

	nodeName: function( elem, name ) {
		return elem.nodeName && elem.nodeName.toUpperCase() === name.toUpperCase();
	},

	// args is for internal usage only
	each: function( object, callback, args ) {
		var name, i = 0,
			length = object.length,
			isObj = length === undefined || jQuery.isFunction(object);

		if ( args ) {
			if ( isObj ) {
				for ( name in object ) {
					if ( callback.apply( object[ name ], args ) === false ) {
						break;
					}
				}
			} else {
				for ( ; i < length; ) {
					if ( callback.apply( object[ i++ ], args ) === false ) {
						break;
					}
				}
			}

		// A special, fast, case for the most common use of each
		} else {
			if ( isObj ) {
				for ( name in object ) {
					if ( callback.call( object[ name ], name, object[ name ] ) === false ) {
						break;
					}
				}
			} else {
				for ( var value = object[0];
					i < length && callback.call( value, i, value ) !== false; value = object[++i] ) {}
			}
		}

		return object;
	},

	trim: function( text ) {
		return (text || "").replace( rtrim, "" );
	},

	// results is for internal usage only
	makeArray: function( array, results ) {
		var ret = results || [];

		if ( array != null ) {
			// The window, strings (and functions) also have 'length'
			// The extra typeof function check is to prevent crashes
			// in Safari 2 (See: #3039)
			if ( array.length == null || typeof array === "string" || jQuery.isFunction(array) || (typeof array !== "function" && array.setInterval) ) {
				push.call( ret, array );
			} else {
				jQuery.merge( ret, array );
			}
		}

		return ret;
	},

	inArray: function( elem, array ) {
		if ( array.indexOf ) {
			return array.indexOf( elem );
		}

		for ( var i = 0, length = array.length; i < length; i++ ) {
			if ( array[ i ] === elem ) {
				return i;
			}
		}

		return -1;
	},

	merge: function( first, second ) {
		var i = first.length, j = 0;

		if ( typeof second.length === "number" ) {
			for ( var l = second.length; j < l; j++ ) {
				first[ i++ ] = second[ j ];
			}
		
		} else {
			while ( second[j] !== undefined ) {
				first[ i++ ] = second[ j++ ];
			}
		}

		first.length = i;

		return first;
	},

	grep: function( elems, callback, inv ) {
		var ret = [];

		// Go through the array, only saving the items
		// that pass the validator function
		for ( var i = 0, length = elems.length; i < length; i++ ) {
			if ( !inv !== !callback( elems[ i ], i ) ) {
				ret.push( elems[ i ] );
			}
		}

		return ret;
	},

	// arg is for internal usage only
	map: function( elems, callback, arg ) {
		var ret = [], value;

		// Go through the array, translating each of the items to their
		// new value (or values).
		for ( var i = 0, length = elems.length; i < length; i++ ) {
			value = callback( elems[ i ], i, arg );

			if ( value != null ) {
				ret[ ret.length ] = value;
			}
		}

		return ret.concat.apply( [], ret );
	},

	// A global GUID counter for objects
	guid: 1,

	proxy: function( fn, proxy, thisObject ) {
		if ( arguments.length === 2 ) {
			if ( typeof proxy === "string" ) {
				thisObject = fn;
				fn = thisObject[ proxy ];
				proxy = undefined;

			} else if ( proxy && !jQuery.isFunction( proxy ) ) {
				thisObject = proxy;
				proxy = undefined;
			}
		}

		if ( !proxy && fn ) {
			proxy = function() {
				return fn.apply( thisObject || this, arguments );
			};
		}

		// Set the guid of unique handler to the same of original handler, so it can be removed
		if ( fn ) {
			proxy.guid = fn.guid = fn.guid || proxy.guid || jQuery.guid++;
		}

		// So proxy can be declared as an argument
		return proxy;
	},

	// Use of jQuery.browser is frowned upon.
	// More details: http://docs.jquery.com/Utilities/jQuery.browser
	uaMatch: function( ua ) {
		ua = ua.toLowerCase();

		var match = /(webkit)[ \/]([\w.]+)/.exec( ua ) ||
			/(opera)(?:.*version)?[ \/]([\w.]+)/.exec( ua ) ||
			/(msie) ([\w.]+)/.exec( ua ) ||
			!/compatible/.test( ua ) && /(mozilla)(?:.*? rv:([\w.]+))?/.exec( ua ) ||
		  	[];

		return { browser: match[1] || "", version: match[2] || "0" };
	},

	browser: {}
});

browserMatch = jQuery.uaMatch( userAgent );
if ( browserMatch.browser ) {
	jQuery.browser[ browserMatch.browser ] = true;
	jQuery.browser.version = browserMatch.version;
}

// Deprecated, use jQuery.browser.webkit instead
if ( jQuery.browser.webkit ) {
	jQuery.browser.safari = true;
}

if ( indexOf ) {
	jQuery.inArray = function( elem, array ) {
		return indexOf.call( array, elem );
	};
}

// All jQuery objects should point back to these
rootjQuery = jQuery(document);

// Cleanup functions for the document ready method
if ( document.addEventListener ) {
	DOMContentLoaded = function() {
		document.removeEventListener( "DOMContentLoaded", DOMContentLoaded, false );
		jQuery.ready();
	};

} else if ( document.attachEvent ) {
	DOMContentLoaded = function() {
		// Make sure body exists, at least, in case IE gets a little overzealous (ticket #5443).
		if ( document.readyState === "complete" ) {
			document.detachEvent( "onreadystatechange", DOMContentLoaded );
			jQuery.ready();
		}
	};
}

// The DOM ready check for Internet Explorer
function doScrollCheck() {
	if ( jQuery.isReady ) {
		return;
	}

	try {
		// If IE is used, use the trick by Diego Perini
		// http://javascript.nwbox.com/IEContentLoaded/
		document.documentElement.doScroll("left");
	} catch( error ) {
		setTimeout( doScrollCheck, 1 );
		return;
	}

	// and execute any waiting functions
	jQuery.ready();
}

function evalScript( i, elem ) {
	if ( elem.src ) {
		jQuery.ajax({
			url: elem.src,
			async: false,
			dataType: "script"
		});
	} else {
		jQuery.globalEval( elem.text || elem.textContent || elem.innerHTML || "" );
	}

	if ( elem.parentNode ) {
		elem.parentNode.removeChild( elem );
	}
}

// Mutifunctional method to get and set values to a collection
// The value/s can be optionally by executed if its a function
function access( elems, key, value, exec, fn, pass ) {
	var length = elems.length;
	
	// Setting many attributes
	if ( typeof key === "object" ) {
		for ( var k in key ) {
			access( elems, k, key[k], exec, fn, value );
		}
		return elems;
	}
	
	// Setting one attribute
	if ( value !== undefined ) {
		// Optionally, function values get executed if exec is true
		exec = !pass && exec && jQuery.isFunction(value);
		
		for ( var i = 0; i < length; i++ ) {
			fn( elems[i], key, exec ? value.call( elems[i], i, fn( elems[i], key ) ) : value, pass );
		}
		
		return elems;
	}
	
	// Getting an attribute
	return length ? fn( elems[0], key ) : undefined;
}

function now() {
	return (new Date).getTime();
}
(function() {

	jQuery.support = {};

	var root = document.documentElement,
		script = document.createElement("script"),
		div = document.createElement("div"),
		id = "script" + now();

	div.style.display = "none";
	div.innerHTML = "   <link/><table></table><a href='/a' style='color:red;float:left;opacity:.55;'>a</a><input type='checkbox'/>";

	var all = div.getElementsByTagName("*"),
		a = div.getElementsByTagName("a")[0];

	// Can't get basic test support
	if ( !all || !all.length || !a ) {
		return;
	}

	jQuery.support = {
		// IE strips leading whitespace when .innerHTML is used
		leadingWhitespace: div.firstChild.nodeType === 3,

		// Make sure that tbody elements aren't automatically inserted
		// IE will insert them into empty tables
		tbody: !div.getElementsByTagName("tbody").length,

		// Make sure that link elements get serialized correctly by innerHTML
		// This requires a wrapper element in IE
		htmlSerialize: !!div.getElementsByTagName("link").length,

		// Get the style information from getAttribute
		// (IE uses .cssText insted)
		style: /red/.test( a.getAttribute("style") ),

		// Make sure that URLs aren't manipulated
		// (IE normalizes it by default)
		hrefNormalized: a.getAttribute("href") === "/a",

		// Make sure that element opacity exists
		// (IE uses filter instead)
		// Use a regex to work around a WebKit issue. See #5145
		opacity: /^0.55$/.test( a.style.opacity ),

		// Verify style float existence
		// (IE uses styleFloat instead of cssFloat)
		cssFloat: !!a.style.cssFloat,

		// Make sure that if no value is specified for a checkbox
		// that it defaults to "on".
		// (WebKit defaults to "" instead)
		checkOn: div.getElementsByTagName("input")[0].value === "on",

		// Make sure that a selected-by-default option has a working selected property.
		// (WebKit defaults to false instead of true, IE too, if it's in an optgroup)
		optSelected: document.createElement("select").appendChild( document.createElement("option") ).selected,

		parentNode: div.removeChild( div.appendChild( document.createElement("div") ) ).parentNode === null,

		// Will be defined later
		deleteExpando: true,
		checkClone: false,
		scriptEval: false,
		noCloneEvent: true,
		boxModel: null
	};

	script.type = "text/javascript";
	try {
		script.appendChild( document.createTextNode( "window." + id + "=1;" ) );
	} catch(e) {}

	root.insertBefore( script, root.firstChild );

	// Make sure that the execution of code works by injecting a script
	// tag with appendChild/createTextNode
	// (IE doesn't support this, fails, and uses .text instead)
	if ( window[ id ] ) {
		jQuery.support.scriptEval = true;
		delete window[ id ];
	}

	// Test to see if it's possible to delete an expando from an element
	// Fails in Internet Explorer
	try {
		delete script.test;
	
	} catch(e) {
		jQuery.support.deleteExpando = false;
	}

	root.removeChild( script );

	if ( div.attachEvent && div.fireEvent ) {
		div.attachEvent("onclick", function click() {
			// Cloning a node shouldn't copy over any
			// bound event handlers (IE does this)
			jQuery.support.noCloneEvent = false;
			div.detachEvent("onclick", click);
		});
		div.cloneNode(true).fireEvent("onclick");
	}

	div = document.createElement("div");
	div.innerHTML = "<input type='radio' name='radiotest' checked='checked'/>";

	var fragment = document.createDocumentFragment();
	fragment.appendChild( div.firstChild );

	// WebKit doesn't clone checked state correctly in fragments
	jQuery.support.checkClone = fragment.cloneNode(true).cloneNode(true).lastChild.checked;

	// Figure out if the W3C box model works as expected
	// document.body must exist before we can do this
	jQuery(function() {
		var div = document.createElement("div");
		div.style.width = div.style.paddingLeft = "1px";

		document.body.appendChild( div );
		jQuery.boxModel = jQuery.support.boxModel = div.offsetWidth === 2;
		document.body.removeChild( div ).style.display = 'none';

		div = null;
	});

	// Technique from Juriy Zaytsev
	// http://thinkweb2.com/projects/prototype/detecting-event-support-without-browser-sniffing/
	var eventSupported = function( eventName ) { 
		var el = document.createElement("div"); 
		eventName = "on" + eventName; 

		var isSupported = (eventName in el); 
		if ( !isSupported ) { 
			el.setAttribute(eventName, "return;"); 
			isSupported = typeof el[eventName] === "function"; 
		} 
		el = null; 

		return isSupported; 
	};
	
	jQuery.support.submitBubbles = eventSupported("submit");
	jQuery.support.changeBubbles = eventSupported("change");

	// release memory in IE
	root = script = div = all = a = null;
})();

jQuery.props = {
	"for": "htmlFor",
	"class": "className",
	readonly: "readOnly",
	maxlength: "maxLength",
	cellspacing: "cellSpacing",
	rowspan: "rowSpan",
	colspan: "colSpan",
	tabindex: "tabIndex",
	usemap: "useMap",
	frameborder: "frameBorder"
};
var expando = "jQuery" + now(), uuid = 0, windowData = {};

jQuery.extend({
	cache: {},
	
	expando:expando,

	// The following elements throw uncatchable exceptions if you
	// attempt to add expando properties to them.
	noData: {
		"embed": true,
		"object": true,
		"applet": true
	},

	data: function( elem, name, data ) {
		if ( elem.nodeName && jQuery.noData[elem.nodeName.toLowerCase()] ) {
			return;
		}

		elem = elem == window ?
			windowData :
			elem;

		var id = elem[ expando ], cache = jQuery.cache, thisCache;

		if ( !id && typeof name === "string" && data === undefined ) {
			return null;
		}

		// Compute a unique ID for the element
		if ( !id ) { 
			id = ++uuid;
		}

		// Avoid generating a new cache unless none exists and we
		// want to manipulate it.
		if ( typeof name === "object" ) {
			elem[ expando ] = id;
			thisCache = cache[ id ] = jQuery.extend(true, {}, name);

		} else if ( !cache[ id ] ) {
			elem[ expando ] = id;
			cache[ id ] = {};
		}

		thisCache = cache[ id ];

		// Prevent overriding the named cache with undefined values
		if ( data !== undefined ) {
			thisCache[ name ] = data;
		}

		return typeof name === "string" ? thisCache[ name ] : thisCache;
	},

	removeData: function( elem, name ) {
		if ( elem.nodeName && jQuery.noData[elem.nodeName.toLowerCase()] ) {
			return;
		}

		elem = elem == window ?
			windowData :
			elem;

		var id = elem[ expando ], cache = jQuery.cache, thisCache = cache[ id ];

		// If we want to remove a specific section of the element's data
		if ( name ) {
			if ( thisCache ) {
				// Remove the section of cache data
				delete thisCache[ name ];

				// If we've removed all the data, remove the element's cache
				if ( jQuery.isEmptyObject(thisCache) ) {
					jQuery.removeData( elem );
				}
			}

		// Otherwise, we want to remove all of the element's data
		} else {
			if ( jQuery.support.deleteExpando ) {
				delete elem[ jQuery.expando ];

			} else if ( elem.removeAttribute ) {
				elem.removeAttribute( jQuery.expando );
			}

			// Completely remove the data cache
			delete cache[ id ];
		}
	}
});

jQuery.fn.extend({
	data: function( key, value ) {
		if ( typeof key === "undefined" && this.length ) {
			return jQuery.data( this[0] );

		} else if ( typeof key === "object" ) {
			return this.each(function() {
				jQuery.data( this, key );
			});
		}

		var parts = key.split(".");
		parts[1] = parts[1] ? "." + parts[1] : "";

		if ( value === undefined ) {
			var data = this.triggerHandler("getData" + parts[1] + "!", [parts[0]]);

			if ( data === undefined && this.length ) {
				data = jQuery.data( this[0], key );
			}
			return data === undefined && parts[1] ?
				this.data( parts[0] ) :
				data;
		} else {
			return this.trigger("setData" + parts[1] + "!", [parts[0], value]).each(function() {
				jQuery.data( this, key, value );
			});
		}
	},

	removeData: function( key ) {
		return this.each(function() {
			jQuery.removeData( this, key );
		});
	}
});
jQuery.extend({
	queue: function( elem, type, data ) {
		if ( !elem ) {
			return;
		}

		type = (type || "fx") + "queue";
		var q = jQuery.data( elem, type );

		// Speed up dequeue by getting out quickly if this is just a lookup
		if ( !data ) {
			return q || [];
		}

		if ( !q || jQuery.isArray(data) ) {
			q = jQuery.data( elem, type, jQuery.makeArray(data) );

		} else {
			q.push( data );
		}

		return q;
	},

	dequeue: function( elem, type ) {
		type = type || "fx";

		var queue = jQuery.queue( elem, type ), fn = queue.shift();

		// If the fx queue is dequeued, always remove the progress sentinel
		if ( fn === "inprogress" ) {
			fn = queue.shift();
		}

		if ( fn ) {
			// Add a progress sentinel to prevent the fx queue from being
			// automatically dequeued
			if ( type === "fx" ) {
				queue.unshift("inprogress");
			}

			fn.call(elem, function() {
				jQuery.dequeue(elem, type);
			});
		}
	}
});

jQuery.fn.extend({
	queue: function( type, data ) {
		if ( typeof type !== "string" ) {
			data = type;
			type = "fx";
		}

		if ( data === undefined ) {
			return jQuery.queue( this[0], type );
		}
		return this.each(function( i, elem ) {
			var queue = jQuery.queue( this, type, data );

			if ( type === "fx" && queue[0] !== "inprogress" ) {
				jQuery.dequeue( this, type );
			}
		});
	},
	dequeue: function( type ) {
		return this.each(function() {
			jQuery.dequeue( this, type );
		});
	},

	// Based off of the plugin by Clint Helfers, with permission.
	// http://blindsignals.com/index.php/2009/07/jquery-delay/
	delay: function( time, type ) {
		time = jQuery.fx ? jQuery.fx.speeds[time] || time : time;
		type = type || "fx";

		return this.queue( type, function() {
			var elem = this;
			setTimeout(function() {
				jQuery.dequeue( elem, type );
			}, time );
		});
	},

	clearQueue: function( type ) {
		return this.queue( type || "fx", [] );
	}
});
var rclass = /[\n\t]/g,
	rspace = /\s+/,
	rreturn = /\r/g,
	rspecialurl = /href|src|style/,
	rtype = /(button|input)/i,
	rfocusable = /(button|input|object|select|textarea)/i,
	rclickable = /^(a|area)$/i,
	rradiocheck = /radio|checkbox/;

jQuery.fn.extend({
	attr: function( name, value ) {
		return access( this, name, value, true, jQuery.attr );
	},

	removeAttr: function( name, fn ) {
		return this.each(function(){
			jQuery.attr( this, name, "" );
			if ( this.nodeType === 1 ) {
				this.removeAttribute( name );
			}
		});
	},

	addClass: function( value ) {
		if ( jQuery.isFunction(value) ) {
			return this.each(function(i) {
				var self = jQuery(this);
				self.addClass( value.call(this, i, self.attr("class")) );
			});
		}

		if ( value && typeof value === "string" ) {
			var classNames = (value || "").split( rspace );

			for ( var i = 0, l = this.length; i < l; i++ ) {
				var elem = this[i];

				if ( elem.nodeType === 1 ) {
					if ( !elem.className ) {
						elem.className = value;

					} else {
						var className = " " + elem.className + " ", setClass = elem.className;
						for ( var c = 0, cl = classNames.length; c < cl; c++ ) {
							if ( className.indexOf( " " + classNames[c] + " " ) < 0 ) {
								setClass += " " + classNames[c];
							}
						}
						elem.className = jQuery.trim( setClass );
					}
				}
			}
		}

		return this;
	},

	removeClass: function( value ) {
		if ( jQuery.isFunction(value) ) {
			return this.each(function(i) {
				var self = jQuery(this);
				self.removeClass( value.call(this, i, self.attr("class")) );
			});
		}

		if ( (value && typeof value === "string") || value === undefined ) {
			var classNames = (value || "").split(rspace);

			for ( var i = 0, l = this.length; i < l; i++ ) {
				var elem = this[i];

				if ( elem.nodeType === 1 && elem.className ) {
					if ( value ) {
						var className = (" " + elem.className + " ").replace(rclass, " ");
						for ( var c = 0, cl = classNames.length; c < cl; c++ ) {
							className = className.replace(" " + classNames[c] + " ", " ");
						}
						elem.className = jQuery.trim( className );

					} else {
						elem.className = "";
					}
				}
			}
		}

		return this;
	},

	toggleClass: function( value, stateVal ) {
		var type = typeof value, isBool = typeof stateVal === "boolean";

		if ( jQuery.isFunction( value ) ) {
			return this.each(function(i) {
				var self = jQuery(this);
				self.toggleClass( value.call(this, i, self.attr("class"), stateVal), stateVal );
			});
		}

		return this.each(function() {
			if ( type === "string" ) {
				// toggle individual class names
				var className, i = 0, self = jQuery(this),
					state = stateVal,
					classNames = value.split( rspace );

				while ( (className = classNames[ i++ ]) ) {
					// check each className given, space seperated list
					state = isBool ? state : !self.hasClass( className );
					self[ state ? "addClass" : "removeClass" ]( className );
				}

			} else if ( type === "undefined" || type === "boolean" ) {
				if ( this.className ) {
					// store className if set
					jQuery.data( this, "__className__", this.className );
				}

				// toggle whole className
				this.className = this.className || value === false ? "" : jQuery.data( this, "__className__" ) || "";
			}
		});
	},

	hasClass: function( selector ) {
		var className = " " + selector + " ";
		for ( var i = 0, l = this.length; i < l; i++ ) {
			if ( (" " + this[i].className + " ").replace(rclass, " ").indexOf( className ) > -1 ) {
				return true;
			}
		}

		return false;
	},

	val: function( value ) {
		if ( value === undefined ) {
			var elem = this[0];

			if ( elem ) {
				if ( jQuery.nodeName( elem, "option" ) ) {
					return (elem.attributes.value || {}).specified ? elem.value : elem.text;
				}

				// We need to handle select boxes special
				if ( jQuery.nodeName( elem, "select" ) ) {
					var index = elem.selectedIndex,
						values = [],
						options = elem.options,
						one = elem.type === "select-one";

					// Nothing was selected
					if ( index < 0 ) {
						return null;
					}

					// Loop through all the selected options
					for ( var i = one ? index : 0, max = one ? index + 1 : options.length; i < max; i++ ) {
						var option = options[ i ];

						if ( option.selected ) {
							// Get the specifc value for the option
							value = jQuery(option).val();

							// We don't need an array for one selects
							if ( one ) {
								return value;
							}

							// Multi-Selects return an array
							values.push( value );
						}
					}

					return values;
				}

				// Handle the case where in Webkit "" is returned instead of "on" if a value isn't specified
				if ( rradiocheck.test( elem.type ) && !jQuery.support.checkOn ) {
					return elem.getAttribute("value") === null ? "on" : elem.value;
				}
				

				// Everything else, we just grab the value
				return (elem.value || "").replace(rreturn, "");

			}

			return undefined;
		}

		var isFunction = jQuery.isFunction(value);

		return this.each(function(i) {
			var self = jQuery(this), val = value;

			if ( this.nodeType !== 1 ) {
				return;
			}

			if ( isFunction ) {
				val = value.call(this, i, self.val());
			}

			// Typecast each time if the value is a Function and the appended
			// value is therefore different each time.
			if ( typeof val === "number" ) {
				val += "";
			}

			if ( jQuery.isArray(val) && rradiocheck.test( this.type ) ) {
				this.checked = jQuery.inArray( self.val(), val ) >= 0;

			} else if ( jQuery.nodeName( this, "select" ) ) {
				var values = jQuery.makeArray(val);

				jQuery( "option", this ).each(function() {
					this.selected = jQuery.inArray( jQuery(this).val(), values ) >= 0;
				});

				if ( !values.length ) {
					this.selectedIndex = -1;
				}

			} else {
				this.value = val;
			}
		});
	}
});

jQuery.extend({
	attrFn: {
		val: true,
		css: true,
		html: true,
		text: true,
		data: true,
		width: true,
		height: true,
		offset: true
	},
		
	attr: function( elem, name, value, pass ) {
		// don't set attributes on text and comment nodes
		if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 ) {
			return undefined;
		}

		if ( pass && name in jQuery.attrFn ) {
			return jQuery(elem)[name](value);
		}

		var notxml = elem.nodeType !== 1 || !jQuery.isXMLDoc( elem ),
			// Whether we are setting (or getting)
			set = value !== undefined;

		// Try to normalize/fix the name
		name = notxml && jQuery.props[ name ] || name;

		// Only do all the following if this is a node (faster for style)
		if ( elem.nodeType === 1 ) {
			// These attributes require special treatment
			var special = rspecialurl.test( name );

			// Safari mis-reports the default selected property of an option
			// Accessing the parent's selectedIndex property fixes it
			if ( name === "selected" && !jQuery.support.optSelected ) {
				var parent = elem.parentNode;
				if ( parent ) {
					parent.selectedIndex;
	
					// Make sure that it also works with optgroups, see #5701
					if ( parent.parentNode ) {
						parent.parentNode.selectedIndex;
					}
				}
			}

			// If applicable, access the attribute via the DOM 0 way
			if ( name in elem && notxml && !special ) {
				if ( set ) {
					// We can't allow the type property to be changed (since it causes problems in IE)
					if ( name === "type" && rtype.test( elem.nodeName ) && elem.parentNode ) {
						jQuery.error( "type property can't be changed" );
					}

					elem[ name ] = value;
				}

				// browsers index elements by id/name on forms, give priority to attributes.
				if ( jQuery.nodeName( elem, "form" ) && elem.getAttributeNode(name) ) {
					return elem.getAttributeNode( name ).nodeValue;
				}

				// elem.tabIndex doesn't always return the correct value when it hasn't been explicitly set
				// http://fluidproject.org/blog/2008/01/09/getting-setting-and-removing-tabindex-values-with-javascript/
				if ( name === "tabIndex" ) {
					var attributeNode = elem.getAttributeNode( "tabIndex" );

					return attributeNode && attributeNode.specified ?
						attributeNode.value :
						rfocusable.test( elem.nodeName ) || rclickable.test( elem.nodeName ) && elem.href ?
							0 :
							undefined;
				}

				return elem[ name ];
			}

			if ( !jQuery.support.style && notxml && name === "style" ) {
				if ( set ) {
					elem.style.cssText = "" + value;
				}

				return elem.style.cssText;
			}

			if ( set ) {
				// convert the value to a string (all browsers do this but IE) see #1070
				elem.setAttribute( name, "" + value );
			}

			var attr = !jQuery.support.hrefNormalized && notxml && special ?
					// Some attributes require a special call on IE
					elem.getAttribute( name, 2 ) :
					elem.getAttribute( name );

			// Non-existent attributes return null, we normalize to undefined
			return attr === null ? undefined : attr;
		}

		// elem is actually elem.style ... set the style
		// Using attr for specific style information is now deprecated. Use style instead.
		return jQuery.style( elem, name, value );
	}
});
var rnamespaces = /\.(.*)$/,
	fcleanup = function( nm ) {
		return nm.replace(/[^\w\s\.\|`]/g, function( ch ) {
			return "\\" + ch;
		});
	};

/*
 * A number of helper functions used for managing events.
 * Many of the ideas behind this code originated from
 * Dean Edwards' addEvent library.
 */
jQuery.event = {

	// Bind an event to an element
	// Original by Dean Edwards
	add: function( elem, types, handler, data ) {
		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
			return;
		}

		// For whatever reason, IE has trouble passing the window object
		// around, causing it to be cloned in the process
		if ( elem.setInterval && ( elem !== window && !elem.frameElement ) ) {
			elem = window;
		}

		var handleObjIn, handleObj;

		if ( handler.handler ) {
			handleObjIn = handler;
			handler = handleObjIn.handler;
		}

		// Make sure that the function being executed has a unique ID
		if ( !handler.guid ) {
			handler.guid = jQuery.guid++;
		}

		// Init the element's event structure
		var elemData = jQuery.data( elem );

		// If no elemData is found then we must be trying to bind to one of the
		// banned noData elements
		if ( !elemData ) {
			return;
		}

		var events = elemData.events = elemData.events || {},
			eventHandle = elemData.handle, eventHandle;

		if ( !eventHandle ) {
			elemData.handle = eventHandle = function() {
				// Handle the second event of a trigger and when
				// an event is called after a page has unloaded
				return typeof jQuery !== "undefined" && !jQuery.event.triggered ?
					jQuery.event.handle.apply( eventHandle.elem, arguments ) :
					undefined;
			};
		}

		// Add elem as a property of the handle function
		// This is to prevent a memory leak with non-native events in IE.
		eventHandle.elem = elem;

		// Handle multiple events separated by a space
		// jQuery(...).bind("mouseover mouseout", fn);
		types = types.split(" ");

		var type, i = 0, namespaces;

		while ( (type = types[ i++ ]) ) {
			handleObj = handleObjIn ?
				jQuery.extend({}, handleObjIn) :
				{ handler: handler, data: data };

			// Namespaced event handlers
			if ( type.indexOf(".") > -1 ) {
				namespaces = type.split(".");
				type = namespaces.shift();
				handleObj.namespace = namespaces.slice(0).sort().join(".");

			} else {
				namespaces = [];
				handleObj.namespace = "";
			}

			handleObj.type = type;
			handleObj.guid = handler.guid;

			// Get the current list of functions bound to this event
			var handlers = events[ type ],
				special = jQuery.event.special[ type ] || {};

			// Init the event handler queue
			if ( !handlers ) {
				handlers = events[ type ] = [];

				// Check for a special event handler
				// Only use addEventListener/attachEvent if the special
				// events handler returns false
				if ( !special.setup || special.setup.call( elem, data, namespaces, eventHandle ) === false ) {
					// Bind the global event handler to the element
					if ( elem.addEventListener ) {
						elem.addEventListener( type, eventHandle, false );

					} else if ( elem.attachEvent ) {
						elem.attachEvent( "on" + type, eventHandle );
					}
				}
			}
			
			if ( special.add ) { 
				special.add.call( elem, handleObj ); 

				if ( !handleObj.handler.guid ) {
					handleObj.handler.guid = handler.guid;
				}
			}

			// Add the function to the element's handler list
			handlers.push( handleObj );

			// Keep track of which events have been used, for global triggering
			jQuery.event.global[ type ] = true;
		}

		// Nullify elem to prevent memory leaks in IE
		elem = null;
	},

	global: {},

	// Detach an event or set of events from an element
	remove: function( elem, types, handler, pos ) {
		// don't do events on text and comment nodes
		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
			return;
		}

		var ret, type, fn, i = 0, all, namespaces, namespace, special, eventType, handleObj, origType,
			elemData = jQuery.data( elem ),
			events = elemData && elemData.events;

		if ( !elemData || !events ) {
			return;
		}

		// types is actually an event object here
		if ( types && types.type ) {
			handler = types.handler;
			types = types.type;
		}

		// Unbind all events for the element
		if ( !types || typeof types === "string" && types.charAt(0) === "." ) {
			types = types || "";

			for ( type in events ) {
				jQuery.event.remove( elem, type + types );
			}

			return;
		}

		// Handle multiple events separated by a space
		// jQuery(...).unbind("mouseover mouseout", fn);
		types = types.split(" ");

		while ( (type = types[ i++ ]) ) {
			origType = type;
			handleObj = null;
			all = type.indexOf(".") < 0;
			namespaces = [];

			if ( !all ) {
				// Namespaced event handlers
				namespaces = type.split(".");
				type = namespaces.shift();

				namespace = new RegExp("(^|\\.)" + 
					jQuery.map( namespaces.slice(0).sort(), fcleanup ).join("\\.(?:.*\\.)?") + "(\\.|$)")
			}

			eventType = events[ type ];

			if ( !eventType ) {
				continue;
			}

			if ( !handler ) {
				for ( var j = 0; j < eventType.length; j++ ) {
					handleObj = eventType[ j ];

					if ( all || namespace.test( handleObj.namespace ) ) {
						jQuery.event.remove( elem, origType, handleObj.handler, j );
						eventType.splice( j--, 1 );
					}
				}

				continue;
			}

			special = jQuery.event.special[ type ] || {};

			for ( var j = pos || 0; j < eventType.length; j++ ) {
				handleObj = eventType[ j ];

				if ( handler.guid === handleObj.guid ) {
					// remove the given handler for the given type
					if ( all || namespace.test( handleObj.namespace ) ) {
						if ( pos == null ) {
							eventType.splice( j--, 1 );
						}

						if ( special.remove ) {
							special.remove.call( elem, handleObj );
						}
					}

					if ( pos != null ) {
						break;
					}
				}
			}

			// remove generic event handler if no more handlers exist
			if ( eventType.length === 0 || pos != null && eventType.length === 1 ) {
				if ( !special.teardown || special.teardown.call( elem, namespaces ) === false ) {
					removeEvent( elem, type, elemData.handle );
				}

				ret = null;
				delete events[ type ];
			}
		}

		// Remove the expando if it's no longer used
		if ( jQuery.isEmptyObject( events ) ) {
			var handle = elemData.handle;
			if ( handle ) {
				handle.elem = null;
			}

			delete elemData.events;
			delete elemData.handle;

			if ( jQuery.isEmptyObject( elemData ) ) {
				jQuery.removeData( elem );
			}
		}
	},

	// bubbling is internal
	trigger: function( event, data, elem /*, bubbling */ ) {
		// Event object or event type
		var type = event.type || event,
			bubbling = arguments[3];

		if ( !bubbling ) {
			event = typeof event === "object" ?
				// jQuery.Event object
				event[expando] ? event :
				// Object literal
				jQuery.extend( jQuery.Event(type), event ) :
				// Just the event type (string)
				jQuery.Event(type);

			if ( type.indexOf("!") >= 0 ) {
				event.type = type = type.slice(0, -1);
				event.exclusive = true;
			}

			// Handle a global trigger
			if ( !elem ) {
				// Don't bubble custom events when global (to avoid too much overhead)
				event.stopPropagation();

				// Only trigger if we've ever bound an event for it
				if ( jQuery.event.global[ type ] ) {
					jQuery.each( jQuery.cache, function() {
						if ( this.events && this.events[type] ) {
							jQuery.event.trigger( event, data, this.handle.elem );
						}
					});
				}
			}

			// Handle triggering a single element

			// don't do events on text and comment nodes
			if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 ) {
				return undefined;
			}

			// Clean up in case it is reused
			event.result = undefined;
			event.target = elem;

			// Clone the incoming data, if any
			data = jQuery.makeArray( data );
			data.unshift( event );
		}

		event.currentTarget = elem;

		// Trigger the event, it is assumed that "handle" is a function
		var handle = jQuery.data( elem, "handle" );
		if ( handle ) {
			handle.apply( elem, data );
		}

		var parent = elem.parentNode || elem.ownerDocument;

		// Trigger an inline bound script
		try {
			if ( !(elem && elem.nodeName && jQuery.noData[elem.nodeName.toLowerCase()]) ) {
				if ( elem[ "on" + type ] && elem[ "on" + type ].apply( elem, data ) === false ) {
					event.result = false;
				}
			}

		// prevent IE from throwing an error for some elements with some event types, see #3533
		} catch (e) {}

		if ( !event.isPropagationStopped() && parent ) {
			jQuery.event.trigger( event, data, parent, true );

		} else if ( !event.isDefaultPrevented() ) {
			var target = event.target, old,
				isClick = jQuery.nodeName(target, "a") && type === "click",
				special = jQuery.event.special[ type ] || {};

			if ( (!special._default || special._default.call( elem, event ) === false) && 
				!isClick && !(target && target.nodeName && jQuery.noData[target.nodeName.toLowerCase()]) ) {

				try {
					if ( target[ type ] ) {
						// Make sure that we don't accidentally re-trigger the onFOO events
						old = target[ "on" + type ];

						if ( old ) {
							target[ "on" + type ] = null;
						}

						jQuery.event.triggered = true;
						target[ type ]();
					}

				// prevent IE from throwing an error for some elements with some event types, see #3533
				} catch (e) {}

				if ( old ) {
					target[ "on" + type ] = old;
				}

				jQuery.event.triggered = false;
			}
		}
	},

	handle: function( event ) {
		var all, handlers, namespaces, namespace, events;

		event = arguments[0] = jQuery.event.fix( event || window.event );
		event.currentTarget = this;

		// Namespaced event handlers
		all = event.type.indexOf(".") < 0 && !event.exclusive;

		if ( !all ) {
			namespaces = event.type.split(".");
			event.type = namespaces.shift();
			namespace = new RegExp("(^|\\.)" + namespaces.slice(0).sort().join("\\.(?:.*\\.)?") + "(\\.|$)");
		}

		var events = jQuery.data(this, "events"), handlers = events[ event.type ];

		if ( events && handlers ) {
			// Clone the handlers to prevent manipulation
			handlers = handlers.slice(0);

			for ( var j = 0, l = handlers.length; j < l; j++ ) {
				var handleObj = handlers[ j ];

				// Filter the functions by class
				if ( all || namespace.test( handleObj.namespace ) ) {
					// Pass in a reference to the handler function itself
					// So that we can later remove it
					event.handler = handleObj.handler;
					event.data = handleObj.data;
					event.handleObj = handleObj;
	
					var ret = handleObj.handler.apply( this, arguments );

					if ( ret !== undefined ) {
						event.result = ret;
						if ( ret === false ) {
							event.preventDefault();
							event.stopPropagation();
						}
					}

					if ( event.isImmediatePropagationStopped() ) {
						break;
					}
				}
			}
		}

		return event.result;
	},

	props: "altKey attrChange attrName bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement handler keyCode layerX layerY metaKey newValue offsetX offsetY originalTarget pageX pageY prevValue relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" "),

	fix: function( event ) {
		if ( event[ expando ] ) {
			return event;
		}

		// store a copy of the original event object
		// and "clone" to set read-only properties
		var originalEvent = event;
		event = jQuery.Event( originalEvent );

		for ( var i = this.props.length, prop; i; ) {
			prop = this.props[ --i ];
			event[ prop ] = originalEvent[ prop ];
		}

		// Fix target property, if necessary
		if ( !event.target ) {
			event.target = event.srcElement || document; // Fixes #1925 where srcElement might not be defined either
		}

		// check if target is a textnode (safari)
		if ( event.target.nodeType === 3 ) {
			event.target = event.target.parentNode;
		}

		// Add relatedTarget, if necessary
		if ( !event.relatedTarget && event.fromElement ) {
			event.relatedTarget = event.fromElement === event.target ? event.toElement : event.fromElement;
		}

		// Calculate pageX/Y if missing and clientX/Y available
		if ( event.pageX == null && event.clientX != null ) {
			var doc = document.documentElement, body = document.body;
			event.pageX = event.clientX + (doc && doc.scrollLeft || body && body.scrollLeft || 0) - (doc && doc.clientLeft || body && body.clientLeft || 0);
			event.pageY = event.clientY + (doc && doc.scrollTop  || body && body.scrollTop  || 0) - (doc && doc.clientTop  || body && body.clientTop  || 0);
		}

		// Add which for key events
		if ( !event.which && ((event.charCode || event.charCode === 0) ? event.charCode : event.keyCode) ) {
			event.which = event.charCode || event.keyCode;
		}

		// Add metaKey to non-Mac browsers (use ctrl for PC's and Meta for Macs)
		if ( !event.metaKey && event.ctrlKey ) {
			event.metaKey = event.ctrlKey;
		}

		// Add which for click: 1 === left; 2 === middle; 3 === right
		// Note: button is not normalized, so don't use it
		if ( !event.which && event.button !== undefined ) {
			event.which = (event.button & 1 ? 1 : ( event.button & 2 ? 3 : ( event.button & 4 ? 2 : 0 ) ));
		}

		return event;
	},

	// Deprecated, use jQuery.guid instead
	guid: 1E8,

	// Deprecated, use jQuery.proxy instead
	proxy: jQuery.proxy,

	special: {
		ready: {
			// Make sure the ready event is setup
			setup: jQuery.bindReady,
			teardown: jQuery.noop
		},

		live: {
			add: function( handleObj ) {
				jQuery.event.add( this, handleObj.origType, jQuery.extend({}, handleObj, {handler: liveHandler}) ); 
			},

			remove: function( handleObj ) {
				var remove = true,
					type = handleObj.origType.replace(rnamespaces, "");
				
				jQuery.each( jQuery.data(this, "events").live || [], function() {
					if ( type === this.origType.replace(rnamespaces, "") ) {
						remove = false;
						return false;
					}
				});

				if ( remove ) {
					jQuery.event.remove( this, handleObj.origType, liveHandler );
				}
			}

		},

		beforeunload: {
			setup: function( data, namespaces, eventHandle ) {
				// We only want to do this special case on windows
				if ( this.setInterval ) {
					this.onbeforeunload = eventHandle;
				}

				return false;
			},
			teardown: function( namespaces, eventHandle ) {
				if ( this.onbeforeunload === eventHandle ) {
					this.onbeforeunload = null;
				}
			}
		}
	}
};

var removeEvent = document.removeEventListener ?
	function( elem, type, handle ) {
		elem.removeEventListener( type, handle, false );
	} : 
	function( elem, type, handle ) {
		elem.detachEvent( "on" + type, handle );
	};

jQuery.Event = function( src ) {
	// Allow instantiation without the 'new' keyword
	if ( !this.preventDefault ) {
		return new jQuery.Event( src );
	}

	// Event object
	if ( src && src.type ) {
		this.originalEvent = src;
		this.type = src.type;
	// Event type
	} else {
		this.type = src;
	}

	// timeStamp is buggy for some events on Firefox(#3843)
	// So we won't rely on the native value
	this.timeStamp = now();

	// Mark it as fixed
	this[ expando ] = true;
};

function returnFalse() {
	return false;
}
function returnTrue() {
	return true;
}

// jQuery.Event is based on DOM3 Events as specified by the ECMAScript Language Binding
// http://www.w3.org/TR/2003/WD-DOM-Level-3-Events-20030331/ecma-script-binding.html
jQuery.Event.prototype = {
	preventDefault: function() {
		this.isDefaultPrevented = returnTrue;

		var e = this.originalEvent;
		if ( !e ) {
			return;
		}
		
		// if preventDefault exists run it on the original event
		if ( e.preventDefault ) {
			e.preventDefault();
		}
		// otherwise set the returnValue property of the original event to false (IE)
		e.returnValue = false;
	},
	stopPropagation: function() {
		this.isPropagationStopped = returnTrue;

		var e = this.originalEvent;
		if ( !e ) {
			return;
		}
		// if stopPropagation exists run it on the original event
		if ( e.stopPropagation ) {
			e.stopPropagation();
		}
		// otherwise set the cancelBubble property of the original event to true (IE)
		e.cancelBubble = true;
	},
	stopImmediatePropagation: function() {
		this.isImmediatePropagationStopped = returnTrue;
		this.stopPropagation();
	},
	isDefaultPrevented: returnFalse,
	isPropagationStopped: returnFalse,
	isImmediatePropagationStopped: returnFalse
};

// Checks if an event happened on an element within another element
// Used in jQuery.event.special.mouseenter and mouseleave handlers
var withinElement = function( event ) {
	// Check if mouse(over|out) are still within the same parent element
	var parent = event.relatedTarget;

	// Firefox sometimes assigns relatedTarget a XUL element
	// which we cannot access the parentNode property of
	try {
		// Traverse up the tree
		while ( parent && parent !== this ) {
			parent = parent.parentNode;
		}

		if ( parent !== this ) {
			// set the correct event type
			event.type = event.data;

			// handle event if we actually just moused on to a non sub-element
			jQuery.event.handle.apply( this, arguments );
		}

	// assuming we've left the element since we most likely mousedover a xul element
	} catch(e) { }
},

// In case of event delegation, we only need to rename the event.type,
// liveHandler will take care of the rest.
delegate = function( event ) {
	event.type = event.data;
	jQuery.event.handle.apply( this, arguments );
};

// Create mouseenter and mouseleave events
jQuery.each({
	mouseenter: "mouseover",
	mouseleave: "mouseout"
}, function( orig, fix ) {
	jQuery.event.special[ orig ] = {
		setup: function( data ) {
			jQuery.event.add( this, fix, data && data.selector ? delegate : withinElement, orig );
		},
		teardown: function( data ) {
			jQuery.event.remove( this, fix, data && data.selector ? delegate : withinElement );
		}
	};
});

// submit delegation
if ( !jQuery.support.submitBubbles ) {

	jQuery.event.special.submit = {
		setup: function( data, namespaces ) {
			if ( this.nodeName.toLowerCase() !== "form" ) {
				jQuery.event.add(this, "click.specialSubmit", function( e ) {
					var elem = e.target, type = elem.type;

					if ( (type === "submit" || type === "image") && jQuery( elem ).closest("form").length ) {
						return trigger( "submit", this, arguments );
					}
				});
	 
				jQuery.event.add(this, "keypress.specialSubmit", function( e ) {
					var elem = e.target, type = elem.type;

					if ( (type === "text" || type === "password") && jQuery( elem ).closest("form").length && e.keyCode === 13 ) {
						return trigger( "submit", this, arguments );
					}
				});

			} else {
				return false;
			}
		},

		teardown: function( namespaces ) {
			jQuery.event.remove( this, ".specialSubmit" );
		}
	};

}

// change delegation, happens here so we have bind.
if ( !jQuery.support.changeBubbles ) {

	var formElems = /textarea|input|select/i,

	changeFilters,

	getVal = function( elem ) {
		var type = elem.type, val = elem.value;

		if ( type === "radio" || type === "checkbox" ) {
			val = elem.checked;

		} else if ( type === "select-multiple" ) {
			val = elem.selectedIndex > -1 ?
				jQuery.map( elem.options, function( elem ) {
					return elem.selected;
				}).join("-") :
				"";

		} else if ( elem.nodeName.toLowerCase() === "select" ) {
			val = elem.selectedIndex;
		}

		return val;
	},

	testChange = function testChange( e ) {
		var elem = e.target, data, val;

		if ( !formElems.test( elem.nodeName ) || elem.readOnly ) {
			return;
		}

		data = jQuery.data( elem, "_change_data" );
		val = getVal(elem);

		// the current data will be also retrieved by beforeactivate
		if ( e.type !== "focusout" || elem.type !== "radio" ) {
			jQuery.data( elem, "_change_data", val );
		}
		
		if ( data === undefined || val === data ) {
			return;
		}

		if ( data != null || val ) {
			e.type = "change";
			return jQuery.event.trigger( e, arguments[1], elem );
		}
	};

	jQuery.event.special.change = {
		filters: {
			focusout: testChange, 

			click: function( e ) {
				var elem = e.target, type = elem.type;

				if ( type === "radio" || type === "checkbox" || elem.nodeName.toLowerCase() === "select" ) {
					return testChange.call( this, e );
				}
			},

			// Change has to be called before submit
			// Keydown will be called before keypress, which is used in submit-event delegation
			keydown: function( e ) {
				var elem = e.target, type = elem.type;

				if ( (e.keyCode === 13 && elem.nodeName.toLowerCase() !== "textarea") ||
					(e.keyCode === 32 && (type === "checkbox" || type === "radio")) ||
					type === "select-multiple" ) {
					return testChange.call( this, e );
				}
			},

			// Beforeactivate happens also before the previous element is blurred
			// with this event you can't trigger a change event, but you can store
			// information/focus[in] is not needed anymore
			beforeactivate: function( e ) {
				var elem = e.target;
				jQuery.data( elem, "_change_data", getVal(elem) );
			}
		},

		setup: function( data, namespaces ) {
			if ( this.type === "file" ) {
				return false;
			}

			for ( var type in changeFilters ) {
				jQuery.event.add( this, type + ".specialChange", changeFilters[type] );
			}

			return formElems.test( this.nodeName );
		},

		teardown: function( namespaces ) {
			jQuery.event.remove( this, ".specialChange" );

			return formElems.test( this.nodeName );
		}
	};

	changeFilters = jQuery.event.special.change.filters;
}

function trigger( type, elem, args ) {
	args[0].type = type;
	return jQuery.event.handle.apply( elem, args );
}

// Create "bubbling" focus and blur events
if ( document.addEventListener ) {
	jQuery.each({ focus: "focusin", blur: "focusout" }, function( orig, fix ) {
		jQuery.event.special[ fix ] = {
			setup: function() {
				this.addEventListener( orig, handler, true );
			}, 
			teardown: function() { 
				this.removeEventListener( orig, handler, true );
			}
		};

		function handler( e ) { 
			e = jQuery.event.fix( e );
			e.type = fix;
			return jQuery.event.handle.call( this, e );
		}
	});
}

jQuery.each(["bind", "one"], function( i, name ) {
	jQuery.fn[ name ] = function( type, data, fn ) {
		// Handle object literals
		if ( typeof type === "object" ) {
			for ( var key in type ) {
				this[ name ](key, data, type[key], fn);
			}
			return this;
		}
		
		if ( jQuery.isFunction( data ) ) {
			fn = data;
			data = undefined;
		}

		var handler = name === "one" ? jQuery.proxy( fn, function( event ) {
			jQuery( this ).unbind( event, handler );
			return fn.apply( this, arguments );
		}) : fn;

		if ( type === "unload" && name !== "one" ) {
			this.one( type, data, fn );

		} else {
			for ( var i = 0, l = this.length; i < l; i++ ) {
				jQuery.event.add( this[i], type, handler, data );
			}
		}

		return this;
	};
});

jQuery.fn.extend({
	unbind: function( type, fn ) {
		// Handle object literals
		if ( typeof type === "object" && !type.preventDefault ) {
			for ( var key in type ) {
				this.unbind(key, type[key]);
			}

		} else {
			for ( var i = 0, l = this.length; i < l; i++ ) {
				jQuery.event.remove( this[i], type, fn );
			}
		}

		return this;
	},
	
	delegate: function( selector, types, data, fn ) {
		return this.live( types, data, fn, selector );
	},
	
	undelegate: function( selector, types, fn ) {
		if ( arguments.length === 0 ) {
				return this.unbind( "live" );
		
		} else {
			return this.die( types, null, fn, selector );
		}
	},
	
	trigger: function( type, data ) {
		
		return this.each(function() {
			jQuery.event.trigger( type, data, this );
		});
	},

	triggerHandler: function( type, data ) {
		if ( this[0] ) {
			var event = jQuery.Event( type );
			event.preventDefault();
			event.stopPropagation();
			jQuery.event.trigger( event, data, this[0] );
			return event.result;
		}
	},

	toggle: function( fn ) {
		// Save reference to arguments for access in closure
		var args = arguments, i = 1;

		// link all the functions, so any of them can unbind this click handler
		while ( i < args.length ) {
			jQuery.proxy( fn, args[ i++ ] );
		}

		return this.click( jQuery.proxy( fn, function( event ) {
			// Figure out which function to execute
			var lastToggle = ( jQuery.data( this, "lastToggle" + fn.guid ) || 0 ) % i;
			jQuery.data( this, "lastToggle" + fn.guid, lastToggle + 1 );

			// Make sure that clicks stop
			event.preventDefault();

			// and execute the function
			return args[ lastToggle ].apply( this, arguments ) || false;
		}));
	},

	hover: function( fnOver, fnOut ) {
		return this.mouseenter( fnOver ).mouseleave( fnOut || fnOver );
	}
});

var liveMap = {
	focus: "focusin",
	blur: "focusout",
	mouseenter: "mouseover",
	mouseleave: "mouseout"
};

jQuery.each(["live", "die"], function( i, name ) {
	jQuery.fn[ name ] = function( types, data, fn, origSelector /* Internal Use Only */ ) {
		var type, i = 0, match, namespaces, preType,
			selector = origSelector || this.selector,
			context = origSelector ? this : jQuery( this.context );

		if ( jQuery.isFunction( data ) ) {
			fn = data;
			data = undefined;
		}

		types = (types || "").split(" ");

		while ( (type = types[ i++ ]) != null ) {
			match = rnamespaces.exec( type );
			namespaces = "";

			if ( match )  {
				namespaces = match[0];
				type = type.replace( rnamespaces, "" );
			}

			if ( type === "hover" ) {
				types.push( "mouseenter" + namespaces, "mouseleave" + namespaces );
				continue;
			}

			preType = type;

			if ( type === "focus" || type === "blur" ) {
				types.push( liveMap[ type ] + namespaces );
				type = type + namespaces;

			} else {
				type = (liveMap[ type ] || type) + namespaces;
			}

			if ( name === "live" ) {
				// bind live handler
				context.each(function(){
					jQuery.event.add( this, liveConvert( type, selector ),
						{ data: data, selector: selector, handler: fn, origType: type, origHandler: fn, preType: preType } );
				});

			} else {
				// unbind live handler
				context.unbind( liveConvert( type, selector ), fn );
			}
		}
		
		return this;
	}
});

function liveHandler( event ) {
	var stop, elems = [], selectors = [], args = arguments,
		related, match, handleObj, elem, j, i, l, data,
		events = jQuery.data( this, "events" );

	// Make sure we avoid non-left-click bubbling in Firefox (#3861)
	if ( event.liveFired === this || !events || !events.live || event.button && event.type === "click" ) {
		return;
	}

	event.liveFired = this;

	var live = events.live.slice(0);

	for ( j = 0; j < live.length; j++ ) {
		handleObj = live[j];

		if ( handleObj.origType.replace( rnamespaces, "" ) === event.type ) {
			selectors.push( handleObj.selector );

		} else {
			live.splice( j--, 1 );
		}
	}

	match = jQuery( event.target ).closest( selectors, event.currentTarget );

	for ( i = 0, l = match.length; i < l; i++ ) {
		for ( j = 0; j < live.length; j++ ) {
			handleObj = live[j];

			if ( match[i].selector === handleObj.selector ) {
				elem = match[i].elem;
				related = null;

				// Those two events require additional checking
				if ( handleObj.preType === "mouseenter" || handleObj.preType === "mouseleave" ) {
					related = jQuery( event.relatedTarget ).closest( handleObj.selector )[0];
				}

				if ( !related || related !== elem ) {
					elems.push({ elem: elem, handleObj: handleObj });
				}
			}
		}
	}

	for ( i = 0, l = elems.length; i < l; i++ ) {
		match = elems[i];
		event.currentTarget = match.elem;
		event.data = match.handleObj.data;
		event.handleObj = match.handleObj;

		if ( match.handleObj.origHandler.apply( match.elem, args ) === false ) {
			stop = false;
			break;
		}
	}

	return stop;
}

function liveConvert( type, selector ) {
	return "live." + (type && type !== "*" ? type + "." : "") + selector.replace(/\./g, "`").replace(/ /g, "&");
}

jQuery.each( ("blur focus focusin focusout load resize scroll unload click dblclick " +
	"mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave " +
	"change select submit keydown keypress keyup error").split(" "), function( i, name ) {

	// Handle event binding
	jQuery.fn[ name ] = function( fn ) {
		return fn ? this.bind( name, fn ) : this.trigger( name );
	};

	if ( jQuery.attrFn ) {
		jQuery.attrFn[ name ] = true;
	}
});

// Prevent memory leaks in IE
// Window isn't included so as not to unbind existing unload events
// More info:
//  - http://isaacschlueter.com/2006/10/msie-memory-leaks/
if ( window.attachEvent && !window.addEventListener ) {
	window.attachEvent("onunload", function() {
		for ( var id in jQuery.cache ) {
			if ( jQuery.cache[ id ].handle ) {
				// Try/Catch is to handle iframes being unloaded, see #4280
				try {
					jQuery.event.remove( jQuery.cache[ id ].handle.elem );
				} catch(e) {}
			}
		}
	});
}
/*!
 * Sizzle CSS Selector Engine - v1.0
 *  Copyright 2009, The Dojo Foundation
 *  Released under the MIT, BSD, and GPL Licenses.
 *  More information: http://sizzlejs.com/
 */
(function(){

var chunker = /((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^[\]]*\]|['"][^'"]*['"]|[^[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g,
	done = 0,
	toString = Object.prototype.toString,
	hasDuplicate = false,
	baseHasDuplicate = true;

// Here we check if the JavaScript engine is using some sort of
// optimization where it does not always call our comparision
// function. If that is the case, discard the hasDuplicate value.
//   Thus far that includes Google Chrome.
[0, 0].sort(function(){
	baseHasDuplicate = false;
	return 0;
});

var Sizzle = function(selector, context, results, seed) {
	results = results || [];
	var origContext = context = context || document;

	if ( context.nodeType !== 1 && context.nodeType !== 9 ) {
		return [];
	}
	
	if ( !selector || typeof selector !== "string" ) {
		return results;
	}

	var parts = [], m, set, checkSet, extra, prune = true, contextXML = isXML(context),
		soFar = selector;
	
	// Reset the position of the chunker regexp (start from head)
	while ( (chunker.exec(""), m = chunker.exec(soFar)) !== null ) {
		soFar = m[3];
		
		parts.push( m[1] );
		
		if ( m[2] ) {
			extra = m[3];
			break;
		}
	}

	if ( parts.length > 1 && origPOS.exec( selector ) ) {
		if ( parts.length === 2 && Expr.relative[ parts[0] ] ) {
			set = posProcess( parts[0] + parts[1], context );
		} else {
			set = Expr.relative[ parts[0] ] ?
				[ context ] :
				Sizzle( parts.shift(), context );

			while ( parts.length ) {
				selector = parts.shift();

				if ( Expr.relative[ selector ] ) {
					selector += parts.shift();
				}
				
				set = posProcess( selector, set );
			}
		}
	} else {
		// Take a shortcut and set the context if the root selector is an ID
		// (but not if it'll be faster if the inner selector is an ID)
		if ( !seed && parts.length > 1 && context.nodeType === 9 && !contextXML &&
				Expr.match.ID.test(parts[0]) && !Expr.match.ID.test(parts[parts.length - 1]) ) {
			var ret = Sizzle.find( parts.shift(), context, contextXML );
			context = ret.expr ? Sizzle.filter( ret.expr, ret.set )[0] : ret.set[0];
		}

		if ( context ) {
			var ret = seed ?
				{ expr: parts.pop(), set: makeArray(seed) } :
				Sizzle.find( parts.pop(), parts.length === 1 && (parts[0] === "~" || parts[0] === "+") && context.parentNode ? context.parentNode : context, contextXML );
			set = ret.expr ? Sizzle.filter( ret.expr, ret.set ) : ret.set;

			if ( parts.length > 0 ) {
				checkSet = makeArray(set);
			} else {
				prune = false;
			}

			while ( parts.length ) {
				var cur = parts.pop(), pop = cur;

				if ( !Expr.relative[ cur ] ) {
					cur = "";
				} else {
					pop = parts.pop();
				}

				if ( pop == null ) {
					pop = context;
				}

				Expr.relative[ cur ]( checkSet, pop, contextXML );
			}
		} else {
			checkSet = parts = [];
		}
	}

	if ( !checkSet ) {
		checkSet = set;
	}

	if ( !checkSet ) {
		Sizzle.error( cur || selector );
	}

	if ( toString.call(checkSet) === "[object Array]" ) {
		if ( !prune ) {
			results.push.apply( results, checkSet );
		} else if ( context && context.nodeType === 1 ) {
			for ( var i = 0; checkSet[i] != null; i++ ) {
				if ( checkSet[i] && (checkSet[i] === true || checkSet[i].nodeType === 1 && contains(context, checkSet[i])) ) {
					results.push( set[i] );
				}
			}
		} else {
			for ( var i = 0; checkSet[i] != null; i++ ) {
				if ( checkSet[i] && checkSet[i].nodeType === 1 ) {
					results.push( set[i] );
				}
			}
		}
	} else {
		makeArray( checkSet, results );
	}

	if ( extra ) {
		Sizzle( extra, origContext, results, seed );
		Sizzle.uniqueSort( results );
	}

	return results;
};

Sizzle.uniqueSort = function(results){
	if ( sortOrder ) {
		hasDuplicate = baseHasDuplicate;
		results.sort(sortOrder);

		if ( hasDuplicate ) {
			for ( var i = 1; i < results.length; i++ ) {
				if ( results[i] === results[i-1] ) {
					results.splice(i--, 1);
				}
			}
		}
	}

	return results;
};

Sizzle.matches = function(expr, set){
	return Sizzle(expr, null, null, set);
};

Sizzle.find = function(expr, context, isXML){
	var set, match;

	if ( !expr ) {
		return [];
	}

	for ( var i = 0, l = Expr.order.length; i < l; i++ ) {
		var type = Expr.order[i], match;
		
		if ( (match = Expr.leftMatch[ type ].exec( expr )) ) {
			var left = match[1];
			match.splice(1,1);

			if ( left.substr( left.length - 1 ) !== "\\" ) {
				match[1] = (match[1] || "").replace(/\\/g, "");
				set = Expr.find[ type ]( match, context, isXML );
				if ( set != null ) {
					expr = expr.replace( Expr.match[ type ], "" );
					break;
				}
			}
		}
	}

	if ( !set ) {
		set = context.getElementsByTagName("*");
	}

	return {set: set, expr: expr};
};

Sizzle.filter = function(expr, set, inplace, not){
	var old = expr, result = [], curLoop = set, match, anyFound,
		isXMLFilter = set && set[0] && isXML(set[0]);

	while ( expr && set.length ) {
		for ( var type in Expr.filter ) {
			if ( (match = Expr.leftMatch[ type ].exec( expr )) != null && match[2] ) {
				var filter = Expr.filter[ type ], found, item, left = match[1];
				anyFound = false;

				match.splice(1,1);

				if ( left.substr( left.length - 1 ) === "\\" ) {
					continue;
				}

				if ( curLoop === result ) {
					result = [];
				}

				if ( Expr.preFilter[ type ] ) {
					match = Expr.preFilter[ type ]( match, curLoop, inplace, result, not, isXMLFilter );

					if ( !match ) {
						anyFound = found = true;
					} else if ( match === true ) {
						continue;
					}
				}

				if ( match ) {
					for ( var i = 0; (item = curLoop[i]) != null; i++ ) {
						if ( item ) {
							found = filter( item, match, i, curLoop );
							var pass = not ^ !!found;

							if ( inplace && found != null ) {
								if ( pass ) {
									anyFound = true;
								} else {
									curLoop[i] = false;
								}
							} else if ( pass ) {
								result.push( item );
								anyFound = true;
							}
						}
					}
				}

				if ( found !== undefined ) {
					if ( !inplace ) {
						curLoop = result;
					}

					expr = expr.replace( Expr.match[ type ], "" );

					if ( !anyFound ) {
						return [];
					}

					break;
				}
			}
		}

		// Improper expression
		if ( expr === old ) {
			if ( anyFound == null ) {
				Sizzle.error( expr );
			} else {
				break;
			}
		}

		old = expr;
	}

	return curLoop;
};

Sizzle.error = function( msg ) {
	throw "Syntax error, unrecognized expression: " + msg;
};

var Expr = Sizzle.selectors = {
	order: [ "ID", "NAME", "TAG" ],
	match: {
		ID: /#((?:[\w\u00c0-\uFFFF-]|\\.)+)/,
		CLASS: /\.((?:[\w\u00c0-\uFFFF-]|\\.)+)/,
		NAME: /\[name=['"]*((?:[\w\u00c0-\uFFFF-]|\\.)+)['"]*\]/,
		ATTR: /\[\s*((?:[\w\u00c0-\uFFFF-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\3|)\s*\]/,
		TAG: /^((?:[\w\u00c0-\uFFFF\*-]|\\.)+)/,
		CHILD: /:(only|nth|last|first)-child(?:\((even|odd|[\dn+-]*)\))?/,
		POS: /:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^-]|$)/,
		PSEUDO: /:((?:[\w\u00c0-\uFFFF-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?/
	},
	leftMatch: {},
	attrMap: {
		"class": "className",
		"for": "htmlFor"
	},
	attrHandle: {
		href: function(elem){
			return elem.getAttribute("href");
		}
	},
	relative: {
		"+": function(checkSet, part){
			var isPartStr = typeof part === "string",
				isTag = isPartStr && !/\W/.test(part),
				isPartStrNotTag = isPartStr && !isTag;

			if ( isTag ) {
				part = part.toLowerCase();
			}

			for ( var i = 0, l = checkSet.length, elem; i < l; i++ ) {
				if ( (elem = checkSet[i]) ) {
					while ( (elem = elem.previousSibling) && elem.nodeType !== 1 ) {}

					checkSet[i] = isPartStrNotTag || elem && elem.nodeName.toLowerCase() === part ?
						elem || false :
						elem === part;
				}
			}

			if ( isPartStrNotTag ) {
				Sizzle.filter( part, checkSet, true );
			}
		},
		">": function(checkSet, part){
			var isPartStr = typeof part === "string";

			if ( isPartStr && !/\W/.test(part) ) {
				part = part.toLowerCase();

				for ( var i = 0, l = checkSet.length; i < l; i++ ) {
					var elem = checkSet[i];
					if ( elem ) {
						var parent = elem.parentNode;
						checkSet[i] = parent.nodeName.toLowerCase() === part ? parent : false;
					}
				}
			} else {
				for ( var i = 0, l = checkSet.length; i < l; i++ ) {
					var elem = checkSet[i];
					if ( elem ) {
						checkSet[i] = isPartStr ?
							elem.parentNode :
							elem.parentNode === part;
					}
				}

				if ( isPartStr ) {
					Sizzle.filter( part, checkSet, true );
				}
			}
		},
		"": function(checkSet, part, isXML){
			var doneName = done++, checkFn = dirCheck;

			if ( typeof part === "string" && !/\W/.test(part) ) {
				var nodeCheck = part = part.toLowerCase();
				checkFn = dirNodeCheck;
			}

			checkFn("parentNode", part, doneName, checkSet, nodeCheck, isXML);
		},
		"~": function(checkSet, part, isXML){
			var doneName = done++, checkFn = dirCheck;

			if ( typeof part === "string" && !/\W/.test(part) ) {
				var nodeCheck = part = part.toLowerCase();
				checkFn = dirNodeCheck;
			}

			checkFn("previousSibling", part, doneName, checkSet, nodeCheck, isXML);
		}
	},
	find: {
		ID: function(match, context, isXML){
			if ( typeof context.getElementById !== "undefined" && !isXML ) {
				var m = context.getElementById(match[1]);
				return m ? [m] : [];
			}
		},
		NAME: function(match, context){
			if ( typeof context.getElementsByName !== "undefined" ) {
				var ret = [], results = context.getElementsByName(match[1]);

				for ( var i = 0, l = results.length; i < l; i++ ) {
					if ( results[i].getAttribute("name") === match[1] ) {
						ret.push( results[i] );
					}
				}

				return ret.length === 0 ? null : ret;
			}
		},
		TAG: function(match, context){
			return context.getElementsByTagName(match[1]);
		}
	},
	preFilter: {
		CLASS: function(match, curLoop, inplace, result, not, isXML){
			match = " " + match[1].replace(/\\/g, "") + " ";

			if ( isXML ) {
				return match;
			}

			for ( var i = 0, elem; (elem = curLoop[i]) != null; i++ ) {
				if ( elem ) {
					if ( not ^ (elem.className && (" " + elem.className + " ").replace(/[\t\n]/g, " ").indexOf(match) >= 0) ) {
						if ( !inplace ) {
							result.push( elem );
						}
					} else if ( inplace ) {
						curLoop[i] = false;
					}
				}
			}

			return false;
		},
		ID: function(match){
			return match[1].replace(/\\/g, "");
		},
		TAG: function(match, curLoop){
			return match[1].toLowerCase();
		},
		CHILD: function(match){
			if ( match[1] === "nth" ) {
				// parse equations like 'even', 'odd', '5', '2n', '3n+2', '4n-1', '-n+6'
				var test = /(-?)(\d*)n((?:\+|-)?\d*)/.exec(
					match[2] === "even" && "2n" || match[2] === "odd" && "2n+1" ||
					!/\D/.test( match[2] ) && "0n+" + match[2] || match[2]);

				// calculate the numbers (first)n+(last) including if they are negative
				match[2] = (test[1] + (test[2] || 1)) - 0;
				match[3] = test[3] - 0;
			}

			// TODO: Move to normal caching system
			match[0] = done++;

			return match;
		},
		ATTR: function(match, curLoop, inplace, result, not, isXML){
			var name = match[1].replace(/\\/g, "");
			
			if ( !isXML && Expr.attrMap[name] ) {
				match[1] = Expr.attrMap[name];
			}

			if ( match[2] === "~=" ) {
				match[4] = " " + match[4] + " ";
			}

			return match;
		},
		PSEUDO: function(match, curLoop, inplace, result, not){
			if ( match[1] === "not" ) {
				// If we're dealing with a complex expression, or a simple one
				if ( ( chunker.exec(match[3]) || "" ).length > 1 || /^\w/.test(match[3]) ) {
					match[3] = Sizzle(match[3], null, null, curLoop);
				} else {
					var ret = Sizzle.filter(match[3], curLoop, inplace, true ^ not);
					if ( !inplace ) {
						result.push.apply( result, ret );
					}
					return false;
				}
			} else if ( Expr.match.POS.test( match[0] ) || Expr.match.CHILD.test( match[0] ) ) {
				return true;
			}
			
			return match;
		},
		POS: function(match){
			match.unshift( true );
			return match;
		}
	},
	filters: {
		enabled: function(elem){
			return elem.disabled === false && elem.type !== "hidden";
		},
		disabled: function(elem){
			return elem.disabled === true;
		},
		checked: function(elem){
			return elem.checked === true;
		},
		selected: function(elem){
			// Accessing this property makes selected-by-default
			// options in Safari work properly
			elem.parentNode.selectedIndex;
			return elem.selected === true;
		},
		parent: function(elem){
			return !!elem.firstChild;
		},
		empty: function(elem){
			return !elem.firstChild;
		},
		has: function(elem, i, match){
			return !!Sizzle( match[3], elem ).length;
		},
		header: function(elem){
			return /h\d/i.test( elem.nodeName );
		},
		text: function(elem){
			return "text" === elem.type;
		},
		radio: function(elem){
			return "radio" === elem.type;
		},
		checkbox: function(elem){
			return "checkbox" === elem.type;
		},
		file: function(elem){
			return "file" === elem.type;
		},
		password: function(elem){
			return "password" === elem.type;
		},
		submit: function(elem){
			return "submit" === elem.type;
		},
		image: function(elem){
			return "image" === elem.type;
		},
		reset: function(elem){
			return "reset" === elem.type;
		},
		button: function(elem){
			return "button" === elem.type || elem.nodeName.toLowerCase() === "button";
		},
		input: function(elem){
			return /input|select|textarea|button/i.test(elem.nodeName);
		}
	},
	setFilters: {
		first: function(elem, i){
			return i === 0;
		},
		last: function(elem, i, match, array){
			return i === array.length - 1;
		},
		even: function(elem, i){
			return i % 2 === 0;
		},
		odd: function(elem, i){
			return i % 2 === 1;
		},
		lt: function(elem, i, match){
			return i < match[3] - 0;
		},
		gt: function(elem, i, match){
			return i > match[3] - 0;
		},
		nth: function(elem, i, match){
			return match[3] - 0 === i;
		},
		eq: function(elem, i, match){
			return match[3] - 0 === i;
		}
	},
	filter: {
		PSEUDO: function(elem, match, i, array){
			var name = match[1], filter = Expr.filters[ name ];

			if ( filter ) {
				return filter( elem, i, match, array );
			} else if ( name === "contains" ) {
				return (elem.textContent || elem.innerText || getText([ elem ]) || "").indexOf(match[3]) >= 0;
			} else if ( name === "not" ) {
				var not = match[3];

				for ( var i = 0, l = not.length; i < l; i++ ) {
					if ( not[i] === elem ) {
						return false;
					}
				}

				return true;
			} else {
				Sizzle.error( "Syntax error, unrecognized expression: " + name );
			}
		},
		CHILD: function(elem, match){
			var type = match[1], node = elem;
			switch (type) {
				case 'only':
				case 'first':
					while ( (node = node.previousSibling) )	 {
						if ( node.nodeType === 1 ) { 
							return false; 
						}
					}
					if ( type === "first" ) { 
						return true; 
					}
					node = elem;
				case 'last':
					while ( (node = node.nextSibling) )	 {
						if ( node.nodeType === 1 ) { 
							return false; 
						}
					}
					return true;
				case 'nth':
					var first = match[2], last = match[3];

					if ( first === 1 && last === 0 ) {
						return true;
					}
					
					var doneName = match[0],
						parent = elem.parentNode;
	
					if ( parent && (parent.sizcache !== doneName || !elem.nodeIndex) ) {
						var count = 0;
						for ( node = parent.firstChild; node; node = node.nextSibling ) {
							if ( node.nodeType === 1 ) {
								node.nodeIndex = ++count;
							}
						} 
						parent.sizcache = doneName;
					}
					
					var diff = elem.nodeIndex - last;
					if ( first === 0 ) {
						return diff === 0;
					} else {
						return ( diff % first === 0 && diff / first >= 0 );
					}
			}
		},
		ID: function(elem, match){
			return elem.nodeType === 1 && elem.getAttribute("id") === match;
		},
		TAG: function(elem, match){
			return (match === "*" && elem.nodeType === 1) || elem.nodeName.toLowerCase() === match;
		},
		CLASS: function(elem, match){
			return (" " + (elem.className || elem.getAttribute("class")) + " ")
				.indexOf( match ) > -1;
		},
		ATTR: function(elem, match){
			var name = match[1],
				result = Expr.attrHandle[ name ] ?
					Expr.attrHandle[ name ]( elem ) :
					elem[ name ] != null ?
						elem[ name ] :
						elem.getAttribute( name ),
				value = result + "",
				type = match[2],
				check = match[4];

			return result == null ?
				type === "!=" :
				type === "=" ?
				value === check :
				type === "*=" ?
				value.indexOf(check) >= 0 :
				type === "~=" ?
				(" " + value + " ").indexOf(check) >= 0 :
				!check ?
				value && result !== false :
				type === "!=" ?
				value !== check :
				type === "^=" ?
				value.indexOf(check) === 0 :
				type === "$=" ?
				value.substr(value.length - check.length) === check :
				type === "|=" ?
				value === check || value.substr(0, check.length + 1) === check + "-" :
				false;
		},
		POS: function(elem, match, i, array){
			var name = match[2], filter = Expr.setFilters[ name ];

			if ( filter ) {
				return filter( elem, i, match, array );
			}
		}
	}
};

var origPOS = Expr.match.POS;

for ( var type in Expr.match ) {
	Expr.match[ type ] = new RegExp( Expr.match[ type ].source + /(?![^\[]*\])(?![^\(]*\))/.source );
	Expr.leftMatch[ type ] = new RegExp( /(^(?:.|\r|\n)*?)/.source + Expr.match[ type ].source.replace(/\\(\d+)/g, function(all, num){
		return "\\" + (num - 0 + 1);
	}));
}

var makeArray = function(array, results) {
	array = Array.prototype.slice.call( array, 0 );

	if ( results ) {
		results.push.apply( results, array );
		return results;
	}
	
	return array;
};

// Perform a simple check to determine if the browser is capable of
// converting a NodeList to an array using builtin methods.
// Also verifies that the returned array holds DOM nodes
// (which is not the case in the Blackberry browser)
try {
	Array.prototype.slice.call( document.documentElement.childNodes, 0 )[0].nodeType;

// Provide a fallback method if it does not work
} catch(e){
	makeArray = function(array, results) {
		var ret = results || [];

		if ( toString.call(array) === "[object Array]" ) {
			Array.prototype.push.apply( ret, array );
		} else {
			if ( typeof array.length === "number" ) {
				for ( var i = 0, l = array.length; i < l; i++ ) {
					ret.push( array[i] );
				}
			} else {
				for ( var i = 0; array[i]; i++ ) {
					ret.push( array[i] );
				}
			}
		}

		return ret;
	};
}

var sortOrder;

if ( document.documentElement.compareDocumentPosition ) {
	sortOrder = function( a, b ) {
		if ( !a.compareDocumentPosition || !b.compareDocumentPosition ) {
			if ( a == b ) {
				hasDuplicate = true;
			}
			return a.compareDocumentPosition ? -1 : 1;
		}

		var ret = a.compareDocumentPosition(b) & 4 ? -1 : a === b ? 0 : 1;
		if ( ret === 0 ) {
			hasDuplicate = true;
		}
		return ret;
	};
} else if ( "sourceIndex" in document.documentElement ) {
	sortOrder = function( a, b ) {
		if ( !a.sourceIndex || !b.sourceIndex ) {
			if ( a == b ) {
				hasDuplicate = true;
			}
			return a.sourceIndex ? -1 : 1;
		}

		var ret = a.sourceIndex - b.sourceIndex;
		if ( ret === 0 ) {
			hasDuplicate = true;
		}
		return ret;
	};
} else if ( document.createRange ) {
	sortOrder = function( a, b ) {
		if ( !a.ownerDocument || !b.ownerDocument ) {
			if ( a == b ) {
				hasDuplicate = true;
			}
			return a.ownerDocument ? -1 : 1;
		}

		var aRange = a.ownerDocument.createRange(), bRange = b.ownerDocument.createRange();
		aRange.setStart(a, 0);
		aRange.setEnd(a, 0);
		bRange.setStart(b, 0);
		bRange.setEnd(b, 0);
		var ret = aRange.compareBoundaryPoints(Range.START_TO_END, bRange);
		if ( ret === 0 ) {
			hasDuplicate = true;
		}
		return ret;
	};
}

// Utility function for retreiving the text value of an array of DOM nodes
function getText( elems ) {
	var ret = "", elem;

	for ( var i = 0; elems[i]; i++ ) {
		elem = elems[i];

		// Get the text from text nodes and CDATA nodes
		if ( elem.nodeType === 3 || elem.nodeType === 4 ) {
			ret += elem.nodeValue;

		// Traverse everything else, except comment nodes
		} else if ( elem.nodeType !== 8 ) {
			ret += getText( elem.childNodes );
		}
	}

	return ret;
}

// Check to see if the browser returns elements by name when
// querying by getElementById (and provide a workaround)
(function(){
	// We're going to inject a fake input element with a specified name
	var form = document.createElement("div"),
		id = "script" + (new Date).getTime();
	form.innerHTML = "<a name='" + id + "'/>";

	// Inject it into the root element, check its status, and remove it quickly
	var root = document.documentElement;
	root.insertBefore( form, root.firstChild );

	// The workaround has to do additional checks after a getElementById
	// Which slows things down for other browsers (hence the branching)
	if ( document.getElementById( id ) ) {
		Expr.find.ID = function(match, context, isXML){
			if ( typeof context.getElementById !== "undefined" && !isXML ) {
				var m = context.getElementById(match[1]);
				return m ? m.id === match[1] || typeof m.getAttributeNode !== "undefined" && m.getAttributeNode("id").nodeValue === match[1] ? [m] : undefined : [];
			}
		};

		Expr.filter.ID = function(elem, match){
			var node = typeof elem.getAttributeNode !== "undefined" && elem.getAttributeNode("id");
			return elem.nodeType === 1 && node && node.nodeValue === match;
		};
	}

	root.removeChild( form );
	root = form = null; // release memory in IE
})();

(function(){
	// Check to see if the browser returns only elements
	// when doing getElementsByTagName("*")

	// Create a fake element
	var div = document.createElement("div");
	div.appendChild( document.createComment("") );

	// Make sure no comments are found
	if ( div.getElementsByTagName("*").length > 0 ) {
		Expr.find.TAG = function(match, context){
			var results = context.getElementsByTagName(match[1]);

			// Filter out possible comments
			if ( match[1] === "*" ) {
				var tmp = [];

				for ( var i = 0; results[i]; i++ ) {
					if ( results[i].nodeType === 1 ) {
						tmp.push( results[i] );
					}
				}

				results = tmp;
			}

			return results;
		};
	}

	// Check to see if an attribute returns normalized href attributes
	div.innerHTML = "<a href='#'></a>";
	if ( div.firstChild && typeof div.firstChild.getAttribute !== "undefined" &&
			div.firstChild.getAttribute("href") !== "#" ) {
		Expr.attrHandle.href = function(elem){
			return elem.getAttribute("href", 2);
		};
	}

	div = null; // release memory in IE
})();

if ( document.querySelectorAll ) {
	(function(){
		var oldSizzle = Sizzle, div = document.createElement("div");
		div.innerHTML = "<p class='TEST'></p>";

		// Safari can't handle uppercase or unicode characters when
		// in quirks mode.
		if ( div.querySelectorAll && div.querySelectorAll(".TEST").length === 0 ) {
			return;
		}
	
		Sizzle = function(query, context, extra, seed){
			context = context || document;

			// Only use querySelectorAll on non-XML documents
			// (ID selectors don't work in non-HTML documents)
			if ( !seed && context.nodeType === 9 && !isXML(context) ) {
				try {
					return makeArray( context.querySelectorAll(query), extra );
				} catch(e){}
			}
		
			return oldSizzle(query, context, extra, seed);
		};

		for ( var prop in oldSizzle ) {
			Sizzle[ prop ] = oldSizzle[ prop ];
		}

		div = null; // release memory in IE
	})();
}

(function(){
	var div = document.createElement("div");

	div.innerHTML = "<div class='test e'></div><div class='test'></div>";

	// Opera can't find a second classname (in 9.6)
	// Also, make sure that getElementsByClassName actually exists
	if ( !div.getElementsByClassName || div.getElementsByClassName("e").length === 0 ) {
		return;
	}

	// Safari caches class attributes, doesn't catch changes (in 3.2)
	div.lastChild.className = "e";

	if ( div.getElementsByClassName("e").length === 1 ) {
		return;
	}
	
	Expr.order.splice(1, 0, "CLASS");
	Expr.find.CLASS = function(match, context, isXML) {
		if ( typeof context.getElementsByClassName !== "undefined" && !isXML ) {
			return context.getElementsByClassName(match[1]);
		}
	};

	div = null; // release memory in IE
})();

function dirNodeCheck( dir, cur, doneName, checkSet, nodeCheck, isXML ) {
	for ( var i = 0, l = checkSet.length; i < l; i++ ) {
		var elem = checkSet[i];
		if ( elem ) {
			elem = elem[dir];
			var match = false;

			while ( elem ) {
				if ( elem.sizcache === doneName ) {
					match = checkSet[elem.sizset];
					break;
				}

				if ( elem.nodeType === 1 && !isXML ){
					elem.sizcache = doneName;
					elem.sizset = i;
				}

				if ( elem.nodeName.toLowerCase() === cur ) {
					match = elem;
					break;
				}

				elem = elem[dir];
			}

			checkSet[i] = match;
		}
	}
}

function dirCheck( dir, cur, doneName, checkSet, nodeCheck, isXML ) {
	for ( var i = 0, l = checkSet.length; i < l; i++ ) {
		var elem = checkSet[i];
		if ( elem ) {
			elem = elem[dir];
			var match = false;

			while ( elem ) {
				if ( elem.sizcache === doneName ) {
					match = checkSet[elem.sizset];
					break;
				}

				if ( elem.nodeType === 1 ) {
					if ( !isXML ) {
						elem.sizcache = doneName;
						elem.sizset = i;
					}
					if ( typeof cur !== "string" ) {
						if ( elem === cur ) {
							match = true;
							break;
						}

					} else if ( Sizzle.filter( cur, [elem] ).length > 0 ) {
						match = elem;
						break;
					}
				}

				elem = elem[dir];
			}

			checkSet[i] = match;
		}
	}
}

var contains = document.compareDocumentPosition ? function(a, b){
	return !!(a.compareDocumentPosition(b) & 16);
} : function(a, b){
	return a !== b && (a.contains ? a.contains(b) : true);
};

var isXML = function(elem){
	// documentElement is verified for cases where it doesn't yet exist
	// (such as loading iframes in IE - #4833) 
	var documentElement = (elem ? elem.ownerDocument || elem : 0).documentElement;
	return documentElement ? documentElement.nodeName !== "HTML" : false;
};

var posProcess = function(selector, context){
	var tmpSet = [], later = "", match,
		root = context.nodeType ? [context] : context;

	// Position selectors must be done after the filter
	// And so must :not(positional) so we move all PSEUDOs to the end
	while ( (match = Expr.match.PSEUDO.exec( selector )) ) {
		later += match[0];
		selector = selector.replace( Expr.match.PSEUDO, "" );
	}

	selector = Expr.relative[selector] ? selector + "*" : selector;

	for ( var i = 0, l = root.length; i < l; i++ ) {
		Sizzle( selector, root[i], tmpSet );
	}

	return Sizzle.filter( later, tmpSet );
};

// EXPOSE
jQuery.find = Sizzle;
jQuery.expr = Sizzle.selectors;
jQuery.expr[":"] = jQuery.expr.filters;
jQuery.unique = Sizzle.uniqueSort;
jQuery.text = getText;
jQuery.isXMLDoc = isXML;
jQuery.contains = contains;

return;

window.Sizzle = Sizzle;

})();
var runtil = /Until$/,
	rparentsprev = /^(?:parents|prevUntil|prevAll)/,
	// Note: This RegExp should be improved, or likely pulled from Sizzle
	rmultiselector = /,/,
	slice = Array.prototype.slice;

// Implement the identical functionality for filter and not
var winnow = function( elements, qualifier, keep ) {
	if ( jQuery.isFunction( qualifier ) ) {
		return jQuery.grep(elements, function( elem, i ) {
			return !!qualifier.call( elem, i, elem ) === keep;
		});

	} else if ( qualifier.nodeType ) {
		return jQuery.grep(elements, function( elem, i ) {
			return (elem === qualifier) === keep;
		});

	} else if ( typeof qualifier === "string" ) {
		var filtered = jQuery.grep(elements, function( elem ) {
			return elem.nodeType === 1;
		});

		if ( isSimple.test( qualifier ) ) {
			return jQuery.filter(qualifier, filtered, !keep);
		} else {
			qualifier = jQuery.filter( qualifier, filtered );
		}
	}

	return jQuery.grep(elements, function( elem, i ) {
		return (jQuery.inArray( elem, qualifier ) >= 0) === keep;
	});
};

jQuery.fn.extend({
	find: function( selector ) {
		var ret = this.pushStack( "", "find", selector ), length = 0;

		for ( var i = 0, l = this.length; i < l; i++ ) {
			length = ret.length;
			jQuery.find( selector, this[i], ret );

			if ( i > 0 ) {
				// Make sure that the results are unique
				for ( var n = length; n < ret.length; n++ ) {
					for ( var r = 0; r < length; r++ ) {
						if ( ret[r] === ret[n] ) {
							ret.splice(n--, 1);
							break;
						}
					}
				}
			}
		}

		return ret;
	},

	has: function( target ) {
		var targets = jQuery( target );
		return this.filter(function() {
			for ( var i = 0, l = targets.length; i < l; i++ ) {
				if ( jQuery.contains( this, targets[i] ) ) {
					return true;
				}
			}
		});
	},

	not: function( selector ) {
		return this.pushStack( winnow(this, selector, false), "not", selector);
	},

	filter: function( selector ) {
		return this.pushStack( winnow(this, selector, true), "filter", selector );
	},
	
	is: function( selector ) {
		return !!selector && jQuery.filter( selector, this ).length > 0;
	},

	closest: function( selectors, context ) {
		if ( jQuery.isArray( selectors ) ) {
			var ret = [], cur = this[0], match, matches = {}, selector;

			if ( cur && selectors.length ) {
				for ( var i = 0, l = selectors.length; i < l; i++ ) {
					selector = selectors[i];

					if ( !matches[selector] ) {
						matches[selector] = jQuery.expr.match.POS.test( selector ) ? 
							jQuery( selector, context || this.context ) :
							selector;
					}
				}

				while ( cur && cur.ownerDocument && cur !== context ) {
					for ( selector in matches ) {
						match = matches[selector];

						if ( match.jquery ? match.index(cur) > -1 : jQuery(cur).is(match) ) {
							ret.push({ selector: selector, elem: cur });
							delete matches[selector];
						}
					}
					cur = cur.parentNode;
				}
			}

			return ret;
		}

		var pos = jQuery.expr.match.POS.test( selectors ) ? 
			jQuery( selectors, context || this.context ) : null;

		return this.map(function( i, cur ) {
			while ( cur && cur.ownerDocument && cur !== context ) {
				if ( pos ? pos.index(cur) > -1 : jQuery(cur).is(selectors) ) {
					return cur;
				}
				cur = cur.parentNode;
			}
			return null;
		});
	},
	
	// Determine the position of an element within
	// the matched set of elements
	index: function( elem ) {
		if ( !elem || typeof elem === "string" ) {
			return jQuery.inArray( this[0],
				// If it receives a string, the selector is used
				// If it receives nothing, the siblings are used
				elem ? jQuery( elem ) : this.parent().children() );
		}
		// Locate the position of the desired element
		return jQuery.inArray(
			// If it receives a jQuery object, the first element is used
			elem.jquery ? elem[0] : elem, this );
	},

	add: function( selector, context ) {
		var set = typeof selector === "string" ?
				jQuery( selector, context || this.context ) :
				jQuery.makeArray( selector ),
			all = jQuery.merge( this.get(), set );

		return this.pushStack( isDisconnected( set[0] ) || isDisconnected( all[0] ) ?
			all :
			jQuery.unique( all ) );
	},

	andSelf: function() {
		return this.add( this.prevObject );
	}
});

// A painfully simple check to see if an element is disconnected
// from a document (should be improved, where feasible).
function isDisconnected( node ) {
	return !node || !node.parentNode || node.parentNode.nodeType === 11;
}

jQuery.each({
	parent: function( elem ) {
		var parent = elem.parentNode;
		return parent && parent.nodeType !== 11 ? parent : null;
	},
	parents: function( elem ) {
		return jQuery.dir( elem, "parentNode" );
	},
	parentsUntil: function( elem, i, until ) {
		return jQuery.dir( elem, "parentNode", until );
	},
	next: function( elem ) {
		return jQuery.nth( elem, 2, "nextSibling" );
	},
	prev: function( elem ) {
		return jQuery.nth( elem, 2, "previousSibling" );
	},
	nextAll: function( elem ) {
		return jQuery.dir( elem, "nextSibling" );
	},
	prevAll: function( elem ) {
		return jQuery.dir( elem, "previousSibling" );
	},
	nextUntil: function( elem, i, until ) {
		return jQuery.dir( elem, "nextSibling", until );
	},
	prevUntil: function( elem, i, until ) {
		return jQuery.dir( elem, "previousSibling", until );
	},
	siblings: function( elem ) {
		return jQuery.sibling( elem.parentNode.firstChild, elem );
	},
	children: function( elem ) {
		return jQuery.sibling( elem.firstChild );
	},
	contents: function( elem ) {
		return jQuery.nodeName( elem, "iframe" ) ?
			elem.contentDocument || elem.contentWindow.document :
			jQuery.makeArray( elem.childNodes );
	}
}, function( name, fn ) {
	jQuery.fn[ name ] = function( until, selector ) {
		var ret = jQuery.map( this, fn, until );
		
		if ( !runtil.test( name ) ) {
			selector = until;
		}

		if ( selector && typeof selector === "string" ) {
			ret = jQuery.filter( selector, ret );
		}

		ret = this.length > 1 ? jQuery.unique( ret ) : ret;

		if ( (this.length > 1 || rmultiselector.test( selector )) && rparentsprev.test( name ) ) {
			ret = ret.reverse();
		}

		return this.pushStack( ret, name, slice.call(arguments).join(",") );
	};
});

jQuery.extend({
	filter: function( expr, elems, not ) {
		if ( not ) {
			expr = ":not(" + expr + ")";
		}

		return jQuery.find.matches(expr, elems);
	},
	
	dir: function( elem, dir, until ) {
		var matched = [], cur = elem[dir];
		while ( cur && cur.nodeType !== 9 && (until === undefined || cur.nodeType !== 1 || !jQuery( cur ).is( until )) ) {
			if ( cur.nodeType === 1 ) {
				matched.push( cur );
			}
			cur = cur[dir];
		}
		return matched;
	},

	nth: function( cur, result, dir, elem ) {
		result = result || 1;
		var num = 0;

		for ( ; cur; cur = cur[dir] ) {
			if ( cur.nodeType === 1 && ++num === result ) {
				break;
			}
		}

		return cur;
	},

	sibling: function( n, elem ) {
		var r = [];

		for ( ; n; n = n.nextSibling ) {
			if ( n.nodeType === 1 && n !== elem ) {
				r.push( n );
			}
		}

		return r;
	}
});
var rinlinejQuery = / jQuery\d+="(?:\d+|null)"/g,
	rleadingWhitespace = /^\s+/,
	rxhtmlTag = /(<([\w:]+)[^>]*?)\/>/g,
	rselfClosing = /^(?:area|br|col|embed|hr|img|input|link|meta|param)$/i,
	rtagName = /<([\w:]+)/,
	rtbody = /<tbody/i,
	rhtml = /<|&#?\w+;/,
	rnocache = /<script|<object|<embed|<option|<style/i,
	rchecked = /checked\s*(?:[^=]|=\s*.checked.)/i,  // checked="checked" or checked (html5)
	fcloseTag = function( all, front, tag ) {
		return rselfClosing.test( tag ) ?
			all :
			front + "></" + tag + ">";
	},
	wrapMap = {
		option: [ 1, "<select multiple='multiple'>", "</select>" ],
		legend: [ 1, "<fieldset>", "</fieldset>" ],
		thead: [ 1, "<table>", "</table>" ],
		tr: [ 2, "<table><tbody>", "</tbody></table>" ],
		td: [ 3, "<table><tbody><tr>", "</tr></tbody></table>" ],
		col: [ 2, "<table><tbody></tbody><colgroup>", "</colgroup></table>" ],
		area: [ 1, "<map>", "</map>" ],
		_default: [ 0, "", "" ]
	};

wrapMap.optgroup = wrapMap.option;
wrapMap.tbody = wrapMap.tfoot = wrapMap.colgroup = wrapMap.caption = wrapMap.thead;
wrapMap.th = wrapMap.td;

// IE can't serialize <link> and <script> tags normally
if ( !jQuery.support.htmlSerialize ) {
	wrapMap._default = [ 1, "div<div>", "</div>" ];
}

jQuery.fn.extend({
	text: function( text ) {
		if ( jQuery.isFunction(text) ) {
			return this.each(function(i) {
				var self = jQuery(this);
				self.text( text.call(this, i, self.text()) );
			});
		}

		if ( typeof text !== "object" && text !== undefined ) {
			return this.empty().append( (this[0] && this[0].ownerDocument || document).createTextNode( text ) );
		}

		return jQuery.text( this );
	},

	wrapAll: function( html ) {
		if ( jQuery.isFunction( html ) ) {
			return this.each(function(i) {
				jQuery(this).wrapAll( html.call(this, i) );
			});
		}

		if ( this[0] ) {
			// The elements to wrap the target around
			var wrap = jQuery( html, this[0].ownerDocument ).eq(0).clone(true);

			if ( this[0].parentNode ) {
				wrap.insertBefore( this[0] );
			}

			wrap.map(function() {
				var elem = this;

				while ( elem.firstChild && elem.firstChild.nodeType === 1 ) {
					elem = elem.firstChild;
				}

				return elem;
			}).append(this);
		}

		return this;
	},

	wrapInner: function( html ) {
		if ( jQuery.isFunction( html ) ) {
			return this.each(function(i) {
				jQuery(this).wrapInner( html.call(this, i) );
			});
		}

		return this.each(function() {
			var self = jQuery( this ), contents = self.contents();

			if ( contents.length ) {
				contents.wrapAll( html );

			} else {
				self.append( html );
			}
		});
	},

	wrap: function( html ) {
		return this.each(function() {
			jQuery( this ).wrapAll( html );
		});
	},

	unwrap: function() {
		return this.parent().each(function() {
			if ( !jQuery.nodeName( this, "body" ) ) {
				jQuery( this ).replaceWith( this.childNodes );
			}
		}).end();
	},

	append: function() {
		return this.domManip(arguments, true, function( elem ) {
			if ( this.nodeType === 1 ) {
				this.appendChild( elem );
			}
		});
	},

	prepend: function() {
		return this.domManip(arguments, true, function( elem ) {
			if ( this.nodeType === 1 ) {
				this.insertBefore( elem, this.firstChild );
			}
		});
	},

	before: function() {
		if ( this[0] && this[0].parentNode ) {
			return this.domManip(arguments, false, function( elem ) {
				this.parentNode.insertBefore( elem, this );
			});
		} else if ( arguments.length ) {
			var set = jQuery(arguments[0]);
			set.push.apply( set, this.toArray() );
			return this.pushStack( set, "before", arguments );
		}
	},

	after: function() {
		if ( this[0] && this[0].parentNode ) {
			return this.domManip(arguments, false, function( elem ) {
				this.parentNode.insertBefore( elem, this.nextSibling );
			});
		} else if ( arguments.length ) {
			var set = this.pushStack( this, "after", arguments );
			set.push.apply( set, jQuery(arguments[0]).toArray() );
			return set;
		}
	},
	
	// keepData is for internal use only--do not document
	remove: function( selector, keepData ) {
		for ( var i = 0, elem; (elem = this[i]) != null; i++ ) {
			if ( !selector || jQuery.filter( selector, [ elem ] ).length ) {
				if ( !keepData && elem.nodeType === 1 ) {
					jQuery.cleanData( elem.getElementsByTagName("*") );
					jQuery.cleanData( [ elem ] );
				}

				if ( elem.parentNode ) {
					 elem.parentNode.removeChild( elem );
				}
			}
		}
		
		return this;
	},

	empty: function() {
		for ( var i = 0, elem; (elem = this[i]) != null; i++ ) {
			// Remove element nodes and prevent memory leaks
			if ( elem.nodeType === 1 ) {
				jQuery.cleanData( elem.getElementsByTagName("*") );
			}

			// Remove any remaining nodes
			while ( elem.firstChild ) {
				elem.removeChild( elem.firstChild );
			}
		}
		
		return this;
	},

	clone: function( events ) {
		// Do the clone
		var ret = this.map(function() {
			if ( !jQuery.support.noCloneEvent && !jQuery.isXMLDoc(this) ) {
				// IE copies events bound via attachEvent when
				// using cloneNode. Calling detachEvent on the
				// clone will also remove the events from the orignal
				// In order to get around this, we use innerHTML.
				// Unfortunately, this means some modifications to
				// attributes in IE that are actually only stored
				// as properties will not be copied (such as the
				// the name attribute on an input).
				var html = this.outerHTML, ownerDocument = this.ownerDocument;
				if ( !html ) {
					var div = ownerDocument.createElement("div");
					div.appendChild( this.cloneNode(true) );
					html = div.innerHTML;
				}

				return jQuery.clean([html.replace(rinlinejQuery, "")
					// Handle the case in IE 8 where action=/test/> self-closes a tag
					.replace(/=([^="'>\s]+\/)>/g, '="$1">')
					.replace(rleadingWhitespace, "")], ownerDocument)[0];
			} else {
				return this.cloneNode(true);
			}
		});

		// Copy the events from the original to the clone
		if ( events === true ) {
			cloneCopyEvent( this, ret );
			cloneCopyEvent( this.find("*"), ret.find("*") );
		}

		// Return the cloned set
		return ret;
	},

	html: function( value ) {
		if ( value === undefined ) {
			return this[0] && this[0].nodeType === 1 ?
				this[0].innerHTML.replace(rinlinejQuery, "") :
				null;

		// See if we can take a shortcut and just use innerHTML
		} else if ( typeof value === "string" && !rnocache.test( value ) &&
			(jQuery.support.leadingWhitespace || !rleadingWhitespace.test( value )) &&
			!wrapMap[ (rtagName.exec( value ) || ["", ""])[1].toLowerCase() ] ) {

			value = value.replace(rxhtmlTag, fcloseTag);

			try {
				for ( var i = 0, l = this.length; i < l; i++ ) {
					// Remove element nodes and prevent memory leaks
					if ( this[i].nodeType === 1 ) {
						jQuery.cleanData( this[i].getElementsByTagName("*") );
						this[i].innerHTML = value;
					}
				}

			// If using innerHTML throws an exception, use the fallback method
			} catch(e) {
				this.empty().append( value );
			}

		} else if ( jQuery.isFunction( value ) ) {
			this.each(function(i){
				var self = jQuery(this), old = self.html();
				self.empty().append(function(){
					return value.call( this, i, old );
				});
			});

		} else {
			this.empty().append( value );
		}

		return this;
	},

	replaceWith: function( value ) {
		if ( this[0] && this[0].parentNode ) {
			// Make sure that the elements are removed from the DOM before they are inserted
			// this can help fix replacing a parent with child elements
			if ( jQuery.isFunction( value ) ) {
				return this.each(function(i) {
					var self = jQuery(this), old = self.html();
					self.replaceWith( value.call( this, i, old ) );
				});
			}

			if ( typeof value !== "string" ) {
				value = jQuery(value).detach();
			}

			return this.each(function() {
				var next = this.nextSibling, parent = this.parentNode;

				jQuery(this).remove();

				if ( next ) {
					jQuery(next).before( value );
				} else {
					jQuery(parent).append( value );
				}
			});
		} else {
			return this.pushStack( jQuery(jQuery.isFunction(value) ? value() : value), "replaceWith", value );
		}
	},

	detach: function( selector ) {
		return this.remove( selector, true );
	},

	domManip: function( args, table, callback ) {
		var results, first, value = args[0], scripts = [], fragment, parent;

		// We can't cloneNode fragments that contain checked, in WebKit
		if ( !jQuery.support.checkClone && arguments.length === 3 && typeof value === "string" && rchecked.test( value ) ) {
			return this.each(function() {
				jQuery(this).domManip( args, table, callback, true );
			});
		}

		if ( jQuery.isFunction(value) ) {
			return this.each(function(i) {
				var self = jQuery(this);
				args[0] = value.call(this, i, table ? self.html() : undefined);
				self.domManip( args, table, callback );
			});
		}

		if ( this[0] ) {
			parent = value && value.parentNode;

			// If we're in a fragment, just use that instead of building a new one
			if ( jQuery.support.parentNode && parent && parent.nodeType === 11 && parent.childNodes.length === this.length ) {
				results = { fragment: parent };

			} else {
				results = buildFragment( args, this, scripts );
			}
			
			fragment = results.fragment;
			
			if ( fragment.childNodes.length === 1 ) {
				first = fragment = fragment.firstChild;
			} else {
				first = fragment.firstChild;
			}

			if ( first ) {
				table = table && jQuery.nodeName( first, "tr" );

				for ( var i = 0, l = this.length; i < l; i++ ) {
					callback.call(
						table ?
							root(this[i], first) :
							this[i],
						i > 0 || results.cacheable || this.length > 1  ?
							fragment.cloneNode(true) :
							fragment
					);
				}
			}

			if ( scripts.length ) {
				jQuery.each( scripts, evalScript );
			}
		}

		return this;

		function root( elem, cur ) {
			return jQuery.nodeName(elem, "table") ?
				(elem.getElementsByTagName("tbody")[0] ||
				elem.appendChild(elem.ownerDocument.createElement("tbody"))) :
				elem;
		}
	}
});

function cloneCopyEvent(orig, ret) {
	var i = 0;

	ret.each(function() {
		if ( this.nodeName !== (orig[i] && orig[i].nodeName) ) {
			return;
		}

		var oldData = jQuery.data( orig[i++] ), curData = jQuery.data( this, oldData ), events = oldData && oldData.events;

		if ( events ) {
			delete curData.handle;
			curData.events = {};

			for ( var type in events ) {
				for ( var handler in events[ type ] ) {
					jQuery.event.add( this, type, events[ type ][ handler ], events[ type ][ handler ].data );
				}
			}
		}
	});
}

function buildFragment( args, nodes, scripts ) {
	var fragment, cacheable, cacheresults,
		doc = (nodes && nodes[0] ? nodes[0].ownerDocument || nodes[0] : document);

	// Only cache "small" (1/2 KB) strings that are associated with the main document
	// Cloning options loses the selected state, so don't cache them
	// IE 6 doesn't like it when you put <object> or <embed> elements in a fragment
	// Also, WebKit does not clone 'checked' attributes on cloneNode, so don't cache
	if ( args.length === 1 && typeof args[0] === "string" && args[0].length < 512 && doc === document &&
		!rnocache.test( args[0] ) && (jQuery.support.checkClone || !rchecked.test( args[0] )) ) {

		cacheable = true;
		cacheresults = jQuery.fragments[ args[0] ];
		if ( cacheresults ) {
			if ( cacheresults !== 1 ) {
				fragment = cacheresults;
			}
		}
	}

	if ( !fragment ) {
		fragment = doc.createDocumentFragment();
		jQuery.clean( args, doc, fragment, scripts );
	}

	if ( cacheable ) {
		jQuery.fragments[ args[0] ] = cacheresults ? fragment : 1;
	}

	return { fragment: fragment, cacheable: cacheable };
}

jQuery.fragments = {};

jQuery.each({
	appendTo: "append",
	prependTo: "prepend",
	insertBefore: "before",
	insertAfter: "after",
	replaceAll: "replaceWith"
}, function( name, original ) {
	jQuery.fn[ name ] = function( selector ) {
		var ret = [], insert = jQuery( selector ),
			parent = this.length === 1 && this[0].parentNode;
		
		if ( parent && parent.nodeType === 11 && parent.childNodes.length === 1 && insert.length === 1 ) {
			insert[ original ]( this[0] );
			return this;
			
		} else {
			for ( var i = 0, l = insert.length; i < l; i++ ) {
				var elems = (i > 0 ? this.clone(true) : this).get();
				jQuery.fn[ original ].apply( jQuery(insert[i]), elems );
				ret = ret.concat( elems );
			}
		
			return this.pushStack( ret, name, insert.selector );
		}
	};
});

jQuery.extend({
	clean: function( elems, context, fragment, scripts ) {
		context = context || document;

		// !context.createElement fails in IE with an error but returns typeof 'object'
		if ( typeof context.createElement === "undefined" ) {
			context = context.ownerDocument || context[0] && context[0].ownerDocument || document;
		}

		var ret = [];

		for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
			if ( typeof elem === "number" ) {
				elem += "";
			}

			if ( !elem ) {
				continue;
			}

			// Convert html string into DOM nodes
			if ( typeof elem === "string" && !rhtml.test( elem ) ) {
				elem = context.createTextNode( elem );

			} else if ( typeof elem === "string" ) {
				// Fix "XHTML"-style tags in all browsers
				elem = elem.replace(rxhtmlTag, fcloseTag);

				// Trim whitespace, otherwise indexOf won't work as expected
				var tag = (rtagName.exec( elem ) || ["", ""])[1].toLowerCase(),
					wrap = wrapMap[ tag ] || wrapMap._default,
					depth = wrap[0],
					div = context.createElement("div");

				// Go to html and back, then peel off extra wrappers
				div.innerHTML = wrap[1] + elem + wrap[2];

				// Move to the right depth
				while ( depth-- ) {
					div = div.lastChild;
				}

				// Remove IE's autoinserted <tbody> from table fragments
				if ( !jQuery.support.tbody ) {

					// String was a <table>, *may* have spurious <tbody>
					var hasBody = rtbody.test(elem),
						tbody = tag === "table" && !hasBody ?
							div.firstChild && div.firstChild.childNodes :

							// String was a bare <thead> or <tfoot>
							wrap[1] === "<table>" && !hasBody ?
								div.childNodes :
								[];

					for ( var j = tbody.length - 1; j >= 0 ; --j ) {
						if ( jQuery.nodeName( tbody[ j ], "tbody" ) && !tbody[ j ].childNodes.length ) {
							tbody[ j ].parentNode.removeChild( tbody[ j ] );
						}
					}

				}

				// IE completely kills leading whitespace when innerHTML is used
				if ( !jQuery.support.leadingWhitespace && rleadingWhitespace.test( elem ) ) {
					div.insertBefore( context.createTextNode( rleadingWhitespace.exec(elem)[0] ), div.firstChild );
				}

				elem = div.childNodes;
			}

			if ( elem.nodeType ) {
				ret.push( elem );
			} else {
				ret = jQuery.merge( ret, elem );
			}
		}

		if ( fragment ) {
			for ( var i = 0; ret[i]; i++ ) {
				if ( scripts && jQuery.nodeName( ret[i], "script" ) && (!ret[i].type || ret[i].type.toLowerCase() === "text/javascript") ) {
					scripts.push( ret[i].parentNode ? ret[i].parentNode.removeChild( ret[i] ) : ret[i] );
				
				} else {
					if ( ret[i].nodeType === 1 ) {
						ret.splice.apply( ret, [i + 1, 0].concat(jQuery.makeArray(ret[i].getElementsByTagName("script"))) );
					}
					fragment.appendChild( ret[i] );
				}
			}
		}

		return ret;
	},
	
	cleanData: function( elems ) {
		var data, id, cache = jQuery.cache,
			special = jQuery.event.special,
			deleteExpando = jQuery.support.deleteExpando;
		
		for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
			id = elem[ jQuery.expando ];
			
			if ( id ) {
				data = cache[ id ];
				
				if ( data.events ) {
					for ( var type in data.events ) {
						if ( special[ type ] ) {
							jQuery.event.remove( elem, type );

						} else {
							removeEvent( elem, type, data.handle );
						}
					}
				}
				
				if ( deleteExpando ) {
					delete elem[ jQuery.expando ];

				} else if ( elem.removeAttribute ) {
					elem.removeAttribute( jQuery.expando );
				}
				
				delete cache[ id ];
			}
		}
	}
});
// exclude the following css properties to add px
var rexclude = /z-?index|font-?weight|opacity|zoom|line-?height/i,
	ralpha = /alpha\([^)]*\)/,
	ropacity = /opacity=([^)]*)/,
	rfloat = /float/i,
	rdashAlpha = /-([a-z])/ig,
	rupper = /([A-Z])/g,
	rnumpx = /^-?\d+(?:px)?$/i,
	rnum = /^-?\d/,

	cssShow = { position: "absolute", visibility: "hidden", display:"block" },
	cssWidth = [ "Left", "Right" ],
	cssHeight = [ "Top", "Bottom" ],

	// cache check for defaultView.getComputedStyle
	getComputedStyle = document.defaultView && document.defaultView.getComputedStyle,
	// normalize float css property
	styleFloat = jQuery.support.cssFloat ? "cssFloat" : "styleFloat",
	fcamelCase = function( all, letter ) {
		return letter.toUpperCase();
	};

jQuery.fn.css = function( name, value ) {
	return access( this, name, value, true, function( elem, name, value ) {
		if ( value === undefined ) {
			return jQuery.curCSS( elem, name );
		}
		
		if ( typeof value === "number" && !rexclude.test(name) ) {
			value += "px";
		}

		jQuery.style( elem, name, value );
	});
};

jQuery.extend({
	style: function( elem, name, value ) {
		// don't set styles on text and comment nodes
		if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 ) {
			return undefined;
		}

		// ignore negative width and height values #1599
		if ( (name === "width" || name === "height") && parseFloat(value) < 0 ) {
			value = undefined;
		}

		var style = elem.style || elem, set = value !== undefined;

		// IE uses filters for opacity
		if ( !jQuery.support.opacity && name === "opacity" ) {
			if ( set ) {
				// IE has trouble with opacity if it does not have layout
				// Force it by setting the zoom level
				style.zoom = 1;

				// Set the alpha filter to set the opacity
				var opacity = parseInt( value, 10 ) + "" === "NaN" ? "" : "alpha(opacity=" + value * 100 + ")";
				var filter = style.filter || jQuery.curCSS( elem, "filter" ) || "";
				style.filter = ralpha.test(filter) ? filter.replace(ralpha, opacity) : opacity;
			}

			return style.filter && style.filter.indexOf("opacity=") >= 0 ?
				(parseFloat( ropacity.exec(style.filter)[1] ) / 100) + "":
				"";
		}

		// Make sure we're using the right name for getting the float value
		if ( rfloat.test( name ) ) {
			name = styleFloat;
		}

		name = name.replace(rdashAlpha, fcamelCase);

		if ( set ) {
			style[ name ] = value;
		}

		return style[ name ];
	},

	css: function( elem, name, force, extra ) {
		if ( name === "width" || name === "height" ) {
			var val, props = cssShow, which = name === "width" ? cssWidth : cssHeight;

			function getWH() {
				val = name === "width" ? elem.offsetWidth : elem.offsetHeight;

				if ( extra === "border" ) {
					return;
				}

				jQuery.each( which, function() {
					if ( !extra ) {
						val -= parseFloat(jQuery.curCSS( elem, "padding" + this, true)) || 0;
					}

					if ( extra === "margin" ) {
						val += parseFloat(jQuery.curCSS( elem, "margin" + this, true)) || 0;
					} else {
						val -= parseFloat(jQuery.curCSS( elem, "border" + this + "Width", true)) || 0;
					}
				});
			}

			if ( elem.offsetWidth !== 0 ) {
				getWH();
			} else {
				jQuery.swap( elem, props, getWH );
			}

			return Math.max(0, Math.round(val));
		}

		return jQuery.curCSS( elem, name, force );
	},

	curCSS: function( elem, name, force ) {
		var ret, style = elem.style, filter;

		// IE uses filters for opacity
		if ( !jQuery.support.opacity && name === "opacity" && elem.currentStyle ) {
			ret = ropacity.test(elem.currentStyle.filter || "") ?
				(parseFloat(RegExp.$1) / 100) + "" :
				"";

			return ret === "" ?
				"1" :
				ret;
		}

		// Make sure we're using the right name for getting the float value
		if ( rfloat.test( name ) ) {
			name = styleFloat;
		}

		if ( !force && style && style[ name ] ) {
			ret = style[ name ];

		} else if ( getComputedStyle ) {

			// Only "float" is needed here
			if ( rfloat.test( name ) ) {
				name = "float";
			}

			name = name.replace( rupper, "-$1" ).toLowerCase();

			var defaultView = elem.ownerDocument.defaultView;

			if ( !defaultView ) {
				return null;
			}

			var computedStyle = defaultView.getComputedStyle( elem, null );

			if ( computedStyle ) {
				ret = computedStyle.getPropertyValue( name );
			}

			// We should always get a number back from opacity
			if ( name === "opacity" && ret === "" ) {
				ret = "1";
			}

		} else if ( elem.currentStyle ) {
			var camelCase = name.replace(rdashAlpha, fcamelCase);

			ret = elem.currentStyle[ name ] || elem.currentStyle[ camelCase ];

			// From the awesome hack by Dean Edwards
			// http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291

			// If we're not dealing with a regular pixel number
			// but a number that has a weird ending, we need to convert it to pixels
			if ( !rnumpx.test( ret ) && rnum.test( ret ) ) {
				// Remember the original values
				var left = style.left, rsLeft = elem.runtimeStyle.left;

				// Put in the new values to get a computed value out
				elem.runtimeStyle.left = elem.currentStyle.left;
				style.left = camelCase === "fontSize" ? "1em" : (ret || 0);
				ret = style.pixelLeft + "px";

				// Revert the changed values
				style.left = left;
				elem.runtimeStyle.left = rsLeft;
			}
		}

		return ret;
	},

	// A method for quickly swapping in/out CSS properties to get correct calculations
	swap: function( elem, options, callback ) {
		var old = {};

		// Remember the old values, and insert the new ones
		for ( var name in options ) {
			old[ name ] = elem.style[ name ];
			elem.style[ name ] = options[ name ];
		}

		callback.call( elem );

		// Revert the old values
		for ( var name in options ) {
			elem.style[ name ] = old[ name ];
		}
	}
});

if ( jQuery.expr && jQuery.expr.filters ) {
	jQuery.expr.filters.hidden = function( elem ) {
		var width = elem.offsetWidth, height = elem.offsetHeight,
			skip = elem.nodeName.toLowerCase() === "tr";

		return width === 0 && height === 0 && !skip ?
			true :
			width > 0 && height > 0 && !skip ?
				false :
				jQuery.curCSS(elem, "display") === "none";
	};

	jQuery.expr.filters.visible = function( elem ) {
		return !jQuery.expr.filters.hidden( elem );
	};
}
var jsc = now(),
	rscript = /<script(.|\s)*?\/script>/gi,
	rselectTextarea = /select|textarea/i,
	rinput = /color|date|datetime|email|hidden|month|number|password|range|search|tel|text|time|url|week/i,
	jsre = /=\?(&|$)/,
	rquery = /\?/,
	rts = /(\?|&)_=.*?(&|$)/,
	rurl = /^(\w+:)?\/\/([^\/?#]+)/,
	r20 = /%20/g,

	// Keep a copy of the old load method
	_load = jQuery.fn.load;

jQuery.fn.extend({
	load: function( url, params, callback ) {
		if ( typeof url !== "string" ) {
			return _load.call( this, url );

		// Don't do a request if no elements are being requested
		} else if ( !this.length ) {
			return this;
		}

		var off = url.indexOf(" ");
		if ( off >= 0 ) {
			var selector = url.slice(off, url.length);
			url = url.slice(0, off);
		}

		// Default to a GET request
		var type = "GET";

		// If the second parameter was provided
		if ( params ) {
			// If it's a function
			if ( jQuery.isFunction( params ) ) {
				// We assume that it's the callback
				callback = params;
				params = null;

			// Otherwise, build a param string
			} else if ( typeof params === "object" ) {
				params = jQuery.param( params, jQuery.ajaxSettings.traditional );
				type = "POST";
			}
		}

		var self = this;

		// Request the remote document
		jQuery.ajax({
			url: url,
			type: type,
			dataType: "html",
			data: params,
			complete: function( res, status ) {
				// If successful, inject the HTML into all the matched elements
				if ( status === "success" || status === "notmodified" ) {
					// See if a selector was specified
					self.html( selector ?
						// Create a dummy div to hold the results
						jQuery("<div />")
							// inject the contents of the document in, removing the scripts
							// to avoid any 'Permission Denied' errors in IE
							.append(res.responseText.replace(rscript, ""))

							// Locate the specified elements
							.find(selector) :

						// If not, just inject the full result
						res.responseText );
				}

				if ( callback ) {
					self.each( callback, [res.responseText, status, res] );
				}
			}
		});

		return this;
	},

	serialize: function() {
		return jQuery.param(this.serializeArray());
	},
	serializeArray: function() {
		return this.map(function() {
			return this.elements ? jQuery.makeArray(this.elements) : this;
		})
		.filter(function() {
			return this.name && !this.disabled &&
				(this.checked || rselectTextarea.test(this.nodeName) ||
					rinput.test(this.type));
		})
		.map(function( i, elem ) {
			var val = jQuery(this).val();

			return val == null ?
				null :
				jQuery.isArray(val) ?
					jQuery.map( val, function( val, i ) {
						return { name: elem.name, value: val };
					}) :
					{ name: elem.name, value: val };
		}).get();
	}
});

// Attach a bunch of functions for handling common AJAX events
jQuery.each( "ajaxStart ajaxStop ajaxComplete ajaxError ajaxSuccess ajaxSend".split(" "), function( i, o ) {
	jQuery.fn[o] = function( f ) {
		return this.bind(o, f);
	};
});

jQuery.extend({

	get: function( url, data, callback, type ) {
		// shift arguments if data argument was omited
		if ( jQuery.isFunction( data ) ) {
			type = type || callback;
			callback = data;
			data = null;
		}

		return jQuery.ajax({
			type: "GET",
			url: url,
			data: data,
			success: callback,
			dataType: type
		});
	},

	getScript: function( url, callback ) {
		return jQuery.get(url, null, callback, "script");
	},

	getJSON: function( url, data, callback ) {
		return jQuery.get(url, data, callback, "json");
	},

	post: function( url, data, callback, type ) {
		// shift arguments if data argument was omited
		if ( jQuery.isFunction( data ) ) {
			type = type || callback;
			callback = data;
			data = {};
		}

		return jQuery.ajax({
			type: "POST",
			url: url,
			data: data,
			success: callback,
			dataType: type
		});
	},

	ajaxSetup: function( settings ) {
		jQuery.extend( jQuery.ajaxSettings, settings );
	},

	ajaxSettings: {
		url: location.href,
		global: true,
		type: "GET",
		contentType: "application/x-www-form-urlencoded",
		processData: true,
		async: true,
		/*
		timeout: 0,
		data: null,
		username: null,
		password: null,
		traditional: false,
		*/
		// Create the request object; Microsoft failed to properly
		// implement the XMLHttpRequest in IE7 (can't request local files),
		// so we use the ActiveXObject when it is available
		// This function can be overriden by calling jQuery.ajaxSetup
		xhr: window.XMLHttpRequest && (window.location.protocol !== "file:" || !window.ActiveXObject) ?
			function() {
				return new window.XMLHttpRequest();
			} :
			function() {
				try {
					return new window.ActiveXObject("Microsoft.XMLHTTP");
				} catch(e) {}
			},
		accepts: {
			xml: "application/xml, text/xml",
			html: "text/html",
			script: "text/javascript, application/javascript",
			json: "application/json, text/javascript",
			text: "text/plain",
			_default: "*/*"
		}
	},

	// Last-Modified header cache for next request
	lastModified: {},
	etag: {},

	ajax: function( origSettings ) {
		var s = jQuery.extend(true, {}, jQuery.ajaxSettings, origSettings);
		
		var jsonp, status, data,
			callbackContext = origSettings && origSettings.context || s,
			type = s.type.toUpperCase();

		// convert data if not already a string
		if ( s.data && s.processData && typeof s.data !== "string" ) {
			s.data = jQuery.param( s.data, s.traditional );
		}

		// Handle JSONP Parameter Callbacks
		if ( s.dataType === "jsonp" ) {
			if ( type === "GET" ) {
				if ( !jsre.test( s.url ) ) {
					s.url += (rquery.test( s.url ) ? "&" : "?") + (s.jsonp || "callback") + "=?";
				}
			} else if ( !s.data || !jsre.test(s.data) ) {
				s.data = (s.data ? s.data + "&" : "") + (s.jsonp || "callback") + "=?";
			}
			s.dataType = "json";
		}

		// Build temporary JSONP function
		if ( s.dataType === "json" && (s.data && jsre.test(s.data) || jsre.test(s.url)) ) {
			jsonp = s.jsonpCallback || ("jsonp" + jsc++);

			// Replace the =? sequence both in the query string and the data
			if ( s.data ) {
				s.data = (s.data + "").replace(jsre, "=" + jsonp + "$1");
			}

			s.url = s.url.replace(jsre, "=" + jsonp + "$1");

			// We need to make sure
			// that a JSONP style response is executed properly
			s.dataType = "script";

			// Handle JSONP-style loading
			window[ jsonp ] = window[ jsonp ] || function( tmp ) {
				data = tmp;
				success();
				complete();
				// Garbage collect
				window[ jsonp ] = undefined;

				try {
					delete window[ jsonp ];
				} catch(e) {}

				if ( head ) {
					head.removeChild( script );
				}
			};
		}

		if ( s.dataType === "script" && s.cache === null ) {
			s.cache = false;
		}

		if ( s.cache === false && type === "GET" ) {
			var ts = now();

			// try replacing _= if it is there
			var ret = s.url.replace(rts, "$1_=" + ts + "$2");

			// if nothing was replaced, add timestamp to the end
			s.url = ret + ((ret === s.url) ? (rquery.test(s.url) ? "&" : "?") + "_=" + ts : "");
		}

		// If data is available, append data to url for get requests
		if ( s.data && type === "GET" ) {
			s.url += (rquery.test(s.url) ? "&" : "?") + s.data;
		}

		// Watch for a new set of requests
		if ( s.global && ! jQuery.active++ ) {
			jQuery.event.trigger( "ajaxStart" );
		}

		// Matches an absolute URL, and saves the domain
		var parts = rurl.exec( s.url ),
			remote = parts && (parts[1] && parts[1] !== location.protocol || parts[2] !== location.host);

		// If we're requesting a remote document
		// and trying to load JSON or Script with a GET
		if ( s.dataType === "script" && type === "GET" && remote ) {
			var head = document.getElementsByTagName("head")[0] || document.documentElement;
			var script = document.createElement("script");
			script.src = s.url;
			if ( s.scriptCharset ) {
				script.charset = s.scriptCharset;
			}

			// Handle Script loading
			if ( !jsonp ) {
				var done = false;

				// Attach handlers for all browsers
				script.onload = script.onreadystatechange = function() {
					if ( !done && (!this.readyState ||
							this.readyState === "loaded" || this.readyState === "complete") ) {
						done = true;
						success();
						complete();

						// Handle memory leak in IE
						script.onload = script.onreadystatechange = null;
						if ( head && script.parentNode ) {
							head.removeChild( script );
						}
					}
				};
			}

			// Use insertBefore instead of appendChild  to circumvent an IE6 bug.
			// This arises when a base node is used (#2709 and #4378).
			head.insertBefore( script, head.firstChild );

			// We handle everything using the script element injection
			return undefined;
		}

		var requestDone = false;

		// Create the request object
		var xhr = s.xhr();

		if ( !xhr ) {
			return;
		}

		// Open the socket
		// Passing null username, generates a login popup on Opera (#2865)
		if ( s.username ) {
			xhr.open(type, s.url, s.async, s.username, s.password);
		} else {
			xhr.open(type, s.url, s.async);
		}

		// Need an extra try/catch for cross domain requests in Firefox 3
		try {
			// Set the correct header, if data is being sent
			if ( s.data || origSettings && origSettings.contentType ) {
				xhr.setRequestHeader("Content-Type", s.contentType);
			}

			// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
			if ( s.ifModified ) {
				if ( jQuery.lastModified[s.url] ) {
					xhr.setRequestHeader("If-Modified-Since", jQuery.lastModified[s.url]);
				}

				if ( jQuery.etag[s.url] ) {
					xhr.setRequestHeader("If-None-Match", jQuery.etag[s.url]);
				}
			}

			// Set header so the called script knows that it's an XMLHttpRequest
			// Only send the header if it's not a remote XHR
			if ( !remote ) {
				xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
			}

			// Set the Accepts header for the server, depending on the dataType
			xhr.setRequestHeader("Accept", s.dataType && s.accepts[ s.dataType ] ?
				s.accepts[ s.dataType ] + ", */*" :
				s.accepts._default );
		} catch(e) {}

		// Allow custom headers/mimetypes and early abort
		if ( s.beforeSend && s.beforeSend.call(callbackContext, xhr, s) === false ) {
			// Handle the global AJAX counter
			if ( s.global && ! --jQuery.active ) {
				jQuery.event.trigger( "ajaxStop" );
			}

			// close opended socket
			xhr.abort();
			return false;
		}

		if ( s.global ) {
			trigger("ajaxSend", [xhr, s]);
		}

		// Wait for a response to come back
		var onreadystatechange = xhr.onreadystatechange = function( isTimeout ) {
			// The request was aborted
			if ( !xhr || xhr.readyState === 0 || isTimeout === "abort" ) {
				// Opera doesn't call onreadystatechange before this point
				// so we simulate the call
				if ( !requestDone ) {
					complete();
				}

				requestDone = true;
				if ( xhr ) {
					xhr.onreadystatechange = jQuery.noop;
				}

			// The transfer is complete and the data is available, or the request timed out
			} else if ( !requestDone && xhr && (xhr.readyState === 4 || isTimeout === "timeout") ) {
				requestDone = true;
				xhr.onreadystatechange = jQuery.noop;

				status = isTimeout === "timeout" ?
					"timeout" :
					!jQuery.httpSuccess( xhr ) ?
						"error" :
						s.ifModified && jQuery.httpNotModified( xhr, s.url ) ?
							"notmodified" :
							"success";

				var errMsg;

				if ( status === "success" ) {
					// Watch for, and catch, XML document parse errors
					try {
						// process the data (runs the xml through httpData regardless of callback)
						data = jQuery.httpData( xhr, s.dataType, s );
					} catch(err) {
						status = "parsererror";
						errMsg = err;
					}
				}

				// Make sure that the request was successful or notmodified
				if ( status === "success" || status === "notmodified" ) {
					// JSONP handles its own success callback
					if ( !jsonp ) {
						success();
					}
				} else {
					jQuery.handleError(s, xhr, status, errMsg);
				}

				// Fire the complete handlers
				complete();

				if ( isTimeout === "timeout" ) {
					xhr.abort();
				}

				// Stop memory leaks
				if ( s.async ) {
					xhr = null;
				}
			}
		};

		// Override the abort handler, if we can (IE doesn't allow it, but that's OK)
		// Opera doesn't fire onreadystatechange at all on abort
		try {
			var oldAbort = xhr.abort;
			xhr.abort = function() {
				if ( xhr ) {
					oldAbort.call( xhr );
				}

				onreadystatechange( "abort" );
			};
		} catch(e) { }

		// Timeout checker
		if ( s.async && s.timeout > 0 ) {
			setTimeout(function() {
				// Check to see if the request is still happening
				if ( xhr && !requestDone ) {
					onreadystatechange( "timeout" );
				}
			}, s.timeout);
		}

		// Send the data
		try {
			xhr.send( type === "POST" || type === "PUT" || type === "DELETE" ? s.data : null );
		} catch(e) {
			jQuery.handleError(s, xhr, null, e);
			// Fire the complete handlers
			complete();
		}

		// firefox 1.5 doesn't fire statechange for sync requests
		if ( !s.async ) {
			onreadystatechange();
		}

		function success() {
			// If a local callback was specified, fire it and pass it the data
			if ( s.success ) {
				s.success.call( callbackContext, data, status, xhr );
			}

			// Fire the global callback
			if ( s.global ) {
				trigger( "ajaxSuccess", [xhr, s] );
			}
		}

		function complete() {
			// Process result
			if ( s.complete ) {
				s.complete.call( callbackContext, xhr, status);
			}

			// The request was completed
			if ( s.global ) {
				trigger( "ajaxComplete", [xhr, s] );
			}

			// Handle the global AJAX counter
			if ( s.global && ! --jQuery.active ) {
				jQuery.event.trigger( "ajaxStop" );
			}
		}
		
		function trigger(type, args) {
			(s.context ? jQuery(s.context) : jQuery.event).trigger(type, args);
		}

		// return XMLHttpRequest to allow aborting the request etc.
		return xhr;
	},

	handleError: function( s, xhr, status, e ) {
		// If a local callback was specified, fire it
		if ( s.error ) {
			s.error.call( s.context || s, xhr, status, e );
		}

		// Fire the global callback
		if ( s.global ) {
			(s.context ? jQuery(s.context) : jQuery.event).trigger( "ajaxError", [xhr, s, e] );
		}
	},

	// Counter for holding the number of active queries
	active: 0,

	// Determines if an XMLHttpRequest was successful or not
	httpSuccess: function( xhr ) {
		try {
			// IE error sometimes returns 1223 when it should be 204 so treat it as success, see #1450
			return !xhr.status && location.protocol === "file:" ||
				// Opera returns 0 when status is 304
				( xhr.status >= 200 && xhr.status < 300 ) ||
				xhr.status === 304 || xhr.status === 1223 || xhr.status === 0;
		} catch(e) {}

		return false;
	},

	// Determines if an XMLHttpRequest returns NotModified
	httpNotModified: function( xhr, url ) {
		var lastModified = xhr.getResponseHeader("Last-Modified"),
			etag = xhr.getResponseHeader("Etag");

		if ( lastModified ) {
			jQuery.lastModified[url] = lastModified;
		}

		if ( etag ) {
			jQuery.etag[url] = etag;
		}

		// Opera returns 0 when status is 304
		return xhr.status === 304 || xhr.status === 0;
	},

	httpData: function( xhr, type, s ) {
		var ct = xhr.getResponseHeader("content-type") || "",
			xml = type === "xml" || !type && ct.indexOf("xml") >= 0,
			data = xml ? xhr.responseXML : xhr.responseText;

		if ( xml && data.documentElement.nodeName === "parsererror" ) {
			jQuery.error( "parsererror" );
		}

		// Allow a pre-filtering function to sanitize the response
		// s is checked to keep backwards compatibility
		if ( s && s.dataFilter ) {
			data = s.dataFilter( data, type );
		}

		// The filter can actually parse the response
		if ( typeof data === "string" ) {
			// Get the JavaScript object, if JSON is used.
			if ( type === "json" || !type && ct.indexOf("json") >= 0 ) {
				data = jQuery.parseJSON( data );

			// If the type is "script", eval it in global context
			} else if ( type === "script" || !type && ct.indexOf("javascript") >= 0 ) {
				jQuery.globalEval( data );
			}
		}

		return data;
	},

	// Serialize an array of form elements or a set of
	// key/values into a query string
	param: function( a, traditional ) {
		var s = [];
		
		// Set traditional to true for jQuery <= 1.3.2 behavior.
		if ( traditional === undefined ) {
			traditional = jQuery.ajaxSettings.traditional;
		}
		
		// If an array was passed in, assume that it is an array of form elements.
		if ( jQuery.isArray(a) || a.jquery ) {
			// Serialize the form elements
			jQuery.each( a, function() {
				add( this.name, this.value );
			});
			
		} else {
			// If traditional, encode the "old" way (the way 1.3.2 or older
			// did it), otherwise encode params recursively.
			for ( var prefix in a ) {
				buildParams( prefix, a[prefix] );
			}
		}

		// Return the resulting serialization
		return s.join("&").replace(r20, "+");

		function buildParams( prefix, obj ) {
			if ( jQuery.isArray(obj) ) {
				// Serialize array item.
				jQuery.each( obj, function( i, v ) {
					if ( traditional || /\[\]$/.test( prefix ) ) {
						// Treat each array item as a scalar.
						add( prefix, v );
					} else {
						// If array item is non-scalar (array or object), encode its
						// numeric index to resolve deserialization ambiguity issues.
						// Note that rack (as of 1.0.0) can't currently deserialize
						// nested arrays properly, and attempting to do so may cause
						// a server error. Possible fixes are to modify rack's
						// deserialization algorithm or to provide an option or flag
						// to force array serialization to be shallow.
						buildParams( prefix + "[" + ( typeof v === "object" || jQuery.isArray(v) ? i : "" ) + "]", v );
					}
				});
					
			} else if ( !traditional && obj != null && typeof obj === "object" ) {
				// Serialize object item.
				jQuery.each( obj, function( k, v ) {
					buildParams( prefix + "[" + k + "]", v );
				});
					
			} else {
				// Serialize scalar item.
				add( prefix, obj );
			}
		}

		function add( key, value ) {
			// If value is a function, invoke it and return its value
			value = jQuery.isFunction(value) ? value() : value;
			s[ s.length ] = encodeURIComponent(key) + "=" + encodeURIComponent(value);
		}
	}
});
var elemdisplay = {},
	rfxtypes = /toggle|show|hide/,
	rfxnum = /^([+-]=)?([\d+-.]+)(.*)$/,
	timerId,
	fxAttrs = [
		// height animations
		[ "height", "marginTop", "marginBottom", "paddingTop", "paddingBottom" ],
		// width animations
		[ "width", "marginLeft", "marginRight", "paddingLeft", "paddingRight" ],
		// opacity animations
		[ "opacity" ]
	];

jQuery.fn.extend({
	show: function( speed, callback ) {
		if ( speed || speed === 0) {
			return this.animate( genFx("show", 3), speed, callback);

		} else {
			for ( var i = 0, l = this.length; i < l; i++ ) {
				var old = jQuery.data(this[i], "olddisplay");

				this[i].style.display = old || "";

				if ( jQuery.css(this[i], "display") === "none" ) {
					var nodeName = this[i].nodeName, display;

					if ( elemdisplay[ nodeName ] ) {
						display = elemdisplay[ nodeName ];

					} else {
						var elem = jQuery("<" + nodeName + " />").appendTo("body");

						display = elem.css("display");

						if ( display === "none" ) {
							display = "block";
						}

						elem.remove();

						elemdisplay[ nodeName ] = display;
					}

					jQuery.data(this[i], "olddisplay", display);
				}
			}

			// Set the display of the elements in a second loop
			// to avoid the constant reflow
			for ( var j = 0, k = this.length; j < k; j++ ) {
				this[j].style.display = jQuery.data(this[j], "olddisplay") || "";
			}

			return this;
		}
	},

	hide: function( speed, callback ) {
		if ( speed || speed === 0 ) {
			return this.animate( genFx("hide", 3), speed, callback);

		} else {
			for ( var i = 0, l = this.length; i < l; i++ ) {
				var old = jQuery.data(this[i], "olddisplay");
				if ( !old && old !== "none" ) {
					jQuery.data(this[i], "olddisplay", jQuery.css(this[i], "display"));
				}
			}

			// Set the display of the elements in a second loop
			// to avoid the constant reflow
			for ( var j = 0, k = this.length; j < k; j++ ) {
				this[j].style.display = "none";
			}

			return this;
		}
	},

	// Save the old toggle function
	_toggle: jQuery.fn.toggle,

	toggle: function( fn, fn2 ) {
		var bool = typeof fn === "boolean";

		if ( jQuery.isFunction(fn) && jQuery.isFunction(fn2) ) {
			this._toggle.apply( this, arguments );

		} else if ( fn == null || bool ) {
			this.each(function() {
				var state = bool ? fn : jQuery(this).is(":hidden");
				jQuery(this)[ state ? "show" : "hide" ]();
			});

		} else {
			this.animate(genFx("toggle", 3), fn, fn2);
		}

		return this;
	},

	fadeTo: function( speed, to, callback ) {
		return this.filter(":hidden").css("opacity", 0).show().end()
					.animate({opacity: to}, speed, callback);
	},

	animate: function( prop, speed, easing, callback ) {
		var optall = jQuery.speed(speed, easing, callback);

		if ( jQuery.isEmptyObject( prop ) ) {
			return this.each( optall.complete );
		}

		return this[ optall.queue === false ? "each" : "queue" ](function() {
			var opt = jQuery.extend({}, optall), p,
				hidden = this.nodeType === 1 && jQuery(this).is(":hidden"),
				self = this;

			for ( p in prop ) {
				var name = p.replace(rdashAlpha, fcamelCase);

				if ( p !== name ) {
					prop[ name ] = prop[ p ];
					delete prop[ p ];
					p = name;
				}

				if ( prop[p] === "hide" && hidden || prop[p] === "show" && !hidden ) {
					return opt.complete.call(this);
				}

				if ( ( p === "height" || p === "width" ) && this.style ) {
					// Store display property
					opt.display = jQuery.css(this, "display");

					// Make sure that nothing sneaks out
					opt.overflow = this.style.overflow;
				}

				if ( jQuery.isArray( prop[p] ) ) {
					// Create (if needed) and add to specialEasing
					(opt.specialEasing = opt.specialEasing || {})[p] = prop[p][1];
					prop[p] = prop[p][0];
				}
			}

			if ( opt.overflow != null ) {
				this.style.overflow = "hidden";
			}

			opt.curAnim = jQuery.extend({}, prop);

			jQuery.each( prop, function( name, val ) {
				var e = new jQuery.fx( self, opt, name );

				if ( rfxtypes.test(val) ) {
					e[ val === "toggle" ? hidden ? "show" : "hide" : val ]( prop );

				} else {
					var parts = rfxnum.exec(val),
						start = e.cur(true) || 0;

					if ( parts ) {
						var end = parseFloat( parts[2] ),
							unit = parts[3] || "px";

						// We need to compute starting value
						if ( unit !== "px" ) {
							self.style[ name ] = (end || 1) + unit;
							start = ((end || 1) / e.cur(true)) * start;
							self.style[ name ] = start + unit;
						}

						// If a +=/-= token was provided, we're doing a relative animation
						if ( parts[1] ) {
							end = ((parts[1] === "-=" ? -1 : 1) * end) + start;
						}

						e.custom( start, end, unit );

					} else {
						e.custom( start, val, "" );
					}
				}
			});

			// For JS strict compliance
			return true;
		});
	},

	stop: function( clearQueue, gotoEnd ) {
		var timers = jQuery.timers;

		if ( clearQueue ) {
			this.queue([]);
		}

		this.each(function() {
			// go in reverse order so anything added to the queue during the loop is ignored
			for ( var i = timers.length - 1; i >= 0; i-- ) {
				if ( timers[i].elem === this ) {
					if (gotoEnd) {
						// force the next step to be the last
						timers[i](true);
					}

					timers.splice(i, 1);
				}
			}
		});

		// start the next in the queue if the last step wasn't forced
		if ( !gotoEnd ) {
			this.dequeue();
		}

		return this;
	}

});

// Generate shortcuts for custom animations
jQuery.each({
	slideDown: genFx("show", 1),
	slideUp: genFx("hide", 1),
	slideToggle: genFx("toggle", 1),
	fadeIn: { opacity: "show" },
	fadeOut: { opacity: "hide" }
}, function( name, props ) {
	jQuery.fn[ name ] = function( speed, callback ) {
		return this.animate( props, speed, callback );
	};
});

jQuery.extend({
	speed: function( speed, easing, fn ) {
		var opt = speed && typeof speed === "object" ? speed : {
			complete: fn || !fn && easing ||
				jQuery.isFunction( speed ) && speed,
			duration: speed,
			easing: fn && easing || easing && !jQuery.isFunction(easing) && easing
		};

		opt.duration = jQuery.fx.off ? 0 : typeof opt.duration === "number" ? opt.duration :
			jQuery.fx.speeds[opt.duration] || jQuery.fx.speeds._default;

		// Queueing
		opt.old = opt.complete;
		opt.complete = function() {
			if ( opt.queue !== false ) {
				jQuery(this).dequeue();
			}
			if ( jQuery.isFunction( opt.old ) ) {
				opt.old.call( this );
			}
		};

		return opt;
	},

	easing: {
		linear: function( p, n, firstNum, diff ) {
			return firstNum + diff * p;
		},
		swing: function( p, n, firstNum, diff ) {
			return ((-Math.cos(p*Math.PI)/2) + 0.5) * diff + firstNum;
		}
	},

	timers: [],

	fx: function( elem, options, prop ) {
		this.options = options;
		this.elem = elem;
		this.prop = prop;

		if ( !options.orig ) {
			options.orig = {};
		}
	}

});

jQuery.fx.prototype = {
	// Simple function for setting a style value
	update: function() {
		if ( this.options.step ) {
			this.options.step.call( this.elem, this.now, this );
		}

		(jQuery.fx.step[this.prop] || jQuery.fx.step._default)( this );

		// Set display property to block for height/width animations
		if ( ( this.prop === "height" || this.prop === "width" ) && this.elem.style ) {
			this.elem.style.display = "block";
		}
	},

	// Get the current size
	cur: function( force ) {
		if ( this.elem[this.prop] != null && (!this.elem.style || this.elem.style[this.prop] == null) ) {
			return this.elem[ this.prop ];
		}

		var r = parseFloat(jQuery.css(this.elem, this.prop, force));
		return r && r > -10000 ? r : parseFloat(jQuery.curCSS(this.elem, this.prop)) || 0;
	},

	// Start an animation from one number to another
	custom: function( from, to, unit ) {
		this.startTime = now();
		this.start = from;
		this.end = to;
		this.unit = unit || this.unit || "px";
		this.now = this.start;
		this.pos = this.state = 0;

		var self = this;
		function t( gotoEnd ) {
			return self.step(gotoEnd);
		}

		t.elem = this.elem;

		if ( t() && jQuery.timers.push(t) && !timerId ) {
			timerId = setInterval(jQuery.fx.tick, 13);
		}
	},

	// Simple 'show' function
	show: function() {
		// Remember where we started, so that we can go back to it later
		this.options.orig[this.prop] = jQuery.style( this.elem, this.prop );
		this.options.show = true;

		// Begin the animation
		// Make sure that we start at a small width/height to avoid any
		// flash of content
		this.custom(this.prop === "width" || this.prop === "height" ? 1 : 0, this.cur());

		// Start by showing the element
		jQuery( this.elem ).show();
	},

	// Simple 'hide' function
	hide: function() {
		// Remember where we started, so that we can go back to it later
		this.options.orig[this.prop] = jQuery.style( this.elem, this.prop );
		this.options.hide = true;

		// Begin the animation
		this.custom(this.cur(), 0);
	},

	// Each step of an animation
	step: function( gotoEnd ) {
		var t = now(), done = true;

		if ( gotoEnd || t >= this.options.duration + this.startTime ) {
			this.now = this.end;
			this.pos = this.state = 1;
			this.update();

			this.options.curAnim[ this.prop ] = true;

			for ( var i in this.options.curAnim ) {
				if ( this.options.curAnim[i] !== true ) {
					done = false;
				}
			}

			if ( done ) {
				if ( this.options.display != null ) {
					// Reset the overflow
					this.elem.style.overflow = this.options.overflow;

					// Reset the display
					var old = jQuery.data(this.elem, "olddisplay");
					this.elem.style.display = old ? old : this.options.display;

					if ( jQuery.css(this.elem, "display") === "none" ) {
						this.elem.style.display = "block";
					}
				}

				// Hide the element if the "hide" operation was done
				if ( this.options.hide ) {
					jQuery(this.elem).hide();
				}

				// Reset the properties, if the item has been hidden or shown
				if ( this.options.hide || this.options.show ) {
					for ( var p in this.options.curAnim ) {
						jQuery.style(this.elem, p, this.options.orig[p]);
					}
				}

				// Execute the complete function
				this.options.complete.call( this.elem );
			}

			return false;

		} else {
			var n = t - this.startTime;
			this.state = n / this.options.duration;

			// Perform the easing function, defaults to swing
			var specialEasing = this.options.specialEasing && this.options.specialEasing[this.prop];
			var defaultEasing = this.options.easing || (jQuery.easing.swing ? "swing" : "linear");
			this.pos = jQuery.easing[specialEasing || defaultEasing](this.state, n, 0, 1, this.options.duration);
			this.now = this.start + ((this.end - this.start) * this.pos);

			// Perform the next step of the animation
			this.update();
		}

		return true;
	}
};

jQuery.extend( jQuery.fx, {
	tick: function() {
		var timers = jQuery.timers;

		for ( var i = 0; i < timers.length; i++ ) {
			if ( !timers[i]() ) {
				timers.splice(i--, 1);
			}
		}

		if ( !timers.length ) {
			jQuery.fx.stop();
		}
	},
		
	stop: function() {
		clearInterval( timerId );
		timerId = null;
	},
	
	speeds: {
		slow: 600,
 		fast: 200,
 		// Default speed
 		_default: 400
	},

	step: {
		opacity: function( fx ) {
			jQuery.style(fx.elem, "opacity", fx.now);
		},

		_default: function( fx ) {
			if ( fx.elem.style && fx.elem.style[ fx.prop ] != null ) {
				fx.elem.style[ fx.prop ] = (fx.prop === "width" || fx.prop === "height" ? Math.max(0, fx.now) : fx.now) + fx.unit;
			} else {
				fx.elem[ fx.prop ] = fx.now;
			}
		}
	}
});

if ( jQuery.expr && jQuery.expr.filters ) {
	jQuery.expr.filters.animated = function( elem ) {
		return jQuery.grep(jQuery.timers, function( fn ) {
			return elem === fn.elem;
		}).length;
	};
}

function genFx( type, num ) {
	var obj = {};

	jQuery.each( fxAttrs.concat.apply([], fxAttrs.slice(0,num)), function() {
		obj[ this ] = type;
	});

	return obj;
}
if ( "getBoundingClientRect" in document.documentElement ) {
	jQuery.fn.offset = function( options ) {
		var elem = this[0];

		if ( options ) { 
			return this.each(function( i ) {
				jQuery.offset.setOffset( this, options, i );
			});
		}

		if ( !elem || !elem.ownerDocument ) {
			return null;
		}

		if ( elem === elem.ownerDocument.body ) {
			return jQuery.offset.bodyOffset( elem );
		}

		var box = elem.getBoundingClientRect(), doc = elem.ownerDocument, body = doc.body, docElem = doc.documentElement,
			clientTop = docElem.clientTop || body.clientTop || 0, clientLeft = docElem.clientLeft || body.clientLeft || 0,
			top  = box.top  + (self.pageYOffset || jQuery.support.boxModel && docElem.scrollTop  || body.scrollTop ) - clientTop,
			left = box.left + (self.pageXOffset || jQuery.support.boxModel && docElem.scrollLeft || body.scrollLeft) - clientLeft;

		return { top: top, left: left };
	};

} else {
	jQuery.fn.offset = function( options ) {
		var elem = this[0];

		if ( options ) { 
			return this.each(function( i ) {
				jQuery.offset.setOffset( this, options, i );
			});
		}

		if ( !elem || !elem.ownerDocument ) {
			return null;
		}

		if ( elem === elem.ownerDocument.body ) {
			return jQuery.offset.bodyOffset( elem );
		}

		jQuery.offset.initialize();

		var offsetParent = elem.offsetParent, prevOffsetParent = elem,
			doc = elem.ownerDocument, computedStyle, docElem = doc.documentElement,
			body = doc.body, defaultView = doc.defaultView,
			prevComputedStyle = defaultView ? defaultView.getComputedStyle( elem, null ) : elem.currentStyle,
			top = elem.offsetTop, left = elem.offsetLeft;

		while ( (elem = elem.parentNode) && elem !== body && elem !== docElem ) {
			if ( jQuery.offset.supportsFixedPosition && prevComputedStyle.position === "fixed" ) {
				break;
			}

			computedStyle = defaultView ? defaultView.getComputedStyle(elem, null) : elem.currentStyle;
			top  -= elem.scrollTop;
			left -= elem.scrollLeft;

			if ( elem === offsetParent ) {
				top  += elem.offsetTop;
				left += elem.offsetLeft;

				if ( jQuery.offset.doesNotAddBorder && !(jQuery.offset.doesAddBorderForTableAndCells && /^t(able|d|h)$/i.test(elem.nodeName)) ) {
					top  += parseFloat( computedStyle.borderTopWidth  ) || 0;
					left += parseFloat( computedStyle.borderLeftWidth ) || 0;
				}

				prevOffsetParent = offsetParent, offsetParent = elem.offsetParent;
			}

			if ( jQuery.offset.subtractsBorderForOverflowNotVisible && computedStyle.overflow !== "visible" ) {
				top  += parseFloat( computedStyle.borderTopWidth  ) || 0;
				left += parseFloat( computedStyle.borderLeftWidth ) || 0;
			}

			prevComputedStyle = computedStyle;
		}

		if ( prevComputedStyle.position === "relative" || prevComputedStyle.position === "static" ) {
			top  += body.offsetTop;
			left += body.offsetLeft;
		}

		if ( jQuery.offset.supportsFixedPosition && prevComputedStyle.position === "fixed" ) {
			top  += Math.max( docElem.scrollTop, body.scrollTop );
			left += Math.max( docElem.scrollLeft, body.scrollLeft );
		}

		return { top: top, left: left };
	};
}

jQuery.offset = {
	initialize: function() {
		var body = document.body, container = document.createElement("div"), innerDiv, checkDiv, table, td, bodyMarginTop = parseFloat( jQuery.curCSS(body, "marginTop", true) ) || 0,
			html = "<div style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;'><div></div></div><table style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;' cellpadding='0' cellspacing='0'><tr><td></td></tr></table>";

		jQuery.extend( container.style, { position: "absolute", top: 0, left: 0, margin: 0, border: 0, width: "1px", height: "1px", visibility: "hidden" } );

		container.innerHTML = html;
		body.insertBefore( container, body.firstChild );
		innerDiv = container.firstChild;
		checkDiv = innerDiv.firstChild;
		td = innerDiv.nextSibling.firstChild.firstChild;

		this.doesNotAddBorder = (checkDiv.offsetTop !== 5);
		this.doesAddBorderForTableAndCells = (td.offsetTop === 5);

		checkDiv.style.position = "fixed", checkDiv.style.top = "20px";
		// safari subtracts parent border width here which is 5px
		this.supportsFixedPosition = (checkDiv.offsetTop === 20 || checkDiv.offsetTop === 15);
		checkDiv.style.position = checkDiv.style.top = "";

		innerDiv.style.overflow = "hidden", innerDiv.style.position = "relative";
		this.subtractsBorderForOverflowNotVisible = (checkDiv.offsetTop === -5);

		this.doesNotIncludeMarginInBodyOffset = (body.offsetTop !== bodyMarginTop);

		body.removeChild( container );
		body = container = innerDiv = checkDiv = table = td = null;
		jQuery.offset.initialize = jQuery.noop;
	},

	bodyOffset: function( body ) {
		var top = body.offsetTop, left = body.offsetLeft;

		jQuery.offset.initialize();

		if ( jQuery.offset.doesNotIncludeMarginInBodyOffset ) {
			top  += parseFloat( jQuery.curCSS(body, "marginTop",  true) ) || 0;
			left += parseFloat( jQuery.curCSS(body, "marginLeft", true) ) || 0;
		}

		return { top: top, left: left };
	},
	
	setOffset: function( elem, options, i ) {
		// set position first, in-case top/left are set even on static elem
		if ( /static/.test( jQuery.curCSS( elem, "position" ) ) ) {
			elem.style.position = "relative";
		}
		var curElem   = jQuery( elem ),
			curOffset = curElem.offset(),
			curTop    = parseInt( jQuery.curCSS( elem, "top",  true ), 10 ) || 0,
			curLeft   = parseInt( jQuery.curCSS( elem, "left", true ), 10 ) || 0;

		if ( jQuery.isFunction( options ) ) {
			options = options.call( elem, i, curOffset );
		}

		var props = {
			top:  (options.top  - curOffset.top)  + curTop,
			left: (options.left - curOffset.left) + curLeft
		};
		
		if ( "using" in options ) {
			options.using.call( elem, props );
		} else {
			curElem.css( props );
		}
	}
};


jQuery.fn.extend({
	position: function() {
		if ( !this[0] ) {
			return null;
		}

		var elem = this[0],

		// Get *real* offsetParent
		offsetParent = this.offsetParent(),

		// Get correct offsets
		offset       = this.offset(),
		parentOffset = /^body|html$/i.test(offsetParent[0].nodeName) ? { top: 0, left: 0 } : offsetParent.offset();

		// Subtract element margins
		// note: when an element has margin: auto the offsetLeft and marginLeft
		// are the same in Safari causing offset.left to incorrectly be 0
		offset.top  -= parseFloat( jQuery.curCSS(elem, "marginTop",  true) ) || 0;
		offset.left -= parseFloat( jQuery.curCSS(elem, "marginLeft", true) ) || 0;

		// Add offsetParent borders
		parentOffset.top  += parseFloat( jQuery.curCSS(offsetParent[0], "borderTopWidth",  true) ) || 0;
		parentOffset.left += parseFloat( jQuery.curCSS(offsetParent[0], "borderLeftWidth", true) ) || 0;

		// Subtract the two offsets
		return {
			top:  offset.top  - parentOffset.top,
			left: offset.left - parentOffset.left
		};
	},

	offsetParent: function() {
		return this.map(function() {
			var offsetParent = this.offsetParent || document.body;
			while ( offsetParent && (!/^body|html$/i.test(offsetParent.nodeName) && jQuery.css(offsetParent, "position") === "static") ) {
				offsetParent = offsetParent.offsetParent;
			}
			return offsetParent;
		});
	}
});


// Create scrollLeft and scrollTop methods
jQuery.each( ["Left", "Top"], function( i, name ) {
	var method = "scroll" + name;

	jQuery.fn[ method ] = function(val) {
		var elem = this[0], win;
		
		if ( !elem ) {
			return null;
		}

		if ( val !== undefined ) {
			// Set the scroll offset
			return this.each(function() {
				win = getWindow( this );

				if ( win ) {
					win.scrollTo(
						!i ? val : jQuery(win).scrollLeft(),
						 i ? val : jQuery(win).scrollTop()
					);

				} else {
					this[ method ] = val;
				}
			});
		} else {
			win = getWindow( elem );

			// Return the scroll offset
			return win ? ("pageXOffset" in win) ? win[ i ? "pageYOffset" : "pageXOffset" ] :
				jQuery.support.boxModel && win.document.documentElement[ method ] ||
					win.document.body[ method ] :
				elem[ method ];
		}
	};
});

function getWindow( elem ) {
	return ("scrollTo" in elem && elem.document) ?
		elem :
		elem.nodeType === 9 ?
			elem.defaultView || elem.parentWindow :
			false;
}
// Create innerHeight, innerWidth, outerHeight and outerWidth methods
jQuery.each([ "Height", "Width" ], function( i, name ) {

	var type = name.toLowerCase();

	// innerHeight and innerWidth
	jQuery.fn["inner" + name] = function() {
		return this[0] ?
			jQuery.css( this[0], type, false, "padding" ) :
			null;
	};

	// outerHeight and outerWidth
	jQuery.fn["outer" + name] = function( margin ) {
		return this[0] ?
			jQuery.css( this[0], type, false, margin ? "margin" : "border" ) :
			null;
	};

	jQuery.fn[ type ] = function( size ) {
		// Get window width or height
		var elem = this[0];
		if ( !elem ) {
			return size == null ? null : this;
		}
		
		if ( jQuery.isFunction( size ) ) {
			return this.each(function( i ) {
				var self = jQuery( this );
				self[ type ]( size.call( this, i, self[ type ]() ) );
			});
		}

		return ("scrollTo" in elem && elem.document) ? // does it walk and quack like a window?
			// Everyone else use document.documentElement or document.body depending on Quirks vs Standards mode
			elem.document.compatMode === "CSS1Compat" && elem.document.documentElement[ "client" + name ] ||
			elem.document.body[ "client" + name ] :

			// Get document width or height
			(elem.nodeType === 9) ? // is it a document
				// Either scroll[Width/Height] or offset[Width/Height], whichever is greater
				Math.max(
					elem.documentElement["client" + name],
					elem.body["scroll" + name], elem.documentElement["scroll" + name],
					elem.body["offset" + name], elem.documentElement["offset" + name]
				) :

				// Get or set width or height on the element
				size === undefined ?
					// Get width or height on the element
					jQuery.css( elem, type ) :

					// Set the width or height on the element (default to pixels if value is unitless)
					this.css( type, typeof size === "string" ? size : size + "px" );
	};

});
// Expose jQuery to the global object
window.jQuery = window.$ = jQuery;

})(window);
var TJG = {}; TJG.vars = {};
TJG.doc = document.documentElement;
TJG.vars.orientationClasses = ['landscape', 'portrait'];
TJG.vars.isDev = true;
TJG.vars.isSwapped = false;
TJG.vars.isIos = false;
TJG.vars.isTouch = false;
TJG.appOfferWall = {};
TJG.openiDialogs = {};
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
    /*!
     * master-class v0.1
     * http://johnboxall.github.com/master-class/
     * Copyright 2010, Mobify
     * Freely distributed under the MIT license.
     */
    var classes = [''], classReplaces = {}, device = "", orientationCompute = "";
    var ua = navigator.userAgent;
    var m = /(ip(od|ad|hone)|android)/gi.exec(ua);
    if (m) {
      var v = RegExp(/OS\s([\d+_?]*)\slike/i).exec(ua);
      TJG.vars.version = v != null ? v[1].replace(/_/g, '.') : 4;
      TJG.vars.device = m[2] ? m[1].toLowerCase() : m[1].toLowerCase();
      classReplaces['device'] = TJG.vars.device;
      classes.push('ratio-' + window.devicePixelRatio);
      classReplaces['no-os'] = m[2] ? 'ios' : m[1].toLowerCase();
      if (TJG.vars.device == 'ipad') {
        classReplaces['mobile'] = 'ipad';
      }
    }
    else {
      classReplaces['mobile'] = 'web';
    }
    classes.push(winW + 'x' + winH);
    function getOrientationClass() {
      return TJG.vars.orientationClasses[window.orientation % 180 ? 0 : 1];
    }
    if ('orientation' in window) {
      var orientationRe = new RegExp('(' + TJG.vars.orientationClasses.join('|') + ')'),
        orientationEvent = ('onorientationchange' in window) ? 'orientationchange' : 'resize',
          currentOrientationClass = classes.push(getOrientationClass());
      if (TJG.vars.width > TJG.vars.height) {
        orientationCompute = 'landscape';
      }
      else {
          orientationCompute = 'portrait';
      }
      var isSwapped = false;
      if (getOrientationClass() != orientationCompute) {
        classes.push('orientation-swap');
        isSwapped = true;
        TJG.vars.isSwapped = isSwapped;
      }
      if (TJG.vars.device == 'android') {
        if (TJG.vars.width <= 480 && getOrientationClass() == 'portrait' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
        if (TJG.vars.width <= 800 && getOrientationClass() == 'landscape' && TJG.vars.isSwapped) {
          classReplaces['web'] = 'android-phone';
        }
      }
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
    if ('ontouchend' in document) {
      classReplaces['no-touch'] = 'touch';
      TJG.vars.isTouch = true;
    }
    if (TJG.vars.device == 'iphone' || TJG.vars.device == 'ipod' || TJG.vars.device == 'ipad') {
      TJG.vars.isIos = true;
    } 
    var test = document.createElement('div');
    test.style.display = 'none';
    test.id = 'mc-test';
    test.innerHTML = '<style type="text/css">@media(-webkit-min-device-pixel-ratio:1.5){#mc-test{color:red}}@media(-webkit-min-device-pixel-ratio:2.0){#mc-test{color:blue}}</style>';
    TJG.doc.appendChild(test);
    var color = test.ownerDocument.defaultView.getComputedStyle(test, null).getPropertyValue('color'), m = /255(\))?/gi.exec(color);
    if (m) {
        classes.push('hd' + (m[1] ? 20 : 15));
        classReplaces['no-hd'] = 'hd';
    }
    TJG.doc.removeChild(test);
    var className = TJG.doc.className;
    for (replace in classReplaces) {              
        className = className.replace(replace, classReplaces[replace]);
    }
    TJG.doc.className = className + classes.join(' ');
})(this, document);/*!
 * Copyright (c) 2009 Simo Kinnunen.
 * Licensed under the MIT license.
 *
 * @version ${Version}
 */

var Cufon = (function() {

	var api = function() {
		return api.replace.apply(null, arguments);
	};

	var DOM = api.DOM = {

		ready: (function() {

			var complete = false, readyStatus = { loaded: 1, complete: 1 };

			var queue = [], perform = function() {
				if (complete) return;
				complete = true;
				for (var fn; fn = queue.shift(); fn());
			};

			// Gecko, Opera, WebKit r26101+

			if (document.addEventListener) {
				document.addEventListener('DOMContentLoaded', perform, false);
				window.addEventListener('pageshow', perform, false); // For cached Gecko pages
			}

			// Old WebKit, Internet Explorer

			if (!window.opera && document.readyState) (function() {
				readyStatus[document.readyState] ? perform() : setTimeout(arguments.callee, 10);
			})();

			// Internet Explorer

			if (document.readyState && document.createStyleSheet) (function() {
				try {
					document.body.doScroll('left');
					perform();
				}
				catch (e) {
					setTimeout(arguments.callee, 1);
				}
			})();

			addEvent(window, 'load', perform); // Fallback

			return function(listener) {
				if (!arguments.length) perform();
				else complete ? listener() : queue.push(listener);
			};

		})(),

		root: function() {
			return document.documentElement || document.body;
		}

	};

	var CSS = api.CSS = {

		Size: function(value, base) {

			this.value = parseFloat(value);
			this.unit = String(value).match(/[a-z%]*$/)[0] || 'px';

			this.convert = function(value) {
				return value / base * this.value;
			};

			this.convertFrom = function(value) {
				return value / this.value * base;
			};

			this.toString = function() {
				return this.value + this.unit;
			};

		},

		addClass: function(el, className) {
			var current = el.className;
			el.className = current + (current && ' ') + className;
			return el;
		},

		color: cached(function(value) {
			var parsed = {};
			parsed.color = value.replace(/^rgba\((.*?),\s*([\d.]+)\)/, function($0, $1, $2) {
				parsed.opacity = parseFloat($2);
				return 'rgb(' + $1 + ')';
			});
			return parsed;
		}),

		// has no direct CSS equivalent.
		// @see http://msdn.microsoft.com/en-us/library/system.windows.fontstretches.aspx
		fontStretch: cached(function(value) {
			if (typeof value == 'number') return value;
			if (/%$/.test(value)) return parseFloat(value) / 100;
			return {
				'ultra-condensed': 0.5,
				'extra-condensed': 0.625,
				condensed: 0.75,
				'semi-condensed': 0.875,
				'semi-expanded': 1.125,
				expanded: 1.25,
				'extra-expanded': 1.5,
				'ultra-expanded': 2
			}[value] || 1;
		}),

		getStyle: function(el) {
			var view = document.defaultView;
			if (view && view.getComputedStyle) return new Style(view.getComputedStyle(el, null));
			if (el.currentStyle) return new Style(el.currentStyle);
			return new Style(el.style);
		},

		gradient: cached(function(value) {
			var gradient = {
				id: value,
				type: value.match(/^-([a-z]+)-gradient\(/)[1],
				stops: []
			}, colors = value.substr(value.indexOf('(')).match(/([\d.]+=)?(#[a-f0-9]+|[a-z]+\(.*?\)|[a-z]+)/ig);
			for (var i = 0, l = colors.length, stop; i < l; ++i) {
				stop = colors[i].split('=', 2).reverse();
				gradient.stops.push([ stop[1] || i / (l - 1), stop[0] ]);
			}
			return gradient;
		}),

		quotedList: cached(function(value) {
			// doesn't work properly with empty quoted strings (""), but
			// it's not worth the extra code.
			var list = [], re = /\s*((["'])([\s\S]*?[^\\])\2|[^,]+)\s*/g, match;
			while (match = re.exec(value)) list.push(match[3] || match[1]);
			return list;
		}),

		recognizesMedia: cached(function(media) {
			var el = document.createElement('style'), sheet, container, supported;
			el.type = 'text/css';
			el.media = media;
			try { // this is cached anyway
				el.appendChild(document.createTextNode('/**/'));
			} catch (e) {}
			container = elementsByTagName('head')[0];
			container.insertBefore(el, container.firstChild);
			sheet = (el.sheet || el.styleSheet);
			supported = sheet && !sheet.disabled;
			container.removeChild(el);
			return supported;
		}),

		removeClass: function(el, className) {
			var re = RegExp('(?:^|\\s+)' + className +  '(?=\\s|$)', 'g');
			el.className = el.className.replace(re, '');
			return el;
		},

		supports: function(property, value) {
			var checker = document.createElement('span').style;
			if (checker[property] === undefined) return false;
			checker[property] = value;
			return checker[property] === value;
		},

		textAlign: function(word, style, position, wordCount) {
			if (style.get('textAlign') == 'right') {
				if (position > 0) word = ' ' + word;
			}
			else if (position < wordCount - 1) word += ' ';
			return word;
		},

		textShadow: cached(function(value) {
			if (value == 'none') return null;
			var shadows = [], currentShadow = {}, result, offCount = 0;
			var re = /(#[a-f0-9]+|[a-z]+\(.*?\)|[a-z]+)|(-?[\d.]+[a-z%]*)|,/ig;
			while (result = re.exec(value)) {
				if (result[0] == ',') {
					shadows.push(currentShadow);
					currentShadow = {};
					offCount = 0;
				}
				else if (result[1]) {
					currentShadow.color = result[1];
				}
				else {
					currentShadow[[ 'offX', 'offY', 'blur' ][offCount++]] = result[2];
				}
			}
			shadows.push(currentShadow);
			return shadows;
		}),

		textTransform: (function() {
			var map = {
				uppercase: function(s) {
					return s.toUpperCase();
				},
				lowercase: function(s) {
					return s.toLowerCase();
				},
				capitalize: function(s) {
					return s.replace(/\b./g, function($0) {
						return $0.toUpperCase();
					});
				}
			};
			return function(text, style) {
				var transform = map[style.get('textTransform')];
				return transform ? transform(text) : text;
			};
		})(),

		whiteSpace: (function() {
			var ignore = {
				inline: 1,
				'inline-block': 1,
				'run-in': 1
			};
			var wsStart = /^\s+/, wsEnd = /\s+$/;
			return function(text, style, node, previousElement) {
				if (previousElement) {
					if (previousElement.nodeName.toLowerCase() == 'br') {
						text = text.replace(wsStart, '');
					}
				}
				if (ignore[style.get('display')]) return text;
				if (!node.previousSibling) text = text.replace(wsStart, '');
				if (!node.nextSibling) text = text.replace(wsEnd, '');
				return text;
			};
		})()

	};

	CSS.ready = (function() {

		// don't do anything in Safari 2 (it doesn't recognize any media type)
		var complete = !CSS.recognizesMedia('all'), hasLayout = false;

		var queue = [], perform = function() {
			complete = true;
			for (var fn; fn = queue.shift(); fn());
		};

		var links = elementsByTagName('link'), styles = elementsByTagName('style');

		function isContainerReady(el) {
			return el.disabled || isSheetReady(el.sheet, el.media || 'screen');
		}

		function isSheetReady(sheet, media) {
			// in Opera sheet.disabled is true when it's still loading,
			// even though link.disabled is false. they stay in sync if
			// set manually.
			if (!CSS.recognizesMedia(media || 'all')) return true;
			if (!sheet || sheet.disabled) return false;
			try {
				var rules = sheet.cssRules, rule;
				if (rules) {
					// needed for Safari 3 and Chrome 1.0.
					// in standards-conforming browsers cssRules contains @-rules.
					// Chrome 1.0 weirdness: rules[<number larger than .length - 1>]
					// returns the last rule, so a for loop is the only option.
					search: for (var i = 0, l = rules.length; rule = rules[i], i < l; ++i) {
						switch (rule.type) {
							case 2: // @charset
								break;
							case 3: // @import
								if (!isSheetReady(rule.styleSheet, rule.media.mediaText)) return false;
								break;
							default:
								// only @charset can precede @import
								break search;
						}
					}
				}
			}
			catch (e) {} // probably a style sheet from another domain
			return true;
		}

		function allStylesLoaded() {
			// Internet Explorer's style sheet model, there's no need to do anything
			if (document.createStyleSheet) return true;
			// standards-compliant browsers
			var el, i;
			for (i = 0; el = links[i]; ++i) {
				if (el.rel.toLowerCase() == 'stylesheet' && !isContainerReady(el)) return false;
			}
			for (i = 0; el = styles[i]; ++i) {
				if (!isContainerReady(el)) return false;
			}
			return true;
		}

		DOM.ready(function() {
			// getComputedStyle returns null in Gecko if used in an iframe with display: none
			if (!hasLayout) hasLayout = CSS.getStyle(document.body).isUsable();
			if (complete || (hasLayout && allStylesLoaded())) perform();
			else setTimeout(arguments.callee, 10);
		});

		return function(listener) {
			if (complete) listener();
			else queue.push(listener);
		};

	})();

	function Font(data) {

		var face = this.face = data.face, wordSeparators = {
			'\u0020': 1,
			'\u00a0': 1,
			'\u3000': 1
		};

		this.glyphs = data.glyphs;
		this.w = data.w;
		this.baseSize = parseInt(face['units-per-em'], 10);

		this.family = face['font-family'].toLowerCase();
		this.weight = face['font-weight'];
		this.style = face['font-style'] || 'normal';

		this.viewBox = (function () {
			var parts = face.bbox.split(/\s+/);
			var box = {
				minX: parseInt(parts[0], 10),
				minY: parseInt(parts[1], 10),
				maxX: parseInt(parts[2], 10),
				maxY: parseInt(parts[3], 10)
			};
			box.width = box.maxX - box.minX;
			box.height = box.maxY - box.minY;
			box.toString = function() {
				return [ this.minX, this.minY, this.width, this.height ].join(' ');
			};
			return box;
		})();

		this.ascent = -parseInt(face.ascent, 10);
		this.descent = -parseInt(face.descent, 10);

		this.height = -this.ascent + this.descent;

		this.spacing = function(chars, letterSpacing, wordSpacing) {
			var glyphs = this.glyphs, glyph, kerning, k,
				jumps = [], width = 0,
				i = -1, j = -1, chr;
			while (chr = chars[++i]) {
				glyph = glyphs[chr] || this.missingGlyph;
				if (!glyph) continue;
				if (kerning) {
					width -= k = kerning[chr] || 0;
					jumps[j] -= k;
				}
				width += jumps[++j] = ~~(glyph.w || this.w) + letterSpacing + (wordSeparators[chr] ? wordSpacing : 0);
				kerning = glyph.k;
			}
			jumps.total = width;
			return jumps;
		};

	}

	function FontFamily() {

		var styles = {}, mapping = {
			oblique: 'italic',
			italic: 'oblique'
		};

		this.add = function(font) {
			(styles[font.style] || (styles[font.style] = {}))[font.weight] = font;
		};

		this.get = function(style, weight) {
			var weights = styles[style] || styles[mapping[style]]
				|| styles.normal || styles.italic || styles.oblique;
			if (!weights) return null;
			// we don't have to worry about "bolder" and "lighter"
			// because IE's currentStyle returns a numeric value for it,
			// and other browsers use the computed value anyway
			weight = {
				normal: 400,
				bold: 700
			}[weight] || parseInt(weight, 10);
			if (weights[weight]) return weights[weight];
			// http://www.w3.org/TR/CSS21/fonts.html#propdef-font-weight
			// Gecko uses x99/x01 for lighter/bolder
			var up = {
				1: 1,
				99: 0
			}[weight % 100], alts = [], min, max;
			if (up === undefined) up = weight > 400;
			if (weight == 500) weight = 400;
			for (var alt in weights) {
				if (!hasOwnProperty(weights, alt)) continue;
				alt = parseInt(alt, 10);
				if (!min || alt < min) min = alt;
				if (!max || alt > max) max = alt;
				alts.push(alt);
			}
			if (weight < min) weight = min;
			if (weight > max) weight = max;
			alts.sort(function(a, b) {
				return (up
					? (a >= weight && b >= weight) ? a < b : a > b
					: (a <= weight && b <= weight) ? a > b : a < b) ? -1 : 1;
			});
			return weights[alts[0]];
		};

	}

	function HoverHandler() {

		function contains(node, anotherNode) {
			if (node.contains) return node.contains(anotherNode);
			return node.compareDocumentPosition(anotherNode) & 16;
		}

		function onOverOut(e) {
			var related = e.relatedTarget;
			if (!related || contains(this, related)) return;
			trigger(this, e.type == 'mouseover');
		}

		function onEnterLeave(e) {
			trigger(this, e.type == 'mouseenter');
		}

		function trigger(el, hoverState) {
			// A timeout is needed so that the event can actually "happen"
			// before replace is triggered. This ensures that styles are up
			// to date.
			setTimeout(function() {
				var options = sharedStorage.get(el).options;
				api.replace(el, hoverState ? merge(options, options.hover) : options, true);
			}, 10);
		}

		this.attach = function(el) {
			if (el.onmouseenter === undefined) {
				addEvent(el, 'mouseover', onOverOut);
				addEvent(el, 'mouseout', onOverOut);
			}
			else {
				addEvent(el, 'mouseenter', onEnterLeave);
				addEvent(el, 'mouseleave', onEnterLeave);
			}
		};

	}

	function ReplaceHistory() {

		var list = [], map = {};

		function filter(keys) {
			var values = [], key;
			for (var i = 0; key = keys[i]; ++i) values[i] = list[map[key]];
			return values;
		}

		this.add = function(key, args) {
			map[key] = list.push(args) - 1;
		};

		this.repeat = function() {
			var snapshot = arguments.length ? filter(arguments) : list, args;
			for (var i = 0; args = snapshot[i++];) api.replace(args[0], args[1], true);
		};

	}

	function Storage() {

		var map = {}, at = 0;

		function identify(el) {
			return el.cufid || (el.cufid = ++at);
		}

		this.get = function(el) {
			var id = identify(el);
			return map[id] || (map[id] = {});
		};

	}

	function Style(style) {

		var custom = {}, sizes = {};

		this.extend = function(styles) {
			for (var property in styles) {
				if (hasOwnProperty(styles, property)) custom[property] = styles[property];
			}
			return this;
		};

		this.get = function(property) {
			return custom[property] != undefined ? custom[property] : style[property];
		};

		this.getSize = function(property, base) {
			return sizes[property] || (sizes[property] = new CSS.Size(this.get(property), base));
		};

		this.isUsable = function() {
			return !!style;
		};

	}

	function addEvent(el, type, listener) {
		if (el.addEventListener) {
			el.addEventListener(type, listener, false);
		}
		else if (el.attachEvent) {
			el.attachEvent('on' + type, function() {
				return listener.call(el, window.event);
			});
		}
	}

	function attach(el, options) {
		var storage = sharedStorage.get(el);
		if (storage.options) return el;
		if (options.hover && options.hoverables[el.nodeName.toLowerCase()]) {
			hoverHandler.attach(el);
		}
		storage.options = options;
		return el;
	}

	function cached(fun) {
		var cache = {};
		return function(key) {
			if (!hasOwnProperty(cache, key)) cache[key] = fun.apply(null, arguments);
			return cache[key];
		};
	}

	function getFont(el, style) {
		var families = CSS.quotedList(style.get('fontFamily').toLowerCase()), family;
		for (var i = 0; family = families[i]; ++i) {
			if (fonts[family]) return fonts[family].get(style.get('fontStyle'), style.get('fontWeight'));
		}
		return null;
	}

	function elementsByTagName(query) {
		return document.getElementsByTagName(query);
	}

	function hasOwnProperty(obj, property) {
		return obj.hasOwnProperty(property);
	}

	function merge() {
		var merged = {}, arg, key;
		for (var i = 0, l = arguments.length; arg = arguments[i], i < l; ++i) {
			for (key in arg) {
				if (hasOwnProperty(arg, key)) merged[key] = arg[key];
			}
		}
		return merged;
	}

	function process(font, text, style, options, node, el) {
		var fragment = document.createDocumentFragment(), processed;
		if (text === '') return fragment;
		var separate = options.separate;
		var parts = text.split(separators[separate]), needsAligning = (separate == 'words');
		if (needsAligning && HAS_BROKEN_REGEXP) {
			// @todo figure out a better way to do this
			if (/^\s/.test(text)) parts.unshift('');
			if (/\s$/.test(text)) parts.push('');
		}
		for (var i = 0, l = parts.length; i < l; ++i) {
			processed = engines[options.engine](font,
				needsAligning ? CSS.textAlign(parts[i], style, i, l) : parts[i],
				style, options, node, el, i < l - 1);
			if (processed) fragment.appendChild(processed);
		}
		return fragment;
	}

	function replaceElement(el, options) {
		var name = el.nodeName.toLowerCase();
		if (options.ignore[name]) return;
		var replace = !options.textless[name];
		var style = CSS.getStyle(attach(el, options)).extend(options);
		var font = getFont(el, style), node, type, next, anchor, text, lastElement;
		if (!font) return;
		for (node = el.firstChild; node; node = next) {
			type = node.nodeType;
			next = node.nextSibling;
			if (replace && type == 3) {
				// Node.normalize() is broken in IE 6, 7, 8
				if (anchor) {
					anchor.appendData(node.data);
					el.removeChild(node);
				}
				else anchor = node;
				if (next) continue;
			}
			if (anchor) {
				el.replaceChild(process(font,
					CSS.whiteSpace(anchor.data, style, anchor, lastElement),
					style, options, node, el), anchor);
				anchor = null;
			}
			if (type == 1) {
				if (node.firstChild) {
					if (node.nodeName.toLowerCase() == 'cufon') {
						engines[options.engine](font, null, style, options, node, el);
					}
					else arguments.callee(node, options);
				}
				lastElement = node;
			}
		}
	}

	var HAS_BROKEN_REGEXP = ' '.split(/\s+/).length == 0;

	var sharedStorage = new Storage();
	var hoverHandler = new HoverHandler();
	var replaceHistory = new ReplaceHistory();
	var initialized = false;

	var engines = {}, fonts = {}, defaultOptions = {
		autoDetect: false,
		engine: null,
		//fontScale: 1,
		//fontScaling: false,
		forceHitArea: false,
		hover: false,
		hoverables: {
			a: true
		},
		ignore: {
			applet: 1,
			canvas: 1,
			col: 1,
			colgroup: 1,
			head: 1,
			iframe: 1,
			map: 1,
			optgroup: 1,
			option: 1,
			script: 1,
			select: 1,
			style: 1,
			textarea: 1,
			title: 1,
			pre: 1
		},
		printable: true,
		//rotation: 0,
		//selectable: false,
		selector: (
				window.Sizzle
			||	(window.jQuery && function(query) { return jQuery(query); }) // avoid noConflict issues
			||	(window.dojo && dojo.query)
			||	(window.Ext && Ext.query)
			||	(window.YAHOO && YAHOO.util && YAHOO.util.Selector && YAHOO.util.Selector.query)
			||	(window.$$ && function(query) { return $$(query); })
			||	(window.$ && function(query) { return $(query); })
			||	(document.querySelectorAll && function(query) { return document.querySelectorAll(query); })
			||	elementsByTagName
		),
		separate: 'words', // 'none' and 'characters' are also accepted
		textless: {
			dl: 1,
			html: 1,
			ol: 1,
			table: 1,
			tbody: 1,
			thead: 1,
			tfoot: 1,
			tr: 1,
			ul: 1
		},
		textShadow: 'none'
	};

	var separators = {
		// The first pattern may cause unicode characters above
		// code point 255 to be removed in Safari 3.0. Luckily enough
		// Safari 3.0 does not include non-breaking spaces in \s, so
		// we can just use a simple alternative pattern.
		words: /\s/.test('\u00a0') ? /[^\S\u00a0]+/ : /\s+/,
		characters: '',
		none: /^/
	};

	api.now = function() {
		DOM.ready();
		return api;
	};

	api.refresh = function() {
		replaceHistory.repeat.apply(replaceHistory, arguments);
		return api;
	};

	api.registerEngine = function(id, engine) {
		if (!engine) return api;
		engines[id] = engine;
		return api.set('engine', id);
	};

	api.registerFont = function(data) {
		if (!data) return api;
		var font = new Font(data), family = font.family;
		if (!fonts[family]) fonts[family] = new FontFamily();
		fonts[family].add(font);
		return api.set('fontFamily', '"' + family + '"');
	};

	api.replace = function(elements, options, ignoreHistory) {
		options = merge(defaultOptions, options);
		if (!options.engine) return api; // there's no browser support so we'll just stop here
		if (!initialized) {
			CSS.addClass(DOM.root(), 'cufon-active cufon-loading');
			CSS.ready(function() {
				// fires before any replace() calls, but it doesn't really matter
				CSS.addClass(CSS.removeClass(DOM.root(), 'cufon-loading'), 'cufon-ready');
			});
			initialized = true;
		}
		if (options.hover) options.forceHitArea = true;
		if (options.autoDetect) delete options.fontFamily;
		if (typeof options.textShadow == 'string') {
			options.textShadow = CSS.textShadow(options.textShadow);
		}
		if (typeof options.color == 'string' && /^-/.test(options.color)) {
			options.textGradient = CSS.gradient(options.color);
		}
		else delete options.textGradient;
		if (!ignoreHistory) replaceHistory.add(elements, arguments);
		if (elements.nodeType || typeof elements == 'string') elements = [ elements ];
		CSS.ready(function() {
			for (var i = 0, l = elements.length; i < l; ++i) {
				var el = elements[i];
				if (typeof el == 'string') api.replace(options.selector(el), options, true);
				else replaceElement(el, options);
			}
		});
		return api;
	};

	api.set = function(option, value) {
		defaultOptions[option] = value;
		return api;
	};

	return api;

})();

Cufon.registerEngine('vml', (function() {

	var ns = document.namespaces;
	if (!ns) return;
	ns.add('cvml', 'urn:schemas-microsoft-com:vml');
	ns = null;

	var check = document.createElement('cvml:shape');
	check.style.behavior = 'url(#default#VML)';
	if (!check.coordsize) return; // VML isn't supported
	check = null;

	var HAS_BROKEN_LINEHEIGHT = (document.documentMode || 0) < 8;

	document.write(('<style type="text/css">' +
		'cufoncanvas{text-indent:0;}' +
		'@media screen{' +
			'cvml\\:shape,cvml\\:rect,cvml\\:fill,cvml\\:shadow{behavior:url(#default#VML);display:block;antialias:true;position:absolute;}' +
			'cufoncanvas{position:absolute;text-align:left;}' +
			'cufon{display:inline-block;position:relative;vertical-align:' +
			(HAS_BROKEN_LINEHEIGHT
				? 'middle'
				: 'text-bottom') +
			';}' +
			'cufon cufontext{position:absolute;left:-10000in;font-size:1px;}' +
			'a cufon{cursor:pointer}' + // ignore !important here
		'}' +
		'@media print{' +
			'cufon cufoncanvas{display:none;}' +
		'}' +
	'</style>').replace(/;/g, '!important;'));

	function getFontSizeInPixels(el, value) {
		return getSizeInPixels(el, /(?:em|ex|%)$|^[a-z-]+$/i.test(value) ? '1em' : value);
	}

	// Original by Dead Edwards.
	// Combined with getFontSizeInPixels it also works with relative units.
	function getSizeInPixels(el, value) {
		if (value === '0') return 0;
		if (/px$/i.test(value)) return parseFloat(value);
		var style = el.style.left, runtimeStyle = el.runtimeStyle.left;
		el.runtimeStyle.left = el.currentStyle.left;
		el.style.left = value.replace('%', 'em');
		var result = el.style.pixelLeft;
		el.style.left = style;
		el.runtimeStyle.left = runtimeStyle;
		return result;
	}

	function getSpacingValue(el, style, size, property) {
		var key = 'computed' + property, value = style[key];
		if (isNaN(value)) {
			value = style.get(property);
			style[key] = value = (value == 'normal') ? 0 : ~~size.convertFrom(getSizeInPixels(el, value));
		}
		return value;
	}

	var fills = {};

	function gradientFill(gradient) {
		var id = gradient.id;
		if (!fills[id]) {
			var stops = gradient.stops, fill = document.createElement('cvml:fill'), colors = [];
			fill.type = 'gradient';
			fill.angle = 180;
			fill.focus = '0';
			fill.method = 'sigma';
			fill.color = stops[0][1];
			for (var j = 1, k = stops.length - 1; j < k; ++j) {
				colors.push(stops[j][0] * 100 + '% ' + stops[j][1]);
			}
			fill.colors = colors.join(',');
			fill.color2 = stops[k][1];
			fills[id] = fill;
		}
		return fills[id];
	}

	return function(font, text, style, options, node, el, hasNext) {

		var redraw = (text === null);

		if (redraw) text = node.alt;

		var viewBox = font.viewBox;

		var size = style.computedFontSize || (style.computedFontSize = new Cufon.CSS.Size(getFontSizeInPixels(el, style.get('fontSize')) + 'px', font.baseSize));

		var wrapper, canvas;

		if (redraw) {
			wrapper = node;
			canvas = node.firstChild;
		}
		else {
			wrapper = document.createElement('cufon');
			wrapper.className = 'cufon cufon-vml';
			wrapper.alt = text;

			canvas = document.createElement('cufoncanvas');
			wrapper.appendChild(canvas);

			if (options.printable) {
				var print = document.createElement('cufontext');
				print.appendChild(document.createTextNode(text));
				wrapper.appendChild(print);
			}

			// ie6, for some reason, has trouble rendering the last VML element in the document.
			// we can work around this by injecting a dummy element where needed.
			// @todo find a better solution
			if (!hasNext) wrapper.appendChild(document.createElement('cvml:shape'));
		}

		var wStyle = wrapper.style;
		var cStyle = canvas.style;

		var height = size.convert(viewBox.height), roundedHeight = Math.ceil(height);
		var roundingFactor = roundedHeight / height;
		var stretchFactor = roundingFactor * Cufon.CSS.fontStretch(style.get('fontStretch'));
		var minX = viewBox.minX, minY = viewBox.minY;

		cStyle.height = roundedHeight;
		cStyle.top = Math.round(size.convert(minY - font.ascent));
		cStyle.left = Math.round(size.convert(minX));

		wStyle.height = size.convert(font.height) + 'px';

		var color = style.get('color');
		var chars = Cufon.CSS.textTransform(text, style).split('');

		var jumps = font.spacing(chars,
			getSpacingValue(el, style, size, 'letterSpacing'),
			getSpacingValue(el, style, size, 'wordSpacing')
		);

		if (!jumps.length) return null;

		var width = jumps.total;
		var fullWidth = -minX + width + (viewBox.width - jumps[jumps.length - 1]);

		var shapeWidth = size.convert(fullWidth * stretchFactor), roundedShapeWidth = Math.round(shapeWidth);

		var coordSize = fullWidth + ',' + viewBox.height, coordOrigin;
		var stretch = 'r' + coordSize + 'ns';

		var fill = options.textGradient && gradientFill(options.textGradient);

		var glyphs = font.glyphs, offsetX = 0;
		var shadows = options.textShadow;
		var i = -1, j = 0, chr;

		while (chr = chars[++i]) {

			var glyph = glyphs[chars[i]] || font.missingGlyph, shape;
			if (!glyph) continue;

			if (redraw) {
				// some glyphs may be missing so we can't use i
				shape = canvas.childNodes[j];
				while (shape.firstChild) shape.removeChild(shape.firstChild); // shadow, fill
			}
			else {
				shape = document.createElement('cvml:shape');
				canvas.appendChild(shape);
			}

			shape.stroked = 'f';
			shape.coordsize = coordSize;
			shape.coordorigin = coordOrigin = (minX - offsetX) + ',' + minY;
			shape.path = (glyph.d ? 'm' + glyph.d + 'xe' : '') + 'm' + coordOrigin + stretch;
			shape.fillcolor = color;

			if (fill) shape.appendChild(fill.cloneNode(false));

			// it's important to not set top/left or IE8 will grind to a halt
			var sStyle = shape.style;
			sStyle.width = roundedShapeWidth;
			sStyle.height = roundedHeight;

			if (shadows) {
				// due to the limitations of the VML shadow element there
				// can only be two visible shadows. opacity is shared
				// for all shadows.
				var shadow1 = shadows[0], shadow2 = shadows[1];
				var color1 = Cufon.CSS.color(shadow1.color), color2;
				var shadow = document.createElement('cvml:shadow');
				shadow.on = 't';
				shadow.color = color1.color;
				shadow.offset = shadow1.offX + ',' + shadow1.offY;
				if (shadow2) {
					color2 = Cufon.CSS.color(shadow2.color);
					shadow.type = 'double';
					shadow.color2 = color2.color;
					shadow.offset2 = shadow2.offX + ',' + shadow2.offY;
				}
				shadow.opacity = color1.opacity || (color2 && color2.opacity) || 1;
				shape.appendChild(shadow);
			}

			offsetX += jumps[j++];
		}

		// addresses flickering issues on :hover

		var cover = shape.nextSibling, coverFill, vStyle;

		if (options.forceHitArea) {

			if (!cover) {
				cover = document.createElement('cvml:rect');
				cover.stroked = 'f';
				cover.className = 'cufon-vml-cover';
				coverFill = document.createElement('cvml:fill');
				coverFill.opacity = 0;
				cover.appendChild(coverFill);
				canvas.appendChild(cover);
			}

			vStyle = cover.style;

			vStyle.width = roundedShapeWidth;
			vStyle.height = roundedHeight;

		}
		else if (cover) canvas.removeChild(cover);

		wStyle.width = Math.max(Math.ceil(size.convert(width * stretchFactor)), 0);

		if (HAS_BROKEN_LINEHEIGHT) {

			var yAdjust = style.computedYAdjust;

			if (yAdjust === undefined) {
				var lineHeight = style.get('lineHeight');
				if (lineHeight == 'normal') lineHeight = '1em';
				else if (!isNaN(lineHeight)) lineHeight += 'em'; // no unit
				style.computedYAdjust = yAdjust = 0.5 * (getSizeInPixels(el, lineHeight) - parseFloat(wStyle.height));
			}

			if (yAdjust) {
				wStyle.marginTop = Math.ceil(yAdjust) + 'px';
				wStyle.marginBottom = yAdjust + 'px';
			}

		}

		return wrapper;

	};

})());

Cufon.registerEngine('canvas', (function() {

	// Safari 2 doesn't support .apply() on native methods

	var check = document.createElement('canvas');
	if (!check || !check.getContext || !check.getContext.apply) return;
	check = null;

	var HAS_INLINE_BLOCK = Cufon.CSS.supports('display', 'inline-block');

	// Firefox 2 w/ non-strict doctype (almost standards mode)
	var HAS_BROKEN_LINEHEIGHT = !HAS_INLINE_BLOCK && (document.compatMode == 'BackCompat' || /frameset|transitional/i.test(document.doctype.publicId));

	var styleSheet = document.createElement('style');
	styleSheet.type = 'text/css';
	styleSheet.appendChild(document.createTextNode((
		'cufon{text-indent:0;}' +
		'@media screen,projection{' +
			'cufon{display:inline;display:inline-block;position:relative;vertical-align:middle;' +
			(HAS_BROKEN_LINEHEIGHT
				? ''
				: 'font-size:1px;line-height:1px;') +
			'}cufon cufontext{display:-moz-inline-box;display:inline-block;width:0;height:0;overflow:hidden;text-indent:-10000in;}' +
			(HAS_INLINE_BLOCK
				? 'cufon canvas{position:relative;}'
				: 'cufon canvas{position:absolute;}') +
		'}' +
		'@media print{' +
			'cufon{padding:0;}' + // Firefox 2
			'cufon canvas{display:none;}' +
		'}'
	).replace(/;/g, '!important;')));
	document.getElementsByTagName('head')[0].appendChild(styleSheet);

	function generateFromVML(path, context) {
		var atX = 0, atY = 0;
		var code = [], re = /([mrvxe])([^a-z]*)/g, match;
		generate: for (var i = 0; match = re.exec(path); ++i) {
			var c = match[2].split(',');
			switch (match[1]) {
				case 'v':
					code[i] = { m: 'bezierCurveTo', a: [ atX + ~~c[0], atY + ~~c[1], atX + ~~c[2], atY + ~~c[3], atX += ~~c[4], atY += ~~c[5] ] };
					break;
				case 'r':
					code[i] = { m: 'lineTo', a: [ atX += ~~c[0], atY += ~~c[1] ] };
					break;
				case 'm':
					code[i] = { m: 'moveTo', a: [ atX = ~~c[0], atY = ~~c[1] ] };
					break;
				case 'x':
					code[i] = { m: 'closePath' };
					break;
				case 'e':
					break generate;
			}
			context[code[i].m].apply(context, code[i].a);
		}
		return code;
	}

	function interpret(code, context) {
		for (var i = 0, l = code.length; i < l; ++i) {
			var line = code[i];
			context[line.m].apply(context, line.a);
		}
	}

	return function(font, text, style, options, node, el) {

		var redraw = (text === null);

		if (redraw) text = node.getAttribute('alt');

		var viewBox = font.viewBox;

		var size = style.getSize('fontSize', font.baseSize);

		var expandTop = 0, expandRight = 0, expandBottom = 0, expandLeft = 0;
		var shadows = options.textShadow, shadowOffsets = [];
		if (shadows) {
			for (var i = shadows.length; i--;) {
				var shadow = shadows[i];
				var x = size.convertFrom(parseFloat(shadow.offX));
				var y = size.convertFrom(parseFloat(shadow.offY));
				shadowOffsets[i] = [ x, y ];
				if (y < expandTop) expandTop = y;
				if (x > expandRight) expandRight = x;
				if (y > expandBottom) expandBottom = y;
				if (x < expandLeft) expandLeft = x;
			}
		}

		var chars = Cufon.CSS.textTransform(text, style).split('');

		var jumps = font.spacing(chars,
			~~size.convertFrom(parseFloat(style.get('letterSpacing')) || 0),
			~~size.convertFrom(parseFloat(style.get('wordSpacing')) || 0)
		);

		if (!jumps.length) return null; // there's nothing to render

		var width = jumps.total;

		expandRight += viewBox.width - jumps[jumps.length - 1];
		expandLeft += viewBox.minX;

		var wrapper, canvas;

		if (redraw) {
			wrapper = node;
			canvas = node.firstChild;
		}
		else {
			wrapper = document.createElement('cufon');
			wrapper.className = 'cufon cufon-canvas';
			wrapper.setAttribute('alt', text);

			canvas = document.createElement('canvas');
			wrapper.appendChild(canvas);

			if (options.printable) {
				var print = document.createElement('cufontext');
				print.appendChild(document.createTextNode(text));
				wrapper.appendChild(print);
			}
		}

		var wStyle = wrapper.style;
		var cStyle = canvas.style;

		var height = size.convert(viewBox.height);
		var roundedHeight = Math.ceil(height);
		var roundingFactor = roundedHeight / height;
		var stretchFactor = roundingFactor * Cufon.CSS.fontStretch(style.get('fontStretch'));
		var stretchedWidth = width * stretchFactor;

		var canvasWidth = Math.ceil(size.convert(stretchedWidth + expandRight - expandLeft));
		var canvasHeight = Math.ceil(size.convert(viewBox.height - expandTop + expandBottom));

		canvas.width = canvasWidth;
		canvas.height = canvasHeight;

		// needed for WebKit and full page zoom
		cStyle.width = canvasWidth + 'px';
		cStyle.height = canvasHeight + 'px';

		// minY has no part in canvas.height
		expandTop += viewBox.minY;

		cStyle.top = Math.round(size.convert(expandTop - font.ascent)) + 'px';
		cStyle.left = Math.round(size.convert(expandLeft)) + 'px';

		var wrapperWidth = Math.max(Math.ceil(size.convert(stretchedWidth)), 0) + 'px';

		if (HAS_INLINE_BLOCK) {
			wStyle.width = wrapperWidth;
			wStyle.height = size.convert(font.height) + 'px';
		}
		else {
			wStyle.paddingLeft = wrapperWidth;
			wStyle.paddingBottom = (size.convert(font.height) - 1) + 'px';
		}

		var g = canvas.getContext('2d'), scale = height / viewBox.height;

		// proper horizontal scaling is performed later
		g.scale(scale, scale * roundingFactor);
		g.translate(-expandLeft, -expandTop);
		g.save();

		function renderText() {
			var glyphs = font.glyphs, glyph, i = -1, j = -1, chr;
			g.scale(stretchFactor, 1);
			while (chr = chars[++i]) {
				var glyph = glyphs[chars[i]] || font.missingGlyph;
				if (!glyph) continue;
				if (glyph.d) {
					g.beginPath();
					if (glyph.code) interpret(glyph.code, g);
					else glyph.code = generateFromVML('m' + glyph.d, g);
					g.fill();
				}
				g.translate(jumps[++j], 0);
			}
			g.restore();
		}

		if (shadows) {
			for (var i = shadows.length; i--;) {
				var shadow = shadows[i];
				g.save();
				g.fillStyle = shadow.color;
				g.translate.apply(g, shadowOffsets[i]);
				renderText();
			}
		}

		var gradient = options.textGradient;
		if (gradient) {
			var stops = gradient.stops, fill = g.createLinearGradient(0, viewBox.minY, 0, viewBox.maxY);
			for (var i = 0, l = stops.length; i < l; ++i) {
				fill.addColorStop.apply(fill, stops[i]);
			}
			g.fillStyle = fill;
		}
		else g.fillStyle = style.get('color');

		renderText();

		return wrapper;

	};

})());/*!
 * The following copyright notice may not be removed under any circumstances.
 * 
 * Copyright:
 * © 1987, 1991, 1995, 1998, 2001, 2002 Adobe Systems Incorporated. All rights
 * reserved.
 * 
 * Full name:
 * CooperBlackStd
 * 
 * Manufacturer:
 * Adobe Systems Incorporated
 * 
 * Designer:
 * Oswald Bruce Cooper
 * 
 * Vendor URL:
 * http://www.adobe.com/type
 * 
 * License information:
 * http://www.adobe.com/type/legal.html
 */
Cufon.registerFont({"w":226,"face":{"font-family":"Cooper Std","font-weight":900,"font-stretch":"normal","units-per-em":"360","panose-1":"2 8 9 3 4 3 11 2 4 4","ascent":"252","descent":"-108","cap-height":"4","bbox":"-8 -289.08 396 90","underline-thickness":"18","underline-position":"-18","stemh":"39","stemv":"81","unicode-range":"U+0020-U+007E"},"glyphs":{" ":{"w":113},"!":{"d":"98,-35v0,22,-18,40,-40,40v-22,0,-40,-18,-40,-40v0,-22,18,-40,40,-40v22,0,40,18,40,40xm58,-103v-27,-15,-43,-63,-43,-99v0,-27,12,-55,43,-55v76,0,40,129,0,154","w":116},"\"":{"d":"57,-118v-25,-14,-38,-57,-39,-90v0,-24,12,-49,39,-49v67,0,35,116,0,139xm155,-118v-25,-14,-38,-57,-39,-90v0,-24,12,-49,39,-49v68,0,35,116,0,139","w":211},"#":{"d":"146,-59r-7,52v-1,9,-11,7,-21,7v-4,0,-7,-3,-6,-7r7,-52v1,-10,-10,-7,-18,-7v-4,0,-7,3,-7,7r-8,52v-1,9,-11,7,-21,7v-4,0,-7,-3,-6,-7r8,-52v-1,-17,-36,6,-29,-27v3,-17,41,6,37,-27v-2,-17,-35,7,-29,-28v3,-15,33,2,35,-13r6,-49v1,-9,12,-7,22,-7v4,0,6,3,5,7r-7,49v-2,8,10,6,18,6v25,-7,-8,-67,36,-62v4,0,7,3,6,7r-7,49v0,15,36,-8,29,27v-4,18,-43,-8,-36,27v-2,17,37,-8,28,27v0,16,-32,-2,-35,14xm109,-120v-14,6,-12,36,9,27v14,-5,13,-34,-9,-27"},"$":{"d":"129,-229v0,20,30,21,46,15v20,-2,58,72,15,72v-19,0,-33,-37,-66,-37v-10,0,-20,5,-20,17v0,35,110,14,110,97v0,47,-51,72,-77,74v-20,2,5,40,-26,30v-29,8,-13,-21,-27,-29v-14,-2,-42,-8,-52,-16v-13,-9,-20,-42,-20,-56v0,-8,4,-16,13,-16v25,0,20,50,76,50v8,0,26,-4,26,-16v0,-11,-3,-13,-42,-27v-33,-12,-67,-34,-67,-73v0,-36,29,-65,63,-71v21,-3,-4,-40,27,-30v17,0,21,-2,21,16"},"%":{"d":"302,-66v2,79,-145,95,-146,8v-2,-86,143,-91,146,-8xm234,-31v23,-7,6,-63,-12,-67v-7,0,-11,8,-11,14v0,6,5,53,23,53xm151,-195v2,80,-144,94,-146,8v-2,-86,143,-91,146,-8xm83,-160v25,-7,6,-63,-12,-67v-7,0,-11,8,-11,14v0,6,5,53,23,53xm242,-249v-10,26,-91,152,-116,197v-25,45,-23,54,-39,54v-5,0,-21,-2,-21,-10v11,-24,111,-182,137,-234v3,-17,30,-22,39,-7","w":306},"&":{"d":"170,-77v-11,0,-17,-17,-17,-26v0,-73,99,-66,99,-96v0,-19,-25,1,-26,-15v14,-46,103,-36,103,17v0,46,-54,58,-54,69v0,10,27,12,27,43v0,39,-52,90,-150,90v-95,0,-147,-50,-147,-101v0,-45,40,-53,40,-60v0,-4,-13,-21,-13,-38v0,-40,44,-68,89,-68v20,0,64,8,64,35v0,10,-11,21,-21,21v-11,0,-19,-15,-36,-15v-14,0,-22,11,-22,24v0,35,39,12,39,37v0,43,-42,14,-42,47v0,36,35,74,72,74v24,0,54,-15,54,-43v0,-13,-11,-22,-24,-22v-23,0,-23,27,-35,27","w":328},"(":{"d":"25,-126v0,-74,36,-163,120,-163v36,0,40,9,40,18v5,19,-24,20,-34,16v-43,0,-48,98,-48,129v0,31,5,129,48,129v9,-3,39,-3,34,16v0,9,-4,18,-40,18v-84,0,-120,-89,-120,-163","w":188},")":{"d":"163,-126v0,74,-35,163,-119,163v-36,0,-40,-9,-40,-18v-6,-19,24,-20,33,-16v43,0,48,-98,48,-129v0,-31,-5,-129,-48,-129v-9,3,-39,3,-33,-16v0,-9,4,-18,40,-18v84,0,119,89,119,163","w":188},"*":{"d":"152,-215v9,11,25,-7,40,-7v13,0,15,28,15,29v0,17,-40,10,-40,20v0,3,22,26,22,35v0,6,-21,22,-27,22v-9,0,-21,-37,-28,-37v-5,0,-25,33,-34,33v-6,0,-24,-14,-24,-22v0,-13,26,-29,26,-35v0,-8,-36,-7,-36,-23v0,-5,6,-27,14,-27v16,-2,42,31,38,-3v-1,-15,-1,-27,15,-27v9,0,22,-1,22,11v0,8,-3,21,-3,31","w":272},"+":{"d":"113,-179v52,-1,-7,79,40,66v24,3,48,-12,48,21v0,33,-24,18,-48,21v-30,-8,-19,21,-19,43v0,16,2,23,-21,23v-33,0,-16,-24,-20,-48v12,-47,-66,13,-67,-39v-1,-33,24,-18,48,-21v30,7,19,-20,19,-43v0,-16,-3,-23,20,-23"},",":{"d":"51,67v-36,0,0,-33,0,-57v0,-15,-39,-7,-39,-51v0,-23,19,-44,42,-44v33,0,48,32,48,61v0,32,-23,91,-51,91","w":113},"-":{"d":"108,-118v-6,19,-10,59,-34,58v-26,-9,-74,10,-74,-13v5,-19,10,-58,34,-57v26,9,74,-11,74,12","w":107},".":{"d":"100,-39v0,24,-19,44,-43,44v-24,0,-44,-20,-44,-44v0,-24,20,-43,44,-43v24,0,43,19,43,43","w":113},"\/":{"d":"179,-239r-128,259v-13,26,-12,33,-28,33v-9,0,-31,-1,-31,-13r128,-259v13,-26,12,-33,28,-33v9,0,31,1,31,13","w":178},"0":{"d":"9,-105v0,-61,38,-107,101,-107v61,0,107,51,107,111v0,71,-57,106,-104,106v-62,0,-104,-50,-104,-110xm137,-78v0,-17,-6,-80,-30,-80v-15,0,-17,16,-17,28v0,16,7,81,30,81v14,0,17,-18,17,-29"},"1":{"d":"210,-20v0,32,-64,25,-95,25v-13,0,-100,-2,-100,-27v1,-17,20,-12,35,-12v14,0,19,-10,19,-51v0,-31,19,-71,-32,-71v-8,0,-14,-3,-14,-11v0,-25,81,-45,134,-45v11,0,30,1,30,16v0,18,-26,5,-27,39v-1,40,-4,70,2,105v5,32,48,6,48,32"},"2":{"d":"3,-9v7,-21,90,-83,88,-120v0,-13,-7,-20,-20,-20v-22,0,-26,21,-43,21v-10,0,-23,-10,-23,-21v0,-32,68,-63,112,-63v61,0,86,28,86,56v0,46,-60,76,-60,91v10,30,52,-8,59,-9v42,16,-4,101,-24,91v-20,0,-2,-17,-35,-17r-119,0v-6,0,-21,1,-21,-9"},"3":{"d":"112,-39v0,-31,-42,-33,-64,-27v-9,0,-15,-21,-15,-28v0,-15,48,-13,48,-47v0,-13,-14,-24,-28,-24v-18,0,-30,13,-36,13v-8,0,-13,-13,-13,-20v0,-19,50,-40,92,-40v29,0,88,9,88,47v0,31,-27,38,-27,46v0,13,61,1,61,64v0,46,-42,93,-137,93v-18,0,-82,-3,-82,-29v7,-32,30,-13,65,-13v23,0,48,-13,48,-35"},"4":{"d":"53,-71v4,12,25,7,37,8v25,0,25,0,25,-23v0,-15,6,-51,-8,-50v-23,7,-45,46,-54,65xm217,-25v5,24,-26,5,-19,37v10,38,-42,18,-70,23v-34,6,4,-53,-33,-45v-34,-6,-92,17,-91,-24v0,-27,4,-35,37,-73r83,-96v15,-14,31,-23,52,-23v17,0,17,11,17,24r0,119v-8,25,30,3,24,29r0,29"},"5":{"d":"179,-145r-76,0v-8,0,-18,-1,-18,11v0,9,10,9,18,10v93,10,112,51,112,76v0,46,-54,87,-131,87v-58,0,-69,-16,-69,-29v0,-46,85,15,85,-38v0,-23,-34,-32,-52,-35v-10,-1,-36,-3,-36,-18v0,-18,17,-68,24,-86v17,-45,19,-43,37,-43r123,0v13,0,17,1,17,16v0,17,-7,49,-34,49"},"6":{"d":"141,-219v-9,18,-37,40,-35,57v6,18,22,-3,48,-3v39,0,69,33,69,71v0,50,-40,99,-106,99v-66,0,-111,-47,-111,-108v0,-59,62,-137,84,-137v8,0,51,10,51,21xm144,-62v0,-17,-11,-50,-32,-50v-13,0,-18,11,-18,22v0,15,16,45,33,45v10,0,17,-7,17,-17"},"7":{"d":"39,-220v26,13,108,13,157,10v16,-1,28,12,19,27r-72,219v-3,9,-3,12,-21,12v-44,0,-63,-10,-53,-29r65,-124v3,-6,10,-18,10,-24v0,-14,-32,-12,-43,-12v-72,0,-37,22,-67,22v-49,0,-23,-105,5,-101"},"8":{"d":"188,-131v58,43,48,136,-68,136v-44,0,-116,-17,-116,-73v0,-33,30,-40,30,-48v0,-6,-24,-18,-24,-49v0,-45,48,-69,99,-69v36,0,110,11,110,59v0,31,-31,37,-31,44xm150,-176v1,-26,-45,-34,-50,-10v0,13,26,31,38,31v9,0,12,-14,12,-21xm136,-51v0,-26,-39,-32,-61,-39v-7,0,-9,8,-9,14v0,23,22,44,45,44v12,0,25,-5,25,-19"},"9":{"d":"178,-14v-11,15,-50,62,-69,62v-12,-1,-66,-22,-39,-35v17,-9,36,-35,36,-49v-1,-11,-16,-5,-25,-6v-52,0,-76,-45,-76,-86v3,-115,215,-113,215,3v0,41,-18,78,-42,111xm139,-109v0,-15,-9,-50,-30,-50v-33,7,-17,69,13,70v11,0,17,-10,17,-20"},":":{"d":"100,-145v0,24,-19,43,-43,43v-24,0,-44,-19,-44,-43v0,-24,20,-44,44,-44v24,0,43,20,43,44xm100,-39v0,24,-19,44,-43,44v-24,0,-44,-20,-44,-44v0,-24,20,-43,44,-43v24,0,43,19,43,43","w":113},";":{"d":"102,-24v0,32,-23,91,-51,91v-36,0,0,-33,0,-57v0,-15,-39,-7,-39,-51v0,-23,19,-44,42,-44v33,0,48,32,48,61xm99,-145v0,24,-20,43,-44,43v-24,0,-43,-19,-43,-43v0,-24,19,-44,43,-44v24,0,44,20,44,44","w":113},"<":{"d":"93,-92r94,41v22,5,16,35,6,46v-56,-20,-107,-46,-161,-68v-9,-8,-9,-30,0,-38r161,-68v11,8,16,43,-6,46"},"=":{"d":"177,-107r-127,0v-16,0,-24,3,-24,-20v0,-23,8,-21,24,-21r127,0v16,0,24,-2,24,21v0,23,-8,20,-24,20xm177,-36r-127,0v-16,0,-24,2,-24,-21v0,-23,8,-21,24,-21r127,0v16,0,24,-2,24,21v0,23,-8,21,-24,21"},">":{"d":"40,-51r94,-41r-94,-41v-21,-4,-17,-34,-7,-46v57,19,107,46,161,68v10,8,10,30,0,38r-161,68v-10,-9,-15,-43,7,-46"},"?":{"d":"70,-201v0,39,-67,54,-67,12v0,-31,31,-68,87,-68v37,0,89,24,89,67v0,22,-14,40,-41,50v-37,14,-16,41,-51,41v-15,0,-24,-8,-24,-23v0,-31,31,-47,31,-78v0,-8,-3,-19,-12,-19v-10,0,-12,10,-12,18xm125,-35v0,22,-18,40,-40,40v-22,0,-40,-18,-40,-40v0,-22,18,-40,40,-40v22,0,40,18,40,40","w":182},"@":{"d":"213,-180v2,17,-23,74,-10,87v4,0,28,-11,33,-55v4,-32,-18,-84,-89,-84v-56,0,-107,43,-111,106v-5,66,43,105,104,105v64,0,76,-66,96,-23v0,4,-47,49,-105,49v-74,0,-131,-52,-122,-128v9,-75,68,-134,144,-134v55,0,117,37,111,104v-5,63,-54,98,-109,98v-23,0,-10,-22,-18,-22v-6,0,-21,23,-48,23v-21,0,-33,-16,-30,-42v8,-62,64,-114,112,-83v5,0,18,-10,33,-10v8,0,9,2,9,9xm124,-95v9,0,33,-37,35,-58v0,-4,0,-8,-4,-8v-9,0,-33,28,-36,56v0,4,0,10,5,10","w":272},"A":{"d":"133,-157v-16,8,-17,33,-24,48v5,11,26,3,40,5v4,0,14,0,14,-5v-6,-15,-14,-42,-30,-48xm30,-42v29,-49,69,-108,69,-173v0,-25,12,-43,44,-43v31,0,51,31,65,55v6,10,61,120,74,150v12,27,31,11,31,32v0,26,-51,25,-69,25v-51,0,-83,-1,-83,-23v0,-17,22,-10,22,-23v0,-16,-9,-18,-67,-18v-19,0,-30,1,-30,19v0,14,23,4,23,23v0,38,-124,23,-109,1v0,-17,22,-11,30,-25","w":312},"B":{"d":"162,-255v103,1,95,73,57,114v0,5,3,5,7,7v15,6,40,26,40,56v0,36,-24,80,-96,80r-141,0v-11,0,-24,-6,-24,-19v0,-22,24,0,26,-60r4,-103v2,-54,-29,-30,-29,-55v13,-42,83,-7,131,-19v8,0,17,-1,25,-1xm132,-217v-21,0,-12,30,-12,50v0,14,0,21,11,21v22,0,26,-15,26,-35v0,-16,-5,-36,-25,-36xm134,-111v-18,0,-13,16,-14,32v0,42,7,43,18,43v21,0,28,-14,28,-33v0,-22,-7,-42,-32,-42","w":271},"C":{"d":"9,-127v0,-74,69,-130,140,-130v48,1,55,24,84,15v15,0,34,22,34,62v0,21,-12,38,-33,38v-37,0,-28,-64,-92,-64v-28,0,-39,26,-39,46v0,53,28,99,78,99v46,0,53,-25,64,-25v34,10,6,68,-19,70v-12,0,-38,21,-80,21v-76,0,-137,-60,-137,-132","w":272},"D":{"d":"35,-68r2,-125v1,-37,-26,-20,-26,-43v0,-17,21,-19,34,-19r117,0v100,0,133,62,133,127v0,80,-62,144,-170,129v-42,-5,-109,18,-120,-20v0,-26,29,4,30,-49xm124,-196r0,134v0,18,3,26,22,26v45,0,53,-46,53,-82v0,-84,-31,-98,-59,-98v-15,0,-16,6,-16,20","w":303},"E":{"d":"225,4v-56,0,-131,-3,-194,-4v-24,0,-24,-10,-24,-15v0,-20,24,-5,27,-43v4,-66,5,-59,1,-124v-3,-55,-30,-26,-30,-52v0,-22,30,-18,45,-18v43,1,148,1,165,-8v21,0,29,36,29,52v0,12,-5,25,-19,25v-28,0,-6,-34,-74,-34v-40,0,-36,8,-36,49v0,21,1,21,23,21v27,0,7,-40,33,-40v21,0,22,41,22,55v0,15,-2,58,-24,58v-22,0,-1,-38,-37,-38v-15,0,-14,13,-14,25v0,53,3,50,41,50v74,0,53,-50,83,-50v40,10,0,91,-17,91","w":261},"F":{"d":"32,-50v12,-41,7,-100,4,-149v-2,-31,-28,-16,-28,-36v11,-41,76,-10,131,-16v7,0,80,-4,85,-4v21,-1,49,78,9,78v-25,0,-12,-37,-81,-37v-22,0,-31,-2,-31,50v0,6,0,13,21,13v28,0,10,-33,35,-33v21,0,22,39,22,53v0,17,-2,60,-26,60v-23,0,1,-40,-38,-40v-16,0,-14,3,-14,40v0,53,35,24,35,51v0,8,3,24,-84,24v-58,0,-67,-9,-67,-24v0,-20,22,-10,27,-30","w":250,"k":{"A":32,",":30,".":31}},"G":{"d":"102,-148v0,74,43,100,66,100v13,0,22,-9,22,-22v0,-30,-38,-1,-38,-34v0,-26,55,-28,73,-28v68,0,72,20,72,30v1,20,-26,11,-30,29v-12,53,-64,78,-115,78v-76,0,-143,-52,-143,-132v0,-97,109,-152,199,-121v35,-19,59,21,58,50v0,18,-9,36,-28,36v-36,0,-36,-50,-85,-50v-31,0,-51,26,-51,64","w":300},"H":{"d":"298,-231v-11,34,-26,-1,-26,78r0,94v-5,21,23,19,24,36v0,9,-1,27,-72,27v-16,0,-62,-1,-62,-25v0,-28,25,3,25,-70v0,-19,-4,-18,-22,-18v-50,0,-46,1,-46,33v0,49,22,30,22,53v0,25,-52,27,-69,27v-17,0,-67,-2,-67,-26v0,-8,6,-12,12,-15v13,-6,17,-5,17,-80v0,-96,-2,-88,-15,-95v-5,-3,-11,-7,-11,-14v0,-28,60,-30,80,-30v15,0,57,1,57,23v0,30,-26,9,-26,62v0,26,23,17,45,17v24,0,23,-3,23,-14v2,-59,-15,-33,-24,-61v0,-7,-2,-27,70,-27v17,0,65,0,65,25","w":303},"I":{"d":"27,-205v-8,-10,-22,-11,-22,-25v0,-26,74,-26,81,-26v22,0,66,1,66,25v0,13,-15,12,-22,21v-14,17,-12,172,4,169v9,5,18,7,18,18v0,11,-4,27,-83,27v-15,0,-60,0,-60,-23v0,-12,12,-14,18,-21v11,-4,12,-163,0,-165","w":156},"J":{"d":"206,-189r-3,111v-2,76,-81,83,-101,83v-42,0,-105,-18,-105,-69v0,-23,17,-43,41,-43v27,0,50,24,39,53v0,9,7,14,16,13v42,-4,22,-78,25,-143v2,-40,-32,-18,-32,-42v0,-7,3,-30,73,-30v68,0,76,16,76,26v0,19,-28,11,-29,41","w":237},"K":{"d":"219,0v-38,-5,-54,-69,-89,-82v-11,0,-10,15,-10,27v0,17,22,19,22,37v0,12,-8,22,-71,22v-57,0,-65,-10,-65,-22v0,-19,19,-9,23,-39v4,-44,6,-91,0,-134v-4,-31,-24,-17,-24,-39v0,-6,-3,-26,76,-26v17,0,54,-1,54,24v0,19,-20,8,-20,50v0,5,1,15,7,15v10,0,38,-37,38,-45v0,-8,-6,-11,-6,-19v0,-27,48,-25,65,-25v17,0,59,-3,59,23v0,30,-37,12,-50,25v-7,7,-38,29,-38,44v0,10,9,18,15,25r75,86v11,12,33,11,33,33v0,35,-60,15,-94,20","w":312},"L":{"d":"205,5v-49,-6,-109,-4,-165,-5v-12,0,-30,1,-30,-16v0,-22,28,-3,29,-45v2,-49,1,-90,-2,-133v-2,-30,-32,-14,-32,-35v0,-47,171,-25,150,-3v0,21,-29,5,-29,39r0,115v0,26,4,38,30,38v61,0,41,-50,64,-50v47,0,10,98,-15,95","w":239,"k":{"T":26,"V":32,"W":31,"y":10,"Y":28}},"M":{"d":"87,-117v-11,0,-7,48,-7,60v0,39,23,21,23,40v0,21,-39,21,-53,21v-13,0,-45,-1,-45,-20v0,-21,22,-3,25,-33v2,-30,14,-120,0,-157v-3,-8,-24,-10,-24,-25v0,-21,33,-25,62,-25v42,0,42,7,53,25v13,21,34,80,50,84v11,3,26,-41,39,-65v18,-34,18,-44,66,-44v16,0,52,0,52,23v0,14,-16,18,-19,30v-10,48,-6,79,-2,147v1,26,22,21,22,37v0,24,-49,23,-65,23v-15,0,-64,1,-64,-22v0,-13,16,-14,19,-26v1,-6,9,-68,-4,-68v-25,9,-39,99,-64,106v-17,5,-39,-94,-64,-111","w":334},"N":{"d":"112,-240v36,29,66,64,108,88v16,-7,8,-37,6,-53v-5,-15,-24,-10,-24,-29v0,-23,37,-22,52,-22v16,0,55,-2,55,23v0,21,-20,12,-25,29v-11,41,-3,94,-5,142v0,16,2,66,-22,66v-7,0,-14,-4,-19,-9r-111,-100v-5,-5,-14,-13,-22,-13v-18,8,-12,44,-9,64v3,23,25,14,25,32v0,24,-37,26,-54,26v-17,0,-54,-3,-54,-26v0,-19,20,-11,24,-34v6,-42,6,-89,0,-133v-5,-36,-32,-21,-32,-43v0,-26,49,-24,65,-24v22,0,25,3,42,16","w":314},"O":{"d":"144,5v-76,0,-135,-55,-135,-132v0,-76,61,-130,139,-130v99,0,137,88,137,134v0,77,-68,128,-141,128xm193,-87v0,-33,-20,-117,-62,-117v-20,0,-30,21,-30,39v0,31,22,116,61,116v22,0,31,-19,31,-38","w":294},"P":{"d":"171,-174v0,-23,-12,-41,-36,-41v-14,0,-14,5,-14,12r0,54v0,8,-2,15,17,15v24,0,33,-18,33,-40xm39,-57r0,-141v0,-27,-34,-12,-34,-35v0,-23,32,-16,54,-16v52,0,91,-6,99,-6v49,0,96,26,96,80v0,65,-60,89,-127,81v-11,0,-4,17,-6,26v1,45,28,26,28,47v0,23,-52,25,-68,25v-15,0,-69,-1,-69,-24v0,-20,27,-7,27,-37","w":258,"k":{"A":33,",":29,".":32}},"Q":{"d":"193,-87v0,-33,-20,-117,-62,-117v-20,0,-30,21,-30,39v0,31,22,116,61,116v22,0,31,-19,31,-38xm204,67v-67,0,-126,-56,-183,-53v-6,0,-8,-5,-8,-10v0,-18,18,-27,36,-23v2,0,5,-1,5,-4v0,-8,-45,-32,-45,-104v0,-76,61,-130,139,-130v99,0,137,88,137,134v0,57,-32,97,-85,118v-2,1,-5,3,-5,5v0,6,12,17,54,17v24,0,38,-16,38,7v0,11,-24,43,-83,43","w":295},"R":{"d":"131,-215v-23,1,-11,34,-15,53v-1,9,-3,18,9,18v23,0,31,-14,31,-36v0,-18,-4,-35,-25,-35xm32,-75r0,-102v0,-56,-27,-34,-27,-56v15,-42,76,-14,122,-21v59,-9,122,4,122,65v0,22,-10,43,-30,52v-9,4,-5,13,3,16v25,8,37,26,42,65v4,33,27,13,27,35v0,14,-16,28,-57,28v-58,0,-65,-32,-76,-80v-4,-17,-10,-33,-30,-33v-8,0,-11,1,-11,24v0,10,1,24,3,34v3,17,21,12,21,29v0,13,-9,23,-67,23v-17,0,-69,0,-69,-26v0,-19,27,-6,27,-53","w":293,"k":{"T":17,"V":26,"W":27,"y":26,"Y":26}},"S":{"d":"49,-110v-64,-50,-36,-147,71,-147v38,0,49,17,72,6v12,0,40,27,40,57v0,12,-8,24,-21,24v-24,0,-39,-41,-76,-41v-11,0,-23,5,-23,18v0,28,50,20,91,49v70,50,31,150,-85,149v-24,0,-64,-6,-85,-17v-17,-10,-25,-48,-25,-66v0,-10,4,-20,15,-20v26,0,21,57,87,57v8,0,28,-3,28,-17v0,-26,-49,-21,-89,-52","w":244},"T":{"d":"46,-257r176,0v14,0,43,27,43,66v0,18,-9,30,-27,30v-31,0,-32,-42,-50,-42v-14,0,-12,19,-12,22r0,110v0,43,33,23,33,48v0,11,-7,27,-74,27v-18,0,-86,1,-86,-27v0,-19,24,-10,29,-25v12,-33,7,-78,9,-118v2,-38,-6,-37,-11,-37v-16,0,-25,42,-54,42v-14,0,-22,-13,-22,-26v0,-31,25,-70,46,-70","w":265,"k":{"w":-12,"y":-11,"A":28,",":27,".":30,"u":-6,"a":12,"c":15,"e":15,"i":-16,"o":15,"s":11,":":-18,";":-20}},"U":{"d":"226,-100r0,-90v0,-39,-31,-24,-31,-45v0,-22,42,-21,57,-21v14,0,53,0,53,21v0,20,-27,7,-27,40r0,97v0,16,1,103,-124,103v-142,0,-126,-110,-126,-114r0,-83v1,-23,-23,-22,-23,-39v0,-5,-4,-25,70,-25v59,0,71,11,71,25v0,26,-27,1,-28,45v-2,63,-8,137,54,137v57,0,54,-47,54,-51","w":310},"V":{"d":"306,-235v-10,30,-26,3,-46,43r-81,165v-8,15,-15,31,-34,31v-21,0,-26,-12,-34,-29r-72,-158v-11,-23,-14,-28,-28,-30v-7,-1,-11,-6,-11,-14v0,-28,58,-29,76,-29v76,0,72,18,72,23v0,14,-17,14,-17,24v0,8,14,36,23,55v3,6,7,20,15,20v12,1,18,-19,22,-27v4,-9,21,-41,21,-50v0,-13,-18,-9,-18,-23v0,-22,45,-22,59,-22v45,0,53,8,53,21","w":303,"k":{"y":30,"A":53,",":44,".":45,"r":32,"u":22,"-":23,"a":35,"e":48,"i":-7,"o":48,":":13,";":12}},"W":{"d":"149,-138v21,-18,35,-55,5,-77v-7,-5,-13,-9,-13,-18v0,-2,-5,-23,70,-23v70,0,68,16,68,22v0,12,-16,15,-16,24v0,10,12,32,16,40v3,6,10,28,19,28v12,0,28,-61,28,-66v0,-15,-24,-7,-24,-27v0,-22,37,-21,52,-21v15,0,42,2,42,22v0,18,-15,13,-25,38r-62,162v-5,38,-51,52,-67,13r-33,-79v-2,-4,-4,-15,-10,-15v-15,7,-31,66,-41,87v-9,19,-12,32,-35,32v-20,0,-26,-12,-32,-29r-67,-171v-10,-26,-24,-13,-24,-35v0,-25,48,-25,65,-25v72,0,67,14,53,46v8,27,13,57,31,72","w":393,"k":{"y":14,"A":47,",":30,".":31,"r":21,"u":11,"-":19,"a":30,"e":30,"i":-8,"o":30,":":6,";":4}},"X":{"d":"158,-39v0,-12,-16,-35,-26,-41v-5,0,-27,33,-27,38v0,8,15,7,15,23v0,10,-9,23,-60,23v-51,0,-60,-13,-60,-25v0,-9,6,-17,21,-17v28,0,62,-58,81,-81v-17,-27,-38,-49,-56,-74v-18,-24,-40,-12,-40,-33v0,-8,1,-30,89,-30v72,0,70,22,50,44v0,5,13,22,17,22v5,0,18,-18,18,-22v0,-8,-13,-7,-13,-22v0,-12,9,-22,62,-22v15,0,52,-1,52,22v0,17,-13,16,-26,18v-32,6,-47,41,-65,64v22,33,49,61,72,92v18,23,39,14,39,35v0,11,-2,29,-90,29v-15,0,-68,2,-68,-22v0,-14,15,-13,15,-21","w":300},"Y":{"d":"251,-206v-23,28,-61,53,-61,104v0,33,2,48,5,55v5,10,24,8,24,25v0,26,-57,26,-75,26v-71,0,-80,-16,-80,-26v0,-19,21,-12,27,-27v5,-14,15,-89,-10,-103r-40,-47v-18,-21,-41,-15,-41,-33v0,-8,-3,-24,81,-24v75,0,74,14,74,22v0,9,-10,12,-10,20v0,8,14,31,23,31v9,0,25,-20,25,-28v0,-10,-10,-10,-10,-24v0,-21,41,-21,55,-21v45,0,57,5,57,21v0,23,-27,9,-44,29","w":294,"k":{"v":31,"A":45,",":39,".":40,"u":22,"-":26,"a":45,"e":46,"i":-5,"o":46,":":14,";":12,"p":30,"q":46}},"Z":{"d":"36,-255v49,11,128,0,184,-1v22,-1,18,23,10,37r-78,133v-3,5,-16,27,-16,33v0,9,20,8,25,8v63,0,43,-48,70,-48v18,0,26,11,26,28v0,59,-24,76,-73,65r-152,0v-12,0,-26,3,-26,-14v31,-66,72,-122,105,-185v0,-9,-15,-11,-24,-11v-45,0,-34,49,-60,49v-49,0,-8,-94,9,-94","w":259},"[":{"d":"116,-226r0,200v-7,33,18,31,45,29v8,0,18,3,18,12v0,22,-28,21,-70,21v-51,0,-63,5,-63,-62r0,-200v0,-67,12,-63,63,-63v42,0,70,-1,70,21v0,17,-24,11,-40,11v-25,0,-23,8,-23,31","w":188},"\\":{"d":"141,20r-141,-259v0,-12,22,-13,31,-13v19,0,17,7,31,33r142,259v0,12,-24,13,-33,13v-16,0,-16,-7,-30,-33","w":178},"]":{"d":"73,-26r0,-200v7,-34,-19,-29,-46,-29v-8,0,-17,-4,-17,-13v0,-22,27,-21,69,-21v51,0,63,-4,63,63r0,200v0,67,-12,62,-63,62v-42,0,-69,1,-69,-21v0,-30,77,11,63,-41","w":188},"^":{"d":"154,-73r-41,-95r-41,95v-5,21,-34,15,-46,6v19,-57,46,-107,68,-161v8,-9,30,-9,38,0r69,161v-9,9,-43,15,-47,-6"},"_":{"d":"0,27r180,0r0,18r-180,0r0,-18","w":180},"a":{"d":"100,-77v-22,-1,-28,40,-5,42v19,0,22,-39,5,-42xm117,-13v-29,24,-113,29,-112,-33v0,-26,25,-58,88,-58v11,0,16,1,16,-12v0,-12,0,-37,-17,-37v-22,0,-24,39,-56,39v-12,0,-20,-8,-20,-20v0,-31,61,-50,95,-50v21,0,77,8,77,62r0,36v0,63,22,29,22,48v0,21,-29,43,-55,43v-28,0,-29,-18,-38,-18","w":214},"b":{"d":"108,-162v10,-6,31,-22,54,-22v38,0,71,32,71,80v0,62,-46,109,-108,109v-45,0,-66,-23,-72,-23v-6,0,-32,13,-35,-2v8,-14,9,-120,8,-160v0,-21,-27,-11,-27,-32v0,-24,69,-40,99,-40v10,0,9,7,9,15r-2,70v0,2,0,5,3,5xm152,-73v0,-17,-5,-56,-29,-56v-16,0,-17,14,-17,26v0,70,4,75,18,75v24,0,28,-27,28,-45","w":239},"c":{"d":"6,-90v0,-52,46,-94,106,-94v54,0,82,30,82,55v0,20,-15,36,-35,36v-39,0,-22,-45,-50,-45v-16,0,-24,17,-24,31v0,27,20,53,48,53v34,0,47,-20,54,10v0,21,-33,49,-83,49v-54,0,-98,-40,-98,-95","w":199},"d":{"d":"144,-100v0,-14,0,-45,-21,-45v-24,0,-29,42,-29,59v0,17,5,46,27,46v24,0,23,-44,23,-60xm142,-16v-12,5,-28,21,-52,21v-47,0,-84,-50,-84,-94v0,-48,39,-95,89,-95v25,0,39,11,43,11v5,0,5,-12,5,-16v0,-22,-26,-11,-26,-30v0,-27,92,-33,93,-33v11,0,13,7,13,19r0,172v0,25,19,17,19,36v0,27,-79,29,-83,29v-18,0,-5,-20,-17,-20","w":245},"e":{"d":"173,-83r-78,0v-4,0,-10,-1,-10,5v0,18,24,33,41,33v27,0,40,-16,48,-16v8,0,14,11,14,18v0,28,-52,48,-84,48v-65,0,-98,-47,-98,-93v0,-55,47,-96,101,-96v61,0,88,47,88,74v0,24,-10,27,-22,27xm105,-117v10,0,21,2,21,-11v0,-13,-8,-23,-21,-23v-12,0,-21,12,-21,24v0,13,12,10,21,10","w":200},"f":{"d":"30,-54v0,-20,15,-56,-12,-56v-4,0,-15,1,-15,-5v0,-28,-2,-30,9,-32v25,-5,-4,-21,-4,-50v0,-43,44,-57,80,-57v59,0,73,31,73,46v0,15,-13,28,-28,28v-31,0,-35,-32,-56,-32v-7,0,-12,6,-12,13v0,23,38,30,44,46v7,11,43,-5,40,10v-3,12,4,34,-11,33v-35,-9,-26,33,-21,55v5,22,32,11,32,33v0,9,-1,26,-82,26v-17,0,-64,-1,-64,-26v0,-20,27,-10,27,-32","w":160,"k":{"f":-14}},"g":{"d":"126,-114v0,-15,-3,-42,-23,-42v-32,2,-26,70,1,70v16,0,22,-14,22,-28xm58,18v0,19,28,24,42,24v12,0,39,-1,39,-18v0,-24,-51,-2,-76,-12v-3,0,-5,3,-5,6xm216,-3v0,32,-31,76,-119,76v-67,0,-92,-25,-92,-48v0,-21,20,-22,20,-27v0,-5,-20,-14,-20,-30v0,-26,30,-34,30,-39v0,-4,-25,-20,-25,-47v0,-65,90,-71,147,-57v27,0,41,-19,46,-19v33,15,-15,51,-7,67v-3,55,-64,69,-115,64v-6,0,-10,4,-10,10v11,28,63,7,92,7v37,0,53,21,53,43","w":218},"h":{"d":"139,-14v6,-11,15,-39,15,-65v0,-18,1,-52,-25,-52v-36,0,-22,46,-22,77v0,30,15,24,15,37v0,21,-41,21,-55,21v-51,0,-63,-11,-63,-22v0,-14,15,-8,20,-31v7,-37,4,-93,3,-134v-1,-26,-23,-16,-23,-33v0,-29,94,-36,94,-36v11,0,12,3,12,13r-2,69v0,7,-1,18,8,18v11,0,16,-32,56,-32v66,0,62,62,62,72r1,58v0,31,18,23,18,37v0,21,-46,21,-59,21v-11,0,-55,0,-55,-18","w":256},"i":{"d":"110,-167r0,100v0,42,21,27,21,46v0,24,-46,25,-62,25v-62,0,-64,-14,-64,-23v0,-13,15,-14,19,-25v5,-13,5,-65,1,-78v-3,-13,-21,-9,-21,-25v0,-26,91,-36,95,-36v11,0,11,8,11,16xm108,-230v0,28,-48,36,-69,36v-15,0,-32,-7,-32,-25v0,-24,48,-33,66,-33v14,0,35,4,35,22","w":135},"j":{"d":"114,-164r0,155v0,18,1,44,-11,59v-13,16,-42,23,-62,23v-21,5,-61,-24,-31,-37v22,5,18,-9,18,-28r0,-112v0,-35,-24,-18,-24,-37v0,-34,98,-42,98,-42v13,0,12,9,12,19xm110,-230v0,28,-48,36,-69,36v-15,0,-32,-7,-32,-25v0,-24,48,-33,66,-33v14,0,35,4,35,22","w":139},"k":{"d":"245,-160v4,18,-41,15,-52,35v0,9,42,61,49,69v16,20,36,20,36,35v0,26,-57,23,-87,21v-40,-3,-44,-51,-72,-69v-14,26,12,37,11,48v0,10,-3,25,-59,25v-30,0,-63,1,-63,-23v0,-17,19,-5,20,-35r3,-126v0,-29,-27,-10,-27,-31v0,-24,81,-41,100,-41v10,0,10,5,10,13r-2,77v-10,52,27,26,37,14v0,-5,-7,-8,-7,-15v0,-19,36,-20,49,-20v15,0,54,1,54,23","w":277},"l":{"d":"117,-234v-2,23,-7,148,-3,194v4,13,20,7,20,22v0,24,-44,22,-59,22v-16,0,-67,2,-67,-24v0,-13,17,-8,20,-21v8,-39,8,-92,2,-135v-4,-27,-26,-16,-26,-37v0,-31,93,-39,98,-39v12,0,15,7,15,18","w":138},"m":{"d":"229,-151v12,-7,36,-32,63,-32v34,0,56,19,56,54r0,76v0,21,13,23,13,33v0,23,-41,24,-55,24v-12,0,-54,-2,-54,-21v0,-13,13,-13,13,-34v0,-31,10,-71,-19,-78v-27,4,-18,35,-18,60v0,44,13,37,13,50v-3,39,-128,23,-113,3v0,-19,19,-4,17,-47v-1,-26,8,-60,-19,-66v-28,5,-18,40,-18,67v0,58,36,66,-48,66v-14,0,-56,0,-56,-19v0,-16,21,-7,21,-52r0,-33v1,-38,-11,-26,-18,-46v0,-27,89,-37,90,-37v19,0,2,28,16,32v14,-8,33,-32,65,-32v43,0,43,32,51,32","w":365},"n":{"d":"113,-153v17,-6,22,-30,55,-30v75,0,62,73,66,128v2,28,16,22,16,37v0,6,2,22,-66,22v-13,0,-48,1,-48,-19v0,-13,12,-8,14,-31v2,-26,12,-83,-22,-83v-32,0,-21,40,-21,69v0,35,13,28,13,42v0,22,-48,22,-63,22v-14,0,-51,0,-51,-22v0,-17,16,-2,17,-37r2,-54v1,-27,-21,-18,-21,-37v0,-19,83,-37,90,-37v20,-1,5,26,19,30","w":253},"o":{"d":"221,-90v-1,114,-215,134,-215,7v0,-64,57,-101,116,-101v63,0,99,49,99,94xm139,-63v0,-16,-8,-78,-32,-78v-12,0,-19,11,-18,21v1,23,8,79,33,80v14,1,17,-11,17,-23","w":227},"p":{"d":"157,-85v0,-17,-4,-46,-27,-46v-13,0,-17,5,-17,71v0,12,5,16,18,16v22,0,26,-24,26,-41xm27,6v8,0,6,-123,1,-125v-5,-5,-24,0,-24,-21v0,-24,73,-43,100,-43v15,0,5,15,14,18v5,0,25,-19,55,-19v109,0,88,189,-14,189v-25,0,-43,-22,-43,3v0,27,22,18,22,36v0,20,-33,23,-47,23v-48,0,-86,-18,-86,-36v0,-16,16,-11,22,-25","w":251},"q":{"d":"141,-87v0,-15,3,-57,-21,-57v-6,0,-24,7,-24,45v0,38,15,58,29,58v18,0,16,-34,16,-46xm6,-90v0,-86,98,-107,168,-85v15,0,25,-9,39,-9v9,0,16,3,16,13v-1,4,-9,112,-6,174v2,41,19,24,19,44v0,23,-34,24,-50,24v-19,0,-80,-4,-80,-32v0,-18,26,-7,26,-36v-6,-24,-19,2,-50,2v-53,0,-82,-46,-82,-95","w":245},"r":{"d":"24,-48v5,-17,4,-40,4,-61v0,-35,-22,-16,-22,-38v0,-28,84,-36,87,-36v23,-4,9,22,22,29v9,0,14,-29,45,-29v24,0,40,18,40,42v0,24,-20,43,-44,43v-23,0,-31,-20,-40,-20v-10,0,-8,24,-8,30v0,11,1,26,3,40v2,16,29,5,29,27v0,23,-31,25,-71,25v-17,0,-65,1,-65,-24v0,-15,16,-15,20,-28","w":202,"k":{"v":-5,"w":-5,"y":-4,"f":-13,",":27,".":28,"g":-3,"h":7,"m":-4,"n":-5,"r":-2,"t":-8,"u":-8,"z":-10,"-":-9}},"s":{"d":"56,0v-33,11,-46,-26,-48,-49v0,-9,4,-17,14,-17v16,0,30,35,50,35v7,0,14,-3,14,-11v0,-21,-70,-24,-70,-83v0,-50,56,-69,103,-54v29,-18,51,20,52,43v0,10,-8,17,-17,17v-21,0,-32,-29,-48,-29v-6,0,-13,6,-13,13v0,23,79,27,79,83v1,51,-66,66,-116,52","w":180},"t":{"d":"102,-229v35,0,-5,56,29,45v18,3,46,-10,40,17v4,33,-19,22,-41,22v-13,0,-13,1,-13,14v1,28,-6,88,19,83v19,-4,37,-15,37,8v0,24,-42,45,-78,45v-18,0,-64,-8,-64,-65r0,-74v5,-26,-55,7,-30,-38r82,-53v8,-5,8,-4,19,-4","w":175},"u":{"d":"145,-18v-13,5,-30,22,-54,22v-68,0,-63,-54,-63,-108v0,-55,-24,-31,-24,-55v0,-23,90,-24,93,-24v10,0,11,5,11,14r0,91v0,14,2,37,21,37v36,-7,19,-56,21,-90v-3,-18,-21,-12,-21,-27v0,-21,72,-25,86,-25v26,-1,18,32,18,54r0,73v0,22,20,12,20,29v0,24,-64,31,-84,31v-28,0,-10,-22,-24,-22","w":256},"v":{"d":"88,-21r-60,-112v-10,-20,-31,-9,-31,-28v0,-9,5,-22,73,-22v13,0,61,-1,61,18v0,12,-14,15,-14,24v0,8,13,36,22,36v12,0,25,-31,25,-38v0,-9,-12,-13,-12,-23v0,-18,39,-17,50,-17v10,0,38,0,38,16v0,17,-24,9,-34,29r-59,115v-20,44,-44,30,-59,2","w":237,"k":{",":33,".":34}},"w":{"d":"255,4v-33,-11,-42,-62,-68,-81v-32,16,-29,70,-65,81v-13,0,-21,-15,-27,-25r-68,-111v-12,-19,-30,-8,-30,-26v0,-23,55,-25,72,-25v14,0,58,1,58,22v0,8,-7,11,-7,16v0,6,16,38,25,38v6,0,17,-19,17,-24v0,-17,-22,-17,-22,-30v0,-7,1,-22,72,-22v14,0,52,-1,52,19v0,13,-11,15,-11,23v0,7,13,35,21,35v11,0,25,-32,25,-35v0,-9,-10,-12,-10,-24v0,-18,32,-18,44,-18v12,0,44,0,44,18v0,20,-24,6,-39,36r-46,90v-6,12,-21,43,-37,43","w":374,"k":{",":33,".":34}},"x":{"d":"167,-95v9,17,20,32,31,47v16,23,30,15,30,30v0,9,-1,22,-73,22v-15,0,-60,3,-60,-21v0,-13,14,-9,14,-20v0,-7,-12,-27,-19,-27v-6,0,-22,26,-22,33v0,8,9,8,9,19v0,15,-28,16,-39,16v-13,0,-38,0,-38,-18v0,-19,17,-3,34,-30r33,-55v-7,-14,-19,-23,-28,-36v-13,-16,-35,-8,-35,-26v0,-23,63,-22,78,-22v12,0,57,-2,57,18v-10,15,-8,29,7,37v5,0,16,-16,16,-21v0,-5,-8,-11,-8,-17v0,-17,28,-17,39,-17v28,0,33,8,33,17v0,13,-20,13,-30,28v-10,15,-21,27,-29,43","w":227},"y":{"d":"200,-131v-42,67,-38,195,-139,195v-26,0,-57,-13,-57,-43v0,-18,14,-33,32,-33v33,0,24,38,39,38v25,0,10,-36,3,-50r-51,-106v-7,-14,-27,-9,-27,-26v0,-11,6,-27,82,-27v14,0,47,1,47,22v0,10,-9,12,-9,21v0,14,16,39,22,39v11,0,19,-24,19,-33v0,-16,-12,-16,-12,-28v0,-19,34,-21,47,-21v12,0,38,1,38,18v0,21,-21,13,-34,34","w":234,"k":{",":35,".":37}},"z":{"d":"146,-179v13,0,39,-3,37,12v-16,44,-46,75,-62,119v0,8,7,9,13,9v30,0,24,-31,40,-31v42,11,0,82,-18,76v-22,-7,-86,-6,-121,-6v-9,0,-29,0,-29,-14v18,-44,51,-76,69,-121v0,-8,-11,-7,-16,-7v-26,0,-21,30,-40,30v-37,-9,0,-74,15,-74v10,0,12,7,72,7r40,0","w":194},"{":{"d":"89,-127v53,5,29,70,34,119v-7,22,34,15,30,31v3,15,-31,13,-48,13v-65,0,-50,-74,-51,-133v6,-22,-35,-14,-31,-31v-4,-17,37,-8,31,-31v1,-58,-13,-130,51,-130v18,0,51,-2,48,14v4,16,-37,8,-30,30v-3,51,14,109,-34,118","w":188},"|":{"d":"68,90r0,-360r42,0r0,360r-42,0","w":178},"}":{"d":"66,-8v5,-49,-18,-114,34,-119r0,-2v-52,-4,-29,-68,-34,-116v7,-22,-34,-13,-30,-30v-4,-16,31,-14,48,-14v63,0,51,72,51,130v-7,23,35,14,30,31v5,16,-37,9,-30,31v-1,59,14,133,-51,133v-17,0,-51,3,-48,-13v-4,-16,37,-9,30,-31","w":188},"~":{"d":"169,-126v17,0,32,3,32,24v0,23,-19,43,-41,43v-28,0,-66,-25,-80,-25v-7,7,-6,29,-22,25v-17,0,-32,-3,-32,-24v0,-23,19,-43,41,-43v28,0,66,24,80,24v4,0,4,-2,4,-6v0,-13,9,-18,18,-18"},"'":{"d":"57,-118v-25,-14,-38,-57,-39,-90v0,-24,12,-49,39,-49v67,0,35,116,0,139","w":113},"`":{"d":"102,-202v-49,0,-77,-33,-77,-42v8,-25,59,-27,74,-9v-13,18,22,19,23,38v0,12,-11,13,-20,13","w":146},"\u00a0":{"w":113}}});
/*!
 * The following copyright notice may not be removed under any circumstances.
 * 
 * Copyright:
 * Copyright 1990-1993 Bitstream Inc.  All rights reserved.
 */
Cufon.registerFont({"w":238,"face":{"font-family":"AmerType Md BT","font-weight":700,"font-stretch":"normal","units-per-em":"360","panose-1":"2 9 8 4 3 5 5 2 2 4","ascent":"288","descent":"-72","x-height":"6","bbox":"-24.1348 -275 388 85","underline-thickness":"39.9023","underline-position":"-17.5781","unicode-range":"U+0020-U+007E"},"glyphs":{" ":{"w":119},"!":{"d":"64,-245v24,0,37,13,33,38v-7,40,-2,94,-14,126v-15,8,-47,4,-44,-20r-9,-114v-1,-21,12,-30,34,-30xm64,4v-18,0,-34,-15,-34,-35v0,-19,15,-34,34,-34v18,0,34,16,34,35v0,17,-17,34,-34,34","w":127},"\"":{"d":"71,-253r34,0r0,98r-34,0r0,-98xm14,-253r34,0r0,98r-34,0r0,-98","w":119},"#":{"d":"125,-149r-16,43r44,0r15,-43r-43,0xm125,-257r38,0r-25,73r42,0r26,-73r39,0r-26,73r50,0r-13,35r-49,0r-15,42r51,0r-13,36r-51,0r-26,73r-39,0r26,-73r-42,0r-27,73r-38,0r25,-73r-50,0r13,-36r50,0r15,-42r-53,0r13,-35r53,0","w":276},"$":{"d":"121,17v-16,3,-10,-16,-11,-30v-41,1,-75,-20,-75,-58v0,-18,10,-32,27,-33v24,-2,36,28,21,43v2,6,16,11,27,10r0,-56v-36,-9,-67,-27,-68,-64v-1,-36,31,-63,68,-63v0,-13,-3,-28,12,-26v15,-2,12,13,12,26v33,1,59,14,61,46v2,29,-48,34,-50,7v3,-10,3,-19,-11,-17r0,43v42,15,67,23,67,70v0,43,-27,64,-67,71v-1,15,4,34,-13,31xm131,-53v19,-2,33,-24,19,-39v-4,-4,-10,-7,-19,-10r0,49xm111,-198v-16,1,-31,17,-18,30v4,3,10,5,18,7r0,-37"},"%":{"d":"69,-2v-4,10,-26,9,-29,0v33,-67,72,-127,107,-191v-15,6,-36,3,-45,-6v10,42,-9,84,-50,84v-34,0,-52,-27,-52,-63v0,-37,19,-61,53,-63v18,-1,62,30,80,28v31,4,29,-27,57,-28v12,-1,9,9,6,15xm53,-211v-22,1,-23,64,0,65v22,-2,20,-63,0,-65xm186,-90v-21,2,-21,63,0,65v21,-1,21,-63,0,-65xm186,-121v34,0,52,27,52,63v0,36,-18,63,-52,63v-34,0,-52,-27,-52,-63v0,-37,18,-62,52,-63","w":243},"&":{"d":"290,-153v0,45,-47,63,-86,45v39,57,-20,113,-90,113v-57,0,-103,-32,-103,-86v0,-35,19,-61,49,-65v-50,-33,-4,-100,58,-100v38,0,65,14,68,47v3,33,-54,43,-59,12v1,-10,-3,-16,-12,-16v-26,-1,-24,38,-1,39v13,1,24,8,23,20v8,50,-69,10,-67,61v1,24,21,34,46,35v24,0,42,-9,44,-29v1,-10,-16,-36,-15,-45v5,-48,72,-14,102,-24v-14,1,-23,-8,-23,-22v0,-18,12,-29,29,-29v23,0,37,19,37,44","w":296},"'":{"d":"14,-253r34,0r0,98r-34,0r0,-98","w":61},"(":{"d":"149,-248v31,0,30,37,-2,42v-55,9,-78,48,-78,116v-1,68,23,107,78,115v32,5,33,44,3,42v-86,-7,-140,-67,-140,-157v0,-91,54,-158,139,-158","w":185},")":{"d":"36,67v-14,1,-23,-8,-23,-20v0,-17,22,-21,37,-25v46,-13,65,-49,65,-112v0,-69,-22,-108,-77,-116v-32,-5,-33,-44,-3,-42v86,7,140,68,140,158v0,91,-54,149,-139,157","w":185},"*":{"d":"110,-128v0,17,-38,17,-39,1v5,-13,12,-26,14,-42v-17,0,-20,30,-35,33v-16,3,-33,-37,-6,-36v12,0,26,-1,33,-9v-11,-13,-46,2,-47,-19v0,-14,20,-39,30,-15v6,13,13,17,22,25v12,-17,-35,-55,8,-55v36,0,5,32,5,53v16,0,21,-29,35,-33v15,-1,33,37,6,36v-13,-1,-23,3,-33,7v5,17,47,-1,47,21v1,14,-21,39,-30,15v-8,-11,-14,-21,-25,-23v1,15,11,30,15,41","w":180},"+":{"d":"132,-215r36,0r0,90r87,0r0,35r-87,0r0,90r-36,0r0,-90r-87,0r0,-35r87,0r0,-90","w":299},",":{"d":"49,1v-40,-8,-25,-72,12,-66v71,11,23,138,-19,147v-39,-11,15,-50,15,-73v0,-4,-2,-7,-8,-8","w":119},"-":{"d":"111,-93v3,36,-50,18,-79,21v-19,2,-23,-4,-24,-21v-3,-38,50,-19,80,-22v20,-2,22,4,23,22","w":119,"k":{"o":-7,"Y":28,"X":13,"W":20,"V":21,"Q":-13,"O":-13,"J":-20,"G":-13,"C":-7,"A":6}},".":{"d":"60,5v-19,0,-35,-16,-35,-35v0,-19,16,-34,35,-34v18,0,34,16,34,35v0,17,-17,34,-34,34","w":119},"\/":{"d":"83,-245v13,-1,12,2,12,12r-70,255v0,12,-37,19,-32,3r71,-258v2,-8,8,-12,19,-12","w":98},"0":{"d":"119,-243v68,0,107,52,107,124v0,72,-38,124,-107,124v-69,0,-106,-52,-106,-124v0,-73,37,-124,106,-124xm119,-195v-36,0,-46,35,-46,77v0,42,11,77,46,77v35,0,46,-35,46,-77v0,-42,-10,-77,-46,-77"},"1":{"d":"70,-48v12,-1,31,10,31,-10r0,-123v3,-30,-56,9,-53,-33v3,-42,62,-16,99,-25v13,1,12,8,13,25r0,158v-1,16,18,8,29,8v12,0,20,10,20,23v2,37,-43,23,-72,22v-34,-1,-89,18,-89,-22v-1,-14,9,-23,22,-23"},"2":{"d":"114,-242v56,0,98,20,98,70v0,55,-43,63,-95,77v-34,9,-51,24,-51,45v12,-12,23,-22,44,-22v30,-6,47,40,69,21v-10,1,-17,-10,-17,-19v-1,-16,14,-27,29,-27v22,0,33,20,33,45v0,34,-28,58,-64,57v-35,6,-51,-39,-77,-35v11,19,-6,36,-29,35v-45,-2,-51,-69,-24,-99v18,-20,49,-37,84,-49v25,-9,37,-19,37,-30v2,-28,-50,-34,-66,-17v18,16,3,49,-24,49v-23,0,-40,-14,-39,-37v1,-42,45,-64,92,-64"},"3":{"d":"166,-235v24,-3,55,-6,52,22v-3,25,-42,51,-58,71v38,3,61,24,61,62v1,56,-49,86,-110,86v-51,0,-97,-23,-97,-69v-1,-25,15,-42,39,-42v27,0,42,36,24,54v20,21,82,9,78,-27v-2,-22,-18,-32,-43,-30v-30,1,-28,-34,-8,-46r37,-38r-54,0v-22,-2,-13,20,-11,33v-1,15,-8,25,-25,25v-42,0,-23,-49,-28,-83v-4,-28,30,-18,51,-18r92,0"},"4":{"d":"149,-1v-32,0,-79,18,-79,-20v0,-22,23,-23,44,-19v15,3,8,-18,10,-30v-44,-5,-134,19,-114,-38v33,-42,72,-95,111,-131v30,-12,59,-8,59,40r0,87v22,1,49,-5,46,20v4,27,-23,21,-46,22v2,12,-6,32,9,30v20,-4,41,-2,41,19v0,38,-49,20,-81,20xm127,-111r3,-85r-61,85r58,0"},"5":{"d":"106,-111v-31,2,-82,24,-78,-22v3,-31,1,-75,13,-98v40,-9,104,-2,152,-4v19,-1,9,27,11,47v2,20,-6,26,-25,27v-29,2,-12,-33,-45,-28v-26,4,-55,-10,-48,22r0,17v60,-23,133,6,131,70v-1,56,-48,86,-110,86v-45,0,-87,-22,-88,-62v0,-21,17,-38,38,-38v25,0,40,24,28,46v21,21,73,4,70,-28v-2,-22,-23,-36,-49,-35"},"6":{"d":"125,-41v24,0,43,-12,43,-36v0,-24,-19,-35,-43,-35v-24,0,-44,11,-43,35v0,23,19,36,43,36xm145,-195v-33,-17,-69,16,-64,56v51,-38,146,-13,146,60v0,55,-43,85,-101,85v-73,0,-110,-49,-110,-123v0,-75,43,-125,115,-125v40,-1,73,14,75,48v0,19,-13,31,-33,31v-20,0,-34,-11,-28,-32"},"7":{"d":"121,6v-48,0,-50,-63,-33,-100v14,-31,60,-58,83,-84v-27,20,-73,-10,-91,-17v-16,0,-3,24,-4,36v0,17,-11,27,-29,27v-42,-1,-17,-54,-26,-87v0,-15,7,-22,21,-22v16,0,19,9,19,25v12,-43,89,-21,114,-7v8,0,17,-20,28,-17v17,0,30,17,30,35v0,42,-90,92,-86,145v2,29,12,66,-26,66"},"8":{"d":"119,-109v-25,0,-45,11,-45,33v0,23,20,35,45,34v25,0,45,-10,45,-34v0,-23,-20,-33,-45,-33xm119,-200v-17,0,-33,8,-33,24v0,16,16,24,33,24v18,1,32,-8,32,-24v0,-17,-15,-24,-32,-24xm215,-175v0,24,-12,35,-29,45v24,12,39,29,39,61v0,53,-46,75,-106,75v-60,0,-105,-21,-105,-75v0,-33,15,-49,39,-61v-17,-11,-30,-21,-30,-45v1,-45,44,-67,96,-67v52,0,95,21,96,67"},"9":{"d":"89,-41v33,16,69,-17,66,-53v-52,41,-142,12,-142,-63v0,-55,43,-86,101,-85v72,0,110,48,110,122v0,78,-48,126,-126,126v-40,0,-74,-11,-77,-45v-3,-37,64,-43,69,-10xm114,-196v-25,0,-41,14,-41,37v0,23,17,36,41,36v24,1,40,-14,41,-36v0,-23,-16,-37,-41,-37"},":":{"d":"64,-92v-18,0,-35,-16,-35,-35v0,-19,16,-35,35,-35v19,0,34,16,34,35v0,18,-17,35,-34,35xm64,4v-19,0,-35,-16,-35,-35v0,-19,16,-34,35,-34v18,0,34,16,34,35v0,17,-17,34,-34,34","w":127},";":{"d":"64,-92v-18,0,-35,-16,-35,-35v0,-19,16,-35,35,-35v19,0,35,17,35,35v0,18,-17,35,-35,35xm60,4v-15,-5,-32,-12,-31,-33v1,-21,14,-36,35,-36v25,0,36,21,35,48v-2,42,-24,88,-55,99v-38,-12,19,-52,16,-78","w":127},"<":{"d":"253,-210r0,39r-156,64r156,64r0,38r-207,-85r0,-35","w":299},"=":{"d":"45,-87r210,0r0,35r-210,0r0,-35xm45,-163r210,0r0,35r-210,0r0,-35","w":299},">":{"d":"46,-210r207,85r0,35r-207,85r0,-38r158,-64r-158,-64r0,-39","w":299},"?":{"d":"146,-172v4,-33,-54,-38,-70,-17v25,13,7,54,-23,54v-20,0,-36,-17,-36,-38v0,-48,48,-72,100,-72v50,0,89,26,89,73v0,43,-38,60,-70,69v-7,6,-2,25,-15,26v-21,7,-49,2,-46,-23v-6,-50,67,-32,71,-72xm105,4v-19,0,-34,-16,-34,-35v0,-18,16,-34,34,-34v18,0,35,16,35,35v0,18,-17,34,-35,34","w":218},"@":{"d":"243,-19v-23,1,-37,-8,-38,-29v-22,46,-118,36,-109,-31v-8,-69,82,-134,127,-76r9,-17r31,0r-27,112v0,9,7,12,17,13v39,-8,58,-44,59,-88v1,-59,-55,-98,-117,-97v-90,3,-147,54,-147,140v0,73,57,120,134,119v43,-1,78,-15,106,-34r14,21v-32,23,-69,40,-120,40v-98,-2,-166,-49,-166,-145v0,-107,72,-169,180,-169v86,0,149,42,149,126v0,64,-37,112,-102,115xm134,-78v0,34,34,41,54,22v16,-15,19,-43,26,-67v-4,-17,-11,-30,-31,-29v-29,0,-49,40,-49,74","w":360},"A":{"d":"166,-122r-21,-72r-20,72r41,0xm-13,-24v0,-40,53,-2,56,-43r51,-153v10,-26,12,-26,51,-26v40,0,42,-1,52,26r59,171v15,9,51,-6,48,25v-4,47,-74,14,-118,25v-20,0,-34,-8,-34,-27v0,-14,12,-26,24,-19v17,-1,8,-21,5,-33v-27,-4,-44,-2,-69,0v-7,11,-12,39,9,31v13,-1,18,9,18,21v0,49,-82,15,-125,28v-17,1,-27,-10,-27,-26","w":291,"k":{"y":6,"w":6,"v":6,"Y":10,"X":6,"W":16,"V":13,"U":10,"T":13,";":-10,":":-10,".":-13,"-":8,",":-13}},"B":{"d":"137,-195v-29,-4,-20,19,-20,40v0,9,3,9,14,9v25,0,44,-4,44,-24v0,-21,-15,-22,-38,-25xm29,-46v12,1,27,8,27,-11r0,-125v3,-21,-15,-11,-28,-11v-11,0,-18,-10,-18,-22v-1,-44,61,-19,98,-23v63,-7,138,-8,136,58v-1,32,-18,46,-50,50v35,3,58,23,58,59v2,99,-131,64,-218,73v-16,2,-24,-9,-24,-25v-1,-13,7,-23,19,-23xm139,-104v-33,-8,-19,23,-22,48v2,12,10,9,28,10v26,1,40,-8,40,-30v0,-22,-21,-28,-46,-28","w":271,"k":{"Y":6,"W":6,"V":6,"-":-10}},"C":{"d":"125,-246v26,0,43,8,53,24v0,-15,8,-22,22,-22v36,1,12,51,20,83v0,19,-9,25,-27,26v-43,2,-15,-68,-62,-63v-38,4,-51,34,-51,78v0,41,14,76,48,78v28,0,40,-13,40,-43v0,-19,9,-25,26,-26v22,-1,33,16,33,38v-2,52,-45,78,-104,78v-70,0,-110,-52,-110,-125v0,-74,40,-127,112,-126","w":235,"k":{"A":6,"-":-8}},"D":{"d":"147,-195v-25,-1,-26,1,-25,25r0,111v0,17,3,16,23,16v40,0,50,-33,50,-79v0,-45,-9,-71,-48,-73xm25,-46v13,1,31,11,31,-11r0,-126v3,-30,-53,8,-53,-34v0,-37,48,-19,79,-22v106,-10,181,11,181,120v0,74,-41,123,-112,121r-75,-2v-30,-1,-75,13,-73,-23v0,-14,8,-23,22,-23","w":278,"k":{"Y":6,"W":6,"V":6,"A":6,"-":-11}},"E":{"d":"56,-182v3,-25,-18,-12,-31,-11v-14,0,-22,-9,-22,-23v3,-46,67,-21,111,-22r114,-3v40,-2,18,49,24,81v6,32,-52,38,-52,8v0,-38,-5,-49,-49,-46v-38,-5,-33,19,-33,53v18,3,32,-2,26,-23v1,-10,8,-16,19,-16v42,2,10,61,22,98v1,13,-10,16,-22,18v-34,4,-1,-51,-45,-37v0,34,-7,67,36,60v48,2,51,-8,48,-49v-1,-13,13,-21,26,-21v44,-1,24,56,29,93v3,21,-14,25,-36,23v-63,-4,-132,-3,-192,0v-18,1,-26,-7,-26,-24v-1,-23,21,-25,43,-22v10,2,9,-1,10,-12r0,-125","w":277},"F":{"d":"129,-44v21,-6,53,-4,52,21v-2,41,-66,22,-105,22v-29,0,-73,13,-73,-22v0,-23,23,-27,43,-21v10,-1,9,-2,10,-13r0,-125v2,-31,-56,8,-53,-34v3,-46,67,-21,111,-22r114,-3v40,-2,18,49,24,81v6,32,-52,38,-52,8v0,-39,-6,-49,-49,-46v-39,-5,-33,20,-33,54v15,6,33,-1,26,-23v2,-20,44,-19,41,5v-3,26,-3,52,0,78v1,13,-10,17,-22,18v-34,4,0,-49,-45,-38r0,51v-1,8,4,9,11,9","w":257,"k":{"r":6,"o":10,"i":-7,"e":10,"a":6,"T":-7,"A":20,";":11,":":11,".":44,"-":11,",":44}},"G":{"d":"13,-120v0,-97,99,-160,170,-104v0,-26,46,-30,46,-3v0,36,14,83,-29,83v-42,0,-19,-55,-67,-54v-39,1,-53,33,-53,78v0,43,12,76,50,77v20,0,37,-10,37,-29v0,-15,-9,-13,-22,-13v-13,0,-21,-9,-21,-22v-3,-38,44,-23,73,-23v31,1,79,-16,79,23v0,35,-46,8,-46,36v0,29,22,79,-22,76v-16,0,-26,-6,-25,-23v-11,14,-39,23,-64,23v-66,1,-106,-55,-106,-125","w":277,"k":{"Y":6,"W":6,"T":6,"-":-8}},"H":{"d":"166,-24v-5,-27,29,-11,29,-33r0,-46v-28,-4,-48,-1,-74,0v3,20,-8,53,9,59v16,0,21,4,20,19v-3,50,-77,14,-122,27v-16,0,-24,-10,-25,-25v-1,-23,23,-27,43,-21v10,-1,9,-2,10,-13r0,-127v-1,-27,-57,8,-53,-32v5,-47,75,-12,118,-25v18,1,29,7,29,26v5,25,-29,14,-29,31r0,30v26,1,45,4,74,0r0,-33v-3,-12,-31,-4,-29,-27v5,-49,76,-14,121,-27v16,0,27,8,27,25v0,22,-23,26,-44,21v-10,1,-9,2,-10,13r0,128v-1,18,21,7,32,7v12,1,23,10,22,24v-4,46,-76,13,-119,25v-19,0,-29,-7,-29,-26","w":316},"I":{"d":"28,-47v12,0,31,11,31,-10r0,-127v1,-27,-53,9,-53,-32v0,-37,46,-25,76,-22v34,3,94,-22,96,21v1,24,-21,25,-43,22v-10,-2,-9,1,-10,12r0,129v-1,18,21,7,32,7v13,0,21,10,21,23v2,38,-46,25,-76,22v-34,-3,-96,23,-96,-21v0,-14,8,-24,22,-24","w":184},"J":{"d":"82,-40v62,0,41,-82,44,-142v3,-32,-56,9,-56,-34v0,-37,49,-22,80,-22v34,0,91,-19,92,22v1,22,-21,26,-42,21v-9,1,-9,1,-10,12r0,95v3,70,-38,91,-101,93v-54,2,-88,-25,-92,-75v-5,-63,100,-85,105,-20v2,26,-33,40,-47,20v-2,-1,-5,2,-4,4v0,15,14,26,31,26","w":240},"K":{"d":"281,2v-38,-14,-105,21,-108,-22v-1,-12,23,-17,12,-29r-33,-59r-31,26v2,14,-6,38,9,38v16,0,20,5,20,19v0,50,-79,13,-122,27v-16,0,-25,-9,-25,-25v0,-24,22,-27,43,-21v10,-1,9,-2,10,-13r0,-125v2,-31,-57,8,-53,-34v3,-47,74,-13,118,-25v30,-8,41,46,13,46v-24,0,-9,35,-13,56v21,-21,46,-38,65,-61v0,-6,-13,-14,-13,-21v1,-31,44,-17,69,-17v26,-1,61,-11,61,20v0,29,-29,20,-47,27v-15,18,-40,28,-50,51v20,31,35,66,57,94v18,4,46,-9,46,20v0,18,-10,29,-28,28","w":307,"k":{"y":20,"u":16,"o":6,"e":6,"Y":13,"W":13,"U":10,"O":13,"C":13,"A":6,"-":11}},"L":{"d":"174,-215v0,40,-53,3,-53,33r0,117v1,19,10,19,31,20v41,2,46,-14,43,-51v-1,-13,12,-21,26,-21v44,-1,24,57,29,94v3,22,-15,26,-39,24v-61,-4,-124,-3,-182,0v-18,1,-26,-7,-26,-24v-1,-23,21,-25,43,-22v10,2,9,-1,10,-12r0,-125v2,-31,-53,8,-53,-34v0,-42,54,-22,88,-22v32,0,83,-18,83,23","w":258,"k":{"y":13,"u":6,"Y":33,"W":26,"V":26,"U":13,"T":26,"A":-20,"-":-7}},"M":{"d":"242,-25v-5,-26,28,-10,28,-32r2,-146r-3,0r-45,175v0,31,-35,32,-57,23v-4,-3,-8,-10,-11,-23r-45,-175r-3,0v4,45,3,97,3,146v0,21,30,6,27,32v-5,47,-65,15,-107,27v-13,0,-21,-11,-21,-25v-1,-21,18,-28,37,-21v8,-1,8,-2,8,-13r0,-125v4,-20,-14,-11,-26,-11v-12,0,-19,-11,-19,-23v-1,-40,51,-22,85,-22v27,0,64,-14,70,18r25,142v4,-52,19,-95,26,-142v4,-31,42,-18,69,-18v32,0,85,-18,85,22v0,22,-17,26,-37,21v-8,1,-7,3,-8,13r0,126v-2,18,15,9,26,9v12,0,20,10,19,24v0,44,-62,14,-100,25v-18,0,-28,-9,-28,-27","w":382},"N":{"d":"27,-47v12,-1,29,11,29,-10r0,-125v2,-19,-17,-11,-29,-11v-30,0,-21,-50,6,-48v34,2,68,4,101,0v11,-1,18,11,23,22r67,165r-6,-129v2,-17,-14,-11,-25,-10v-13,0,-18,-10,-19,-23v-3,-36,40,-22,68,-22v31,0,82,-17,82,22v0,23,-20,26,-40,21v-7,-1,-9,5,-9,13r0,149v-2,33,-9,34,-48,35v-23,0,-39,-10,-47,-30r-62,-140v-4,-9,-7,-18,-9,-26r5,137v-1,17,14,12,26,10v12,1,19,10,19,24v0,35,-41,23,-68,22v-31,-1,-84,18,-83,-22v0,-15,5,-24,19,-24","w":322},"O":{"d":"80,-120v0,43,10,76,48,76v37,0,49,-35,49,-76v0,-43,-11,-76,-49,-76v-37,0,-48,33,-48,76xm129,-245v73,0,115,50,115,125v0,75,-43,125,-116,125v-74,0,-115,-50,-115,-125v0,-75,42,-125,116,-125","w":257,"k":{"Y":6,"X":6,"V":6,"A":6,";":-7,":":-7,".":15,"-":-10,",":15}},"P":{"d":"29,-47v11,0,27,10,27,-10r0,-127v2,-17,-16,-8,-27,-8v-11,-1,-19,-10,-19,-23v0,-40,44,-19,79,-23v76,-9,153,-1,149,77v-3,61,-41,83,-115,78v-12,-2,-4,20,-6,30v0,16,21,6,32,6v14,1,23,10,24,24v1,38,-51,22,-82,22v-36,0,-81,18,-81,-22v-1,-14,7,-24,19,-24xm139,-194v-33,-7,-19,29,-22,55v1,8,2,9,10,10v28,0,48,-8,49,-31v1,-23,-13,-35,-37,-34","w":245,"k":{"o":6,"e":6,"W":6,"U":6,"A":13,";":13,":":13,".":53,",":53}},"Q":{"d":"128,-196v-55,0,-56,91,-37,131v7,13,18,20,32,21v-3,-6,-24,-19,-21,-31v0,-13,15,-22,28,-22v19,1,30,13,36,30v23,-39,16,-129,-38,-129xm189,62v-37,0,-55,-18,-53,-57v-80,4,-122,-48,-123,-125v0,-75,42,-125,116,-125v73,0,116,50,115,125v0,55,-23,93,-59,113v2,8,4,22,13,21v12,-2,10,-23,27,-23v13,0,26,11,25,24v-1,31,-27,47,-61,47","w":257,"k":{"-":-10}},"R":{"d":"138,-194v-30,-7,-21,21,-21,44v0,10,4,9,15,9v27,0,46,-3,47,-26v0,-22,-16,-27,-41,-27xm31,-46v11,1,25,8,25,-11r0,-128v-1,-22,-46,6,-46,-30v0,-43,50,-18,88,-22v64,-7,152,-14,149,59v-1,34,-18,46,-50,51v36,6,49,24,46,68v-3,32,47,-5,47,34v0,39,-47,23,-75,27v-65,10,-5,-112,-79,-100v-27,-3,-17,23,-19,44v-1,16,17,8,27,8v27,0,21,52,-8,48v-31,-4,-72,-3,-103,0v-16,1,-23,-9,-23,-25v-1,-14,7,-23,21,-23","w":281,"k":{"y":6,"W":10,"V":13,"T":6,"C":6,"A":-20}},"S":{"d":"219,-76v7,80,-115,104,-160,59v0,14,-9,21,-23,21v-39,0,-20,-47,-25,-78v-3,-18,11,-29,29,-28v22,0,29,16,30,38v7,27,78,31,77,-5v5,-22,-52,-29,-71,-35v-37,-11,-64,-27,-66,-68v-4,-72,105,-96,151,-51v-5,-14,7,-22,21,-22v37,0,19,44,24,74v2,13,-13,21,-26,21v-31,1,-20,-54,-63,-50v-18,2,-37,7,-37,24v-5,18,50,23,70,28v42,9,65,28,69,72","w":229},"T":{"d":"57,-47v12,-1,31,10,31,-10r0,-123v0,-8,-7,-15,-16,-14v-20,0,-12,28,-11,44v0,13,-13,21,-27,21v-44,0,-24,-54,-29,-91v-3,-18,15,-23,35,-21v27,1,54,2,81,2r90,-2v42,-2,18,51,26,85v0,17,-12,27,-30,27v-27,0,-28,-24,-24,-48v-1,-10,-4,-17,-13,-17v-11,-1,-20,9,-16,19r0,121v-1,16,20,7,31,7v14,0,22,9,22,23v1,40,-52,22,-86,22v-33,0,-88,19,-86,-22v0,-14,8,-23,22,-23","w":241,"k":{"y":-7,"w":-7,"r":-7,"o":10,"i":-7,"e":10,"c":10,"T":-7,"A":13,";":11,":":11,".":26,",":26}},"U":{"d":"155,-48v58,0,30,-84,36,-135v2,-21,-32,-7,-29,-32v6,-48,76,-13,121,-26v18,0,26,8,27,24v1,23,-24,30,-44,22v-10,1,-9,1,-9,13r0,78v4,80,-32,109,-102,109v-80,0,-111,-41,-102,-132r0,-55v3,-22,-31,-10,-32,-10v-13,0,-21,-10,-21,-23v3,-48,74,-13,118,-26v18,0,27,10,29,27v3,25,-31,11,-29,32v5,51,-21,134,37,134","w":308,"k":{"A":10}},"V":{"d":"292,-216v0,21,-19,26,-39,21v-10,2,-10,8,-15,20r-49,151v1,36,-62,27,-87,21v-31,-52,-40,-132,-68,-188v-4,-9,-17,-2,-27,-2v-11,-1,-21,-10,-20,-23v3,-47,74,-14,118,-25v31,-8,42,46,10,47v-10,0,-11,5,-9,12r33,118r35,-124v-5,-11,-31,-3,-29,-26v5,-49,76,-14,121,-27v17,0,26,9,26,25","w":277,"k":{"y":6,"u":20,"o":29,"i":13,"e":29,"a":31,"O":8,"A":20,";":24,":":24,".":60,"-":29,",":60}},"W":{"d":"279,-182v5,-23,-36,-6,-33,-32v6,-46,75,-16,117,-27v14,0,25,10,25,24v0,38,-42,6,-51,42r-38,154v3,32,-58,23,-84,17v-4,-3,-7,-8,-8,-16r-19,-141r-4,0r-19,141v5,32,-65,21,-81,17v-5,-3,-9,-9,-11,-18r-38,-154v0,-37,-54,-4,-51,-42v4,-43,71,-12,110,-24v18,-1,32,9,32,26v0,20,-16,19,-31,22v-4,2,-2,6,-2,11r25,122r3,0r24,-159v-1,-30,51,-19,76,-15v17,50,19,118,30,174r3,0","w":374,"k":{"y":6,"u":15,"r":16,"o":18,"i":11,"e":20,"a":20,"A":16,";":21,":":21,".":44,"-":21,",":44}},"X":{"d":"145,-22v-3,-19,29,-14,16,-35r-23,-38v-8,16,-21,31,-26,49v2,10,23,7,20,24v-7,45,-73,10,-113,24v-29,4,-32,-46,-7,-49v15,3,26,2,34,-10r44,-65r-50,-71v-19,-3,-44,4,-42,-23v2,-46,67,-13,107,-25v15,0,28,8,27,23v4,19,-25,15,-14,34r20,33r25,-42v-2,-6,-20,-11,-18,-25v6,-42,71,-14,111,-23v28,-7,29,45,7,48v-17,-3,-29,-4,-35,11r-41,60v18,24,32,53,52,75v19,4,45,-5,43,23v-4,47,-70,12,-110,26v-15,-1,-28,-8,-27,-24","w":276,"k":{"O":6,"C":6,"A":6,"-":18}},"Y":{"d":"300,-216v0,37,-44,10,-59,34r-61,95v3,14,-8,42,9,42v23,0,50,-3,49,21v-1,39,-58,22,-92,22v-34,0,-89,17,-90,-22v-1,-24,26,-24,49,-21v18,2,10,-34,6,-47v-23,-33,-41,-71,-68,-100v-19,-6,-52,5,-50,-24v3,-47,75,-12,119,-25v17,0,29,7,29,23v5,21,-27,12,-16,34r22,42v8,-17,18,-33,25,-51v-4,-9,-22,-10,-20,-25v7,-43,78,-11,121,-23v17,0,27,8,27,25","w":294,"k":{"u":26,"o":28,"i":6,"e":28,"a":23,"O":6,"C":13,"A":16,";":31,":":31,".":29,"-":43,",":29}},"Z":{"d":"167,-240v25,-2,60,-7,57,22v1,8,-7,20,-14,29r-108,139v26,-4,73,12,75,-15v-7,-23,-10,-58,25,-55v45,4,17,62,27,100v1,31,-47,19,-75,20r-120,1v-32,-2,-33,-38,-10,-58r107,-138v-20,3,-57,-8,-60,11v7,23,1,46,-24,45v-40,0,-19,-52,-26,-86v2,-29,49,-15,75,-15r71,0","w":244},"[":{"d":"97,78v-29,-2,-73,20,-73,-25r0,-270v-5,-42,44,-22,73,-24v30,-1,76,-12,76,23v0,45,-61,13,-91,20r0,233v26,8,90,-26,91,20v0,35,-45,26,-76,23","w":185},"\\":{"d":"104,22v0,11,0,13,-13,12v-10,0,-16,-4,-18,-13r-71,-259v-1,-9,8,-6,17,-7v8,0,13,3,15,12","w":98},"]":{"d":"89,-241v30,1,73,-18,73,25r0,270v-1,53,-72,11,-119,27v-19,1,-30,-9,-30,-26v0,-45,61,-13,90,-20r0,-233v-26,-8,-89,26,-90,-20v-1,-36,46,-24,76,-23","w":185},"^":{"d":"158,-257r44,0r85,99r-42,0r-65,-65r-66,65r-41,0","w":360},"_":{"d":"0,49r180,0r0,36r-180,0r0,-36","w":180},"`":{"d":"45,-234v-23,-6,-23,-39,1,-40v32,9,52,45,74,65v-20,17,-54,-20,-75,-25","w":180},"a":{"d":"90,-34v27,0,35,-19,33,-48v-11,8,-55,6,-55,28v0,12,8,20,22,20xm211,-21v0,36,-65,34,-72,5v-33,36,-136,30,-131,-34v2,-42,22,-52,65,-58v26,-4,54,-13,51,-25v4,-19,-34,-29,-39,-11v6,19,-12,28,-30,28v-17,0,-32,-11,-32,-28v3,-34,36,-42,77,-42v53,0,80,13,80,71r0,67v2,15,31,4,31,27","w":219},"b":{"d":"127,6v-26,0,-42,-10,-54,-26v0,19,-1,24,-23,23v-20,-1,-24,1,-24,-16r0,-181v-5,-20,-53,9,-50,-26v3,-40,58,-12,93,-22v9,0,11,5,11,15r0,65v6,-15,27,-25,48,-25v47,0,75,43,75,94v0,55,-25,99,-76,99xm112,-141v-33,0,-34,30,-34,65v0,23,12,40,35,39v26,-1,36,-23,36,-52v0,-32,-9,-51,-37,-52","w":216},"c":{"d":"102,6v-54,0,-91,-41,-91,-96v0,-58,37,-96,94,-96v40,0,70,18,73,53v3,35,-57,43,-60,10v4,-11,4,-20,-13,-19v-27,2,-38,22,-38,52v0,29,13,51,37,53v29,1,22,-40,49,-40v15,0,27,12,27,27v0,35,-38,56,-78,56","w":188},"d":{"d":"13,-92v0,-74,74,-120,123,-73v-2,-14,6,-38,-9,-37v-19,3,-43,5,-42,-18v2,-40,59,-12,94,-22v10,0,9,4,10,15r0,177v1,23,46,-7,44,28v-3,39,-50,16,-81,24v-12,3,-10,-9,-10,-20v-15,14,-27,23,-53,24v-51,-1,-76,-41,-76,-98xm103,-37v33,1,34,-31,34,-66v0,-26,-11,-38,-34,-38v-27,0,-36,21,-36,52v0,30,9,52,36,52","w":225},"e":{"d":"136,-114v4,-31,-35,-41,-53,-23v-6,6,-9,13,-9,23r62,0xm195,-101v0,12,-2,19,-13,19r-110,0v1,28,11,46,39,46v29,1,22,-34,52,-34v18,0,30,7,30,24v-1,34,-44,52,-85,52v-59,0,-97,-37,-97,-96v0,-58,37,-97,94,-96v54,0,90,32,90,85","w":204,"k":{"x":6}},"f":{"d":"128,-200v2,-8,0,-12,-7,-12v-15,0,-15,17,-15,34v22,-2,44,-4,44,20v0,20,-16,21,-33,19v-9,-1,-8,1,-9,10r0,80v-2,15,17,7,27,7v12,0,21,9,20,21v-5,44,-80,12,-128,22v-15,3,-23,-8,-23,-22v0,-19,19,-24,38,-19v10,0,9,-1,10,-11r0,-78v-1,-24,-49,5,-45,-29v-2,-24,23,-23,46,-20v-3,-48,20,-69,66,-69v34,-1,59,10,61,39v2,29,-47,31,-52,8","w":166},"g":{"d":"145,16v0,-28,-49,-10,-72,-19v-7,2,-15,9,-15,18v2,30,87,27,87,1xm105,-149v-15,0,-24,11,-24,27v0,15,9,27,24,26v15,0,23,-11,23,-26v0,-15,-8,-27,-23,-27xm3,18v0,-25,14,-34,37,-40v-17,-3,-28,-12,-28,-32v0,-20,11,-31,28,-37v-34,-44,11,-107,76,-93v-1,-26,17,-37,43,-38v21,0,39,10,38,30v0,13,-7,22,-21,21v-14,3,-20,-27,-29,-8r1,6v22,11,32,23,33,53v4,55,-68,77,-115,53v-4,0,-5,5,-6,8v5,23,24,18,63,18v53,0,75,13,75,57v0,46,-46,63,-99,63v-52,0,-96,-16,-96,-61","w":195},"h":{"d":"5,-21v-3,-35,40,-5,40,-30r0,-140v3,-23,-42,5,-40,-28v3,-41,49,-16,86,-24v10,1,9,5,10,17r0,62v37,-40,131,-23,114,54r0,59v-1,24,41,-3,41,29v0,45,-62,11,-97,24v-15,0,-21,-8,-21,-23v-6,-22,20,-12,20,-28v0,-35,11,-86,-26,-86v-38,0,-29,46,-31,84v-1,19,28,9,26,30v-4,43,-67,10,-102,23v-14,0,-19,-8,-20,-23","w":258},"i":{"d":"80,-189v-18,0,-34,-16,-34,-33v0,-18,15,-33,34,-33v17,0,34,15,34,33v0,17,-16,33,-34,33xm25,-42v12,1,28,8,28,-9r0,-80v0,-25,-50,6,-47,-28v3,-40,60,-14,95,-23v9,0,11,7,11,17r0,115v0,24,47,-8,47,29v0,36,-51,20,-81,20v-28,0,-73,14,-72,-20v0,-12,6,-22,19,-21","w":160},"j":{"d":"88,-189v-18,0,-35,-15,-35,-33v0,-19,16,-33,35,-33v18,0,33,14,33,33v0,18,-15,33,-33,33xm92,-180v15,-1,28,-5,28,15r0,150v4,62,-29,80,-81,83v-31,2,-59,-13,-60,-40v-1,-18,13,-31,31,-31v23,0,24,19,28,33v30,-1,23,-40,23,-81r0,-80v0,-26,-46,7,-46,-28v0,-35,47,-18,77,-21","w":152},"k":{"d":"2,-21v-2,-37,47,-1,47,-30r0,-140v0,-25,-50,6,-47,-29v4,-36,54,-15,88,-22v13,0,12,4,12,20r0,118v12,-12,28,-20,37,-35v0,-7,-21,-14,-18,-25v8,-37,65,-8,107,-18v25,-6,29,40,6,42v-8,-1,-20,-9,-29,-2v-10,12,-33,18,-34,35v17,22,28,52,50,69v14,-6,39,-2,38,17v-2,41,-63,11,-95,23v-32,1,-8,-31,-18,-46v-10,-9,-13,-37,-29,-31v-7,8,-20,9,-17,26v-2,15,10,10,18,8v9,0,17,10,16,21v-2,43,-71,8,-108,22v-16,0,-23,-7,-24,-23","w":256,"k":{"u":13,"a":6}},"l":{"d":"21,-42v11,0,28,9,28,-9r0,-140v1,-26,-51,7,-47,-29v4,-38,60,-13,94,-22v10,1,11,8,11,20r0,172v-1,24,40,-7,40,29v0,35,-43,20,-72,20v-28,0,-74,14,-73,-20v1,-11,6,-21,19,-21","w":150},"m":{"d":"211,-51v-2,20,22,8,22,30v0,39,-49,13,-76,23v-13,0,-20,-8,-20,-23v-4,-21,20,-12,20,-28v0,-35,12,-87,-25,-87v-37,0,-28,49,-29,85v-1,19,26,9,24,30v-4,43,-65,10,-100,23v-15,0,-21,-8,-21,-23v0,-18,16,-24,33,-19v8,0,7,-5,8,-14r0,-75v1,-27,-41,5,-41,-30v0,-36,42,-19,75,-23v15,-1,10,19,11,33v10,-41,85,-49,103,-10v38,-42,135,-34,121,49r0,63v0,12,22,5,24,5v20,2,19,45,-4,44v-29,-14,-96,21,-93,-23v1,-11,1,-16,9,-19v8,1,9,-2,9,-9v-3,-34,13,-87,-25,-87v-36,0,-22,51,-25,85","w":356},"n":{"d":"133,-135v-37,0,-29,47,-30,84v0,19,27,9,25,30v-4,41,-63,12,-102,22v-15,1,-21,-7,-21,-22v0,-18,16,-24,33,-19v7,-1,7,-2,8,-11r0,-80v2,-15,-14,-9,-24,-8v-11,1,-17,-9,-17,-20v0,-38,46,-17,77,-24v13,0,8,20,9,34v11,-22,31,-35,63,-36v67,-2,65,64,62,134v-1,17,15,9,26,9v22,0,20,46,-5,43v-26,-3,-52,-1,-78,0v-15,0,-20,-8,-20,-22v-6,-22,20,-11,20,-28v0,-35,11,-86,-26,-86","w":259},"o":{"d":"105,-142v-27,0,-38,22,-38,52v0,30,11,52,38,52v27,0,38,-21,38,-52v0,-29,-12,-51,-38,-52xm105,6v-57,1,-94,-38,-94,-96v0,-58,37,-96,94,-96v58,0,95,38,95,96v0,59,-36,96,-95,96","w":210,"k":{"x":6,"-":-7}},"p":{"d":"20,-182v30,9,71,-19,64,26v14,-17,28,-30,58,-29v51,1,75,41,75,97v0,75,-74,121,-123,73v3,16,-9,48,10,48v20,-3,41,-4,41,19v0,37,-51,20,-80,20v-26,0,-65,14,-65,-19v0,-19,16,-25,34,-20v7,-1,6,-3,7,-11r0,-153v0,-23,-41,6,-41,-27v0,-13,7,-24,20,-24xm163,-91v7,-59,-69,-71,-69,-13v0,35,0,67,33,66v28,0,32,-23,36,-53","w":232},"q":{"d":"103,-38v33,2,34,-30,34,-66v0,-23,-12,-39,-34,-39v-25,0,-37,22,-36,52v0,31,8,52,36,53xm85,52v0,-38,51,-4,51,-30r0,-37v-48,48,-134,1,-123,-73v-12,-82,82,-127,129,-72v0,-18,0,-23,22,-22v21,1,25,-2,25,15r0,189v-2,16,14,10,24,9v11,0,17,10,17,22v0,32,-39,20,-64,19v-30,-1,-81,17,-81,-20","w":215},"r":{"d":"49,-131v1,-17,-18,-8,-27,-8v-9,0,-15,-10,-15,-20v0,-36,47,-18,76,-23v14,-2,7,22,9,36v10,-24,24,-34,54,-38v52,-6,73,79,19,82v-21,1,-35,-19,-26,-38v-37,2,-34,49,-33,90v-1,24,47,-7,47,29v0,37,-53,20,-82,20v-26,0,-64,13,-64,-20v0,-20,15,-23,34,-19v7,2,7,-4,8,-11r0,-80","w":199,"k":{".":23,"-":13,",":23}},"s":{"d":"185,-57v4,64,-99,82,-133,43v-2,12,-7,18,-20,18v-29,0,-13,-35,-18,-61v0,-23,37,-24,42,-2v4,15,20,24,39,24v37,0,39,-27,1,-34v-40,-8,-77,-17,-80,-61v-3,-57,87,-68,120,-41v0,-12,6,-14,19,-14v26,-2,11,29,16,51v0,12,-6,18,-18,18v-23,0,-25,-31,-54,-31v-12,0,-22,5,-22,15v0,8,11,14,34,18v42,8,71,13,74,57","w":196},"t":{"d":"95,6v-65,0,-60,-66,-56,-132v2,-27,-47,4,-41,-30v-3,-25,18,-21,39,-23v7,-20,-5,-62,34,-56v28,-3,21,22,22,46v0,25,68,-10,63,28v3,29,-26,20,-52,22v-7,0,-11,1,-10,8r0,71v0,14,0,20,12,20v29,1,-4,-57,32,-53v16,2,22,16,21,36v0,42,-22,63,-64,63","w":171},"u":{"d":"122,-44v38,2,28,-49,30,-87v1,-13,-12,-10,-20,-9v-12,1,-22,-8,-21,-20v1,-38,53,-15,86,-23v10,1,11,6,12,17r0,119v6,17,49,-7,43,25v1,41,-51,13,-81,24v-15,1,-9,-18,-10,-31v-7,20,-36,35,-63,35v-67,0,-60,-69,-59,-137v0,-23,-41,5,-41,-28v0,-40,52,-16,86,-24v10,1,12,4,12,17v0,44,-18,119,26,122","w":254},"v":{"d":"139,-131v2,-16,-26,-10,-22,-32v6,-35,62,-12,96,-19v12,-3,20,9,20,22v0,30,-33,9,-41,31r-41,117v-3,27,-70,25,-78,0v-14,-42,-27,-89,-46,-127v-14,-4,-36,2,-35,-21v0,-40,59,-14,97,-22v11,-2,18,8,18,19v0,11,-5,19,-14,21v-6,0,-9,4,-8,11v10,28,19,57,27,88","w":224,"k":{".":28,",":28}},"w":{"d":"313,-160v0,30,-34,8,-39,31v-10,43,-19,94,-36,132v-18,4,-70,12,-67,-17r-23,-126v-11,46,-12,102,-29,142v-16,5,-69,15,-67,-14r-34,-127v-12,-5,-37,2,-35,-21v2,-42,61,-12,96,-23v21,-1,24,38,5,41v-7,1,-10,3,-9,9r18,97v11,-46,12,-103,30,-142v17,-8,62,-11,58,18r26,124r14,-98v0,-15,-23,-7,-21,-27v3,-40,58,-11,93,-22v12,0,20,9,20,23","w":302,"k":{".":26,"-":-7,",":26}},"x":{"d":"158,2v-34,4,-25,-32,-13,-43r-23,-31r-22,33v13,7,20,48,-12,41v-35,-8,-92,18,-93,-23v-1,-32,37,-10,50,-28r32,-43v-18,-15,-25,-52,-57,-48v-12,1,-19,-9,-19,-20v0,-42,62,-11,97,-23v26,1,17,36,7,45v3,12,12,20,18,29v5,-10,14,-17,17,-29v-10,-8,-20,-44,7,-45v33,11,95,-19,97,23v1,29,-33,12,-46,29r-31,39v20,18,27,61,67,51v25,4,19,46,-5,43v-23,-4,-47,-2,-71,0","w":245,"k":{"o":6,"e":6,"c":6}},"y":{"d":"61,28v25,-2,31,-35,19,-62r-47,-106v-15,-2,-39,2,-38,-21v3,-41,64,-12,102,-22v18,-5,25,36,7,36v-9,0,-10,9,-7,15v7,27,21,48,23,80v10,-19,20,-61,28,-87v-4,-10,-20,-9,-20,-26v0,-23,28,-15,47,-15v27,0,67,-14,67,20v0,31,-35,8,-44,31v-31,78,-45,192,-146,196v-30,1,-50,-16,-52,-43v-2,-30,54,-42,54,-6v0,6,1,11,7,10","k":{".":31,"-":6,",":31}},"z":{"d":"139,-180v44,-12,57,30,31,57r-78,80v21,-4,61,13,51,-22v0,-13,6,-22,19,-22v37,-1,14,47,22,78v-2,16,-31,8,-47,9r-96,0v-33,2,-34,-31,-16,-50r88,-89v-19,4,-59,-13,-52,17v0,13,-8,22,-20,22v-27,1,-19,-35,-20,-62v-2,-21,15,-18,34,-18r84,0","w":198},"{":{"d":"74,-200v-4,-57,29,-60,81,-60r0,37v-78,-16,1,126,-75,130v43,3,37,48,37,94v0,31,8,36,38,35r0,37v-52,1,-81,-3,-81,-60v0,-46,8,-95,-46,-88r0,-37v50,10,49,-40,46,-88","w":180},"|":{"d":"72,-275r36,0r0,360r-36,0r0,-360","w":180},"}":{"d":"100,-93v-76,-5,8,-142,-75,-130r0,-37v52,-1,84,4,81,60v-2,46,-6,99,47,88r0,37v-53,-7,-50,40,-47,88v3,58,-29,61,-81,60r0,-37v79,17,0,-125,75,-129","w":180},"~":{"d":"150,-127v46,19,86,14,119,-14r0,39v-20,13,-39,23,-67,24v-34,0,-78,-26,-103,-23v-28,3,-47,12,-68,28r0,-39v34,-23,71,-34,119,-15","w":299},"\u00a0":{"w":119}}});
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
                    // scrollTo(0, 0);
                    // toPage.css('top', 0);
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

})(jQuery);/*!*
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
    if (TJG) {
      if (!TJG.vars.isTouch) {
        return null;
      } 
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
                    "padding-bottom":"40px",
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
            endPoint = -(dimension - parent),
            quarter = parent / options.divider;
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
TJG.utils = {

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
  } 
  
};
TJG.ui = { 
  
  hideLoader : function(delay,fn) {
    TJG.repositionDialog = [];
    if (delay == null) {
      delay = 300;
    }
    setTimeout(function() {
      $('#loader').fadeOut(delay,fn);
    });
  },
  
  showLoader : function(delay,fn) {
    TJG.utils.centerDialog("#loader");
    TJG.repositionDialog = ["#loader"];
    if (delay == null) {
      delay = 300;
    } 
    setTimeout(function() {
      $('#loader').fadeIn(delay,fn);
    });
  },
  
  removeDialogs : function () {
    $('.dialog_wrapper').fadeOut();
    TJG.repositionDialog = [];
  },
  
  getOffferRow : function (obj,currency,i,hidden) {
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
      t.push('<li class="offer_item clearfix '+ clsId +'" '+ style +'>'); 
        t.push('<div class="offer_image">');
          t.push('<img src="' + v.IconURL + '">');
          //t.push('<div class="image_loader"></div>');
        t.push('</div>');
        t.push('<div class="offer_text">');
          t.push('<div class="offer_title title">');
            t.push(v.Name);
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
    });
    return t.join('');    
  },
  
  showRegister : function () {
    var hasLinked = true, path;
    if (TJG.path) {
       path = TJG.path;
    }
    else {
      path = location.pathname.replace(/\/$/, '');
    }
    TJG.repositionDialog = ["#sign_up_dialog"];
    $("#sign_up_dialog_content").html($('#sign_up_dialog_content_placeholder').html());
    TJG.onload.loadCufon();
    $(".close_dialog").show();
    $("#sign_up_dialog_content").parent().animate({ height: "260px", }, 250);
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
        $("#sign_up_dialog_content").parent().animate({ height: "120px", }, 250);
        TJG.onload.loadCufon();
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
              $("#sign_up_dialog_content").parent().animate({ height: "230px", }, 250);
              $("#sign_up_dialog_content").html(msg);
              TJG.onload.loadCufon(); 
              if (TJG.vars.isIos == false) {
                  if (d.more_games_url) {
                    $('.close_dialog,.continue_link_device').click(function(){
                      document.location.href = d.more_games_url;
                    });                    
                  }
                  else {
                    document.location.href = location.protocol + '//' + location.host;
                  }
              }
              else if (d.link_device_url) {
                $('.close_dialog,.continue_link_device').click(function(){
                  document.location.href = d.link_device_url;
                  $("#sign_up_dialog").hide();
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
              $("#sign_up_dialog_content").parent().animate({ height: "260px", }, 250);
              TJG.onload.loadCufon();
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
            TJG.onload.loadCufon();
            $('#sign_up_again').click(function(){
               TJG.ui.showRegister();
              $("#sign_up_dialog_content").parent().animate({ height: "260px", }, 250);
              TJG.onload.loadCufon();
            });
          }
        });
      }
    });
  }
};
  
(function(window, document) {

    TJG.onload = {
      loadCufon : function (fn,delay) {
        if (!delay) {
          delay = 1;
        }
        if (Cufon) {
          Cufon.replace('.title', { fontFamily: 'Cooper Std' });
          Cufon.replace('.title_2', { fontFamily: 'AmerType Md BT' });
        }
        if (fn) {
          setTimeout(function() { 
            fn;
            }, delay);
        }
      },

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
        $('#sign_up, #sign_up_form').click(function(){
          TJG.utils.centerDialog("#sign_up_dialog");
          TJG.repositionDialog = ["#sign_up_dialog"];
          TJG.ui.showRegister();
        });
        $('#how_works').click(function(){
          TJG.utils.centerDialog("#how_works_dialog");
          TJG.repositionDialog = ["#how_works_dialog"];
          $("#how_works_dialog").fadeIn(350);
        });
      },
    };

    TJG.init = function() {  
      
      TJG.utils.hideURLBar();
      for (var key in TJG.onload) {
        TJG.onload[key]();
      }
    };
    window.addEventListener("load", TJG.init, false);

})(this, document);
