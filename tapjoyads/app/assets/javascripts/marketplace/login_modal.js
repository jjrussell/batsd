$('#login_modal .ui-close-btn').on('click', function(){
    $('#login_modal').hide();
    $('body').removeClass('modal-overlay-enabled');
    });

$('html.nologin').on('click', '.req-login', function(e){
    showLoginModal();
    e.preventDefault();
});
function showLoginModal(){
    var path = encodeURIComponent(location.href);
    var $overlay = $('#login_modal .overlay');
    var $floaty  = $('#login_modal .floaty');
    var $signup = $('#login_modal .action-signup');
    var $login = $('#login_modal .action-login');
    $('.menu-grid').trigger('menu-close');
    var signup_href=$signup.attr('href').replace(/\?.*/,'')+ '?path=' + path;
    var login_href=$login.attr('href').replace(/\?.*/,'')+ '?path=' + path;
    $signup.attr('href', signup_href);
    $login.attr('href', login_href);
    $overlay.height($(document).height());
    $floaty.css({top:$(window).scrollTop() + 'px'});
    $('body').addClass('modal-overlay-enabled');
    $('#login_modal').show();
}