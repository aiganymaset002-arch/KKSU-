//
//  AMAssistant.swift
//  ATA MURA
//
//  AI ATA MURA: встроенный помощник. Ребёнок описывает идею — AI отвечает:
//  проблема, возможное решение, что изучить, первый прототип — и предлагает
//  «Создать проект ATA MURA» с готовой карточкой.
//

import SwiftUI

struct AMAssistantView: View {
    var body: some View {
        NavigationStack { AMAssistantScreen() }
    }
}

struct AMAssistantScreen: View {
    @EnvironmentObject private var store: AMStore
    @ObservedObject private var ai = AMAI.shared
    @State private var text = ""
    @State private var thinking = false
    @State private var draftBox: AMDraftBox?

    private let examples = ["ai.example.1", "ai.example.2", "ai.example.3"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.aiChat.isEmpty {
                            AMCard {
                                Label("AI ATA MURA", systemImage: "sparkles").font(.headline)
                                Text(L("ai.intro")).font(.callout)
                                if !ai.isConfigured {
                                    Text(L("ai.localMode")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            ForEach(examples, id: \.self) { key in
                                Button {
                                    text = L(key)
                                } label: {
                                    Text(L(key)).font(.callout).multilineTextAlignment(.leading)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AMTheme.sky.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ForEach(store.aiChat) { message in
                            bubble(message).id(message.id)
                        }
                        if thinking {
                            HStack { ProgressView(); Text(L("ai.thinking")).foregroundStyle(.secondary) }
                        }
                    }
                    .padding()
                }
                .onChange(of: store.aiChat.count) { _, _ in
                    if let last = store.aiChat.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            Divider()
            HStack(alignment: .bottom) {
                TextField(L("ai.placeholder"), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || thinking)
                .accessibilityLabel(L("common.send"))
            }
            .padding()
        }
        .navigationTitle("AI ATA MURA")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.aiChat.isEmpty {
                Button(L("ai.new")) { store.aiChat = [] }
            }
        }
        .sheet(item: $draftBox) { box in
            NavigationStack { AMProjectEditorView(draft: box.draft) }
        }
    }

    private func send() {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        store.aiChat.append(AMChatMessage(isUser: true, text: question))
        text = ""
        thinking = true
        Task {
            let reply = await AMAI.shared.inventorReply(history: store.aiChat)
            store.aiChat.append(reply)
            thinking = false
        }
    }

    @ViewBuilder
    private func bubble(_ message: AMChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text).textSelection(.enabled)
                if let draft = message.projectDraft {
                    Button {
                        draftBox = AMDraftBox(draft: draft)
                    } label: {
                        Label(L("ai.createProject"), systemImage: "lightbulb.max.fill").bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AMTheme.gold)
                    .foregroundStyle(AMTheme.night)
                }
                if !message.isUser {
                    AMSpeakButton(text: message.text, id: message.id).controlSize(.small)
                }
            }
            .padding(12)
            .foregroundStyle(message.isUser ? .white : .primary)
            .background(message.isUser ? AnyShapeStyle(AMTheme.skyDeep) : AnyShapeStyle(Color(.secondarySystemBackground)),
                        in: RoundedRectangle(cornerRadius: 16))
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

private struct AMDraftBox: Identifiable {
    let id = UUID()
    let draft: AMProjectDraft
}
