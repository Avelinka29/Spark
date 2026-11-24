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
    func testRegistrationDismissesKeyboard() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Регистрация"].tap()

        let name = app.textFields["Имя"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))

        app.buttons["Зарегистрироваться"].tap()
        let keyboardGone = NSPredicate(format: "exists == false")
        expectation(for: keyboardGone, evaluatedWith: app.keyboards.firstMatch)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.alerts["Не удалось зарегистрироваться"].waitForExistence(timeout: 3))
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

    @MainActor
    func testMapSearchIsAccessible() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Пропустить и посмотреть приложение"].tap()
        let mapTab = app.buttons["Карта"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()
        let search = app.textFields["Поиск возможностей"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(search.isHittable)
    }
}
