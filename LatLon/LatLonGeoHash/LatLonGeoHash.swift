import CoreLocation

public typealias Geohash = String

extension String {

    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}

public enum GeoHashDirection {
    case N
    case NE
    case E
    case SE
    case S
    case SW
    case W
    case NW
}

/**
* Geohash encode, decode, bounds, neighbours.
*
* @namespace
*/
public extension Geohash
{
    /* (Geohash-specific) Base32 map */
    static let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"

    /**
    * Encodes latitude/longitude to geohash, either to specified precision or to automatically
    * evaluated precision.
    *
    * @param   {number} lat - Latitude in degrees.
    * @param   {number} lon - Longitude in degrees.
    * @param   {number} [precision] - Number of characters in resulting geohash.
    * @returns {string} Geohash of supplied latitude/longitude.
    * @throws  Invalid geohash.
    *
    * @example
    *     var geohash = Geohash.encode(CLLocationCoordinate2D(latitude: 52.205, longitude: 0.119), 7) // geohash: "u120fxw"
    */
    public static func encode(location: CLLocationCoordinate2D, precision: Int?) -> Geohash
    {
        var precision = precision

        // infer precision?
        if (precision == nil) {
            // refine geohash until it matches precision of supplied lat/lon
            for p in 1..<12 {
                let hash = encode(location, precision: p)

                if let posn = hash.decode() {
                    if (posn.latitude == location.latitude && posn.longitude == location.longitude) {
                        Geohash(hash)
                    }
                }
            }

            precision = 12 // set to maximum
        }

        var idx = 0 // index into base32 map
        var bit = 0 // each char holds 5 bits
        var evenBit = true
        var geohash = ""

        var latMin:Double =  -90
        var latMax:Double =  90
        var lonMin:Double = -180
        var lonMax:Double = 180

        while (geohash.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < precision) {
            if (evenBit) {
                // bisect E-W longitude
                let lonMid = (lonMin + lonMax) / 2
                if (location.longitude > lonMid) {
                    idx = idx*2 + 1
                    lonMin = lonMid
                } else {
                    idx = idx*2
                    lonMax = lonMid
                }
            } else {
                // bisect N-S latitude
                let latMid = (latMin + latMax) / 2
                if (location.latitude > latMid) {
                    idx = idx*2 + 1
                    latMin = latMid
                } else {
                    idx = idx*2
                    latMax = latMid
                }
            }
            evenBit = !evenBit

            if (++bit == 5) {
                // 5 bits gives us a character: append it and start over
                geohash += Geohash.base32[idx]
                bit = 0
                idx = 0
            }
        }

        return Geohash(geohash)
    }

    /**
    * Decode geohash to latitude/longitude (location is approximate centre of geohash cell,
    *     to reasonable precision).
    *
    * @param   {string} geohash - Geohash string to be converted to latitude/longitude.
    * @returns {{lat:number, lon:number}} (Center of) geohashed location.
    * @throws  Invalid geohash.
    *
    * @example
    *     var latlon = Geohash.decode("u120fxw") // latlon: { lat: 52.205, lon: 0.1188 }
    */
    public func decode() -> CLLocationCoordinate2D?
    {
        // <-- the hard work
        if let b = self.bounds() {
            // now just determine the centre of the cell...
            let latMin = b.sw.latitude
            let lonMin = b.sw.longitude
            let latMax = b.ne.latitude
            let lonMax = b.ne.longitude

            // cell centre
            var lat = (latMin + latMax)/2
            var lon = (lonMin + lonMax)/2

            // round to close to centre without excessive precision: ⌊2-log10(Δ°)⌋ decimal places
            lat = floor(2-log10(latMax-latMin))
            lon = floor(2-log10(lonMax-lonMin))

            return CLLocationCoordinate2D( latitude: lat, longitude: lon )
        }

        return nil
    }

