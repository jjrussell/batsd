$(document).ready(function() {

  // Login
  $('#login, #login-web').bind('click', function() {
    
    var modal = $('.login.modal');
    var mTop = (modal.height() + 24) / 2; 
    var mLeft = (modal.width() + 24) / 2; 
    
    modal.css({ 
      'margin-top' : -mTop,
      'margin-left' : -mLeft
    });

    $('.login.modal').fadeIn('fast');
    $('body').append('<div id="mask"></div>');
    $('#mask').fadeIn('fast').bind('click', function() {
      $('.login.modal').fadeOut('fast');
      $(this).fadeOut('fast');
    });

  });
  
  // Menu Grid
  $('.menu-grid').bind('click', function(){
    if ($(this).hasClass('active')) {
      $(this).removeClass('active');
      $('.menu-dropdown').removeClass('open').addClass('close');
    }
    else {
      $(this).addClass('active');
      $('.menu-dropdown').removeClass('close').addClass('open');
    }
  });
  
  // Menu - Device Toggle
  $('.device-toggle').bind('click', function(){
    if ($(this).hasClass('up')) {
      $(this).removeClass('up').addClass('down');
    }
    else {
      $(this).removeClass('down').addClass('up');
    }
  });
  
  // App Icons
  $('.icon img').each(function(n, o){
		var el = $(o);
		
    el.attr("src", el.attr("source")).load(function(){
      $(this).fadeIn('slow');
    });
    el.error(function(){
      el.attr("src", "data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==");
    });
  });

/*
	Tapjoy.Utils.notification({
		message: 'Thanks, your settings have been saved.'
	});

  Tapjoy.delay(function(){
	  Tapjoy.Utils.notification({
	    message: 'Thanks, we would like to save hello again.'
	  });
	}, 4000);
*/	
});
