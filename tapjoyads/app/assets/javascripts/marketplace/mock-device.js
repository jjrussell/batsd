(function (Tap, w, $) {
  "use strict";

  var udid;

  $(function () {
    var template = Tap.Utils.underscoreTemplate($("#plist-tmp").text()),
      $form = $("#plist-form");

    $form.submit(function () {
      var formData = [], rawPost = "";

      udid = $("input[name='UDID']", $form).val();

      $("input", $form).each(function () {
        var $t = $(this);
        formData.push({key: $t.attr("name"),  value: $t.val()});
      });

      rawPost = template({data: formData});

      $.ajax({
        url: $form.attr("action"),
        type: "post",
        data: rawPost,
        success: function () {
          Tap.Utils.notification({message: "Success - now you can add apps."});
          $("#device-section").hide();
          $("#app-list").show();
        },
        error: function () {
          Tap.Utils.notification({message: "Failed", type: "error"});
        }
      });

      return false;
    });

    $(".app-link").on('click', function () {
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

    $(".existing-device").on('click', function () {
      udid = $(this).data('udid');
      $("#device-section").hide();
      $("#app-list").show();

      return false;
    });
  });
}(window.Tapjoy, window, jQuery));
