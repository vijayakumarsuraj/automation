// Call-back after the DOM is ready to be worked with.
$(document).ready(function () {
    // Auto-refresh can start working now...
    refreshBusy = false;
    // All elements with the 'title' attribute will use qtip instead.
    $('[title!=""]').qtip();
});

// Shows / hides the required elements.
function toggleDropDown(url, id) {
    var $target = $('div#' + id);
    var $img = $('img#' + id);

    if ($target.is(':visible')) {
        $target.hide(function () {
            $img.attr('src', url + '/expand.png');
        });
    } else {
        $target.show(function () {
            $img.attr('src', url + '/collapse.png');
        });
    }
}

// Stores the id of the timer used to refresh the page content.
var timer = null;

// Sets up this page to auto-refresh every x seconds.
function autoRefresh(timeout) {
    // First clear any existing timer.
    if (timer != null)
        clearInterval(timer);
    // Then, if the timeout was greater than 0, setup a new timer.
    if (timeout > 0)
        timer = setInterval(doRefresh, timeout);
}

// Flag to indicate that a previous refresh AJAX call has not completed.
var refreshBusy = true;

// Refresh the page.
function doRefresh() {
    if (refreshBusy) return;

    // AJAX call to refresh the content.
    refreshBusy = true;
    var url = window.location.pathname;
    $.ajax(url, {
        cache: false,
        dataType: 'html',
        success: function (response) {
            var newContent = $(response).filter('body');
            $('body').replaceWith(newContent);
        },
        complete: function () {
            refreshBusy = false;
        }
    });
}

// Defaults for new data tables.
var dataTableDefaults = {
    'bPaginate': true,
    'bLengthChange': false,
    'iDisplayLength': 50,
    'sPaginationType': 'full_numbers',
    'bFilter': true,
    'bSort': false,
    'bInfo': true,
    'bAutoWidth': false,
    'oLanguage': {'sSearch': 'Filter'}
};

// Adds absolute sorting functions for formatted numbers.
jQuery.extend(jQuery.fn.dataTableExt.oSort, {
    'abs-formatted-num-pre': function (a) {
        if (a === '-') a = Number.MAX_VALUE;
        else if (a === '') a = 0;
        else a = a.replace(/[^\d\-\.]/g, '');
        return Math.abs(parseFloat(a));
    },

    'abs-formatted-num-asc': function (a, b) {
        return a - b;
    },

    'abs-formatted-num-desc': function (a, b) {
        return b - a;
    }
});

// Returns a comma separated string of all selected checkbox values.
// Restricted to checkboxes with the specified name.
function checkboxGetSelected(name) {
    var thisVal = function () {
        return $(this).val();
    };
    var values = $("input:checkbox:checked[name='" + name + "']").map(thisVal).get();
    return values.join(',');
}

// Un-selects all the check-boxes with the specified name.
function checkboxSelectNone(name) {
    $("input:checkbox[name='" + name + "']").prop('checked', false);
}

// Sends a 'post' request.
function postRunAction(url, name) {
    var values = checkboxGetSelected(name);
    if (values.length == 0)
        return;

    $.post(url, {'values': values}, function () {
        location.reload();
        checkboxSelectNone(name);
    });
}

// Sends a 'post' request to show / hide failing tests.
function postShowPassingTests(url, flag) {
    $.post(url, {'show_passing_tests': flag}, function() {
        location.reload();
    });
}

// Deletes all selected runs.
function deleteRuns(url, name) {
    postRunAction(url, name);
}

// Invalidates all selected runs.
function invalidateRuns(url, name) {
    postRunAction(url, name);
}
