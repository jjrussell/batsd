(function () {
  "use strict";

  $('.flocus').each(function () {
    var $t = $(this),
      $flocals = $('.flocal', $t),
      flocused = null,
      flocuser_selector = $t.data('flocuser-selector');

    function hide(which) {
      which.removeClass('flocused');
      which.addClass('unflocused');
    }

    function show(which) {
      which.removeClass('unflocused');
      which.addClass('flocused');
    }

    $flocals.on('flocus', function () {
      if (flocused !== $(this)) {
        $t.trigger('flocus-change', this);
      }

      hide($flocals);
      flocused = $(this);
      show(flocused);
    });

    $t.on('reset', function () {
      if (flocused !== null) {
        $t.trigger('flocus-change', this);
      }

      $flocals.removeClass('unflocused');
      $flocals.removeClass('flocused');
      flocused = null;
    });

    $('.flocuser,' + flocuser_selector, $flocals).on('click focus', function () {
      $(this).closest('.flocal').trigger('flocus');
    });

    $('.unflocuser', $flocals).on('click focus', function () {
      $t.trigger('reset');
    });
  });

  $('.js-toggle').each(function () {
    var $t = $(this)
      , href = $t.attr('href')
      , on = false
      , $target = $(href)
      ;

    function render() {
      if (on) {
        $('.toggle-on', $t).show();
        $('.toggle-off', $t).hide();
        $target.show();
      } else {
        $('.toggle-on', $t).hide();
        $('.toggle-off', $t).show();
        $target.hide();
      }
    }

    $t.on('click', function () {
      on = !on;
      render();
      return false;
    });

    $t.on('toggle-on', function () {
      on = true;
      render();
    });

    $t.on('toggle-off', function () {
      on = false;
      render();
    });

    render();
  });
}());
