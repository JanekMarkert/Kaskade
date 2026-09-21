import XCTest

/// End-to-End-Rauchtest: tippt wirklich auf jede Werkzeug-Kachel, prüft,
/// dass das jeweilige Sheet aufgeht und sich wieder schließen lässt.
/// Läuft im Simulator; Sensor-Funktionen (UWB/BLE/LiDAR) selbst greifen dort
/// nicht, aber Sheet-Öffnen/-Schließen und die grundlegende Bedienung schon.
final class SmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHauptbildschirmZeigtAlleWerkzeuge() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["m1-button"].exists)
        XCTAssertTrue(app.buttons["uwb-button"].exists)
        XCTAssertTrue(app.buttons["lidar-button"].exists)
        XCTAssertTrue(app.buttons["export-button"].exists)
        XCTAssertTrue(app.buttons["karte-button"].exists)
        XCTAssertTrue(app.buttons["checkliste-button"].exists)
    }

    func testM1SheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["m1-button"].tap()
        XCTAssertTrue(app.buttons["start-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testUwbSheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["uwb-button"].tap()
        XCTAssertTrue(app.buttons["start-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testLidarSheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["lidar-button"].tap()
        XCTAssertTrue(app.buttons["start-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testExportSheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["export-button"].tap()
        XCTAssertTrue(app.buttons["done-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testKarteSheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["karte-button"].tap()
        XCTAssertTrue(app.buttons["done-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testChecklisteSheetOeffnetUndSchliesst() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["checkliste-button"].tap()
        XCTAssertTrue(app.buttons["done-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testTripsUeberGpsAnsichtErreichbar() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["gps-button"].tap()
        XCTAssertTrue(app.buttons["trips-button"].waitForExistence(timeout: 5))
        app.buttons["trips-button"].tap()
        XCTAssertTrue(app.buttons["trips-done-button"].waitForExistence(timeout: 5))
        app.buttons["trips-done-button"].tap()

        XCTAssertTrue(app.buttons["done-button"].waitForExistence(timeout: 5))
        app.buttons["done-button"].tap()
        XCTAssertTrue(app.buttons["gps-button"].waitForExistence(timeout: 5))
    }

    func testAufzeichnungStartetUndZeigtLabelLeisteUndStatistik() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["gps-button"].tap()
        XCTAssertTrue(app.buttons["start-button"].waitForExistence(timeout: 5))
        app.buttons["start-button"].tap()
        XCTAssertTrue(app.buttons["Fuß"].waitForExistence(timeout: 3))

        app.buttons["start-button"].tap()
        XCTAssertTrue(app.buttons["done-button"].waitForExistence(timeout: 5))
    }
}
