//
//  AMLocalization.swift
//  ATA MURA
//
//  Три языка интерфейса: русский, English, қазақша.
//  Тексты — в AMStrings.swift; язык выбирается при входе и в настройках.
//

import Foundation

enum AMLanguage: String, Codable, CaseIterable, Identifiable {
    case ru, en, kk

    var id: String { rawValue }

    /// Текущий язык интерфейса. Меняется только через AMStore.language.
    static var current: AMLanguage = {
        if let saved = UserDefaults.standard.string(forKey: "atamura.language"), let language = AMLanguage(rawValue: saved) {
            return language
        }
        let system = Locale.preferredLanguages.first?.prefix(2) ?? "ru"
        return AMLanguage(rawValue: String(system)) ?? .ru
    }()

    var nativeName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .kk: return "Қазақша"
        }
    }

    var flag: String {
        switch self {
        case .ru: return "RU"
        case .en: return "EN"
        case .kk: return "KZ"
        }
    }

    var locale: Locale {
        switch self {
        case .ru: return Locale(identifier: "ru_KZ")
        case .en: return Locale(identifier: "en_KZ")
        case .kk: return Locale(identifier: "kk_KZ")
        }
    }

    /// Голос для озвучивания (Low Vision).
    var speechCode: String {
        switch self {
        case .ru: return "ru-RU"
        case .en: return "en-US"
        case .kk: return "kk-KZ"
        }
    }
}

/// Перевод строки интерфейса по ключу.
func L(_ key: String) -> String {
    guard let entry = AMStrings.table[key] else { return key }
    switch AMLanguage.current {
    case .ru: return entry.ru
    case .en: return entry.en.isEmpty ? entry.ru : entry.en
    case .kk: return entry.kk.isEmpty ? entry.ru : entry.kk
    }
}

/// Перевод с подстановкой значений вместо %@ (по порядку).
func L(_ key: String, _ args: CustomStringConvertible...) -> String {
    var text = L(key)
    for arg in args {
        guard let range = text.range(of: "%@") else { break }
        text.replaceSubrange(range, with: arg.description)
    }
    return text
}

struct AMString {
    let ru: String
    let en: String
    let kk: String
}

extension Date {
    var amDate: String {
        let formatter = DateFormatter()
        formatter.locale = AMLanguage.current.locale
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var amDateTime: String {
        let formatter = DateFormatter()
        formatter.locale = AMLanguage.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var amRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = AMLanguage.current.locale
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    /// Цена в тенге: «12 000 ₸» или «Бесплатно».
    var tenge: String {
        if self == 0 { return L("price.free") }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return (formatter.string(from: NSNumber(value: self)) ?? "\(self)") + " ₸"
    }
}
