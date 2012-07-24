(function (window, document) {
  "use strict";

  $.fn.watchValid = function () {
    return this.each(function () {
      var $$ = $(this),
        _t = window.i18n.t,
        $form = $$.closest("form"),
        $req = $("[required]", $form),
        $check = $("[data-must-check]", $form),
        $psword = $("input[name*='password']", $form),
        $submit = $("input[type='submit']", $$),
        invalid;

      $$.submit(function () {
        var i, ii,
            msg = "",
            failed = invalid.length > 0,
            curr_msg;

        for (i = 0, ii = invalid.length; i < ii; i++) {
          curr_msg = $(invalid[i]).data("validation-message");
          if (curr_msg) {
            msg += curr_msg + "<br />";
          }
        }

        if (failed) {
          window.Tapjoy.Utils.notification({
            message: msg || _t('games.invalid_fields')
          });
          return false;
        }
      });

      function enable() {
        $$.trigger('is-valid');
        $submit.removeClass("disabled");
      }

      function disable() {
        $$.trigger('is-not-valid', [invalid]);
        $submit.addClass("disabled");
      }

      function checkValid() {
        invalid = [];

        $req.each(function () {
          if (!$(this).val()) {
            invalid.push($(this));
          }
        });

        $check.each(function () {
          if(!$(this).attr('checked')) {
            invalid.push($(this));
          }
        });

        if ($psword.length === 2) {
          if($psword.first().val() !== $psword.last().val()) {
            invalid = invalid.concat($psword);
          }
        }

        return invalid.length === 0 ? enable() : disable();
      }

      $req.bind("change focus blur keyup", Tapjoy.Utils.debounce(checkValid));
      $$.bind("check-valid", Tapjoy.Utils.debounce(checkValid));
      checkValid();
    });
  };

  $(function () {
    $(".enable-when-valid, .js-watch-valid").watchValid();
  });

}(this.window, this.document));
