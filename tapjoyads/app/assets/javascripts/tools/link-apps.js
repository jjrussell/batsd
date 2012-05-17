(function (w, $) {
  "use strict";
  $(function () {
    var $form = $("[id^='edit_gamer_device']"),
      udid = $('#udid').html();

    $(".app-link").bind('click', function () {
      var $t = $(this),
        $parent = $t.closest('li'),
        $spinner = $('.screw-spinner', $parent).trigger('start-spinner');

      $.ajax({
        url: $t.attr("href"),
        type: 'GET',
        data: {udid: udid},
        success: function () {
          //$t.closest('li').hide();
          $spinner.trigger('complete-spinner');
        }
      });

      return false;
    });

    $(".existing-device").bind('click', function () {
      udid = $(this).data('udid');
      $("#device-section").hide();
      $("#app-section").show();

      return false;
    });
  });
}(window, jQuery));
