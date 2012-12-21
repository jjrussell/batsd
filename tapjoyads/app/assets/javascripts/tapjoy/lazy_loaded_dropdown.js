function populateDropdownOffers(element) {
  insertLoadingIcon();
  $.get('/dashboard/offers', { count: true }, function(response) {
    var count = parseInt(response);
    var pageSize = 100;
    var page = 0;

    monitorFinishedLoading(count);

    for(null; (page*pageSize) <= count; page++) {
      $.ajax({
        url: partnerOfferPath(),
        data: {page_size: pageSize, page: page, source: 'dropdown', selected: selectedID() },
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
};

function dropdownify(offers, element) {
  for(var i in offers) {
    var offer = offers[i]
    var html =
    '<div id="' + offer.id + '" class="app" title="' + safeOfferName(offer) + '">' +
      "<span class='app_name'>" + titleFor(offer) + "</span>" +
      "<img alt='" + offer.platform + "_flat' class='platform_icon' src='/images/" + offer.platform_icon_url + "'>" +
      "<input disabled='disabled' id='app_id' name='app_id' type='hidden' value='" + safeOfferName(offer) + "'>" +
      linkTo(offer) +
    "</div>";

    element.append(html);
    addLinkBehaviorTo($('#' + offer.id + '.app').not('selected'));
  };
  return false;
}

function titleFor(offer) {
  return "<div class='offer_name'>" +
    "<div class='icon'>" +
      "<img alt='' height='24' width='24' id='icon' src='" + offer.icon_url + "'>" +
    "</div>" +
    "<h1 class='name'>" + offer.name + "</h1>" +
    "<div class='descriptors'>" + offer.descriptors.join(', ') + "</div>" +
  "</div>";
}

function safeOfferName(offer) {
  return offer.name.replace("\'", "\\'");
}

function linkTo(offer) {
  return "<a href='" + urlFor(offer) + "' class='hidden'>#</a>";
}

function urlFor(offer) {
  return '/dashboard/reporting/' + offer.id
}

function isSelected(offer) {
  offer.id == ('#selected_app .app .offer_name').attr('id');
}

function selected(offer) {
  return (isSelected(offer) ? ' selected' : '');
}

function selectedID() {
  return $('#selected_app .offer_name').attr('id');
}

function partnerOfferPath() {
  return '/dashboard/offers';
}

function monitorFinishedLoading(count) {
  var k = setInterval(function () {
    if($('#apps_box .app').size() >= count-1) {
      removeLoadingIcon();
      clearInterval(k);
    }
  }, 100);
}

function insertLoadingIcon() {
  $('#selected_app img.platform_icon').after('<img id="app_dropdown_loading_icon" alt="loading" src="/images/load-circle.gif">');
  return false;
}

function removeLoadingIcon() {
  $('#app_dropdown_loading_icon').remove();
}

function markSelected(element, selectedID) {
  $('.app').each(function() {
    if($(this).attr('id') == selectedID) {
      $(this).addClass('selected');
    }
  });
}

function addLinkBehaviorTo(element) {
  element.click(function(e) {
    $('.app.selected').removeClass('selected');
    $(this).addClass('selected');
    $('#selected_app_text').html($(this).html());
    location.href = $(this).children('a').attr('href');
  });
}
