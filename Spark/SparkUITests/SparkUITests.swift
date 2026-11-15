import XCTest

final class SparkUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSwitchesBetweenLoginAndRegistration() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["С возвращением!"].waitForExistence(timeout: 5))

        app.buttons["Регистрация"].tap()

        XCTAssertTrue(app.staticTexts["Создай аккаунт"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Зарегистрироваться"].exists)
    }

    @MainActor
    func testGuestCanOpenMainApplication() throws {
        let app = XCUIApplication()
        app.launch()

        let guestButton = app.buttons["Пропустить и посмотреть приложение"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5))
        guestButton.tap()

        XCTAssertTrue(app.buttons["Лента"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Карта"].exists)
        XCTAssertTrue(app.buttons["Проекты"].exists)
        XCTAssertTrue(app.buttons["Профиль"].exists)
    }
}
