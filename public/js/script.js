var $mainForm = $('#main-form');

$mainForm.submit(function (e) {
  e.preventDefault();
  var $this = $(this);
  var deviceId = $this.find('#device-id').val();
  var value = $this.find('#amount').val();

  '/devices/' + deviceId + '/send_command';
  $.ajax({
      type: 'PUT'
    , url: '/devices/' + deviceId + '/send_command'
    , data: {
      command: value
    }
  });

  // TODO: notifiy the user whether the request was a success.
});