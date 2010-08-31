if (typeof(Tapjoy) == "undefined") Tapjoy = {};

$(function(){
  $('.flash').click(function(){
    $(this).slideUp();
  });

  // watch text fields in editable table
  var numChanged = 0;
  $('table.editable input[type=text], table.editable textarea').each(function() {
    $(this).attr('init', $(this).val());
  });

  $('table.editable input[type=text], table.editable textarea').focus(function() {
    $(this).addClass('active');
  });

  $('table.editable input[type=text], table.editable textarea').blur(function() {
    $(this).removeClass('active');
    if ($(this).val() != $(this).attr('init')) {
      $(this).addClass('changed');
      numChanged += 1;
    } else {
      $(this).removeClass('changed');
      numChanged -= 1;
    }
  });
});

