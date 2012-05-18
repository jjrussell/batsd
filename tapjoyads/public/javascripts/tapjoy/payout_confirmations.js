$(function($) {
      $('form.enable_request').submit(function() {
        if (!confirm('Are you sure?')) { return false; }

        var spinner = $(this).find('img.spinner');
        var disabled = $(this).find('div.disabled');
        var enabled = $(this).find('div.enabled');
        var notes = $(this).parent().parent().find('td.notes');

        $.ajax({
          dataType: 'json',
          type: $(this).attr('method'),
          url: $(this).attr('action'),
          data: $(this).serialize(),
          beforeSend: function() {
            disabled.hide();
            enabled.hide();
            spinner.show();
          },
          complete: function() {
            spinner.hide();
          },
          success: function(response) {
            if (response.success == true) {
              if(response.was_confirmed == true) {
                enabled.show();
                notes.empty();
              } else {
                disabled.show();
                notes.find('span').html(response.notes);
                if(response.can_confirm == false) {
                  disabled.find('.submit').remove();
                }
              }
            } else {
              $(this).parent().html('Error');
            }
          }
        });
        return false;
      });
});
