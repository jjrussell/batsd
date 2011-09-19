/**
 * Quotes and testimonials
 */

$(document).ready(function() {
  $("#clients .client").click(function() {
    var title = $(this).attr('title');
    if (title) {
      $("#quote > div").removeClass('show');
      $(".client").removeClass('on');
      $("#"+title).addClass('show');
      $(this).addClass('on');
    }
    return false;
  })
});

/**
 * Developer product section
 */

$(document).ready(function() {
  $("#products a").click(function() {
    var title = $(this).attr('title');
    if (title) {
      $(".product_details").removeClass('show');
      $(".screenshot").removeClass('show');
      $("."+title).addClass('show');
      $("#products a").removeClass('selected');
      $("#products a."+title+"_link").addClass('selected');
    }
    return false;
  })
});

/**
 * Advertiser products slider
 */

$(document).ready(function() {
  $(".link_box a").click(function() {
    var title = $(this).attr('title');
    if (title) {
        // Highlight link
        $(".link_box").removeClass('selected');
        $(this).parent().addClass('selected');

        // Change screenshot & content
        $(".screenshot").hide();
        $(".details").hide();
        $("."+title).show();
        $("."+title+'_copy').show();
    }
    return false;
  })
});

/**
 * show / hide full bio in about section
 */

$(document).ready(function() {
  $(".showbio").click(function() {
    var biolarge = $(this).parent().parent().children(".biolarge");
    var biosmall = $(this).parent().parent().children(".biosmall");
    if (biolarge.is(':hidden')) {
      biolarge.show();
      biosmall.hide();
    } else {
      biolarge.hide();
      biosmall.show();
    }
    return false;
  })
})
