$(document).ready(function(){
  var content = $('#content'),
      pager = $('#paging'),
      started = $('#getting-started'),
      gradient = $('.gradient-backdrop'),
      group = $('#benefits, #footer');
      
  $('#favorites').Carousel({
    hasPager: true,
    pagerContainer: '#paging'
  });
  
  
  $('#arrow').bind('click', function(){
    if(window.innerHeight < 1000 && window.innerWidth > 1024){
      $('#getting-started').css('position', 'relative');
      content.css('height', 'auto');
      $('.gradient-backdrop').css('height', '155px');
      $('#benefits, #footer').show();
    }
  });


  $(window).resize(function(){
    
    if(pager.is(':visible'))
      pager.css('left', (this.innerWidth - pager.outerWidth(true)) / 2)

    if(this.innerHeight < 1000 && this.innerWidth > 1024){
      content.css('height', this.innerHeight - ($('#header').outerHeight(true) + 3))
      gradient.css('height', this.innerHeight - 435);
      started.css('position', 'fixed');
      group.hide();
    }else{
      content.css('height', 'auto');
      group.show();
      gradient.css('height', '155px');
      started.css('position', 'relative');
    }
  });
  
  $(window).trigger('resize');
}); 