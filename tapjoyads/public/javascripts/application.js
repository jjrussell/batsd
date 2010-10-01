if (typeof(Tapjoy) == "undefined") Tapjoy = {};
if (typeof(console) == "undefined") console={log:$.noop};

function numberToCurrency(number) {
  return '$' + Number(number).toFixed(2).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
}

function stringToNumber(currency, allowNegative) {
  if (allowNegative) {
    return Number(currency.replace(/[^\d\.\-]/g, ''));
  } else {
    return Number(currency.replace(/[^\d\.]/g, ''));
  }
}

$(function($){
  $('.flash').click(function(){
    $(this).slideUp();
  });

  $('.help').click(function() {
    $('.ui-dialog').remove();
    var content = $('#' + this.id + '_content');
    var position = [$(this).position().left - 300, $(this).position().top - $(window).scrollTop()];
    content.dialog({title: "Help: " + content.attr('name'), position: position, minHeight: 75, dialogClass: 'help-dialog', resizable: false});
  });

  $('input.currency_field').change(function() {
    $(this).val(numberToCurrency(stringToNumber($(this).val(), $(this).hasClass('allow_negative'))));
  });
});
