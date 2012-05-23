(function(Tap){
  var _t = window.i18n.t;

  Tap.extend({
    Plugins: {

      showAddHomeDialog : function() {
        var startY = startX = 0,
          boldText = Tap.Utils.sprintfTemplate("<span class='bold'>%s</span>"),
        options = {
          message: '<div>'+
              _t('games.add_to_homescreen', {
                tapjoy: boldText("Tap")
              })+
            '</div><div class="bookmark"><span>'+
              _t("games.tap_that", {
                icon:'</span><span class="bookmark_icon"></span><span>',
                button:'</span><span class="bookmark_btn"></span><span>'
              })+
            '</span></div>',
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
        expired = Tap.Utils.Storage.get("tjg.bookmark.expired"),
        shown = Tap.Utils.Storage.get("tjg.bookmark.shown");
        if (Tap.Utils.isEmpty(shown)) {
          shown = 0;
        }
        shown = parseInt(shown);
        if (expired == "true") {
          return;
        }
        if (shown >= 4) {
          Tap.Utils.Storage.set("tjg.bookmark.expired", "true");
        }
        Tap.browser.version =  Tap.browser.version ?  Tap.browser.version[0].replace(/[^\d_]/g,'').replace('_','.')*1 : 0;
        expired = expired == 'null' ? 0 : expired*1;
        var div = document.createElement('div'), close;
        div.id = 'addToHome';
        div.style.cssText += 'position:absolute;-webkit-transition-property:-webkit-transform,opacity;-webkit-transition-duration:0;-webkit-transform:translate3d(0,0,0);';
        div.style.left = '-9999px';
        div.className = (Tap.device.ipad ? 'ipad wide' : 'iphone');
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
          posY = Tap.device.ipad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
          posX = Tap.device.ipad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX;
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
          var posY = Tap.device.ipad ? window.scrollY - startY : window.scrollY + window.innerHeight - startY,
          posX = Tap.device.ipad ? window.scrollX - startX : window.scrollX + Math.round((window.innerWidth - el.offsetWidth)/2) - startX,
          opacity = '0.95',
          duration = '0';
          el.style.webkitTransitionProperty = '-webkit-transform,opacity';
          switch (options.animationOut) {
            case 'drop':
            if (Tap.device.ipad) {
              duration = '0.4s';
              opacity = '0';
              posY = posY + 50;
            } else {
              duration = '0.6s';
              posY = posY + el.offsetHeight + options.bottomOffset + 50;
            }
            break;
            case 'bubble':
            if (Tap.device.ipad) {
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
          startY = Tap.device.ipad  ? window.scrollY : window.innerHeight + window.scrollY;
          startX = Tap.device.ipad  ? window.scrollX : Math.round((window.innerWidth - el.offsetWidth)/2) + window.scrollX;
          el.style.top = Tap.device.ipad ? startY + options.bottomOffset + 'px' : startY - el.offsetHeight - options.bottomOffset + 'px';
          el.style.left = Tap.device.ipad ? startX + (Tap.browser.version >=5 ? 160 : 208) - Math.round(el.offsetWidth/2) + 'px' : startX + 'px';
          switch (options.animationIn) {
            case 'drop':
            if (Tap.device.ipad) {
              duration = '0.6s';
              el.style.webkitTransform = 'translate3d(0,' + -(window.scrollY + options.bottomOffset + el.offsetHeight) + 'px,0)';
            }
            else {
              duration = '0.9s';
              el.style.webkitTransform = 'translate3d(0,' + -(startY + options.bottomOffset) + 'px,0)';
            }
            break;
            case 'bubble':
            if (Tap.device.ipad) {
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
            Tap.Utils.Storage.set("tjg.bookmark.shown", shown);
            el.style.webkitTransform = 'translate3d(0,0,0)';
            el.addEventListener('webkitTransitionEnd', transitionEnd, false);
            }, 0);
            closeTimeout = setTimeout(addToHomeClose, options.lifespan);
        }, options.startDelay);
        window.addToHomeClose = addToHomeClose;
      }

    }
  });
})(Tap);
