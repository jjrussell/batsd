//= require marketplace/auth-pages/common
$(function () {
  'use strict';

  var redirectUrl = '',
      tjStates = window.tjStates,
      Tapjoy = window.Tapjoy,
      $slides = $('.mobile-forward, .mobile-backward, .slide-forward, .slide-back'),
      isIos = Tapjoy.device.idevice,
      isAndroid = Tapjoy.device.android,
      datePickerOpts,
      datePickerLocale = $('.ui-date-picker').data('locale-info');

  datePickerOpts = $.extend({
    title: window.i18n.t('games.birthdate'),
    dateOutput: 'M d, yyyy',
    name: 'gamer[birthdate]',
    id: 'gamer_birthdate'
  }, datePickerLocale || {});

  $('.ui-date-picker').DatePicker(datePickerOpts);

  $('#new_gamer, #log-in-with-facebook-form').on('ajax-success', function (ev, $this, data) {
    var nextState = 'device-setup';
    if (data.android_app || (!isIos && !isAndroid)) {
      nextState = 'redirect';
    }

    redirectUrl = data.redirect_url;

    tjStates.setState(nextState);
  }).on('ajax-error', tjStates.fn.handleAjaxError);

  $('.platform-detected').each(function () {
    var $this = $(this),
      dev = null;

    dev = isIos ? 'ios' : dev;
    dev = isAndroid ? 'android' : dev;

    if (dev) {
      $this.val(dev);
    }
  });

  // State logic described here
  tjStates.add('signup-form', {
    enter: function () {
      $('.auth.flocus').trigger('reset');
    },
    leave: function () { },
    removeClasses: [['.slides-down', 'show']],
    addClasses: [[$slides, 'hide-button']],
    bindEvents: [['.flocal', 'flocus', tjStates.next]],
    next: 'signup-focused'
  })
  .add('facebook-connect', tjStates.fn.facebookConnect('#log-in-with-facebook-form'), 'signup-form')
  .add('signup-focused', tjStates.fn.focusFormState('#new_gamer', $slides), 'signup-form', 'signup-submit')
  .add('signup-submit', {
    enter: function () {
      $('.right-form').trigger('flocus');
      $('#new_gamer').submit();
    },
    leave: function () { },
    addClasses: [['.slide-forward', 'loading']],
    bindEvents: [['#new_gamer', 'ajax-error', tjStates.previous]],
    previous: 'signup-focused'
  })
  .add('device-setup', tjStates.fn.deviceSetup('#connect-device'), 'signup-focused', 'redirect')
  .add('redirect', {
    enter: function () {
      var now = new Date(), last = now;
      Tapjoy.Utils.notification({message: i18n.t('games.loading')});
      document.location.href = redirectUrl;

      // make sure that page is refreshed if user cancels device connect
      window.setInterval(function () {
        now = new Date();

        if ((now - last) > 1500) {
          window.location.reload();
        }

        last = now;
      }, 100);
    },
    addClasses: [[$slides, 'hide-button'], ['.auth', 'hidden']]
  })
  .begin('signup-form');
});
