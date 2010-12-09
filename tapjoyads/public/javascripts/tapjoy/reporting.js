var loadData = function(data) {
  $('div#charts canvas').each(function(){
    RGraph.Clear(this);
  });

  Tapjoy.Graph.drawLargeGraph(data.connect_data, 'connects');
  Tapjoy.Graph.drawLargeGraph(data.rewarded_installs_plus_spend_data, 'installs_spend');
  Tapjoy.Graph.drawLargeGraph(data.rewarded_installs_plus_rank_data, 'installs_rank');
  Tapjoy.Graph.drawLargeGraph(data.published_offers_data, 'published_offers');
  Tapjoy.Graph.drawLargeGraph(data.offerwall_views_data, 'offerwall_views');
  Tapjoy.Graph.drawLargeGraph(data.display_ads_data, 'display_ads');
  Tapjoy.Graph.drawLargeGraph(data.virtual_goods_data, 'virtual_goods');
  Tapjoy.Graph.drawLargeGraph(data.ads_data, 'ads');

  $('#date').val(data.date);
  $('#end_date').val(data.end_date);
  $('#granularity').val(data.granularity);
};

var updateURL = function(oldURL) {
  return oldURL.split(/#/)[0] +
    '#date=' + $('#date').val() +
    '&end_date=' + $('#end_date').val() +
    '&granularity=' + $('#granularity').val();
}

$(function($) {
  Tapjoy.Graph.initGraphs($('#charts .graph'));

  $('#date').datepicker();
  $('#end_date').datepicker();

  var ajaxCall = function(){
    if ($('#granularity').val()=='hourly') {
      var diff = new Date($('#end_date').val()) - new Date($('#date').val());
      if (diff > 518400000) { // 7 days
        $('#flash_warning span.message').text('Hourly reports are only available for date ranges of seven or fewer days.');
        $('#flash_warning').fadeIn();
      }
    }
    $('.load-circle').show();
    $('#date, #end_date, #granularity').attr('disabled', true);
    $('#tables, #charts').css('opacity', 0.3);
    var params = {
      date: $('#date').val(),
      end_date: $('#end_date').val(),
      granularity: $('#granularity').val()
    };

    $.ajax({
      url: location.pathname.replace(/statz/,'reporting'),
      data: params,
      success: function(response, status, request) {
        loadData(response.data);
        $('#tables').html(response.stats_table);
        $('#date, #end_date, #granularity').attr('disabled', false);
        $('#tables, #charts').css('opacity', 1.0);
        location.href = updateURL(location.href);
        $('#apps_box .app a').each(function() {
          $(this).attr('href', updateURL($(this).attr('href')));
        });
      },
      error: function() {
        alert('Could not generate reports. Check the date range and try again.');
        $('#date, #end_date, #granularity').attr('disabled', false);
      },
      complete: function() {
        $('.load-circle').hide();
      },
      dataType: 'json'
    })
  };
  $('#date, #end_date, #granularity').change(ajaxCall);
  // load appropriate data from anchor
  $.each(Tapjoy.anchorToParams(), function(key,val){
    $('#'+key).val(val);
  });
  ajaxCall();

});
