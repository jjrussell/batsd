if (typeof(Tapjoy) == "undefined") Tapjoy = {};

$(function(){
  $('.flash').click(function(){
    $(this).slideUp();
  });

  var numChanged = 0;
  Tapjoy.watchTextFields = function() {
    $('input').focus(function() {
      $(this).addClass('active');
    });

    $('input,textarea').blur(function() {
      $(this).removeClass('active');
      if ($(this).val() != $(this).attr('init')) {
        $(this).addClass('changed');
        numChanged += 1;
      } else {
        $(this).removeClass('changed');
        numChanged -= 1;
      }
    });
  };
});

