//= require marketplace/auth-pages/common
$(function () {
  'use strict';

  var redirectUrl = '',
      _t = window.i18n.t,
      $slides = $('.mobile-forward, .slide-forward'),
      tjStates = window.tjStates,
      $loginForm = $('#login-form'),
      $mainSection = $('#mainsection'),
      $footer = $('#footer'),
      focusState = tjStates.fn.focusFormState('#new_gamer_session', $slides),
      deviceState = tjStates.fn.deviceSetup('#connect-device'),
      facebookState = tjStates.fn.facebookConnect('#log-in-with-facebook-form'),
      isIos = Tapjoy.device.idevice,
      isAndroid = Tapjoy.device.android;

  $('#log-in-with-facebook-form').on('ajax-success', function (ev, $this, data) {
    var nextState = 'redirect';

    if (data.new_gamer) {
      if (isIos || isAndroid) {
        nextState = 'device-setup';
      }
    }

    redirectUrl = data.redirect_url;

    tjStates.setState(nextState);
  }).on('ajax-error', tjStates.handleAjaxError);

  (function prepStates() {
    focusState.addClasses = focusState.addClasses || [];
    deviceState.addClasses = deviceState.addClasses || [];
    facebookState.addClasses = facebookState.addClasses || [];

    focusState.addClasses.push([$loginForm, 'show']);
    focusState.addClasses.push([$mainSection, 'hidden']);
    focusState.addClasses.push([$footer, 'hidden']);

    deviceState.addClasses.push([$loginForm, 'show']);
    deviceState.addClasses.push([$mainSection, 'hidden']);
    deviceState.addClasses.push([$footer, 'hidden']);

    facebookState.addClasses.push([$loginForm, 'show']);
    facebookState.addClasses.push([$mainSection, 'hidden']);
    facebookState.addClasses.push([$footer, 'hidden']);
    facebookState.addClasses.push([$slides, 'hide-button']);
  }());


  tjStates.add('home', {
    enter: function (prev) { },
    next: 'login-form'
  })
  .add('login-form', {
    enter: function () {
      $('.auth.flocus').trigger('reset');
    },
    leave: function () { },
    bindEvents: [['.flocal', 'flocus', tjStates.next]],
    addClasses: [[$slides, 'hide-button'], [$loginForm, 'show'], [$mainSection, 'hidden'], [$footer, 'hidden']],
    next: 'login-focused',
    previous: 'home'
  })
  .add('login-focused', focusState, 'login-form', 'login-submit')
  .add('login-submit', {
    enter: function () {
      $('form#new_gamer_session').submit();
    },
    leave: function () {
    },
    addClasses: [[$loginForm, 'show'], ['.slide-forward', 'loading'], [$mainSection, 'hidden'], [$footer, 'hidden']],
    previous: 'login-focused'
  })
  .add('facebook-connect', facebookState, 'login-form')
  .add('device-setup', deviceState, 'login-form', 'redirect')
  .add('redirect', {
    enter: function () {
      var now = new Date(), last = now;
      Tapjoy.Utils.notification({message: i18n.t('games.loading')});
      document.location.href = redirectUrl;

      // make sure that page is refreshed if user cancels device connect
      window.setInterval(function () {
        now = new Date();

        if ((now - last) > 2000) {
          window.location.reload();
        }

        last = now;
      }, 100);
    },
    addClasses: [[$loginForm, 'show'], [$mainSection, 'hidden'], [$footer, 'hidden'], ['.mobile-forward, .slide-forward, .mobile-backward, .slide-back', 'hide-button']]
  }, 'login-form')
  .begin('home');
});
