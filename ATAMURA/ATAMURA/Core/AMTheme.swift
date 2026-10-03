//
//  AMTheme.swift
//  ATA MURA
//
//  Цвета, общие компоненты и INCLUSIVE MODE (комфортные режимы интерфейса).
//

import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

enum AMTheme {
    /// Небесно-бирюзовый — цвет флага Казахстана.
    static let sky = Color(red: 0.0, green: 0.62, blue: 0.76)
    static let skyDeep = Color(red: 0.0, green: 0.36, blue: 0.50)
    /// Золото солнца и орнамента.
    static let gold = Color(red: 0.96, green: 0.73, blue: 0.10)
    static let night = Color(red: 0.05, green: 0.12, blue: 0.20)
    static let calm = Color(red: 0.33, green: 0.47, blue: 0.52)
    static let success = Color(red: 0.10, green: 0.55, blue: 0.30)
    static let danger = Color(red: 0.78, green: 0.15, blue: 0.15)

    static var heroGradient: LinearGradient {
        LinearGradient(colors: [skyDeep, sky], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - INCLUSIVE MODE

extension EnvironmentValues {
    @Entry var amMode: AMInclusiveMode = .standard
}

struct AMInclusiveModifier: ViewModifier {
    let mode: AMInclusiveMode

    func body(content: Content) -> some View {
        content
            .environment(\.amMode, mode)
            .dynamicTypeSize(dynamicType)
            .fontDesign(mode == .dyslexia ? .rounded : .default)
            .fontWeight(mode == .lowVision ? .semibold : nil)
            .tint(mode == .asd ? AMTheme.calm : (mode == .lowVision ? AMTheme.night : AMTheme.skyDeep))
            .transaction { transaction in
                // ASD Friendly: без анимаций и неожиданных движений.
                if mode == .asd { transaction.animation = nil }
            }
    }

    private var dynamicType: DynamicTypeSize {
        switch mode {
        case .lowVision: return .accessibility2
        case .dyslexia: return .xLarge
        default: return .large
        }
    }
}

extension View {
    func amInclusive(_ mode: AMInclusiveMode) -> some View {
        modifier(AMInclusiveModifier(mode: mode))
    }
}

/// Основной текст статьи: межстрочный интервал для Dyslexia Friendly.
struct AMBodyText: View {
    @Environment(\.amMode) private var mode
    let text: String

    var body: some View {
        Text(text)
            .lineSpacing(mode == .dyslexia ? 9 : (mode == .lowVision ? 6 : 3))
            .tracking(mode == .dyslexia ? 0.6 : 0)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Озвучивание (Low Vision)

@MainActor
final class AMSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AMSpeaker()
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var speakingId: UUID?

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if !self.synthesizer.isSpeaking { self.speakingId = nil }
        }
    }

    func toggle(_ text: String, id: UUID) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            if speakingId == id { speakingId = nil; return }
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AMLanguage.current.speechCode)
            ?? AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speakingId = id
        synthesizer.speak(utterance)
    }
}

struct AMSpeakButton: View {
    @ObservedObject private var speaker = AMSpeaker.shared
    let text: String
    let id: UUID

    var body: some View {
        Button {
            speaker.toggle(text, id: id)
        } label: {
            Label(speaker.speakingId == id ? L("common.stop") : L("common.listen"),
                  systemImage: speaker.speakingId == id ? "stop.circle.fill" : "speaker.wave.2.fill")
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Карточки и заголовки

struct AMCard<Content: View>: View {
    @Environment(\.amMode) private var mode
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(mode == .lowVision ? Color.primary.opacity(0.6) : Color.primary.opacity(0.06),
                        lineWidth: mode == .lowVision ? 2 : 1))
    }
}

struct AMSectionHeader: View {
    let title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon).foregroundStyle(AMTheme.gold) }
            Text(title).font(.title3.bold())
            Spacer()
        }
        .padding(.top, 6)
        .accessibilityAddTraits(.isHeader)
    }
}

struct AMTag: View {
    let text: String
    var icon: String?
    var color: Color = AMTheme.skyDeep

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.12), in: Capsule())
    }
}

