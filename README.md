geohash
=======

Functions to convert a [geohash](http://en.wikipedia.org/wiki/Geohash) to/from a latitude/longitude
point, and to determine bounds of a geohash cell and find neighbours of a geohash.

Methods summary:

- `encode`: latitude/longitude point to geohash
- `decode`: geohash to latitude/longitude
- `bounds` of a geohash cell
- `adjacent` `neighbours` of a geohash

Install
-------



Usage
-----

Class methods

- `Geohash.encode(location: CLLocationCoordinate2D, precision: Int?) -> Geohash` : encode latitude/longitude point to geohash of given precision
   (number of characters in resulting geohash); if precision is not specified, it is inferred from
   precision of latitude/longitude values.
   
Instance methods

- `geohash.decode() -> CLLocationCoordinate2D?`: return { lat, lon } of centre of geohash, to appropriate precision
- `geohash.bounds() -> (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D)?`: return { sw, ne } bounds of geohash
- `geohash.adjacent(direction: GeoHashDirection) -> Geohash`: return adjacent cell to geohash in specified direction (N/S/E/W)
- `neighbours() -> [GeoHashDirection: Geohash]`: return all 8 adjacent cells (n/ne/e/se/s/sw/w/nw) to geohash

Further details
---------------

More information (with interactive conversion) at
[www.movable-type.co.uk/scripts/geohash.html](http://www.movable-type.co.uk/scripts/geohash.html).

Full JsDoc at [www.movable-type.co.uk/scripts/js/latlon-geohash/docs/Geohash.html](http://www.movable-type.co.uk/scripts/js/latlon-geohash/docs/Geohash.html).
