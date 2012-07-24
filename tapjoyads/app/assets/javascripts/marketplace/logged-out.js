(function($){
  $(document).ready(function(){
    var pager;
    pager = $('#paging');
    $('#favorites').Carousel({
      forceSlideWidth: true,
      hasPager: true,
      minHeight: 300,
      pagerContainer: '#paging'
    });
    $('#arrow').bind(Tapjoy.EventsMap.start, function() {
      $('html, body').animate({
        scrollTop: $('#getting-started').offset().top +'px'
      }, 'slow');
    });
    $(window).resize(function() {
      if (pager.is(':visible')) {
        pager.css('left', (this.innerWidth - pager.outerWidth(true)) / 2);
      }
    });
    $(window).trigger('resize');
  });
})(jQuery);
