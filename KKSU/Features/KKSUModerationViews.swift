//
//  KKSUModerationViews.swift
//  KKSU Online
//
//  Жалобы на контент, блокировка пользователей, модерация (администратор)
//  и удаление аккаунта из приложения (App Store Guidelines 1.2 и 5.1.1(v)).
//

import SwiftUI

// MARK: - Жалоба

struct ReportTarget: Identifiable {
    let id = UUID()
    let kind: ReportedContentKind
    let contentID: UUID?
    let reportedUserID: UUID?
    let excerpt: String
}

struct ReportContentSheet: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss
    let target: ReportTarget
    @State private var reason: ReportReason = .harassment
    @State private var comment = ""
    @State private var alsoBlock = true
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Form {
                if sent {
                    Section {
                        Label("Жалоба отправлена", systemImage: "checkmark.seal.fill").foregroundStyle(KKSUTheme.success)
                        Text("Модератор KKSU рассмотрит её в течение 24 часов. Этот контент уже скрыт у вас.")
                            .font(.callout)
                    }
                } else {
                    Section(target.kind.title) {
                        Text(target.excerpt).lineLimit(4).foregroundStyle(.secondary)
                        if let user = target.reportedUserID {
                            KInfoRow(label: "Автор", value: store.userName(user))
                        }
                    }
                    Section("Причина") {
                        Picker("Причина", selection: $reason) {
                            ForEach(ReportReason.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        TextField("Комментарий (необязательно)", text: $comment, axis: .vertical)
                    }
                    if let user = target.reportedUserID, user != store.currentUser?.id {
                        Section {
                            Toggle("Заблокировать \(store.userName(user))", isOn: $alsoBlock)
                        } footer: {
                            Text("Вы больше не увидите сообщения и публикации этого пользователя. Разблокировать можно в «Профиль → Заблокированные пользователи».")
                        }
                    }
                }
            }
            .navigationTitle("Пожаловаться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(sent ? "Готово" : "Отмена") { dismiss() } }
                if !sent {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Отправить") {
                            store.report(target.kind, contentID: target.contentID, reportedUserID: target.reportedUserID,
                                         excerpt: target.excerpt, reason: reason, comment: comment,
                                         alsoBlock: alsoBlock && target.reportedUserID != nil)
                            sent = true
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Заблокированные пользователи

struct BlockedUsersView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        List {
            let blocked = store.blockedUserIDs.sorted { store.userName($0) < store.userName($1) }
            if blocked.isEmpty {
                KEmptyState(text: "Вы никого не блокировали", icon: "hand.raised")
            }
            ForEach(blocked, id: \.self) { userID in
                HStack {
                    KAvatar(name: store.userName(userID), size: 36)
                    Text(store.userName(userID))
                    Spacer()
                    Button("Разблокировать") { store.unblockUser(userID) }
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Заблокированные")
    }
}

// MARK: - Модерация (администратор)

struct ModerationView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showClosed = false

    var body: some View {
        let reports = showClosed
            ? store.db.contentReports.filter { $0.status != .open }.sorted { $0.createdAt > $1.createdAt }
            : store.openReports
        List {
            Picker("", selection: $showClosed) {
                Text("Новые · \(store.openReports.count)").tag(false)
                Text("Рассмотренные").tag(true)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            if reports.isEmpty {
                KEmptyState(text: showClosed ? "Рассмотренных жалоб нет" : "Новых жалоб нет", icon: "checkmark.shield")
            }
            ForEach(reports) { report in
                ReportRow(report: report)
            }
        }
        .navigationTitle("Модерация")
    }
}

private struct ReportRow: View {
    @EnvironmentObject private var store: KKSUStore
    let report: ContentReport
    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(report.kind.title, systemImage: report.kind.icon).font(.headline)
                Spacer()
                KBadge(text: report.status.title, color: report.status == .open ? KKSUTheme.danger : .secondary)
            }
            Text(report.reason.title).font(.subheadline.weight(.semibold)).foregroundStyle(KKSUTheme.danger)
            Text(report.excerpt).font(.callout).lineLimit(5)
            if !report.comment.isEmpty { Text("Комментарий: \(report.comment)").font(.caption) }
            Text("От: \(store.userName(report.reporterID)) · на: \(store.userName(report.reportedUserID)) · \(report.createdAt.kksuDateTime)")
                .font(.caption).foregroundStyle(.secondary)
            if report.status == .open {
                HStack {
                    if report.kind != .user {
                        Button("Удалить контент") { store.removeReportedContent(report.id) }
                            .buttonStyle(.borderedProminent).tint(KKSUTheme.warning)
                    }
                    if report.reportedUserID != nil {
                        Button("Заблокировать автора") {
                            working = true
                            Task {
                                await store.banReportedUser(report.id)
                                working = false
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(KKSUTheme.danger)
                        .disabled(working)
                    }
                    Button("Отклонить") { store.closeReport(report.id, status: .dismissed, resolution: "Нарушений не найдено") }
                        .buttonStyle(.bordered)
                }
                .font(.caption)
            } else if !report.resolution.isEmpty {
                Text(report.resolution).font(.caption).foregroundStyle(KKSUTheme.success)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Удаление аккаунта

struct DeleteAccountButton: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var confirm = false
    @State private var deleting = false
    @State private var errorText: String?

    var body: some View {
        Button(role: .destructive) {
            confirm = true
        } label: {
            HStack {
                Label("Удалить аккаунт", systemImage: "person.crop.circle.badge.xmark")
                if deleting { Spacer(); ProgressView() }
            }
        }
        .disabled(deleting)
        .confirmationDialog("Удалить аккаунт навсегда?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Удалить аккаунт", role: .destructive) { delete() }
        } message: {
            Text("Профиль, работы, сообщения и другие данные будут удалены без возможности восстановления. Активные подписки App Store отменяются в настройках Apple ID.")
        }
        .alert("Не удалось удалить аккаунт", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorText ?? "")
        }
    }

    private func delete() {
        guard let id = store.currentUser?.id else { return }
        guard KKSUCloud.shared.isSignedIn else {
            store.deleteAccount(id)
            return
        }
        deleting = true
        Task {
            do {
                try await KKSUCloud.shared.deleteAccount()
                store.deleteAccount(id)
            } catch {
                errorText = "\(error.localizedDescription)\nПроверьте интернет и попробуйте ещё раз."
            }
            deleting = false
        }
    }
}
