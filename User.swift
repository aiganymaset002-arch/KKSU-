//
//  User.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//

import Foundation

// MARK: - Роли KKSU Online (задача 4)

enum KKSURole: String, Codable, CaseIterable, Identifiable, Hashable {
    case student
    case parent
    case teacher
    case psychologist
    case expert
    case mentor
    case partner
    case admin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Ученик"
        case .parent: return "Родитель"
        case .teacher: return "Педагог"
        case .psychologist: return "Психолог"
        case .expert: return "Эксперт"
        case .mentor: return "Наставник"
        case .partner: return "Партнёр"
        case .admin: return "Администратор"
        }
    }

    var icon: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .parent: return "person.2.fill"
        case .teacher: return "person.fill.viewfinder"
        case .psychologist: return "heart.text.square.fill"
        case .expert: return "checkmark.seal.fill"
        case .mentor: return "figure.2.and.child.holdinghands"
        case .partner: return "building.2.fill"
        case .admin: return "gearshape.2.fill"
        }
    }

    /// Роли, которые может выбрать пользователь при самостоятельной регистрации.
    /// Администратора назначает только другой администратор.
    static var selfRegistrable: [KKSURole] {
        allCases.filter { $0 != .admin }
    }

    /// Может ли роль проверять и оценивать работы учеников.
    var canTeach: Bool { self == .teacher || self == .admin }

    /// Может ли роль выполнять экспертную оценку.
    var canReview: Bool { self == .expert || self == .mentor || self == .admin }
}

// MARK: - Пользователь (задачи 2, 3)

struct KKSUUser: Identifiable, Codable, Hashable {
    var id = UUID()
    var fullName: String
    var email: String
    var phone: String = ""
    var role: KKSURole
    var passwordHash: String
    var salt: String
    var createdAt = Date()
    var isBlocked = false
    /// Для родителя — дети, для наставника — подопечные.
    var linkedStudentIDs: [UUID] = []
    /// Для партнёра — организация.
    var partnerID: UUID?
    var recoveryCode: String?
    var recoveryExpires: Date?
    var lastLogin: Date?

    var initials: String {
        fullName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
}

// MARK: - Профиль ученика (задача 10)

struct StudentProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var userID: UUID
    var birthDate: Date = Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    var grade: String = "6"
    var school: String = "KKSU"
    var city: String = "Алматы"
    var interests: [String] = []
    var specialNeeds: String = ""
    var supportNotes: String = ""
    var goals: String = ""
    var avatarSymbol: String = "person.crop.circle.fill"
    var xp: Int = 0

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
}
