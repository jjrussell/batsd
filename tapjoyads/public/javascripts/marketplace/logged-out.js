$(document).ready(function(){
  var content = $('#content'),
      pager = $('#paging'),
      gradient = $('.gradient-backdrop');

  $('#favorites').Carousel({
		forceSlideWidth: true,
    hasPager: true,
    pagerContainer: '#paging'
  });

  $('#arrow').bind('click', function(){
    $('body').animate({scrollTop: $('#getting-started').offset().top}, 200);
  });

  $(window).resize(function(){

    if(pager.is(':visible')) {
      pager.css('left', (this.innerWidth - pager.outerWidth(true)) / 2)
    }

    if(this.innerHeight < 1000 && this.innerWidth > 1024) {
      gradient.css('height', this.innerHeight - 435);
    } else {
      content.css('height', 'auto');
      gradient.css('height', '155px');
    }

  });

  $(window).trigger('resize');
});
