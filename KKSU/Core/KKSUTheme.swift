//
//  KKSUTheme.swift
//  KKSU Online
//
//  Цвета, общие компоненты и адаптивный интерфейс (задачи 73, 74).
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum KKSUTheme {
    static let primary = Color(red: 0.0, green: 0.20, blue: 0.49)
    static let primaryHighContrast = Color(red: 0.0, green: 0.08, blue: 0.25)
    static let accent = Color(red: 0.93, green: 0.55, blue: 0.10)
    static let success = Color(red: 0.0, green: 0.50, blue: 0.20)
    static let warning = Color(red: 0.85, green: 0.45, blue: 0.0)
    static let danger = Color(red: 0.75, green: 0.10, blue: 0.10)
    static let background = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let softBlue = Color(red: 0.88, green: 0.92, blue: 1.0)
}

// MARK: - Среда адаптивного интерфейса

extension EnvironmentValues {
    @Entry var kksuAccessibility = AccessibilitySettings()
}

extension AccessibilitySettings {
    var dynamicTypeSize: DynamicTypeSize {
        switch textScale {
        case ..<0.9: return .small
        case ..<1.05: return .large
        case ..<1.2: return .xLarge
        case ..<1.4: return .xxLarge
        case ..<1.6: return .xxxLarge
        case ..<1.8: return .accessibility2
        default: return .accessibility4
        }
    }

    var colorScheme: ColorScheme? {
        switch darkMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var tint: Color { highContrast ? KKSUTheme.primaryHighContrast : KKSUTheme.primary }
}

/// Применяет настройки доступности пользователя ко всему дереву экранов.
struct KKSUAdaptiveModifier: ViewModifier {
    let settings: AccessibilitySettings

    func body(content: Content) -> some View {
        content
            .environment(\.kksuAccessibility, settings)
            .dynamicTypeSize(settings.dynamicTypeSize)
            .fontDesign(settings.dyslexiaFriendlyFont ? .rounded : .default)
            .fontWeight(settings.boldText ? .semibold : nil)
            .tint(settings.tint)
            .preferredColorScheme(settings.colorScheme)
            .transaction { transaction in
                if settings.reduceMotion { transaction.animation = nil }
            }
    }
}

extension View {
    func kksuAdaptive(_ settings: AccessibilitySettings) -> some View {
        modifier(KKSUAdaptiveModifier(settings: settings))
    }
}

// MARK: - Карточка

struct KCard<Content: View>: View {
    @Environment(\.kksuAccessibility) private var a11y
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(a11y.largeButtons ? 20 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(a11y.highContrast ? Color.primary : Color.gray.opacity(0.18), lineWidth: a11y.highContrast ? 2 : 1)
            )
    }
}

struct KSectionHeader: View {
    let title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon).foregroundStyle(.tint) }
            Text(title).font(.title3.bold())
            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct KStatTile: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = KKSUTheme.primary

    var body: some View {
        KCard {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}

struct KBadge: View {
    let text: String
    var color: Color = KKSUTheme.primary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct KProgressBar: View {
    let value: Double
    var color: Color = KKSUTheme.primary

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.18))
                Capsule().fill(color).frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 10)
        .accessibilityElement()
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(Int(value * 100)) процентов")
    }
}

/// Кольцо прогресса (0...1) с процентом в центре.
struct KProgressRing: View {
    let progress: Double
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(KKSUTheme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(KKSUTheme.primary)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Прогресс \(Int(progress * 100)) процентов")
    }
}

struct KEmptyState: View {
    let text: String
    var icon: String = "tray"

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.secondary)
            Text(text).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

struct KAvatar: View {
    let name: String
    var size: CGFloat = 40

    var body: some View {
        let initials = name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
        Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(KKSUTheme.primary.gradient, in: Circle())
            .accessibilityHidden(true)
    }
}

struct KInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}

/// Экран-страница с прокруткой и единым оформлением.
struct KPage<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(16)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
        }
        .background(KKSUTheme.background.opacity(0.6))
        .navigationTitle(title)
    }
}

// MARK: - Вложения (задачи 20, 49, 76)

struct AttachmentRow: View {
    @Environment(\.kksuAccessibility) private var a11y
    let attachment: Attachment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: attachment.kind.icon)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName).font(.callout.weight(.medium))
                Text(attachment.kind.title + (attachment.sizeBytes > 0 ? " · " + ByteCountFormatter.string(fromByteCount: Int64(attachment.sizeBytes), countStyle: .file) : ""))
                    .font(.caption).foregroundStyle(.secondary)
                if (a11y.showTextAlternatives || attachment.kind == .photo || attachment.kind == .drawing), !attachment.altText.isEmpty {
                    Label(attachment.altText, systemImage: "text.below.photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let url = KKSUStore.fileURL(for: attachment) {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Открыть или поделиться файлом")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Кнопки загрузки файлов: фото/видео из галереи и документы (PDF, чертежи, презентации).
struct AttachmentPicker: View {
    @Binding var attachments: [Attachment]
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showImporter = false
    @State private var altText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(attachments) { attachment in
                HStack {
                    AttachmentRow(attachment: attachment)
                    Button(role: .destructive) {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Удалить вложение")
                }
            }
            TextField("Описание для незрячих (текстовая альтернатива)", text: $altText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            HStack {
                PhotosPicker(selection: $photoItems, maxSelectionCount: 5, matching: .any(of: [.images, .videos])) {
                    Label("Фото / видео", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
                Button {
                    showImporter = true
                } label: {
                    Label("Документ / чертёж", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .image, .movie, .presentation, .text, .data], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    if var attachment = KKSUStore.importFile(at: url) {
                        attachment.altText = altText
                        attachments.append(attachment)
                    }
                }
                altText = ""
            }
        }
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            let alt = altText
            Task { @MainActor in
                for (index, item) in items.enumerated() {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
                        let name = isVideo ? "video-\(index + 1).mov" : "photo-\(index + 1).jpg"
                        if var attachment = KKSUStore.storeFile(data: data, fileName: name) {
                            attachment.altText = alt
                            attachments.append(attachment)
                        }
                    }
                }
                photoItems = []
                altText = ""
            }
        }
    }
}

// MARK: - Форматирование

extension Date {
    var kksuShort: String { formatted(date: .abbreviated, time: .omitted) }
    var kksuDateTime: String { formatted(date: .abbreviated, time: .shortened) }
    var kksuTime: String { formatted(date: .omitted, time: .shortened) }
}
