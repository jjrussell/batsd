var loadData = function(data) {
  Tapjoy.Graph.drawLargeGraph(data.connect_data, 'connects');
  Tapjoy.Graph.drawLargeGraph(data.rewarded_installs_plus_spend_data, 'installs_spend');
  Tapjoy.Graph.drawLargeGraph(data.rewarded_installs_plus_rank_data, 'installs_rank');
  Tapjoy.Graph.drawLargeGraph(data.revenue_data, 'revenue');
  Tapjoy.Graph.drawLargeGraph(data.offerwall_data, 'offerwall');
  Tapjoy.Graph.drawLargeGraph(data.tjm_offerwall_data, 'tjm_offerwall');
  Tapjoy.Graph.drawLargeGraph(data.featured_offers_data, 'featured_offers');
  Tapjoy.Graph.drawLargeGraph(data.display_ads_data, 'display_ads');
  Tapjoy.Graph.drawLargeGraph(data.virtual_goods_data, 'virtual_goods');
  Tapjoy.Graph.drawLargeGraph(data.ads_data, 'ads');

  $('#date').val(data.date);
  $('#end_date').val(data.end_date);
  $('#granularity').val(data.granularity);
  $('#platform').val(data.platform);
  $('#download_date').val(data.date);
  $('#download_end_date').val(data.end_date);
  $('#download_granularity').val(data.granularity);
  $('#download_platform').val(data.platform);
};

var rangeIsLast24Hours = function() {
  var endDate = new Date($('#end_date').val());
  var startDate = new Date($('#date').val());
  var today = new Date();
  var diff = endDate - startDate;
  var granularity = $('#granularity').val();
  return (granularity == 'hourly' && diff == 86400000 && endDate.toDateString() == today.toDateString());
};

var updateURL = function(oldURL) {
  if (window.history && window.history.replaceState) {
    var split = oldURL.split('#')[0].split('?');
    var url = split[0];

    var hash = {};
    if (split[1]) {
      var params = split[1].split('&');
      for (var i in params) {
        var pair = params[i].split('=');
        hash[pair[0]] = pair[1];
      }
    }

    // overwrite
    if (rangeIsLast24Hours()) {
      delete hash.date;
      delete hash.end_date;
      delete hash.granularity;
      delete hash.platform;
    } else {
      hash.date = $('#date').val();
      hash.end_date = $('#end_date').val();
      hash.granularity = $('#granularity').val();
      if ($('#platform').val()) {
        hash.platform = $('#platform').val();
      }
    }

    // recreate query string
    var arr = [];
    for (var key in hash) {
      arr.push(key + '=' + hash[key]);
    }
    if (arr.length == 0) {
      return url;
    } else {
      return url + '?' + arr.join('&');
    }
  }

  var kids = $('#change_date').children();
  var j = 0;
  var params_arr = [];
  for (j = 0; j < kids.length; j++) {
    if (kids[j].id != 'date_submit') {
      params_arr.push(kids[j].id + "=" + kids[j].value);
    }
  }
  return oldURL.split(/#/)[0] + "#" + params_arr.join('&');
};

$(function($) {
  try {
    Tapjoy.Graph.initGraphs($('#charts .graph'));
  } catch(e) {
  }

  $('#date').datepicker();
  $('#end_date').datepicker();

  var ajaxCall = function(){
    $('#flash_warning span.message').text('');
    $('#flash_warning').fadeOut();
    if ($('#granularity').val()=='hourly') {
      var diff = new Date($('#end_date').val()) - new Date($('#date').val());
      if (diff > 518400000) { // 7 days
        $('#flash_warning span.message').text('Hourly reports are only available for date ranges of seven or fewer days.');
        $('#flash_warning').fadeIn();
      }
    }
    $('.load-circle').show();
    $('#change_date').children().attr('disabled', true);
    $('#tables, #charts').css('opacity', 0.3);
    var params = {
      date: $('#date').val(),
      end_date: $('#end_date').val(),
      granularity: $('#granularity').val(),
      platform: $('#platform').val()
    };

    if (rangeIsLast24Hours()) {
      params.date = '';
    }

    $.ajax({
      url: location.pathname,
      data: params,
      success: function(response, status, request) {
        loadData(response.data);
        $('#change_date').children().attr('disabled', false);
        $('#tables, #charts').css('opacity', 1.0);
        if (window.history && window.history.replaceState) {
          window.history.replaceState({},'', updateURL(location.href));
        } else {
          location.href = updateURL(location.href);
        }
        $('#apps_box .app a').each(function() {
          $(this).attr('href', updateURL($(this).attr('href')));
        });
      },
      error: function() {
        alert('Could not generate reports. Check the date range and try again.');
        $('#change_date').children().attr('disabled', false);
      },
      complete: function() {
        $('.load-circle').hide();
      },
      dataType: 'json'
    });
  };
  $('#date_submit').click(function(event) {
      event.preventDefault();
      ajaxCall();
  });

  $('#export_submit').click(function(event) {
    event.preventDefault();
  });

  // load appropriate data from anchor
  $.each(Tapjoy.anchorToParams(), function(key,val){
    $('#'+key).val(val);
  });
  ajaxCall();

});

