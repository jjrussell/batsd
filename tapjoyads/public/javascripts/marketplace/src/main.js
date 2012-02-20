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
  
  $('.device-toggle').bind('click', function(){
    if ($(this).hasClass('up')) {
      $(this).removeClass('up').addClass('down');
    }
    else {
      $(this).removeClass('down').addClass('up');
    }
  });
  
  $('.icon img').each(function(n,o){
    $(o).attr("src", $(o).attr("source")).load(function(){
      $(this).fadeIn('slow');
    });
    $(o).error(function(){
      $(o).attr("src", "data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==");
    });
  });

});
