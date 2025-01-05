// Javascript representation of a GeoJSON file
//   https://wiki.openstreetmap.org/wiki/GeoJSON
var pmGroups = {
	"type": "FeatureCollection",
	"features": [
    [% FOREACH group IN allgroups; group=group.value %]
      [% IF group.latitude AND group.longitude %]
        {
          "geometry": {
            "type": "Point",
            "coordinates": [[% group.longitude %], [% group.latitude %]]
          },
          "type": "Feature",
          "properties": {
            "popupContent": "[% group.name | html_entity %]",
            "website": "[% group.web %]",
          },
          "id": [% group.id %]  
        },
      [% END %]
    [% END %]
	]
};