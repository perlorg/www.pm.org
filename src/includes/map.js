function processMapJSON(data) {
    $(data).each(function() {
        var pm_group = this;

        if (pm_group.latitude && pm_group.longitude && pm_group.status == 'active') {

            var myLatlng = new google.maps.LatLng(pm_group.latitude, pm_group.longitude);

            var marker = new google.maps.Marker({
                position: myLatlng,
                map: PM.map,
                title: pm_group.name
            });

            var msg = "<h4>" + pm_group.name + "</h4>";
            msg = msg + "<a href='/groups/" + pm_group.id + ".html'>More info</a> | ";
            msg = msg + "<a href='" + pm_group.web + "'>Web site</a><br/>";

            var infowindow = new google.maps.InfoWindow({
                content: msg
            });

            google.maps.event.addListener(marker, 'click',
            function() {
                infowindow.open(PM.map, marker);
            });
        }
    });
};