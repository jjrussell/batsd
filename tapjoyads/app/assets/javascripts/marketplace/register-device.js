(function (Tap, $, _t) {
  "use strict";

  var $message = $('#register-message'),
      $head = $('.message-header', $message),
      $action = $('#link-device'),
      desktopMsg = $head.data('desktop-text'),
      possibleLinks = $action.data('links');

  function sendEmail() {
    var url = possibleLinks.desktop;

    $('.message-content .register-btn', $message).html(_t('shared.sending'));
    $.ajax({
      type: 'POST',
      url: url,
      cache: false,
      timeout: 15000,
      dataType: 'json',
      success: function (d) {
        if (d.success) {
          $action.off('click');
          $('#register-message .message-content .register-btn').html(_t('shared.sent'));
        }
        else {
          $('#register-message .message-content .register-btn').html(_t('shared.please_try_again'));
        }
      },
      error: function (d) {
        $('#register-message .message-content .register-btn').html(_t('shared.please_try_again'));
      }
    });

    return false;
  }

  if (!Tap.device.idevice && !Tap.device.android) {
    // display message
    $head.html(desktopMsg);
    $('.register-btn', $message).html(_t('games.email_device_link'));

    $action.on('click', sendEmail);
  } else {
    $action.attr('href', Tap.device.idevice ? possibleLinks.ios : possibleLinks.android);
  }
}(this.Tapjoy, this.jQuery, this.i18n.t));
