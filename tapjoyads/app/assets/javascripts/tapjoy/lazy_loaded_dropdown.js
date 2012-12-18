function dropdownify(offers, element) {
  for(var i in offers) {
    var offer = offers[i]
    var html =
    "<div id='" + offer.id + "' class='app' title='" + offer.name + "'>" +
      "<span class='app_name'>" + titleFor(offer) + "</span>" +
      "<img alt='" + offer.platform + "_flat' class='platform_icon' src='/images/" + offer.platform_icon_url + "'>" +
      "<input disabled='disabled' id='app_id' name='app_id' type='hidden' value='" + offer.name + "'>" +
      linkTo(offer) +
    "</div>";

    element.append(html);
  };
  return false;
}

function titleFor(offer) {
  return "<div class='offer_name'>" +
    "<div class='icon'>" +
      // "<img alt='' height='24' width='24' id='icon' src='" + offer.icon_url + "'>" +
    "</div>" +
    "<h1 class='name'>" + offer.name + "</h1>" +
    "<div class='descriptors'>" + offer.descriptors.join(', ') + "</div>" +
  "</div>";
}

function linkTo(offer) {
  return "<a href='" + urlFor(offer) + "' class='hidden'>#</a>";
}

function urlFor(offer) {
  return '/dashboard/reporting/' + offer.id
}

function isSelected(offer) {
  offer.id == ('#selected_app .app .offer_name').attr('id');  //TODO: Not this
}

function selected(offer) {
  if(isSelected(offer)) {
    return ' selected';
  } else
  {
    return '';
  }
}

function fetchDropdownOffers(element) {
  var selectedID = $('#selected_app .offer_name').attr('id');
  $('#selected_app img.platform_icon').after('<img id="app_dropdown_loading_icon" alt="loading" src="/images/load-circle.gif">');
  $.get('/dashboard/offers', { count: true }, function(response) {
    var count = parseInt(response);
    var partnerOfferPath = '/dashboard/offers';
    var pageSize = 100;
    var page = 0;

    checkFinishedLoading(count);

    for(null; (page*pageSize) <= count; page++) {
      $.ajax({
        url: partnerOfferPath,
        data: {page_size: pageSize, page: page, source: 'dropdown', selected: selectedID },
        success: function(response, status, xhr) {
          dropdownify(response.data, element);
        },
        tryCount: 0,
        retryLimit: 3,
        error: function(request, status, errorThrown){
          this.tryCount++;
          if(this.tryCount <= this.retryLimit) {
            $.ajax(this);
            return;
          }
        },
        dataType: 'json'
      });
    }
  });

  $('.app').each(function(){
    if($(this).attr('id') == selectedID) {
      $(this).addClass('selected');
    }
  });
};

function checkFinishedLoading(count) {
  setInterval(function () {
    if($('#apps_box .app').size() >= count-1) {
      $('#app_dropdown_loading_icon').remove();
      clearInterval();
    }
  }, 100);
}
