(function (tjStates) {
  "use strict";

  var isIos = Tapjoy.device.idevice;
  
  function capFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  tjStates.fn.handleAjaxError = function (ev, $this, xhr) {
    var errors = JSON.parse(xhr.responseText),
      errorMsgs = errors && errors.error ? errors.error : {},
      msg = [], key;

    for (key in errorMsgs) {
      if (errorMsgs.hasOwnProperty(key)) {
        msg.push(capFirstLetter(key) + " " + errorMsgs[key]);
      }
    }

    Tapjoy.Utils.notification({message: msg.join('<br />'), type: 'error'});
  };

  tjStates.fn.focusFormState = function (formSelector, $slides) {
    var state,
      $form = $(formSelector);

    function enableForward() {
      $('.slide-forward, .mobile-forward').removeClass('disabled').addClass('primary').removeAttr('disabled');
    }

    function disableForward() {
      $('.slide-forward, .mobile-forward').addClass('disabled').removeClass('primary').attr('disabled', true);
    }

    function nextAndPreventDefault() {
      tjStates.next();
      return false;
    }

    state = {
      enter: function () {
        $('.right-form').trigger('flocus');
        $form.trigger('check-valid');
      },
      leave: function () {
        $('.slide-forward, .mobile-forward').removeAttr('disabled').removeClass('disabled');
      },
      bindEvents: [[$form, 'is-valid', enableForward],
                   [$form, 'is-not-valid', disableForward],
                   [$form, 'submit', nextAndPreventDefault]],
      addClasses: [[$form, 'show']],
      previous: 'signup-form',
      next: 'signup-submit'
    };

    return state;
  };

  tjStates.fn.facebookConnect = function (selector) {
    var state, $form = $(selector);

    state = {
      bindEvents: [[$form, 'facebook-connect-fail', tjStates.previous]]
    };

    return state;
  };

  tjStates.fn.deviceSetup = function (selector) {
    var state, $connect = $(selector);

    function enableBackward() {
      $('.slide-back, .mobile-backward').removeClass('disabled').removeAttr('disabled');
    }

    function disableBackward() {
      $('.slide-back, .mobile-backward').addClass('disabled').attr('disabled', true);
    }

    state = {
      enter: function () {
        var platform = $('[name="platform[default]"]:checked').val();
        platform || (platform = isIos ? 'ios' : 'android');
        $('#register-' + platform).removeClass('hidden');
        disableBackward();
      },
      leave: function () {
        $('.instructions').addClass('hidden');
        enableBackward();
      },
      removeClasses: [[$connect, 'hidden']],
      addClasses: [['.flocal', 'hidden'], ['.slide-forward, .mobile-forward', 'primary']]
    };

    return state;
  };
}(window.tjStates));
