var loginDiv = null;

// Shows the login-div. Also sends a request to the server to get the content of said div.
function showLoginDiv(url) {
    if (loginDiv == null) {
        $('body').append('<div id="login_container"></div>');
        loginDiv = $('#login_container');
    }
    // Callbacks.
    var onSuccess = function (data) {
        loginDiv.html(data);
        loginDiv.show();
    };
    // Send the ajax request.
    $.ajax(url, {'success': onSuccess});
}

// Hides the login-div.
function hideLoginDiv() {
    loginDiv.hide();
}

// Sends a login request to the server.
function login(url) {
    // Callbacks.
    var onSuccess = function (data) {
        if (data['success']) location.reload();
        else {
            var messageDiv = $('#message');
            messageDiv.html(data['message']);
            messageDiv.show();
        }
    };
    // Send the ajax submit request.
    $('form#login').ajaxSubmit({'url': url, 'dataType': 'json', 'success': onSuccess});
}

function logout(url) {
    // Callbacks.
    // Send the ajax request.
    $.post(url, {}, function () {
        location.reload();
    });
}
