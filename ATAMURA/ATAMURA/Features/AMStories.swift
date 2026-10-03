//
//  AMStories.swift
//  ATA MURA
//
//  100 PEOPLE — 100 STORIES: истории обычных людей (фото, документы, рассказ, аудио, видео).
//  Лучшие истории редакция отбирает в книгу «100 People — 100 Stories — 100 Ideas of Kazakhstan».
//

import SwiftUI

struct AMStoriesView: View {
    @EnvironmentObject private var store: AMStore
    @State private var showEditor = false
    @State private var onlyBook = false

    private var stories: [AMPost] {
        store.visiblePosts.filter { ($0.type == .familyStory || $0.type == .person) && (!onlyBook || $0.selectedForBook) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AMCard {
                    Text("100 People — 100 Stories — 100 Ideas of Kazakhstan").font(.headline)
                    Text(L("stories.about")).font(.callout).foregroundStyle(.secondary)
                    let selected = store.db.posts.filter(\.selectedForBook).count
                    ProgressView(value: Double(min(selected, 100)), total: 100) {
                        Text(L("stories.book", selected)).font(.caption)
                    }
                    Button {
                        showEditor = true
                    } label: {
                        Label(L("create.story"), systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Toggle(L("stories.onlyBook"), isOn: $onlyBook)
                if stories.isEmpty { AMEmptyState(icon: "person.2", text: L("stories.empty")) }
                ForEach(stories) { post in
                    NavigationLink { AMPostDetailView(postId: post.id) } label: {
                        AMCard {
                            HStack(alignment: .top, spacing: 12) {
                                if let image = post.images.first, let ui = UIImage(data: image) {
                                    Image(uiImage: ui).resizable().scaledToFill().frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Image(systemName: "person.crop.square.fill").font(.system(size: 56)).foregroundStyle(AMTheme.sky.opacity(0.6))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.title).font(.headline).multilineTextAlignment(.leading)
                                    if !post.heroName.isEmpty {
                                        Text("\(post.heroName) \(post.heroYears)").font(.subheadline)
                                    }
                                    Text(post.authorName).font(.caption).foregroundStyle(.secondary)
                                    HStack {
                                        if post.selectedForBook { AMTag(text: L("stories.inBook"), icon: "book.fill", color: AMTheme.gold) }
                                        AMStatusBadge(status: post.status)
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("100 Stories")
        .sheet(isPresented: $showEditor) {
            NavigationStack { AMPostEditorView(type: .familyStory) }
        }
    }
}
