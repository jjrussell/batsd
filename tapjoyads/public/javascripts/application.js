if (typeof(Tapjoy) == "undefined") Tapjoy = {};
if (typeof(console) == "undefined") console={log:$.noop};

function addCommaSeparators(number) {
  return String(number).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
}

function numberToCurrency(number) {
  return '$' + addCommaSeparators(Number(number).toFixed(2));
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
    if ($(this).children('a, span a').length == 0) {
      $(this).slideUp();
    }
  });

  $('.help').click(function() {
    $('.ui-dialog').remove();
    var content = $('#' + this.id + '_content');
    var position = [$(this).position().left - 300, $(this).position().top - $(window).scrollTop()];
    content.dialog({title: "Help: " + content.attr('name'), position: position, minHeight: 75, dialogClass: 'help-dialog', resizable: false});
  });

  $('input.currency_field').change(function() {
    if (!$(this).hasClass('allow_nil') || $(this).val().length > 0) {
      $(this).val(numberToCurrency(stringToNumber($(this).val(), $(this).hasClass('allow_negative'))));
    }
  });

  $(document).click(function(e){
    if (!$(e.target).is('#active_campaigns') &&
      !$(e.target).parents().is('#active_campaigns_box')) {
      $('#active_campaigns_box').hide();
    }
  });

  $('a#active_campaigns').click(function() {
    var link = $(this);
    var box = $('#active_campaigns_box');
    if (box.is(':hidden')) {
      var top = link.attr('offsetTop') + link.height();
      var left = link.attr('offsetLeft');
      box.css({left: left, top: top});
      box.show();
    } else {
      box.hide();
    }
  });

  $('input.toggle_offer').change(function() {
    var checkbox = $(this);
    var form = checkbox.parent();
    var url = form.attr('action');
    form.attr('action', '');
    var loadingImage = $("<img src='/images/load-circle.gif'>");

    $.ajax({
      data: { action : "toggle", user_enabled: false },
      dataType: 'json',
      beforeSend: function() {
        checkbox.attr('disabled', 'disabled');
        checkbox.hide();
        checkbox.after(loadingImage);
      },
      complete: function(result) {
        if (result.error) {
          $('#flash_warning').text('Error - please try again');
          $('#flash_warning').fadeIn();
          checkbox.attr('disabled', '');
          checkbox.attr('checked', true);
          checkbox.show();
          loadingImage.remove();
        } else {
          checkbox.parents('tr').remove();
          var numOffers = $('input.toggle_offer').length;
          $('#number_of_active_offers').text(numOffers);
          if (numOffers == 0) {
            $('#active_campaigns_box').remove();
            $('#active_campaigns').addClass('inactive');
          }
        }
      },
      type: 'post',
      url: url
    });
  });
});

Tapjoy.anchorToParams = function(){
  var params = {};
  var anchor = location.href.split(/#/)[1];
  if (anchor) {
    $(anchor.split(/&/)).each(function(i, pair){
      pair = pair.split(/=/);
      params[pair[0]] = pair[1];
    });
  }
  return params;
};
