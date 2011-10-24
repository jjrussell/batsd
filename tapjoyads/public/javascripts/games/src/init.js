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
    winH = $(window).height();
    winW = $(window).width();
    var nav = navigator, classes = [''], classReplaces = {}, device = "", orientationCompute = "";
    TJG.vars.isIos = (/iphone|ipod|ipad/gi).test(nav.platform);
    TJG.vars.device_type = nav.platform.toLowerCase();
    TJG.vars.isIpad = (/ipad/gi).test(nav.userAgent);
    TJG.vars.isIpod = (/ipod/gi).test(nav.userAgent);
    TJG.vars.isIphone = (/iphone/gi).test(nav.userAgent);
    TJG.vars.isAndroid = (/android/gi).test(nav.userAgent);
    TJG.vars.isMobile = /(ip(od|ad|hone))/gi.test(nav.userAgent);
    if (TJG.vars.isAndroid) {
     TJG.vars.device_type = 'android';
     if ((/mobile/gi).test(nav.userAgent)) {
       TJG.vars.isMobile = true;
     }
    }
    if (TJG.vars.device_type) {
     TJG.vars.device_type = '' + TJG.vars.device_type.toLowerCase();
    }
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
})(this, document);