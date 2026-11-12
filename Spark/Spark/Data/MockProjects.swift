import Foundation

let mockProjects: [Project] = [
    Project(
        category: "EdTech",
        title: "EduScan: AI-помощник для школьников",
        summary: "Приложение помогает школьникам готовиться к ЦТ и ЦЭ с помощью ИИ и распознаёт задания по фото.",
        ownerRole: "Product Manager",
        vacancies: [
            Vacancy(title: "Flutter Developer", roleDescription: "Dart / Firebase"),
            Vacancy(title: "ML Engineer", roleDescription: "Python / PyTorch"),
            Vacancy(
                title: "UI/UX Designer",
                status: "ЗАНЯТО",
                roleDescription: "Figma / прототипирование",
                isActive: false
            )
        ],
        memberCount: 3
    ),
    Project(
        category: "GreenTech",
        title: "GreenStep",
        summary: "Сервис локальных экологических инициатив и волонтёрских команд.",
        ownerRole: "iOS Developer",
        vacancies: [
            Vacancy(title: "Backend Developer", roleDescription: "Python / FastAPI"),
            Vacancy(title: "UI/UX Designer", roleDescription: "Figma")
        ],
        memberCount: 2
    )
]
