(function ($) {
  $(function () {
    $('.screw-spinner').each(function () {
      var $t = $(this),
        $s = $('.screw', $t),
        loading = $s.hasClass('loading');


      $t.bind('start-spinner', function () {
        loading = true;
        $s.addClass('loading');
        $s.removeClass('done');
      });

      $t.bind('complete-spinner', function () {
        function helper() {
          loading = false;
          $s.addClass('done');
          $s.removeClass('loading');
          $s.unbind('animationiteration webkitAnimationIteration', helper);
        }

        if(!loading) {
          helper();
        } else {
          $s.bind('animationiteration webkitAnimationIteration', helper);
        }
      });
    });
  });
}(jQuery));
