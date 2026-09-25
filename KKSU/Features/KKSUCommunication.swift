//
//  KKSUCommunication.swift
//  KKSU Online
//
//  Внутренний чат ученик–преподаватель (34) и уведомления (35).
//

import SwiftUI

// MARK: - Список диалогов

struct ChatListView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var showNew = false

    var body: some View {
        let me = store.currentUser?.id
        let threads = store.db.threads.filter { thread in me.map { thread.participantIDs.contains($0) } ?? false }
            .sorted { lastDate($0) > lastDate($1) }
        List {
            if threads.isEmpty {
                KEmptyState(text: "Диалогов пока нет. Начните новый.", icon: "bubble.left.and.bubble.right")
            }
            ForEach(threads) { thread in
                let other = thread.participantIDs.first { $0 != me }
                let last = store.db.messages.filter { $0.threadID == thread.id }.max { $0.date < $1.date }
                let unread = store.db.messages.filter { message in
                    guard let me else { return false }
                    return message.threadID == thread.id && !message.readBy.contains(me)
                }.count
                NavigationLink { ChatThreadView(threadID: thread.id) } label: {
                    HStack(spacing: 12) {
                        KAvatar(name: store.userName(other), size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(store.userName(other)).font(.headline)
                                Text(store.user(other)?.role.title ?? "").font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(last?.text ?? "Нет сообщений").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        if unread > 0 {
                            Text("\(unread)").font(.caption.bold()).foregroundStyle(.white)
                                .padding(6).background(KKSUTheme.danger, in: Circle())
                        }
                    }
                }
            }
        }
        .navigationTitle("Сообщения")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel("Новый диалог")
            }
        }
        .sheet(isPresented: $showNew) {
            NavigationStack { NewChatView() }
        }
    }

    private func lastDate(_ thread: ChatThread) -> Date {
        store.db.messages.filter { $0.threadID == thread.id }.map(\.date).max() ?? .distantPast
    }
}

struct NewChatView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss

    /// Ученик пишет педагогам, наставникам и психологу; родитель — педагогам; сотрудники — всем.
    private var contacts: [KKSUUser] {
        let me = store.currentUser
        let staff: Set<KKSURole> = [.teacher, .mentor, .psychologist, .admin]
        return store.db.users.filter { user in
            guard user.id != me?.id else { return false }
            switch me?.role {
            case .student, .parent: return staff.contains(user.role)
            default: return true
            }
        }
    }

    var body: some View {
        List(contacts) { user in
            NavigationLink { ChatThreadView(otherID: user.id) } label: {
                HStack {
                    KAvatar(name: user.fullName, size: 36)
                    VStack(alignment: .leading) {
                        Text(user.fullName)
                        Text(user.role.title).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Новый диалог")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
    }
}

// MARK: - Диалог

struct ChatThreadView: View {
    @EnvironmentObject private var store: KKSUStore
    private let fixedThreadID: UUID?
    private let otherID: UUID?
    @State private var createdThreadID: UUID?
    @State private var text = ""

    init(threadID: UUID) {
        fixedThreadID = threadID
        otherID = nil
    }

    init(otherID: UUID) {
        fixedThreadID = nil
        self.otherID = otherID
    }

    private var threadID: UUID? {
        if let fixedThreadID { return fixedThreadID }
        if let createdThreadID { return createdThreadID }
        guard let otherID, let me = store.currentUser?.id else { return nil }
        return store.db.threads.first { Set($0.participantIDs) == Set([me, otherID]) }?.id
    }

    var body: some View {
        let me = store.currentUser?.id
        let messages = threadID.map { id in store.db.messages.filter { $0.threadID == id }.sorted { $0.date < $1.date } } ?? []
        let partner = otherID ?? store.db.threads.first { $0.id == threadID }?.participantIDs.first { $0 != me }
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if messages.isEmpty {
                            KEmptyState(text: "Напишите первое сообщение", icon: "bubble.left")
                        }
                        ForEach(messages) { message in
                            ChatBubble(message: message, isMine: message.senderID == me)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    markRead()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            Divider()
            HStack(spacing: 10) {
                TextField("Сообщение", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                Button {
                    send()
                } label: {
                    Image(systemName: "paperplane.fill").font(.title3)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Отправить")
            }
            .padding(12)
        }
        .navigationTitle(store.userName(partner))
    }

    private func send() {
        var id = threadID
        if id == nil, let otherID {
            id = store.thread(with: otherID).id
            createdThreadID = id
        }
        guard let id else { return }
        store.send(text, in: id)
        text = ""
    }

    private func markRead() {
        guard let me = store.currentUser?.id, let threadID else { return }
        for index in store.db.messages.indices where store.db.messages[index].threadID == threadID && !store.db.messages[index].readBy.contains(me) {
            store.db.messages[index].readBy.append(me)
        }
    }
}

struct ChatBubble: View {
    @EnvironmentObject private var store: KKSUStore
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .foregroundStyle(isMine ? Color.white : Color.primary)
                    .background(isMine ? KKSUTheme.primary : Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                Text(message.date.kksuDateTime).font(.caption2).foregroundStyle(.secondary)
            }
            if !isMine { Spacer(minLength: 40) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isMine ? "Вы" : store.userName(message.senderID)): \(message.text)")
    }
}

// MARK: - Уведомления (задача 35)

struct NotificationsView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        List {
            if store.myNotifications.isEmpty {
                KEmptyState(text: "Уведомлений нет", icon: "bell.slash")
            }
            ForEach(store.myNotifications) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.kind.icon)
                        .foregroundStyle(item.isRead ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                        .font(.title3)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(item.isRead ? .body : .body.bold())
                        Text(item.body).font(.callout).foregroundStyle(.secondary)
                        Text(item.date.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        store.db.notifications.removeAll { $0.id == item.id }
                    } label: { Label("Удалить", systemImage: "trash") }
                }
                .onTapGesture {
                    if let index = store.db.notifications.firstIndex(where: { $0.id == item.id }) {
                        store.db.notifications[index].isRead = true
                    }
                }
            }
        }
        .navigationTitle("Уведомления")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Прочитать все") { store.markAllRead() }
                    .disabled(store.unreadCount == 0)
            }
        }
    }
}
