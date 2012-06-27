(function(Tap, $){

  Tap.Components = {
    Elements: {
      activeCls: 'active',
      attr: {},
      borderRadius: 0,
      click: Tap.emptyFn,
      clickEvent: Tap.supportsTouch ? 'tap' : 'click',
      container: $(document),
      containerCSS : {},
      containerCls: '',
      css: {},
      cssCls: '',
      disabled: false,
      disabledCls: 'disabled',
      emptyText: '',
      height: 'auto',
      hidden: false,
      hoverCls: 'hover',
      iconCls: null,
      id: null,
      name: null,
      tap: Tap.emptyFn,
      text: '',
      theme: 'tapped',
      transition: 'fade',
      tooltip: null,
      width: null
    },
    Button: {
      enableToggle: false,
      handleMouseEvents: true,
      target: '',
      textAlign: 'left',
      toggle: Tap.emptyFn,
      touch: Tap.emptyFn,
      type: 'button'
    },
    Carousel: {
      animation: 'all .3s ease-in',
      enableSwipe: true,
      forceSlideWidth: false,
      hasPager: false,
      minHeight: 200,
      moveThreshold: null,
      pagerContainer: null
    },
    DatePicker: {
      title: 'Calendar',
      dateOutput: 'dddd, M d, yyyy', // can be any date format (dddd, M d, yyyy - mm-dd-yyyy - etc...). We save selections in MM-DD-YYYY format via hidden field as default. Format is for presentation.
      hiddenOutput: 'mm/dd/yyyy', // what we look for on the server-side
      months: {
        long: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
        short: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      },
      days: {
        long : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        short: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      },
      yearRange: 81,
      yearSlots: 16,
      tabs: ['Month', 'Day', 'Year'],
      templates: {
        datepicker: '<div class="ui-joy-datepicker-title"><h1>{0}</h1></div><div class="ui-joy-datepicker-tabs"></div><div class="ui-joy-datepicker-selections"><div class="ui-joy-datepicker-months collection"></div><div class="ui-joy-datepicker-days hidden collection"></div><div class="ui-joy-datepicker-years hidden collection"></div></div><div class="ui-joy-datepicker-submit"><button class="disabled">Complete</button></div>',
        tab: '<div class="ui-joy-datepicker-tab"><a href="javascript:void(0);">{0}</a></div>',
        month: '<div class="ui-joy-datepicker-month mon{0}" data-month="{0}"><a href="javascript:void(0);">{1}</a></div>',
        day: '<div class="ui-joy-datepicker-day day{0}" data-day="{0}"><a href="javascript:void(0);">{0}</a></div>',
        year: '<div class="ui-joy-datepicker-year y{0} {2}" data-year="{1}"><a href="javascript:void(0);">{1}</a></div>'
      }      
    }
  };

  // shared methods
  $.fn.extend({
    disableComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          disabled: true
        });
      });
    },

    enableComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          disabled: false
        });
      });
    },

    hideComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          hidden: true
        });
      });
    },

    showComponent : function(){
      return this.each(function(){
        $(this).setProperty({
          hidden: false
        });
      });
    },

    setValue : function(val){
      return this.each(function(){
        $(this).setProperty({
          value: val
        });
      });
    },

    getValue : function(val){
      for(var i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Tap.xtypes[i].toLowerCase());

        if(instance){
          return instance.config.value || '';
          break;
        }
      }
    },

    isHidden : function(){
      for(var i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Tap.xtypes[i].toLowerCase());

        if(instance){
          return instance.config.hidden || false;
          break;
        }
      }
    },

    isDisabled : function(){
      for(var i = Tap.xtypes.length; i--;){
        var instance = $.data(this[0], Tap.xtypes[i].toLowerCase());

        if(instance){
          return instance.config.disabled || false;
          break;
        }
      }
    },

    removeComponent : function(){
      return this.each(function(){

        for(var i = Tap.xtypes.length; i--;){
          var instance = $.data(this, Tap.xtypes[i].toLowerCase());

          if(instance){
            $(this)['remove'+Tap.xtypes[i]]();
            break;
          }
        }
      });
    },

    setProperty : function(obj){
      var el = this;

      for(var i = 0, k = Tap.xtypes.length; i < k; i++){
        var instance = $.data(el[0], Tap.xtypes[i].toLowerCase());

        if(instance){
          $(this)['set'+Tap.xtypes[i]+'Property'](obj);
          break;
        }
      }
    },

    Tapified: function(type){
      return $.data(this[0], type) ? true : false;
    }
  });
})(Tapjoy, jQuery);
