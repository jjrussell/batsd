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

$(document).ready(function() {
    $("#products a").click(function() {
        var title = $(this).attr('title');
        if (title) {
            // hide all product info
            $(".product_details").removeClass('show');
            // hide all screenshots
            $(".screenshot").removeClass('show');
            // show p info
            $("."+title).addClass('show');
            // show screenshot
            $("#products a").removeClass('selected');
            $("#products a."+title+"_link").addClass('selected');
        }
        return false;
    })
});