(function ($) {
  $(function () {
    $('.screw-spinner').each(function () {
      var $t = $(this),
        $s = $('.screw', $t),
        loading = $s.hasClass('loading');


      $t.on('start-spinner', function () {
        loading = true;
        $s.addClass('loading');
        $s.removeClass('done');
      });

      $t.on('complete-spinner', function () {
        function helper() {
          loading = false;
          $s.addClass('done');
          $s.removeClass('loading');
          $s.off('animationiteration webkitAnimationIteration', helper);
        }

        if(!loading) {
          helper();
        } else {
          $s.on('animationiteration webkitAnimationIteration', helper);
        }
      });
    });
  });
}(jQuery));
