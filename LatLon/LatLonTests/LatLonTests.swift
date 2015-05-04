//
//  LatLonTests.swift
//  LatLonTests
//
//  Created by Andy Bennett on 02/05/2015.
//  Copyright (c) 2015 Firefly. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation

class LatLonTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOne() {
        let location = CLLocationCoordinate2D(latitude: 57.648, longitude: 10.410)
        let geohash = Geohash.encode(location, precision: 6)

        XCTAssert(geohash == "u4pruy", "encode Jutland")
    }

    func testTwo() {
        let location = CLLocationCoordinate2D(latitude: 57.648, longitude: 10.410)
        let geohash = Geohash("u4pruy")

        if let loca = geohash.decode() {
            XCTAssert(loca.latitude == location.latitude && loca.longitude == location.longitude, "decode Jutland")
        }
    }

    func testThree() {
        let location = CLLocationCoordinate2D(latitude: -25.38262, longitude: -49.26561)
        let geohash = Geohash.encode(location, precision: 8)

        XCTAssert(geohash == "6gkzwgjz", "encode Curitiba")
    }

    func testFour() {
        let location = CLLocationCoordinate2D(latitude: -25.38262, longitude: -49.26561)
        let geohash = Geohash("6gkzwgjz")

        if let loca = geohash.decode() {
            XCTAssert(loca.latitude == location.latitude && loca.longitude == location.longitude, "decode Curitiba")
        }
    }

    func testFive() {
        let neighbours = Geohash("ezzz").neighbours()
        let test = [
                        GeoHashDirection.N: "gbpb",
                        GeoHashDirection.NE: "u000",
                        GeoHashDirection.E: "spbp",
                        GeoHashDirection.SE: "spbn",
                        GeoHashDirection.S: "ezzy",
                        GeoHashDirection.SW: "ezzw",
                        GeoHashDirection.W: "ezzx",
                        GeoHashDirection.NW: "gbp8"
                    ]

        XCTAssert(neighbours == test, "neighbours")
    }
}
