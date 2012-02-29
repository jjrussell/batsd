(function(Tap, $){

  Tap.extend({
    Utils: {
      /**
       * Prints to the window console
       * @param {mixed} result Can be elements, functions, arrays, objects, you name it
       * @param {mixed} message Can be elements, functions, arrays, objects, you name it
       */
      log : function(result, message){
        if(window.console && window.console.log){
          window.console.log(result +' :: '+ message);
        }
      },

			mask: function(){
			  var wrap = $(document.createElement('div'));

				wrap.attr('id', 'ui-simple-mask')
				.css({
          height: $(document).outerHeight() + 'px'
				})
				.appendTo(document.body);

			  this.mask.element = wrap;

			},
			removeMask: function(){
				if(this.mask.element){
          this.mask.element.empty().remove();
					this.mask.element = null;
				}
			},
			notification: function(config){

				config = Tap.extend({}, {
          container: $(document.body),
					delay: 10000,
          message: '',
					type: 'normal'
				}, config || {});

				var wrap = $(document.createElement('div'));

				if($('#ui-notification').length == 0){
	        wrap.attr('id', 'ui-notification')
	        .addClass('ui-notification')
	        .appendTo(config.container);
				}else{
					wrap = $('#ui-notification');
				}

        wrap.html(config.message)

        var width = wrap.outerWidth(true);

        wrap.css({
          width: width + 'px',
          left: ((config.container.outerWidth(true) - width) / 2) + 'px'
        });

				$(window).resize(function(){
	        wrap.css('left', ((config.container.outerWidth(true) - width) / 2) + 'px')
				});

				Tap.delay(function(){
					if(wrap.length > 0)
            wrap.empty().remove();
				}, config.delay);
			},

			or: function(v,d) {
			  console.log(this);
        if (this.isEmpty(v)) {
          return d;
        }
        return v;
			},

			isEmpty: function(v) {
        return v == undefined || v == null || v == '' || v == 'undefined';
			},

      Storage: {
        set: function(k) {
          try {
            localStorage[k] = v;
            return true;
          } catch (e) {
            return false;
          }
        },
        get: function(k) {
          return localStorage[k];
        },
        remove: function(k) {
          localStorage.removeItem(k);
        },

        delete: function(k) {
          this.remove(k);
        },
        reset: function() {
          localStorage.clear();
        }
      },

      Cookie: {
        set: function(k, v, days, years) {
          if (days) {
            var date = new Date();
            var time = 0;
            if (years) {
              time = years*365*24*60*60*1000;
            }
            else {
              time = days*24*60*60*1000;
            }
            date.setTime(date.getTime()+(time));
            var expires = "; expires=" + date.toGMTString();
          }
          else var expires = "";
          document.cookie = k + "=" + v + expires + "; path=/";
        },
        get: function(k) {
          var name = k + "=";
          var ca = document.cookie.split(';');
          for(var i=0;i < ca.length;i++) {
            var c = ca[i];
            while (c.charAt(0)==' ') c = c.substring(1,c.length);
            if (c.indexOf(name) == 0) return c.substring(name.length,c.length);
          }
          return null;
        },
        remove: function(k) {
          this.setCookie(k, "", -1);
        },
        delete: function(k) {
          this.remove(k);
        }
      }
    }
  });

  Tap.log = Tap.alias(Tap.Utils, 'log');
  Tap.ls = Tap.alias(Tap.Utils.Storage, 'ls');

  $.fn.extend({
    preventHighlight: function(){
      return this.each(function(){
        this.onselectstart = function(){
          return false;
        };

        this.unselectable = 'on';
        $(this).css({
          '-moz-user-select': 'none',
          '-khtml-user-select': 'none',
          'user-select': 'none',
          '-webkit-user-select': 'none'
        });
      });
    }
  });

})(Tapjoy, jQuery);


