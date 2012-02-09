/*global jQuery */
/*!	
 * FitText.js 1.0
 *
 * Copyright 2011, Dave Rupert http://daverupert.com
 * Released under the WTFPL license 
 * http://sam.zoy.org/wtfpl/
 *
 * Date: Thu May 05 14:23:00 2011 -0600
 */

(function( $ ){
  var resizeOccurred = true
    , clearStyles
    ;

  clearStyles = function($$) {
    var args = arguments
      , i, ii
      ;

    for(i=1, ii=args.length; i<ii; i++) {
      $$.css(args[i], "");
    }
  };

  function setup_throttle() {
    $(window).resize(function() {
      resizeOccurred = true;
    });

    window.setInterval(function() {
      if(resizeOccurred) {
        resizeOccurred = false;
        $(document).trigger("fittext-resize");
      }
    }, 300);

    setup_throttle = function() {};
  }

  $.fn.vAlign = function() {
    return this.each(function() {
      var $$ = $(this)
        , $p = $$.parent()
        , resizer
        , resetter
        ;

      resetter = function() {
        clearStyles($$, "position", "top", "margin-top");
        $(document).unbind("fittext-resize", resizer);
        $(document).unbind("fittext-reset", resetter);
      };
      resizer = function() {
        $$.css({
          "position":"relative", 
          "top":($p.height()/2),
          "margin-top":(-$$.height()/2)
        });
      };

      $(document).bind("fittext-resize", resizer);
      $(document).bind("fittext-reset", resetter);
    });
  };

  $.fn.fitText = function( kompressor, options ) {
    var settings = {
      'minFontSize' : Number.NEGATIVE_INFINITY,
      'maxFontSize' : Number.POSITIVE_INFINITY
    };

    return this.each(function(){
      var $this = $(this);              // store the object
      var compressor = kompressor || 1; // set the compressor
      if ( options ) { 
         $.extend( settings, options );
      }

      setup_throttle();

      // Resizer() resizes items based on the object width divided by the compressor * 10
      var resizer = function () {
        $this.css('font-size', Math.max(Math.min($this.width() / (compressor*10), parseFloat(settings.maxFontSize)), parseFloat(settings.minFontSize)));
      };

      // Call once to set.
      resizer();

      var resetter = function() {
        clearStyles($this, "font-size");
        $(document).unbind("fittext-resize", resizer);
        $(document).unbind("fittext-reset", resetter);
      };

      $(document).bind("fittext-resize", resizer);
      $(document).bind("fittext-reset", resetter);
    });
  };

})( jQuery );
