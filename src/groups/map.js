var usa = new GPoint(-95.677068, 37.0625);
var world = new GPoint(0.0, 18.0);
var na = new GPoint(-102.832031, 52.268157);
var europe = new GPoint(15.029297, 49.61071);
var australia = new GPoint(134.296875, -25.641526);
var asia = new GPoint(95, 45);
var africa = new GPoint(20, 0);
var sa = new GPoint(-63.63, -25.00);

    var map;
    function onLoad() {
      // Center the map
      map = new GMap(document.getElementById("map"));
      map.addControl(new GLargeMapControl());
      map.addControl(new GMapTypeControl());
      //map.centerAndZoom(new GPoint(-78.6588, 35.8219), 16);
      map.centerAndZoom(new GPoint(0.0, 18.0), 15);
      var spamicon = new GIcon();
      spamicon.image = "http://labs.google.com/ridefinder/images/mm_20_red.png";
      spamicon.shadow = "http://labs.google.com/ridefinder/images/mm_20_shadow.png";
      spamicon.iconSize = new GSize(12, 20);
      spamicon.shadowSize = new GSize(22, 20);
      spamicon.iconAnchor = new GPoint(6, 20);
      spamicon.infoWindowAnchor = new GPoint(5, 1);

        // Creates a marker whose info window displays the given number
            function createMarkerJay(point, spamicon, name, web, lat, lng) {
              var marker = new GMarker(point, spamicon);

              // Show this marker's index in the info window when it is clicked
              var msg = "<small>";
              msg = msg+"<a href='" + web + "'>" + name + "</a><br/>";
              msg = msg+"<nobr>" + lat + ", " + lng + "</nobr>";
              msg = msg+"</small>";

              GEvent.addListener(marker, "click", function() {
                marker.openInfoWindowHtml(msg);
              });

              return marker;
            }

      // Download the data in map.xml and load it on the map.
      var request = GXmlHttp.create();
      request.open("GET", "map.xml", true);
      request.onreadystatechange = function() {
        if (request.readyState == 4) {
          var xmlDoc = request.responseXML;
          var markers = xmlDoc.documentElement.getElementsByTagName("marker");
          for (var i = 0; i < markers.length; i++) {
            var point = new GPoint(parseFloat(markers[i].getAttribute("lng")),
                                   parseFloat(markers[i].getAttribute("lat")));
            //var marker = new GMarker(point);
              var marker = createMarkerJay(point, spamicon,
                    markers[i].getAttribute("name"), markers[i].getAttribute("web"),
                    markers[i].getAttribute("lat"),  markers[i].getAttribute("lng"));
              map.addOverlay(marker);
          }
        }
      }
      request.send(null);
    }

    function cz(p, z) {
        map.centerAndZoom(p, z);
    }


function initialize() {
  var latitude  = {
	max: coords[0][0],
	min:  coords[0][0],
  }
  var longitude = {
	max: coords[0][1],
	min: coords[0][1],
  }
  for(i = 1; i < coords.length; i++) {
     latitude['min'] = Math.min(coords[i][0], latitude['min']);
     latitude['max'] = Math.max(coords[i][0], latitude['max']);
     longitude['min'] = Math.min(coords[i][1], longitude['min']);
     longitude['max'] = Math.max(coords[i][1], longitude['max']);
  }
  //var zoom = 13; // TODO should be calculated?
  //alert(longitude['min'] + " " + longitude['max']);
  //alert(latitude['min']  + " " + latitude['max']);
  longitude['center'] = (longitude['max'] + longitude['min'])/2;
  latitude['center']  = (latitude['max']  + latitude['min'])/2;

  if (GBrowserIsCompatible()) {
    var map = new GMap2(document.getElementById("map-canvas"));
    map.setCenter(new GLatLng(latitude['center'], longitude['center']), zoom);
    map.setUIToDefault();

    // Add 10 markers to the map at random locations
    var bounds = map.getBounds();
    var southWest = bounds.getSouthWest();
    var northEast = bounds.getNorthEast();
    var lngSpan = northEast.lng() - southWest.lng();
    var latSpan = northEast.lat() - southWest.lat();
    for (var i = 0; i < coords.length; i++) {
      var point = new GLatLng(coords[i][0], coords[i][1]);
      map.addOverlay(new GMarker(point));
    }
  }
}


