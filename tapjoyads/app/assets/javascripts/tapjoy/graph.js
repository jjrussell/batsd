if (typeof(Tapjoy) == "undefined") { Tapjoy = {}; }

Tapjoy.Graph = {

  initGraphs: function(graphs) {
    graphs.each(function(){
      var id = $(this).attr('id');
      var holder = $('<div class="holder">').
        append( $('<canvas id="' + id + '_graph" width="800px" height="440px">') ).
        append( $('<div class="bar">') ).
        append( $('<div class="tooltip">') ).
        append( $('<div class="error">') );
      $(this).
        append( $('<h3>') ).
        append( $('<div class="dropdown">')).
        append( $('<div class="totals">') ).
        append( holder );
    });
  },

  setGraphProperties: function(g, options) {
    g.Set('chart.linewidth', 1.1);
    g.Set('chart.shadow', true);
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
      g.Set('chart.units.pre', options.unitPrefix);
    }

    if (options.yMax) {
      g.Set('chart.ymax', options.yMax);
    }

    if (options.decimals) {
      g.Set('chart.scale.decimals', options.decimals);
    }

    if (options.drawGrid != null) {
      g.Set('chart.background.grid', options.drawGrid);
    }

  },

  clone: function clone(obj) {
    if(obj == null || typeof(obj) != 'object') {
      return obj;
    }

    var temp = new obj.constructor();
    for(var key in obj) {
      temp[key] = clone(obj[key]);
    }

    return temp;
  },

  mergePartitions: function(part1, part2) {
    var end_part;
    if (part1 && part2) {
      end_part = Tapjoy.Graph.clone(part1);
      end_part.names = part1.names.concat(part2.names);
      end_part.data = part1.data.concat(part2.data);
      if (part1.stringData && part2.stringData) {
        end_part.stringData = part1.stringData.concat(part2.stringData);
      }
      end_part.totals = part1.totals.concat(part2.totals);
    } else if (part1) {
      end_part = Tapjoy.Graph.clone(part1);
    } else if (part2) {
      end_part = Tapjoy.Graph.clone(part2);
    }
    return end_part;
  },

  drawLargeGraph: function(obj, id, partition_index) {
    if ($('#' + id).length == 0 || obj == null) { return; }

    if (partition_index == undefined) {
      $('#' + id + '>.dropdown').html('');
    }

    $('#' + id + '>h3').html(obj['name']);
    if (obj['partition_names']) {
      if ($('#' + id + '>.dropdown').html() == '') {
        if (obj['partition_names'].length == 0) {
          $('#' + id + '>.dropdown').html(obj['partition_fallback']);
        } else {
          html = obj['partition_title'] + ": <select>";
          index = 0;
          for(var i = 0, name; name = obj['partition_names'][i]; i++) {
            html += '<option value="' + i + '"';
            if (name.search(obj['partition_default']) == 0 && index == 0) {
              index = i;
              html += ' selected="selected"';
            }
            html += '>' + name + '</option>';
          }
          html += '</select>';
          $('#' + id + '>.dropdown').html(html);
          partition_index = index;

          $('#' + id + '>.dropdown>select').change(function(event) {
            new_index = Number(event.target.value);
            Tapjoy.Graph.drawLargeGraph(obj, id, new_index);
          });
        }
      }
    }

    if (obj.partition_right && obj.right) {
      obj.graph_right = Tapjoy.Graph.mergePartitions(obj.right, obj.partition_right[partition_index]);
    } else if (obj.partition_right) {
      obj.graph_right = obj.partition_right[partition_index];
    } else if (obj.right) {
      obj.graph_right = obj.right;
    }

    if (obj.partition_left && obj.main) {
      obj.graph_left = Tapjoy.Graph.mergePartitions(obj.main, obj.partition_left[partition_index]);
    } else if (obj.partition_left) {
      obj.graph_left = obj.partition_left[partition_index];
    } else if (obj.main) {
      obj.graph_left = obj.main;
    }

    if ($('#' + id + '>.totals').length == 1) {
      $('#' + id + '>.totals').html(Tapjoy.Graph.getTotalsHtml(obj));
    }

    var gutterPx = 80;
    var hMarginPx = 5;
    var numPoints = obj['intervals'].length - 1;

    var legendKeys = obj['graph_left']['names'];
    if (obj['graph_right']) {
      legendKeys = legendKeys.concat(obj['graph_right']['names']);
    }

    try {
      var g = new RGraph.Line(id + '_graph');
      g.original_data = obj['graph_left']['data'];
      RGraph.Clear(g.canvas);

      g.Set('chart.key', legendKeys);
      g.Set('chart.key.background', 'rgba(255,255,255,0.5)');
      g.Set('chart.key.position', 'gutter');

      g.Set('chart.labels', obj['xLabels']);
      g.Set('chart.text.angle', 90);

      Tapjoy.Graph.setGraphProperties(g, {
        hMarginPx: hMarginPx,
        gutterPx: gutterPx,
        unitPrefix: obj['graph_left']['unitPrefix'],
        colors: ['#f00', '#0f0', '#00f', '#f0f', '#ff0', '#0ff', '#000'],
        yMax: obj['graph_left']['yMax'],
        decimals: obj['graph_left']['decimals']
      });
      g.Draw();


      if (obj['graph_right']) {
        var g2 = new RGraph.Line(id + '_graph');
        g2.original_data = obj['graph_right']['data'];

        Tapjoy.Graph.setGraphProperties(g2, {
          hMarginPx: hMarginPx,
          gutterPx: gutterPx,
          unitPrefix: obj['graph_right']['unitPrefix'],
          colors: g.properties['chart.colors'].slice(obj['graph_left']['data'].length),
          yAxisPos: 'right',
          yMax: obj['graph_right']['yMax'],
          decimals: obj['graph_right']['decimals'],
          drawGrid: false
        });

        g2.Draw();
      }

      var graphNode = $('#' + id + '_graph');
      var barNode = $('#' + id + ' .bar');
      var tooltipNode = $('#' + id + ' .tooltip');

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
    } catch(e) {
      $('#' + id + ' .error').html('Error drawing chart');
      $('#' + id + '_graph').hide();
    }
  },

  getTooltipHtml: function(obj, idx) {
    idx = idx % (obj['intervals'].length - 1);
    var html = [];
    html.push(obj['intervals'][idx] + ' - ' + obj['intervals'][idx + 1]);

    groups = ['graph_left', 'graph_right', 'extra'];
    for (var i = 0, group; group = groups[i]; i++) {
      if (obj[group]) {
        for (var j = 0, name; name = obj[group]['names'][j]; j++) {
          if (obj[group]['longNames']) {
            name = obj[group]['longNames'][j];
          }
          data = obj[group]['stringData'] ? obj[group]['stringData'] : obj[group]['data'];
          var value = data[j][idx];
          if (value == null) {
            value = '-';
          }

          html.push(name + ': ' + value);
        }
      }
    }

    return html.join('<br />');
  },

  getTotalsHtml: function(obj) {
    var html = [];

    groups = ['graph_left', 'graph_right', 'extra'];
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

    return html.join('&nbsp; ');
  }
};
