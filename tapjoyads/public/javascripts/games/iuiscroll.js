/*
   Copyright (c) 2007-9, iUI Project Members
   See LICENSE.txt for licensing terms
   ************
   LAST UDPATE: 31th Jan 2011 - remi.grumeau@gmail.com
   ************
*/

iui.iScroll = {

	myScroll : '',

	setHeight : function(pageId) 
	{
		if(typeof pageId!='string')
		{
			var pageId = iui.getSelectedPage();
			pageId = pageId.id;
		}
	
		if(document.getElementById(pageId+'_scroller'))
		{
			var toolbarHeight = document.getElementsByClassName('toolbar')[0].clientHeight;
			var footerHeight = (document.getElementById(pageId+'_footer'))?document.getElementById(pageId+'_footer').clientHeight:0;
			var wrapperH = window.innerHeight - (toolbarHeight+footerHeight);
			document.getElementById(pageId+'_scroller').parentNode.style.height = wrapperH + 'px';
			document.getElementById(pageId+'_scroller').parentNode.style['min-height'] = wrapperH + 'px';
		}
	},

	activeScroller : function(force) 
	{
		var screens = document.getElementsByClassName('iuiscroll');
		for (var i = 0; i <= (screens.length-1); i++) 
		{
			if ((screens[i].id != '') && (screens[i].title != '') && (typeof screens[i] === 'object')) 
			{
				if(document.getElementById(screens[i].id+'_scroller'))
				{
					if(force) {
						iui.iScroll.setHeight(screens[i].id);
						iui.iScroll.myScroll = new iScroll(screens[i].id+'_scroller', {desktopCompatibility:true});
						
					};

					screens[i].addEventListener('aftertransition', function() 
					{
						iui.iScroll.setHeight(this.id);
						if(iui.iScroll.myScroll) iui.iScroll.myScroll.destroy();
						iui.iScroll.myScroll = new iScroll(this.id+'_scroller', {desktopCompatibility:true});
					}, false);
				}
			}
		}
	}
}


addEventListener("load", function(event) {
	iui.iScroll.activeScroller(true);
	document.body.addEventListener('afterinsert', iui.iScroll.activeScroller, false);
}, false);

window.addEventListener('touchmove', function (e) { e.preventDefault();  }, false);
window.addEventListener('onorientationchange' in window ? 'orientationchange' : 'resize', iui.iScroll.setHeight, false);