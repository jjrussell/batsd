$(document).ready(function(){
  var pager = $('#paging');

  $('#favorites').Carousel({
    hasPager: true,
    pagerContainer: '#paging'
  });

  $('#arrow').bind(Tapjoy.EventsMap.start, function(){

		// html tag for firefox, body for chrome/safari
    $('html, body').animate({
			scrollTop: $('#getting-started').offset().top +'px'
		}, 'slow');
  });

  $(window).resize(function(){
    if(pager.is(':visible')) {
      pager.css('left', (this.innerWidth - pager.outerWidth(true)) / 2)
    }
  });

  $(window).trigger('resize');
});
