$(document).ready(function() {
    $("#clients .client").click(function() {
        var title = $(this).attr('title');
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