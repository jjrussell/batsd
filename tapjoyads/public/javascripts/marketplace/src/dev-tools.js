(function () {
  "use strict";

  var responsive_keys = function () {
    var text = "<iframe style='position: absolute; top: 0; left: 0; z-index:10000; display:none; height:2000px; border:0px;' src='%s'></iframe>",
      response_iframe = $(text.replace(/%s/, window.location.pathname)),
      overlay = $("<div style='display: none; position: fixed; top: 0; left: 0;width: 100%; height:100%; background: #fff; z-index: 9999;'></div>"),
      initial_title = $("title").html(),
      ONE = 49,
      NINE = 57;
    $("body").append(response_iframe);
    $("body").append(overlay);

    $(window).keydown(function (e) {
      var breakpoints = [320, 480, 768, 1024, 1200],
        code = parseInt(e.keyCode, 10),
        breakpoint,
        target = e.target.nodeName.toLowerCase();

      if (/input|textarea|select/i.test(target)) {
        return;
      }

      code = code < NINE && code >= ONE ? code - ONE : false;
      breakpoint = breakpoints[code] || "";

      if (!breakpoint) {
        response_iframe.hide();
        overlay.hide();
      } else {
        response_iframe.show();
        overlay.show();
        response_iframe.css("width", breakpoint);
      }
      $("title").html(breakpoint || initial_title);
    });
  };


  $(function () {
    // recursive iframes are bad, m'kay
    if (window.self === window.top) {
      responsive_keys();
    }
  });
}());
