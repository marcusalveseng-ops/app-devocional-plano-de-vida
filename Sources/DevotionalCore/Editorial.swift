import Foundation

public struct ExaminationTemplate: Identifiable {
    public let id: String
    public let name: String
    public let questions: [String]
    public func copyQuestions() -> [Question] { questions.map { Question(text: $0) } }
}

public enum Editorial {
    public static let version = "0.1-draft"
    public static let reviewNotice = "Textos iniciais em revisão editorial. Você pode adaptá-los ao seu plano."
    public static let hailMary = "Ave Maria, cheia de graça, o Senhor é convosco. Bendita sois vós entre as mulheres e bendito é o fruto do vosso ventre, Jesus. Santa Maria, Mãe de Deus, rogai por nós, pecadores, agora e na hora de nossa morte. Amém."
    public static let examinations: [ExaminationTemplate] = [
        .init(id: "daily", name: "Exame geral do dia", questions: [
            "Coloco este dia na presença de Deus. Por quais graças desejo agradecer?",
            "Como respondi a Deus e às pessoas que encontrei? Em que preciso pedir perdão?",
            "Que propósito concreto posso levar para amanhã, confiando na ajuda de Deus?"
        ]),
        .init(id: "particular", name: "Exame particular", questions: [
            "Qual propósito escolhi trabalhar hoje?",
            "Em quais momentos fui fiel a esse propósito? Onde encontrei dificuldades?",
            "Que pequeno passo posso dar na próxima oportunidade?"
        ]),
        .init(id: "brief", name: "Exame breve", questions: [
            "Senhor, pelo que quero agradecer e pelo que preciso pedir perdão hoje?",
            "Que propósito simples desejo oferecer a Deus para amanhã?"
        ])
    ]
    public static func starterPlan() -> PlanState {
        var state = PlanState(); state.hasOnboarded = true
        state.moments = [Moment(name: "Ao acordar"), Moment(name: "Durante o dia"), Moment(name: "Antes de dormir")]
        var offering = Activity(name: "Oferecimento do dia", kind: .devotion, momentID: state.moments[0].id)
        offering.supportText = "Senhor, ofereço este dia, meu trabalho e meus encontros. Ajuda-me a viver na tua presença e a servir com amor."
        offering.durationMinutes = nil
        let gospel = Activity(name: "Evangelho do dia", kind: .gospel, momentID: state.moments[0].id, position: 1)
        let reading = Activity(name: "Leitura espiritual", kind: .spiritualReading, momentID: state.moments[1].id)
        var examination = Activity(name: "Exame de consciência", kind: .examination, momentID: state.moments[2].id)
        examination.questions = examinations[0].copyQuestions()
        // Suggested hours are shown in the editor; no reminder is enabled without a user action.
        state.activities = [offering, gospel, reading, examination]
        return state
    }
}