struct AMEmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.secondary)
            Text(text).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}

struct AMAvatar: View {
    let user: AMUser?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = user?.avatar, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    AMTheme.heroGradient
                    Text(user?.initials ?? "?").font(.system(size: size * 0.38, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// Строка «иконка + число» для профиля и аналитики.
struct AMStatTile: View {
    let value: String
    let title: String
    var icon: String?

    var body: some View {
        VStack(spacing: 4) {
            if let icon { Image(systemName: icon).foregroundStyle(AMTheme.gold) }
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Изображения

enum AMImageTools {
    /// Уменьшает фото до 1400 px и сжимает в JPEG, чтобы база оставалась лёгкой.
    static func compress(_ data: Data, maxSide: CGFloat = 1400) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

struct AMImageView: View {
    let data: Data
    var height: CGFloat = 200

    var body: some View {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(L("common.photo"))
        }
    }
}

struct AMImageStrip: View {
    let images: [Data]
    var height: CGFloat = 220

    var body: some View {
        if images.count == 1, let first = images.first {
            AMImageView(data: first, height: height)
        } else if !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(images.indices, id: \.self) { index in
                        AMImageView(data: images[index], height: height).frame(width: height * 1.3)
                    }
                }
            }
        }
    }
}

/// Кнопка выбора фото из галереи; добавляет сжатые изображения в массив.
struct AMPhotoPicker: View {
    @Binding var images: [Data]
    var limit = 6
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(images.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                if let image = UIImage(data: images[index]) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                        .frame(width: 90, height: 90).clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                Button {
                                    images.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .accessibilityLabel(L("common.delete"))
                            }
                        }
                    }
                }
            }
            PhotosPicker(selection: $selection, maxSelectionCount: max(limit - images.count, 1), matching: .images) {
                Label(L("common.addPhoto"), systemImage: "photo.badge.plus")
            }
            .disabled(images.count >= limit)
        }
        .onChange(of: selection) { _, items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self), let compressed = AMImageTools.compress(data) {
                        images.append(compressed)
                    }
                }
                selection = []
            }
        }
    }
}

/// Одно изображение (обложка, аватар).
struct AMSinglePhotoPicker: View {
    let title: String
    @Binding var image: Data?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading) {
            if let image { AMImageView(data: image, height: 140) }
            HStack {
                PhotosPicker(selection: $selection, matching: .images) {
                    Label(title, systemImage: "photo")
                }
                if image != nil {
                    Spacer()
                    Button(L("common.delete"), role: .destructive) { image = nil }
                }
            }
        }
        .onChange(of: selection) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    image = AMImageTools.compress(data)
                }
                selection = nil
            }
        }
    }
}

// MARK: - Поля ввода

struct AMTextArea: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(title)
        }
    }
}

/// Поле для списка через запятую (теги, навыки).
struct AMListField: View {
    let title: String
    @Binding var items: [String]

    var body: some View {
        TextField(title, text: Binding(
            get: { items.joined(separator: ", ") },
            set: { items = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        ))
    }
}

/// Перенос тегов по строкам.
struct AMFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxX, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Статус модерации

struct AMStatusBadge: View {
    let status: AMModerationStatus

    var body: some View {
        if status != .approved {
            AMTag(text: status.title, icon: status.icon, color: status == .rejected ? AMTheme.danger : .orange)
        }
    }
}

struct AMVerificationBadge: View {
    let verification: AMVerification

    var body: some View {
        if verification != .none {
            AMTag(text: verification.title, icon: verification.icon,
                  color: verification == .verifiedFact || verification == .sourceConfirmed ? AMTheme.success : .purple)
        }
    }
}

/// Кнопка ссылки (YouTube, PDF, сайт).
struct AMLinkButton: View {
    let title: String
    let url: String
    var icon = "link"

    var body: some View {
        if let link = URL(string: url.trimmingCharacters(in: .whitespaces)), link.scheme?.hasPrefix("http") == true {
            Link(destination: link) {
                Label(title, systemImage: icon)
            }
            .buttonStyle(.bordered)
        }
    }
}
