if (typeof(Tapjoy) == "undefined") Tapjoy = {};

function numberToCurrency(number) {
  return '$' + number.toFixed(2);
}

function stringToNumber(currency) {
  return Number(currency.replace(/[^\d\.]/g, ''));
}

$(function($){
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

  $('.help').click(function() {
    $('.ui-dialog').remove();
    var content = $('#' + this.id + '_content');
    var position = [$(this).position().left - 300, $(this).position().top - $(window).scrollTop()];
    content.dialog({title: "Help: " + content.attr('name'), position: position, minHeight: 75, dialogClass: 'help-dialog'});
  });

  $('input.currency_field').change(function() {
    $(this).val(numberToCurrency(stringToNumber($(this).val())));
  });
});
