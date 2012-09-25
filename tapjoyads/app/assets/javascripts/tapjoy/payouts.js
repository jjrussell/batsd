$(function($) {
  $.initPayouts = function(redirectPath, lookupPath, hasDateFilter) {

    var redirect = function(query) {
      var path = redirectPath;
      if (reseller = $('#reseller_id').val()) {
        if (!(query instanceof Object)) {
          query = {};
        }
        query['reseller_id'] = reseller;
      }
      if (query instanceof Object) {
        path += '?' + $.param(query);
      }
      window.location = path;
    };

    if (!hasDateFilter) {
      $('#unfiltered').show();
    } else {
      $('#filtered').show();
    }
    $('#unfiltered a').click(function(e){
      $('#unfiltered').hide();
      $('#filtered').show();
      e.preventDefault();
    });
    $('#date_submit').click(function() {
      var query = {
        year:  $('select#date_year').val(),
        month: $('select#date_month').val()
      };
      redirect(query);
    });
    $('#date_reset').click(function(){
      $('#filtered').hide();
      if (hasDateFilter) {
        redirect();
      } else {
        $('#unfiltered').show();
      }
    });

    $('#date').datepicker();
    $('form.json').submit(function() {
      if (!confirm('Are you sure?')) { return false; }

      var spinner = $(this).find('img.spinner');
      var submit = $(this).find('input.submit');
      var amount = $(this).find('input.amount');
      var status = $(this).find('span.status');

      $.ajax({
        dataType: 'json',
        type: $(this).attr('method'),
        url: $(this).attr('action'),
        data: $(this).serialize(),
        beforeSend: function() {
          amount.hide();
          submit.hide();
          spinner.show();
        },
        complete: function() {
          spinner.hide();
        },
        success: function(response) {
          if (response.success == true) {
            status.html('Complete');
          } else {
            status.html('Error');
          }
        }
      });
      return false;
    });
    var options = {
      source: lookupPath,
      delay: 250,
      minLength: 2,
      select: function(event, ui) {
        redirect({partners_filter: ui.item.partner_id});
      }
    };
    $('#partners').focus().autocomplete(options);
    $('input.clear_filter').click(function(){
      redirect();
    });
    $('select#confirm_filter').change(function() {
      var query = {confirm_filter: $(this).val()};
      redirect(query);
    });
    $('#print_all').click(function() {
      var url = redirectPath + '?print=true';
      var params = window.location.href.split('?');
      if(params.length > 1) {
        url += '&'+params[1];
      }
      window.location = url;
    });
    $(document).ready(function() {
      if(window.location.href.match(/print=true/)) {
        window.print();
      }
    });
  };
});
