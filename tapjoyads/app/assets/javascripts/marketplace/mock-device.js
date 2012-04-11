(function (Tap, w, $) {
  "use strict";

  $(function () {
    var template = Tap.Utils.underscoreTemplate($("#plist-tmp").text()),
      $form = $("#plist-form");

    $form.submit(function () {
      var formData = [], rawPost = "";

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
          $form.hide();
          $(".app-link").show();
        },
        error: function () {
          Tap.Utils.notification({message: "Failed", type: "error"});
        }
      });

      return false;
    });

    $(".app-link").hide().click(function () {
      var $t = $(this);
      $.ajax({
        url: $t.attr("href"),
        type: 'GET',
        data: {udid: $("#plist-form input[name='UDID']").val()},
        success: function () {
          $t.hide();
          Tap.Utils.notification({message: "Added app: " + $t.html()});
        }
      });

      return false;
    });
  });
}(window.Tapjoy, window, jQuery));
