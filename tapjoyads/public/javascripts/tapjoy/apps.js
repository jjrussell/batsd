// apps.js
var search = $.noop;
$(function(){

  // app state
  var toggleAppState = function() {
    if ($('select#app_state').val() == 'live') {
      $('.search').show();
      $('tr.app_store_url').show();
      $('tr.app_icon').show();
      $('tr.price').show();
      if ($('input#app_name').val()=='') {
        $('input#app_name').focus();
      }
    } else {
      $('.search').hide();
      $('tr.app_store_url').hide();
      $('tr.app_icon').hide();
      $('tr.price').hide();
    }
  };
  $('select#app_state').change(toggleAppState);
  if ($('input#app_store_id').val()) {
    $('select#app_state').val('live');
    toggleAppState();
  }

  // hide search results on just about everything
  $(document).click(function(e){
    if (e.srcElement && e.srcElement.className != 'search' && !$('#search_results').hasClass('searching')) {
      $('#search_results').hide();
    }
  }).keydown(function(e){
    // 27 = escape
    if (e.which == 27 && !$('#search_results').hasClass('searching')) {
      $('#search_results').hide();
    }
  });

  // calculate correct position/offset
  var width = $('input#app_name').width() - 2;
  var offset = $('input#app_name').offset();
  if (offset) {
    offset.top += $('input#app_name').height() + 3;
    $('#search_results').offset(offset).css('width', width + 'px');
  }

  // on success
  var success = function(data){
    $('#search_results').removeClass('searching');
    if (data.length > 0) {
      $(data).each(function(i,app){
        var result = $('<div/>').attr('id', 'app_' + app.item_id).
                                 addClass('search-result').
                                 append($('<img/>').attr('src', app.icon_url)).
                                 append(app.title).
                                 click(populate);
        $.data(result[0], 'data', app);
        $('#search_results').append(result);
      });
    }
  };

  // on error
  var error = function(data){
    var result = $('<div/>').addClass('search-result').text("Error: please try again.");
    $('#search_results').removeClass('searching');
    $('#search_results').append(result);
  };

  // on item select
  var populate = function(){
    var app = $.data(this, 'data');
    $('input#app_name').val(app.title);
    $('input#app_store_url').val(app.url);
    $('input#app_store_id').val(app.item_id);
    $('input#app_icon_url').val(app.icon_url);
    $('input#app_price').val(app.price);
    $('td#app_icon').html($('<img/>').attr('src', app.icon_url));
    $('#search_results').hide();
  };

  // on search
  search = function(){
    $('.search-result').remove();
    $('#search_results').show().addClass('searching');

    var term = $('input#app_name').val();
    if (term != "") {
      var platform = $('select#app_platform').val()
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
