jQuery(function(){
    var escapeHTML = function(string) {
        // Lifted from mustache.js
        var entityMap = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': '&quot;',
            "'": '&#39;',
            "/": '&#x2F;'
        };
        return string.replace(/[&<>"'\/]/g, function(s) {
            return entityMap[s];
        });
    };

    var template =
        '<table><tr><td>Status: </td><td><a href="{{ title_url }}""><span class="travis-status-{{ last_build_state }}">{{ pretty_build_state }}</span></a></td></tr>'
        + '<tr><td>Build started: </td><td>{{ build_start }}</td></tr>'
        + '<tr><td>Build ended: </td><td>{{ build_end }}</td></tr></table>'
    ;

    var travisci_fetch = function(template) {
        var _ = this;
        var ticket_id = jQuery(this).attr("data-travisci-ticketid");
        jQuery.getJSON(
            RT.Config.WebPath + "/Helpers/TravisCI?id=" + ticket_id,
            function(data) {
                if (data == null) return;
                if (!data.success) {
                    jQuery(".travisci").html(escapeHTML(data.error));
                    return;
                }
                data = data.result;
                var title_url = data.title_url;
                var last_build_state = data.last_build.state;
                var pretty_build_state = data.last_build.pretty_build_state;
                var build_start = data.last_build.started_at;
                var build_end = data.last_build.finished_at;
                jQuery(".travisci").html(template.replace(
                    /{{\s*(.+?)\s*}}/g,
                    function(m,code){
                        return escapeHTML(eval(code));
                    }
                ));
            }
        );
    };

    jQuery(".travisci").each(function(){
        travisci_fetch.call(this, template);
    });

});
