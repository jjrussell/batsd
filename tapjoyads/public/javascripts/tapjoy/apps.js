// apps.js
var search = $.noop;
$(function($){

  // app state
  var toggleAppState = function() {
    if ($('select#app_state').val() == 'live') {
      $('#search_button').show();
      $('.app_data').show();
    } else {
      $('#search_button').hide();
      $('.app_data').hide();
    }
  };
  $('select#app_state').change(toggleAppState);
  toggleAppState();

  // app platform
  var toggleAppPlatform = function() {
    if ($('select#app_platform').val() == 'iphone') {
      $('#search_button').val('Search App Store');
      $('span#app_store_name').text('App Store.')
    } else {
      $('#search_button').val('Search Marketplace');
      $('span#app_store_name').text('Marketplace.')
    }
  };
  $('select#app_platform').change(toggleAppPlatform);

  // hide search results on just about everything
  $(document).click(function(e){
    if (!$(e.srcElement || e.originalTarget).hasClass('search') && !$('#search_results').hasClass('searching')) {
      $('#search_results').hide();
    }
  }).keydown(function(e){
    // 27 = escape
    if (e.which == 27 && !$('#search_results').hasClass('searching')) {
      $('#search_results').hide();
    }
  });

  // on success
  var success = function(data){
    $('#search_results').removeClass('searching');
    if (data['error']) {
      error();
    } else if (data.length > 0) {
      $(data).each(function(i,app){
        var result = $('<div/>').attr('id', 'app_' + app.item_id).
                                 addClass('search-result').
                                 append($('<img/>').attr('src', app.icon_url)).
                                 append(app.title).
                                 append(' (' + app.item_id + ')').
                                 click(populate);
        $.data(result[0], 'data', app);
        $('#search_results').append(result);
      });
    }
  };

  // on error
  var error = function(data){
    var result = $('<div/>').addClass('search-result').text("Error searching the app store. Please try again.");
    $('#search_results').removeClass('searching');
    $('#search_results').append(result);
  };

  // on item select
  var populate = function(){
    var app = $.data(this, 'data');
    $('input#app_name').val(app.title);
    $('input#app_store_id').val(app.item_id);
    $('input#app_store_id').change();
    $('#app_store_link').text(app.item_id);
    $('#app_store_link').attr('href', app.url);
    $('#app_price').text('$' + app.price);
    $('#app_icon').html($('<img/>').attr('src', app.icon_url));
    $('#app_description').html(app.description.replace(/\n/g, "<br>"));
    $('#search_results').hide();
  };

  // on search
  search = function(){
    $('.search-result').remove();
    $('#search_results').show().addClass('searching');

    // calculate correct position/offset
    var width = $('input#app_name').width() - 2;
    var offset = $('input#app_name').offset();
    offset.top += $('input#app_name').height() + 7;
    offset.left += 1;
    $('#search_results').css({ left: offset.left, top: offset.top, width: width });

    var term = $('input#app_name').val();
    if (term != "") {
      var platform = $('#app_platform').val() || $('#app_platform').text()
      $.ajax({
        url: '/apps/search/;',
        data: { term: term, platform: platform },
        dataType: 'json',
        success: success,
        error: error
      });
    }
  };
});
