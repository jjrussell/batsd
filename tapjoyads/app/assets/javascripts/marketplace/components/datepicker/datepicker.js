(function(Tap, $){

  $.fn.DatePicker = function(config){
    config = $.extend({}, Tap.Components.DatePicker, config || {});
    return this.each(function(){

      var $t = $(this);

      if($t.Tapified('datepicker'))
        return;

      new DatePicker($t.get(0), config);
    });
  };

  function sanitizeLocaleData(array) {
    var i, ii, res = [];

    for (i = 0, ii = array.length; i < ii; i++) {
      if (typeof array[i] === 'string') {
        res.push(array[i]);
      }
    }

    return res;
  }

  var DatePicker = function(container, config){

    var $t = this;

    $t.config = config;

    $t.container = $t.config.container = $(container);
    
    $t.container.bind('focus', function(){

      if(!$t.mask){
        $t.create();
      }else{
        
        $('.ui-joy-datepicker-mask').hide();

        $t.mask.show();
        $t.wrap.removeClass('pop out').addClass('pop in');
      }
    });

    $.data(container, 'datepicker', $t);
  };

  $.extend(DatePicker.prototype, {
    index: 0,
    position: 0,
    create : function(){
      var $t = this,
          mask = $(document.createElement('div')),
          wrap = $(document.createElement('div')),
          close = $(document.createElement('div')),
          hidden = $(document.createElement('input'));

      $t.config.months.long = sanitizeLocaleData($t.config.months.long);
      $t.config.months.short = sanitizeLocaleData($t.config.months.short);

      mask.addClass('ui-joy-datepicker-mask');

      wrap.addClass('ui-joy-datepicker')
      .html(Tap.String.format($t.config.templates.datepicker, $t.config.title))
      .appendTo(mask);

      hidden.attr({
        type: 'text',
        hidden: true,
        name: $t.config.name || $t.container.attr('name') || 'datepicker_' + Math.floor((Math.random()*10000)+1) 
      })
      .addClass('ui-joy-datepicker-hidden')
      .appendTo($t.container);

      close.addClass('ui-joy-datepicker-close')
      .html('<a href="javascript:void(0);">x</a>')
      .appendTo(wrap);

      $('body:eq(0)').append(mask);

      wrap.addClass('pop in');

      $t.tabsContainer = $('.ui-joy-datepicker-tabs', wrap);
      $t.monthsContainer = $('.ui-joy-datepicker-months', wrap);
      $t.daysContainer = $('.ui-joy-datepicker-days', wrap);
      $t.yearsContainer = $('.ui-joy-datepicker-years', wrap);
      $t.submit = $('button', wrap);
      $t.cancel = $(close, wrap);
      $t.hidden = hidden;
      $t.wrap = $(wrap, mask);
      $t.contents = $('.collection', wrap);
      $t.mask = mask;

      $t.submit.bind('click', function(){
        var btn = $(this);

        if(btn.hasClass('disabled'))
          return;

        $t.close();
      });

      $t.cancel.bind('click', function(){
        $t.close();
      });

      $t.mask.bind('mousedown', function(e){
        var target = $(e.target);
        if(!target.is('.ui-joy-datepicker') && !target.parents().is('.ui-joy-datepicker'))
          $t.close();
      });

      $t.tabs();
      $t.months();
      $t.days();
      $t.years();
    },

    close: function(){
      var $t = this;

      $t.container.attr('value', $t.format(new Date($t.year, $t.month, $t.day)));
      $t.wrap.addClass('pop in').addClass('pop out');

      setTimeout(function(){
        $t.mask.hide();
      }, 200);
    },

    days: function(){
      var $t = this,
          total = $t.total($t.year || 2012, $t.month || 0),
          days = [];

      for(var i = 0, k = total; i < k; i++){
        days.push(Tap.String.format($t.config.templates.day, i < 9 ? '0' + (i+1) : i+1));
      }

      $t.daysContainer.empty().append(days.join(''));

      $('.ui-joy-datepicker-day', $t.daysContainer).bind(Tap.EventsMap.start, function(e){
        $t.set(this);
      });

      return days.join('');
    },

    format: function(date, format){
      var $t = this;

      if(date instanceof Date && String(date) !== 'Invalid Date') {
        var yyyy = date.getFullYear(),
            yy = yyyy.toString().substring(2),
            m = date.getMonth(),
            mm = (m < 9 ? '0' : '') + (m + 1),
            mmm = $t.config.months.short[m],
            M = $t.config.months.long[m],
            d = date.getDate(),
            d_ = date.getDay(),
            dd = d < 10 ? '0' + d : d,
            ddd = $t.config.days.short[d_],
            dddd = $t.config.days.long[d_],
            h = date.getHours(),
            hh = h < 10 ? '0' + h : h,
            n = date.getMinutes(),
            nn = n < 10 ? '0' + n : n,
            s = date.getSeconds(),
            ss = s < 10 ? '0' + s : s,
            map,
            regex,
            fragment,
            keys = [];

        map = {
          'yyyy': yyyy,
          'yy': yy,
          'mmm': mmm,
          'mm': mm,
          'm': m,
          'M': M,
          'dddd': dddd,
          'ddd': ddd,
          'dd': dd,
          'd': d,
          'hh': hh,
          'h': h,
          'nn': nn,
          'ss': ss,
          's': s
        };
      
      for(fragment in map){
        keys.push(fragment);
      }
      
      regex = new RegExp('(' + keys.join('|') + ')', 'g');
      
        return (format || $t.config.dateOutput).replace(regex, function(pattern, value) {
          return map[value] || '';
        });
      }else{
        return '';
      }
    },

    months: function(){
      var $t = this,
          months = [];
      
      for(var i = 0, k = $t.config.months.long.length; i < k; i++){
        months.push(Tap.String.format($t.config.templates.month, i, $t.config.months.long[i]));
      }

      $t.monthsContainer.append(months.join(''));

      $('.ui-joy-datepicker-month', $t.monthsContainer).bind(Tap.EventsMap.start, function(e){
        $t.set(this);
      });
    },
    
    next: function(){
      var $t = this,
          index = $t.index + 1;
      
      $t.tabs_.removeClass('active');
      $t.tabs_.eq(index).addClass('active');

      $t.contents.addClass('hidden');
      $t.contents.eq(index).removeClass('hidden').addClass('active');
    },

    set: function(element){
      var $t = this,
          el = $(element),
          anchor = $('a', el),
          text = anchor.text(),
          type = el.attr('class').split(' ')[0].split('-')[3],
          data = el.attr('data-'+type);

      $('.ui-joy-datepicker-' + type, $t.wrap).removeClass('active');

      el.addClass('active');

      if(anchor.html() !== '&nbsp;'){
        $t[type] = data; 
      }

      if(type === 'month'){
        $t.days();
        $t.day = undefined;
        $t.index = 0;
        $t.tabs_.eq(1).find('a').text($t.config.tabs[1]);
      }else if(type === 'day'){
        $t.index = 1;
      }else{
        $t.index = 2;
      }

      if(anchor.html() !== '&nbsp;'){
        $t.tabs_.eq($t.index).find('a').text(text);
      }

      if(type !== 'year'){
        setTimeout(function(){
          $t.next();
        }, 350);
      }

      $t.update();
    },

    tabs: function(){
      var $t = this,
          tabs = [];
      for(var i = 0, k = $t.config.tabs.length; i < k; i++){
        tabs.push(Tap.String.format($t.config.templates.tab, $t.config.tabs[i]));
      }

      $t.tabsContainer.append(tabs.join(''));

      $t.tabs_ = $('.ui-joy-datepicker-tab', $t.tabsContainer);

      $t.tabs_.bind(Tap.EventsMap.start, function(){
        var tab = $(this),
            index = tab.index();

        $t.tabs_.removeClass('active');
        tab.addClass('active');

        $t.contents.addClass('hidden');
        $t.contents.eq(index).removeClass('hidden').addClass('active');
      });

      $t.tabs_.eq(0).addClass('active');
    },
    
    total: function(year, month){
      return 32 - new Date(year, month, 32).getDate();
    },

    update: function(){
      var $t = this;
      $t.hidden.attr('value', $t.format(new Date($t.year, parseInt($t.month, 0), $t.day), $t.config.hiddenOutput)); 

      if($t.month !== undefined && $t.day !== undefined && $t.year !== undefined && $t.year !== '&nbsp;'){
        $t.submit.removeClass('disabled');
      }else{
        $t.submit.addClass('disabled');
      }
    },

    years: function(direction){
      var $t = this,
          years = [],
          yearsGroup = [],
          yearsRange = [],
          currYear = $t.config.yearStart || new Date().getFullYear(),
          endYear = currYear - ($t.config.yearRange || 81),
          slots = $t.config.yearSlots || 16;

      for (var year = currYear; year >= endYear; year--){
        yearsRange.push(year);
      }
      var pages = Math.ceil(yearsRange.length/slots);
      for (var i = 0; i < pages; i++) {
        var o = [];
        if (i == 0) {
            o = yearsRange.splice(0, slots - 1);
            o.push('->');
        }
        else {
            o = yearsRange.splice(0, slots - 2);
            o.unshift('<-');
            if (i != (pages - 1)) {
              o.push('->');
            }
        }
        yearsGroup.push(o);
      }
      for(var i = 0, k = yearsGroup[$t.position].length; i < k; i++){
        var cls = '',
            year = yearsGroup[$t.position][i];

        if(year === '->'){
          cls = 'ui-joy-datepicker-right-arrow';
          year = '&nbsp;';
        }

        if(year === '<-'){
          cls = 'ui-joy-datepicker-left-arrow';
          year = '&nbsp;';
        }
      
        years.push(Tap.String.format($t.config.templates.year, i, year, cls));
      }

      $t.yearsContainer.empty().html(years.join(''));

      $('.ui-joy-datepicker-year', $t.yearsContainer).bind(Tap.EventsMap.start, function(e){
        $t.set(this);
      });

      $('.ui-joy-datepicker-right-arrow', $t.yearsContainer).bind('click', function(){
        $t.position++;
        $t.years();
        $('a:contains("' + $t.year + '")', $t.yearsContainer).parent().addClass('active');
      });

      $('.ui-joy-datepicker-left-arrow', $t.yearsContainer).bind('click', function(){
        $t.position > 0 ? $t.position-- : 0;
        $t.years();
        $('a:contains("' + $t.year + '")', $t.yearsContainer).parent().addClass('active');
      });
    }    
  });

  Tap.apply(Tap, {
    DatePicker : function(config){

      var $t = $(config.container),
          config = Tap.extend(this, Tap.Components.DatePicker, config || {});

      return $t.DatePicker(config);
    }
  });
}(Tapjoy, jQuery));
