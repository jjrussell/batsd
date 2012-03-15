(function (w) {
  var module = function (url) {
    var me = {
      url: url,
      data: null,
      queue: [],
      flush: function(data) {
        var i, ii;
        for(i = 0, ii = me.queue.length; i < ii; i++) {
          me.queue[i](data);
        }
        me.queue = [];
      },
      cbName: function () {
        return "jsonp_response_" + new Date().getTime();
      },
      getData: function() {
        var script_el, full_url, cb = me.cbName();

        w[cb] = function (data) {
          me.data = data;
          me.flush(data);
        };

        full_url = url.match(/\?/) ? url + "&" : "?";
        full_url += "callback=" + cb;

        script_el = document.createElement("script");
        script_el.setAttribute("type", "text/javascript");
        script_el.setAttribute("src", full_url);

        document.getElementsByTagName("head")[0].appendChild(script_el);
      },
      ready: function (callback) {
        if(me.data) {
          callback(me.data);
        } else {
          me.queue.push(callback);
        }
      }
    };

    me.getData();
    return me;
  };

  w.ajaxPreload = module;
}(window));
