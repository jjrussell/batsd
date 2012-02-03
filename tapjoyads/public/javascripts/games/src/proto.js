$(document).ready(function() {
  $(".item").hover(function() {
    $(this).addClass("selected");
  }, function() {
    $(this).removeClass("selected");  
  });
});
