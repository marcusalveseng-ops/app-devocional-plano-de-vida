import XCTest

final class PlanoDeVidaUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        app.launch()
    }
    func testExaminationWithoutWrittenAnswersAndNotePersistence() {
        XCTAssertTrue(app.buttons["onboard-template"].waitForExistence(timeout: 10))
        capture("01-primeiro-uso")
        app.buttons["onboard-template"].tap()
        XCTAssertTrue(app.tabBars.buttons["Hoje"].waitForExistence(timeout: 5))
        capture("02-hoje")
        openExamination()
        scrollTo(app.buttons["Refletir em silêncio"])
        app.buttons["Refletir em silêncio"].tap()
        XCTAssertTrue(app.staticTexts["Pergunta 1 de 3"].waitForExistence(timeout: 3))
        app.buttons["Próxima pergunta"].tap()
        XCTAssertTrue(app.staticTexts["Pergunta 2 de 3"].exists)
        app.buttons["Próxima pergunta"].tap()
        scrollTo(app.buttons["Concluir reflexão"])
        app.buttons["Concluir reflexão"].tap()
        XCTAssertTrue(app.staticTexts["Um momento para recomeçar."].exists)
        scrollTo(app.buttons["complete-activity"])
        app.buttons["complete-activity"].tap()
        XCTAssertTrue(app.buttons["complete-activity"].label.contains("Realizada"))
        scrollTo(app.buttons["Nova anotação"])
        app.buttons["Nova anotação"].tap()
        let editor = app.textViews["note-text"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3)); editor.tap(); editor.typeText("Nota de teste de persistência")
        // Compare persistence with the text actually entered by the simulator keyboard.
        let enteredText = editor.value as? String ?? ""
        XCTAssertTrue(enteredText.contains("persist"))
        app.buttons["save-note"].tap()
        scrollTo(app.staticTexts[enteredText])
        XCTAssertTrue(app.staticTexts[enteredText].exists)
        capture("03-reflexao-concluida")
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        openExamination()
        scrollTo(app.staticTexts[enteredText])
        XCTAssertTrue(app.staticTexts[enteredText].exists)
        capture("06-anotacao-preservada")
    }
    func testCreateMomentAndFreeActivity() {
        app.buttons["onboard-template"].tap()
        app.tabBars.buttons["Meu plano"].tap()
        capture("04-meu-plano")
        scrollTo(app.buttons["Novo momento do dia"])
        app.buttons["Novo momento do dia"].tap()
        let field = app.textFields["moment-name"]; XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap(); field.typeText("Após o trabalho"); app.buttons["Salvar"].tap()
        let addButtons = app.buttons.matching(identifier: "Adicionar prática")
        XCTAssertGreaterThan(addButtons.count, 0)
        let add = addButtons.element(boundBy: addButtons.count - 1)
        scrollTo(add); add.tap()
        let visit = app.buttons["Visita a enfermos"]
        scrollTo(visit); visit.tap()
        XCTAssertTrue(app.buttons["save-activity"].waitForExistence(timeout: 3))
        app.buttons["save-activity"].tap()
        let activity = app.staticTexts["Visita a enfermos"]
        XCTAssertTrue(activity.waitForExistence(timeout: 5))
        app.tabBars.buttons["Ajustes"].tap(); capture("05-ajustes")
    }
    private func openExamination() {
        let button = app.buttons.containing(.staticText, identifier: "Exame de consciência").firstMatch
        scrollTo(button); XCTAssertTrue(button.exists); button.tap()
        XCTAssertTrue(app.buttons["Refletir em silêncio"].waitForExistence(timeout: 5))
    }
    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<7 { if element.isHittable { return }; app.swipeUp() }
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
