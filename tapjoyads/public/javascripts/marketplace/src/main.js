$(document).ready(function() {

  $('.menu-grid').bind('click', function(){
    if ($(this).hasClass('active')) {
      $(this).removeClass('active');
      $('.menu-dropdown').removeClass('open');
    }
    else {
      $(this).addClass('active');
      $('.menu-dropdown').addClass('open');
    }
  });

});
