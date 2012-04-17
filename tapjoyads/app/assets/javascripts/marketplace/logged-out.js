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
      return $('html, body').animate({
        scrollTop: $('#getting-started').offset().top +'px'
      }, 'slow');
    });
    $(window).resize(function() {
      if (pager.is(':visible')) {
        return pager.css('left', (this.innerWidth - pager.outerWidth(true)) / 2);
      }
    });
    return $(window).trigger('resize');
  });
})(jQuery);
