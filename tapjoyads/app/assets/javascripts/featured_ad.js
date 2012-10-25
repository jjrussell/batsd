var ad = document.getElementById('featured');
var creative = document.getElementById('creative');
var thumb = document.getElementById('thumb');
var ppi = document.getElementById('app');

var video_offer = false;
if (document.getElementsByClassName('btn')[0] == null){
  video_offer = true;
};


vertical_layout = function(){
  // Calculate creative proportion factor:
  // Mobile, scaling 300x250 image
  var proportion;
  if(height < 566 && width < 639) {
    proportion = 5/6;
  } else {
  // Tablet
  // Portrait, scaling 748x720 image
    if(width < height){
      proportion = 180/187;
    } else {
    //Landscape, scaling 1000x490
      proportion = 49/100;
    };
  };

  // Calculate creative size: scale by vertical dimension
  if (video_offer) {
    var creative_height = height-146;
  } else {
    var creative_height = height-196;
  };
  var creative_width = creative_height/proportion;
  // scale by horizontal dimension if necessary
  if(creative_width > width-30) {
    creative_width = width-30;
    creative_height = creative_width*proportion;
  };

  // resize video thumbnail if applicable
  if (video_offer) {
    if (creative_width > 300) {
      thumb.style.width = 300;
    } else {
      thumb.style.width = creative_width;
    };
  };

  // center video link & thumbnail
  if (video_offer) {
    thumb.style.marginTop = mt;
    var mt = (creative_height-thumb.height)/2;
    thumb.style.marginTop = mt;
    var video_button = document.getElementById('play');
    mt = (creative_height-80)/2;
    video_button.style.marginTop = mt;
  };

  // center app icon if appropriate
  if (ppi) {
    ppi.style.marginTop = (creative_height/2)-50;
  };

  // Assign ad dimensions

  if (video_offer) {
    ad.style.height = creative_height+116;
  } else {
    ad.style.height = creative_height+166;
  };
  ad.style.width = creative_width;

  // Truncate instructions for mobile
  var title_text = title.innerHTML;
  var title_length = title.textContent.length;
  // portrait
  if(width < 358){
    if(title_length > 40){
      title_text = title_text.substring(0,38)+"..."
    };
  };
  //landscape
  if(358 <= width < 639) {
    if(title_length > 60){
      title_text = title_text.substring(0,58)+"..."
    };
  };
  // replace with shortened instructions if necessary
  title.innerHtml = title_text;

  //Assign creative dimensions
  creative.style.height = creative_height;
  creative.style.width = creative_width;

  // reset title height for resizing back without refresh
  title.style.height = "";
};

horizontal_layout = function(){
  var proportion = 5/6
  // Calculate creative size
  // scale by vertical dimension
  var creative_height = height-60;
  var creative_width = creative_height/proportion;
  // scale by horizontal dimension if necessary
  if(creative_width > width-170){
    creative_width = width-170;
    creative_height = creative_width*proportion;
  };

  //Assign creative dimensions
  creative.style.height = creative_height;
  creative.style.width = creative_width;

  // Assign ad dimensions
  ad.style.height = creative_height+50;
  ad.style.width = creative_width+180;

  // center video link & thumbnail
  if (video_offer) {
    var mt = (creative_height-thumb.height)/2;
    thumb.style.marginTop = mt;
    var video_button = document.getElementById('play');
    mt = (creative_height-80)/2;
    video_button.style.marginTop = mt;
  };

  // center app icon if appropriate
  if (ppi) {
    ppi.style.marginTop = (creative_height/2)-50;
  };

  // Make sure the logo and donload button (if applicable) is at the bottom
  if (video_offer){
    title.style.height = creative_height-48;
  } else {
    title.style.height = creative_height-98;
  };
};

resize_ad = function(){
  rearrange();
  height = window.innerHeight;
  width = window.innerWidth;
  title = document.getElementById('title');

  if(height>350) {
    vertical_layout();
  } else {
    horizontal_layout();
  };

  // set margins
  ad.style.margin = 'auto';
};

document.addEventListener('DOMContentLoaded', function(){
  setTimeout(function(){
    resize_ad();
  }, 400);
  setTimeout(function(){
    ad.style.opacity = 1;
  }, 550);
});

window.onresize = window.onorientationchange = resize_ad;
