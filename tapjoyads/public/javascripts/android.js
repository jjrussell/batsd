$(document).ready(function() {
  $(".icon").click(function() {
    iconId = $(this).attr('id');
    $(".screenshot").removeClass('show');
    $("."+iconId).addClass('show');
    $(".icon").removeClass('selected');
    $(this).addClass('selected');
  })
})