    /**
    * Returns SW/NE latitude/longitude bounds of specified geohash.
    *
    * @param   {string} geohash - Cell that bounds are required of.
    * @returns {{sw: {lat: number, lon: number}, ne: {lat: number, lon: number}}}
    * @throws  Invalid geohash.
    */
    public func bounds() -> (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D)? {
        var evenBit = true

        var latMin:Double =  -90
        var latMax:Double =  90
        var lonMin:Double = -180
        var lonMax:Double = 180

        for i in [0..<self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)] {
            let chr = self[i]
            let idx = Geohash.base32.rangeOfString(chr)

            if (idx == nil) {
                return nil
            }

            let index = idx!.startIndex
            let idx2 = index.distanceTo(index.advancedBy(1))

            for n in 4.stride(to: 0, by: -1) {
                let bitN = idx2 >> n & 1
                if (evenBit) {
                    // longitude
                    let lonMid = (lonMin+lonMax) / 2
                    if (bitN == 1) {
                        lonMin = lonMid
                    } else {
                        lonMax = lonMid
                    }
                } else {
                    // latitude
                    let latMid = (latMin+latMax) / 2
                    if (bitN == 1) {
                        latMin = latMid
                    } else {
                        latMax = latMid
                    }
                }
                evenBit = !evenBit
            }
        }

        return (
            sw: CLLocationCoordinate2D( latitude: latMin, longitude: lonMin ),
            ne: CLLocationCoordinate2D( latitude: latMax, longitude: lonMax )
        )
    }

    /**
    * Determines adjacent cell in given direction.
    *
    * @param   geohash - Cell to which adjacent cell is required.
    * @param   direction - Direction from geohash (N/S/E/W).
    * @returns {string} Geocode of adjacent cell.
    * @throws  Invalid geohash.
    */
    public func adjacent(direction: GeoHashDirection) -> Geohash {
        // based on github.com/davetroy/geohash-js

        let neighbour = [
            GeoHashDirection.N: [ "p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx" ],
            GeoHashDirection.S: [ "14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp" ],
            GeoHashDirection.E: [ "bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy" ],
            GeoHashDirection.W: [ "238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb" ]
        ]

        let border = [
            GeoHashDirection.N: [ "prxz",     "bcfguvyz" ],
            GeoHashDirection.S: [ "028b",     "0145hjnp" ],
            GeoHashDirection.E: [ "bcfguvyz", "prxz"     ],
            GeoHashDirection.W: [ "0145hjnp", "028b"     ]
        ]

        let endIndex = self.endIndex.advancedBy(-1)

        let lastCh = self.substringFromIndex(endIndex)    // last character of hash
        var parent = self.substringToIndex(endIndex) // hash without last character

        let type = self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) % 2

        // check for edge-cases which don't share common prefix
        if let borderDir = border[direction] {
            let borderType = borderDir[type]

            if (borderType.rangeOfString(lastCh) != nil && parent != "") {
                parent = parent.adjacent(direction)
            }
        }

        // append letter for direction to parent
        if let neighbourDir = neighbour[direction],
           let n = neighbourDir[type].rangeOfString(lastCh)
        {
            parent += Geohash.base32[n]
        }

        return parent
    }

    /**
    * Returns all 8 adjacent cells to specified geohash.
    *
    * @param   {string} geohash - Geohash neighbours are required of.
    * @returns {{n,ne,e,se,s,sw,w,nw: string}}
    * @throws  Invalid geohash.
    */
    public func neighbours() -> [GeoHashDirection: Geohash] {
        return [
            .N:  self.adjacent(.N),
            .NE: self.adjacent(.N).adjacent(.E),
            .E:  self.adjacent(.E),
            .SE: self.adjacent(.S).adjacent(.E),
            .S:  self.adjacent(.S),
            .SW: self.adjacent(.S).adjacent(.W),
            .W:  self.adjacent(.W),
            .NW: self.adjacent(.N).adjacent(.W)
        ]
    }
}
