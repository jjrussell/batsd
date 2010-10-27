if (typeof(Tapjoy) == "undefined") Tapjoy = {};

Tapjoy.Graph = {

  initGraphs: function(graphs) {
    graphs.each(function(){
      var id = $(this).attr('id');
      var holder = $('<div class="holder">').
        append( $('<canvas id="' + id + '_graph" width="800px" height="440px">') ).
        append( $('<div class="bar">') ).
        append( $('<div class="tooltip">') );
      $(this).
        append( $('<h3>') ).
        append( $('<div class="totals">') ).
        append( holder );
    });
  },

  setGraphProperties: function(g, options) {
    g.Set('chart.shadow', false);
    g.Set('chart.tickmarks', 'circle');

    g.Set('chart.hmargin', options.hMarginPx);
    g.Set('chart.gutter', options.gutterPx);

    if (options.yAxisPos) {
      g.Set('chart.yaxispos', options.yAxisPos);
    }

    if (options.colors) {
      g.Set('chart.colors', options.colors);
    }

    if (options.unitPrefix) {
      g.Set('chart.units.pre', options.unitPrefix)
    }

    if (options.yMax) {
      g.Set('chart.ymax', options.yMax)
    }

    if (options.decimals) {
      g.Set('chart.scale.decimals', options.decimals)
    }
  },

  drawLargeGraph: function(obj, id) {
    $('#' + id + '>h3').html(obj['name']);
    if ($('#' + id + '>.totals').length == 1) {
      $('#' + id + '>.totals').html(Tapjoy.Graph.getTotalsHtml(obj));
    }

    var gutterPx = 60;
    var hMarginPx = 5;
    var numPoints = obj['intervals'].length - 1;

    var legendKeys = obj['main']['names'];
    if (obj['right']) {
      legendKeys = legendKeys.concat(obj['right']['names']);
    }

    var g = new RGraph.Line(id + '_graph');
    g.original_data = obj['main']['data'];

    g.Set('chart.key', legendKeys);
    g.Set('chart.key.background', 'rgba(255,255,255,0.5)');
    g.Set('chart.key.position', 'gutter');

    g.Set('chart.labels', obj['xLabels']);
    g.Set('chart.text.angle', 90);

    Tapjoy.Graph.setGraphProperties(g, {
      hMarginPx: hMarginPx,
      gutterPx: gutterPx,
      unitPrefix: obj['main']['unitPrefix'],
      yMax: obj['main']['yMax'],
      decimals: obj['main']['decimals']
    });
    g.Draw();

    if (obj['right']) {
      var g2 = new RGraph.Line(id + '_graph');
      g2.original_data = obj['right']['data'];

      Tapjoy.Graph.setGraphProperties(g2, {
        hMarginPx: hMarginPx,
        gutterPx: gutterPx,
        unitPrefix: obj['right']['unitPrefix'],
        colors: g2.properties['chart.colors'].slice(obj['main']['data'].length),
        yAxisPos: 'right',
        yMax: obj['right']['yMax'],
        decimals: obj['right']['decimals']
      })

      g2.Draw();
    }

    var graphNode = $('#' + id + '_graph');
    var barNode = $('#' + id + ' .bar')
    var tooltipNode = $('#' + id + ' .tooltip')

    $('#' + id + '>.holder').hover(function() {
      barNode.show();
      tooltipNode.show();
    },function() {
      barNode.hide();
      tooltipNode.hide();
    }).mousemove(function(e) {
      var graphInternalHeight = graphNode.height() - gutterPx * 2;
      var graphInternalWidth = graphNode.width() - gutterPx * 2 - hMarginPx * 2;
      var graphInternalTop = graphNode.offset().top + gutterPx;
      var graphInternalLeft = graphNode.offset().left + gutterPx;

      var mouseX = e.pageX - graphInternalLeft;
      var newX = mouseX - mouseX % (graphInternalWidth / (numPoints - 1));
      newX = Math.max(newX, 0);
      newX = Math.min(newX, graphInternalWidth);
      newX = Math.floor(newX);

      barNode.css('height', graphInternalHeight).css('top', graphInternalTop);
      barNode.css('left', newX + graphInternalLeft + 4);
      tooltipNode.css('left', newX + graphInternalLeft + 4).css('top', e.pageY);

      var activeId = Math.ceil(newX / graphInternalWidth * (numPoints - 1));

      tooltipNode.html(Tapjoy.Graph.getTooltipHtml(obj, activeId));
    });
    return [g, g2];
  },

  getTooltipHtml: function(obj, idx) {
    idx = idx % (obj['intervals'].length - 1);
    var html = [];
    html.push(obj['intervals'][idx] + ' - ' + obj['intervals'][idx + 1]);

    groups = ['main', 'right', 'extra'];
    for (var i = 0, group; group = groups[i]; i++) {
      if (obj[group]) {
        for (var j = 0, name; name = obj[group]['names'][j]; j++) {
          data = obj[group]['stringData'] ? obj[group]['stringData'] : obj[group]['data']
          var value = data[j][idx];
          if (value == null) {
            value = '-';
          }

          html.push(name + ': ' + value);
        }
      }
    }

    return html.join('<br />')
  },

  getTotalsHtml: function(obj) {
    var html = [];

    groups = ['main', 'right', 'extra'];
    for (var i = 0, group; group = groups[i]; i++) {
      if (obj[group] && obj[group]['totals']) {
        for (var j = 0, name; name = obj[group]['names'][j]; j++) {
          var value = obj[group]['totals'][j];
          
          if (value || value == 0) {
            html.push(name + ': ' + value);
          }
        }
      }
    }

    return html.join(',&nbsp; ')
  }
};
