//
//  AMCreatorStudio.swift
//  ATA MURA
//
//  ATA MURA CREATOR STUDIO: контент-календарь (YouTube, Shorts, TikTok, Instagram, LinkedIn,
//  платформа), рабочая карточка ролика, Банк идей с AI, Vlog Diary, People & Guests,
//  Series, Media Library, Analytics и задачи.
//

import SwiftUI
import Charts
import UserNotifications

// MARK: - Контент-календарь

struct AMContentCalendarView: View {
    @EnvironmentObject private var store: AMStore
    @State private var month = Date()
    @State private var status: AMContentStatus?
    @State private var editing: AMContentItem?

    private var calendar: Calendar { Calendar.current }

    private var items: [AMContentItem] {
        store.db.contentItems.filter { item in
            let date = item.publishDate ?? item.shootDate ?? item.createdAt
            return calendar.isDate(date, equalTo: month, toGranularity: .month) && (status == nil || item.status == status)
        }
        .sorted { ($0.publishDate ?? $0.shootDate ?? $0.createdAt) < ($1.publishDate ?? $1.shootDate ?? $1.createdAt) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Button { month = calendar.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(monthTitle).font(.headline)
                    Spacer()
                    Button { month = calendar.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }
                }
                .buttonStyle(.borderless)
                monthGrid
                Picker(L("studio.status"), selection: $status) {
                    Text(L("common.all")).tag(AMContentStatus?.none)
                    ForEach(AMContentStatus.allCases) { Label($0.title, systemImage: $0.icon).tag(AMContentStatus?.some($0)) }
                }
            }
            Section(L("studio.pipeline")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AMContentStatus.allCases) { option in
                            let count = store.db.contentItems.filter { $0.status == option }.count
                            VStack {
                                Image(systemName: option.icon)
                                Text("\(count)").font(.headline)
                                Text(option.title).font(.caption2)
                            }
                            .frame(width: 74)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            Section(L("studio.videos")) {
                if items.isEmpty { Text(L("studio.empty")).foregroundStyle(.secondary) }
                ForEach(items) { item in
                    Button { editing = item } label: { AMContentRow(item: item) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    let ids = offsets.map { items[$0].id }
                    store.db.contentItems.removeAll { ids.contains($0.id) }
                }
            }
        }
        .navigationTitle("Content Calendar")
        .toolbar {
            Button {
                var item = AMContentItem(title: "")
                item.publishDate = month
                editing = item
            } label: { Image(systemName: "plus") }
        }
        .sheet(item: $editing) { item in
            NavigationStack { AMContentEditorView(item: item) }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = AMLanguage.current.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month).capitalized
    }

    /// Сетка месяца: точки в дни съёмок (синие) и публикаций (золотые).
    private var monthGrid: some View {
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<31
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
            ForEach(0..<(offset + range.count), id: \.self) { index in
                if index < offset {
                    Color.clear.frame(height: 34)
                } else {
                    let day = index - offset + 1
                    let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                    let shoots = store.db.contentItems.contains { $0.shootDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
                    let publishes = store.db.contentItems.contains { $0.publishDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
                    VStack(spacing: 2) {
                        Text("\(day)").font(.caption).fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                        HStack(spacing: 2) {
                            Circle().fill(shoots ? AMTheme.sky : .clear).frame(width: 5, height: 5)
                            Circle().fill(publishes ? AMTheme.gold : .clear).frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 34)
                    .frame(maxWidth: .infinity)
                    .background(calendar.isDateInToday(date) ? AMTheme.sky.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

struct AMContentRow: View {
    @EnvironmentObject private var store: AMStore
    let item: AMContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: item.status.icon)
                Text(item.title.isEmpty ? L("studio.untitled") : item.title).font(.headline)
            }
            HStack {
                AMTag(text: item.status.title)
                Text(item.platforms.map(\.title).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if let shoot = item.shootDate { Label(shoot.amDate, systemImage: "video").font(.caption) }
                if let publish = item.publishDate { Label(publish.amDate, systemImage: "paperplane").font(.caption) }
                if let series = store.db.series.first(where: { $0.id == item.seriesId }) {
                    Label(series.name, systemImage: "rectangle.stack").font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

/// Рабочая карточка ролика: идея → цель → аудитория → название → хук → сценарий → кадры →
/// вопросы → реквизит → место → участники → музыка → обложка → описание → хэштеги → ссылки → результат.
struct AMContentEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var item: AMContentItem
    @State private var hasShoot = false
    @State private var hasPublish = false
    @State private var aiResult = ""
    @State private var aiBusy = false

    var body: some View {
        Form {
            Section {
                TextField(L("studio.title"), text: $item.title, axis: .vertical)
                Picker(L("studio.status"), selection: $item.status) {
                    ForEach(AMContentStatus.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                Picker(L("admin.series"), selection: $item.seriesId) {
                    Text(L("common.notSelected")).tag(UUID?.none)
                    ForEach(store.db.series) { Text($0.name).tag(UUID?.some($0.id)) }
                }
                ForEach(AMPlatform.allCases) { platform in
                    Toggle(platform.title, isOn: Binding(
                        get: { item.platforms.contains(platform) },
                        set: { on in
                            if on { item.platforms.append(platform) } else { item.platforms.removeAll { $0 == platform } }
                        }))
                }
            }
            Section(L("studio.dates")) {
                Toggle(L("studio.shootDate"), isOn: $hasShoot)
                if hasShoot {
                    DatePicker(L("studio.shootDate"), selection: Binding(get: { item.shootDate ?? Date() }, set: { item.shootDate = $0 }))
                }
                Toggle(L("studio.publishDate"), isOn: $hasPublish)
                if hasPublish {
                    DatePicker(L("studio.publishDate"), selection: Binding(get: { item.publishDate ?? Date() }, set: { item.publishDate = $0 }))
                }
                Toggle(L("studio.reminder"), isOn: $item.reminder)
                TextField(L("studio.responsible"), text: $item.responsible)
            }
            Section(L("studio.card")) {
                AMTextArea(title: L("studio.idea"), text: $item.idea, minHeight: 60)
                TextField(L("studio.goal"), text: $item.goal, axis: .vertical)
                TextField(L("studio.audience"), text: $item.audience, axis: .vertical)
                TextField(L("studio.hook"), text: $item.hook, axis: .vertical)
                AMTextArea(title: L("studio.script"), text: $item.script, minHeight: 160)
                AMTextArea(title: L("studio.shotList"), text: $item.shotList, minHeight: 80)
                AMTextArea(title: L("studio.questions"), text: $item.interviewQuestions, minHeight: 80)
                TextField(L("studio.props"), text: $item.props, axis: .vertical)
                TextField(L("studio.location"), text: $item.location)
                TextField(L("studio.participants"), text: $item.participants, axis: .vertical)
                TextField(L("studio.music"), text: $item.music)
                AMSinglePhotoPicker(title: L("studio.cover"), image: $item.cover)
                AMTextArea(title: L("studio.description"), text: $item.descriptionText, minHeight: 80)
                TextField(L("studio.hashtags"), text: $item.hashtags)
                TextField(L("studio.links"), text: $item.links, axis: .vertical)
            }
            Section(L("admin.guests")) {
                ForEach(store.db.guests) { guest in
                    Toggle(guest.name, isOn: Binding(
                        get: { item.guestIds.contains(guest.id) },
                        set: { on in
                            if on { item.guestIds.append(guest.id) } else { item.guestIds.removeAll { $0 == guest.id } }
                        }))
                }
            }
            Section {
                Button {
                    Task {
                        aiBusy = true
                        aiResult = await AMAI.shared.ideaSuggestions(for: item.title.isEmpty ? item.idea : item.title)
                        aiBusy = false
                    }
                } label: {
                    if aiBusy { ProgressView() } else { Label(L("studio.aiHelp"), systemImage: "sparkles") }
                }
                .disabled(item.title.isEmpty && item.idea.isEmpty)
                if !aiResult.isEmpty {
                    Text(aiResult).font(.callout).textSelection(.enabled)
                    Button(L("studio.aiToScript")) { item.script += (item.script.isEmpty ? "" : "\n\n") + aiResult }
                }
            }
            Section(L("studio.result")) {
                LabeledContent(L("analytics.views")) {
                    TextField(L("analytics.views"), value: $item.views, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                TextField(L("studio.likes"), value: $item.likes, format: .number).keyboardType(.numberPad)
                TextField(L("studio.comments"), value: $item.comments, format: .number).keyboardType(.numberPad)
                TextField(L("studio.subscribers"), value: $item.newSubscribers, format: .number).keyboardType(.numberPad)
                AMTextArea(title: L("studio.resultNotes"), text: $item.resultNotes, minHeight: 60)
            }
        }
        .navigationTitle(item.title.isEmpty ? L("studio.newVideo") : item.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hasShoot = item.shootDate != nil
            hasPublish = item.publishDate != nil
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    if !hasShoot { item.shootDate = nil }
                    if !hasPublish { item.publishDate = nil }
                    if let index = store.db.contentItems.firstIndex(where: { $0.id == item.id }) {
                        store.db.contentItems[index] = item
                    } else {
                        store.db.contentItems.append(item)
                    }
                    if item.reminder { AMReminders.schedule(item) }
                    dismiss()
                }
                .disabled(item.title.isEmpty)
            }
        }
    }
}

/// Локальные напоминания о съёмке и публикации.
enum AMReminders {
    static func schedule(_ item: AMContentItem) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let pairs: [(Date?, String, String)] = [(item.shootDate, "shoot", L("reminder.shoot", item.title)),
                                                    (item.publishDate, "publish", L("reminder.publish", item.title))]
            for (date, kind, text) in pairs {
                guard let date, date > Date() else { continue }
                let content = UNMutableNotificationContent()
                content.title = "ATA MURA Studio"
                content.body = text
                content.sound = .default
                let fire = Calendar.current.date(byAdding: .hour, value: -2, to: date) ?? date
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: max(fire, Date().addingTimeInterval(60)))
                let request = UNNotificationRequest(identifier: "\(item.id)-\(kind)", content: content,
                                                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
                center.add(request)
            }
        }
    }
}

// MARK: - Банк идей

struct AMIdeaBankView: View {
    @EnvironmentObject private var store: AMStore
    @State private var text = ""
    @State private var busyId: UUID?
    @State private var editing: AMContentItem?

    var body: some View {
        List {
            Section {
                TextField(L("ideas.placeholder"), text: $text, axis: .vertical)
                Button(L("ideas.save")) {
                    store.db.ideas.insert(AMIdea(text: text), at: 0)
                    text = ""
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ForEach(store.db.ideas) { idea in
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.text).font(.headline)
                    Text(idea.createdAt.amDate).font(.caption2).foregroundStyle(.secondary)
                    if !idea.aiSuggestion.isEmpty {
                        DisclosureGroup(L("ideas.aiResult")) {
                            Text(idea.aiSuggestion).font(.callout).textSelection(.enabled)
                        }
                    }
                    HStack {
                        Button {
                            Task {
                                busyId = idea.id
                                let result = await AMAI.shared.ideaSuggestions(for: idea.text)
                                if let index = store.db.ideas.firstIndex(where: { $0.id == idea.id }) {
                                    store.db.ideas[index].aiSuggestion = result
                                }
                                busyId = nil
                            }
                        } label: {
                            if busyId == idea.id { ProgressView() } else { Label("AI", systemImage: "sparkles") }
                        }
                        .buttonStyle(.bordered)
                        if idea.contentItemId == nil {
                            Button {
                                var item = AMContentItem(title: idea.text)
                                item.idea = idea.text
                                item.script = idea.aiSuggestion
                                store.db.contentItems.append(item)
                                if let index = store.db.ideas.firstIndex(where: { $0.id == idea.id }) {
                                    store.db.ideas[index].contentItemId = item.id
                                }
                                editing = item
                            } label: {
                                Label(L("ideas.toCalendar"), systemImage: "calendar.badge.plus")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            AMTag(text: L("ideas.inCalendar"), icon: "checkmark")
                        }
                    }
                }
            }
            .onDelete { store.db.ideas.remove(atOffsets: $0) }
        }
        .navigationTitle(L("admin.ideas"))
        .sheet(item: $editing) { item in NavigationStack { AMContentEditorView(item: item) } }
    }
}

// MARK: - Vlog Diary

struct AMVlogDiaryView: View {
    @EnvironmentObject private var store: AMStore
    @State private var entry = AMVlogEntry()
    @State private var plan = ""
    @State private var busy = false

    private var weekEntries: [AMVlogEntry] {
        store.db.vlog.filter { $0.date > Date().addingTimeInterval(-7 * 86_400) }
    }

    var body: some View {
        List {
            Section(L("vlog.today")) {
                DatePicker(L("vlog.date"), selection: $entry.date, displayedComponents: .date)
                TextField(L("vlog.happened"), text: $entry.happened, axis: .vertical)
                TextField(L("vlog.meetings"), text: $entry.meetings, axis: .vertical)
                TextField(L("vlog.filmed"), text: $entry.filmed, axis: .vertical)
                TextField(L("vlog.quote"), text: $entry.quote, axis: .vertical)
                TextField(L("vlog.forAudience"), text: $entry.forAudience, axis: .vertical)
                AMPhotoPicker(images: $entry.photos, limit: 4)
                Button(L("common.save")) {
                    store.db.vlog.insert(entry, at: 0)
                    entry = AMVlogEntry()
                }
                .disabled(entry.happened.isEmpty)
            }
            Section {
                Button {
                    Task {
                        busy = true
                        plan = await AMAI.shared.vlogEpisodePlan(weekEntries)
                        busy = false
                    }
                } label: {
                    if busy { ProgressView() } else { Label(L("vlog.makePlan"), systemImage: "sparkles") }
                }
                .disabled(weekEntries.isEmpty)
                if !plan.isEmpty {
                    Text(plan).font(.callout).textSelection(.enabled)
                    Button(L("vlog.toCalendar")) {
                        var item = AMContentItem(title: "ATA MURA Vlog — \(Date().amDate)", platforms: [.youtube])
                        item.script = plan
                        item.status = .editing
                        store.db.contentItems.append(item)
                    }
                }
            } header: {
                Text(L("vlog.weekPlan"))
            }
            Section(L("vlog.history")) {
                ForEach(store.db.vlog) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.date.amDate).font(.caption.bold())
                        Text(item.happened)
                        if !item.quote.isEmpty { Text("«\(item.quote)»").font(.callout).italic() }
                        AMImageStrip(images: item.photos, height: 80)
                    }
                }
                .onDelete { store.db.vlog.remove(atOffsets: $0) }
            }
        }
        .navigationTitle("Vlog Diary")
    }
}

// MARK: - People & Guests

struct AMGuestsView: View {
    @EnvironmentObject private var store: AMStore
    @State private var editing: AMGuest?

    var body: some View {
        List {
            ForEach(AMGuestStatus.allCases, id: \.self) { status in
                let guests = store.db.guests.filter { $0.status == status }
                if !guests.isEmpty {
                    Section(status.title) {
                        ForEach(guests) { guest in
                            Button { editing = guest } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(guest.name).font(.headline).foregroundStyle(.primary)
                                    Text("\(guest.category.title) · \(guest.topic)").font(.caption).foregroundStyle(.secondary)
                                    if let date = guest.shootDate { Label(date.amDate, systemImage: "video").font(.caption) }
                                    let episodes = store.db.contentItems.filter { $0.guestIds.contains(guest.id) }
                                    if !episodes.isEmpty {
                                        Text(L("guests.appeared") + ": " + episodes.map(\.title).joined(separator: ", ")).font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if store.db.guests.isEmpty { AMEmptyState(icon: "person.crop.rectangle.stack", text: L("guests.empty")) }
        }
        .navigationTitle("People & Guests")
        .toolbar { Button { editing = AMGuest(name: "") } label: { Image(systemName: "plus") } }
        .sheet(item: $editing) { guest in NavigationStack { AMGuestEditor(guest: guest) } }
    }
}

struct AMGuestEditor: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var guest: AMGuest
    @State private var hasDate = false

    var body: some View {
        Form {
            TextField(L("guests.name"), text: $guest.name)
            Picker(L("guests.category"), selection: $guest.category) {
                ForEach(AMGuestCategory.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Picker(L("studio.status"), selection: $guest.status) {
                ForEach(AMGuestStatus.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            TextField(L("guests.contacts"), text: $guest.contacts, axis: .vertical)
            TextField(L("guests.topic"), text: $guest.topic, axis: .vertical)
            Toggle(L("studio.shootDate"), isOn: $hasDate)
            if hasDate {
                DatePicker(L("studio.shootDate"), selection: Binding(get: { guest.shootDate ?? Date() }, set: { guest.shootDate = $0 }))
            }
            AMTextArea(title: L("studio.questions"), text: $guest.questions)
            AMTextArea(title: L("guests.notes"), text: $guest.notes, minHeight: 60)
        }
        .navigationTitle(guest.name.isEmpty ? L("guests.new") : guest.name)
        .onAppear { hasDate = guest.shootDate != nil }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    if !hasDate { guest.shootDate = nil }
                    if let index = store.db.guests.firstIndex(where: { $0.id == guest.id }) {
                        store.db.guests[index] = guest
                    } else {
                        store.db.guests.append(guest)
                    }
                    dismiss()
                }
                .disabled(guest.name.isEmpty)
            }
        }
    }
}

// MARK: - Series

struct AMSeriesAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var name = ""

    var body: some View {
        List {
            Section {
                TextField(L("series.new"), text: $name)
                Button(L("common.add")) {
                    store.db.series.append(AMSeries(name: name))
                    name = ""
                }
                .disabled(name.isEmpty)
            }
            ForEach(store.seriesStats) { stat in
                let items = store.db.contentItems.filter { $0.seriesId == stat.id }
                let next = items.filter { $0.status != .published }
                    .sorted { ($0.publishDate ?? .distantFuture) < ($1.publishDate ?? .distantFuture) }.first
                VStack(alignment: .leading, spacing: 6) {
                    Text(stat.name).font(.headline)
                    ProgressView(value: Double(min(stat.episodes, stat.planned)), total: Double(max(stat.planned, 1))) {
                        Text(L("series.progress", stat.episodes, stat.planned)).font(.caption)
                    }
                    if let next {
                        Label(L("series.next", next.title), systemImage: "forward.end").font(.caption)
                    }
                    if stat.averageViews > 0 {
                        Text(L("series.avgViews", stat.averageViews)).font(.caption).foregroundStyle(.secondary)
                    }
                    Stepper(L("series.planned", stat.planned), value: Binding(
                        get: { stat.planned },
                        set: { value in
                            if let index = store.db.series.firstIndex(where: { $0.id == stat.id }) { store.db.series[index].plannedEpisodes = value }
                        }), in: 1...1000)
                    .font(.caption)
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { store.seriesStats[$0].id }
                store.db.series.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle("Series")
    }
}

// MARK: - Media Library

struct AMMediaLibraryView: View {
    @EnvironmentObject private var store: AMStore
    @State private var kind: AMMediaKind?
    @State private var newAsset = AMMediaAsset(title: "", kind: .photo)
    @State private var showAdd = false

    var body: some View {
        let assets = store.db.media.filter { kind == nil || $0.kind == kind }
        List {
            Picker(L("media.kind"), selection: $kind) {
                Text(L("common.all")).tag(AMMediaKind?.none)
                ForEach(AMMediaKind.allCases, id: \.self) { Label($0.title, systemImage: $0.icon).tag(AMMediaKind?.some($0)) }
            }
            if assets.isEmpty { AMEmptyState(icon: "photo.stack", text: L("media.empty")) }
            ForEach(assets) { asset in
                HStack {
                    if let data = asset.data, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: asset.kind.icon).frame(width: 56, height: 56).background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading) {
                        Text(asset.title).font(.headline)
                        Text("\(asset.kind.title) · \(asset.tags)").font(.caption).foregroundStyle(.secondary)
                        if !asset.url.isEmpty, let url = URL(string: asset.url) { Link(asset.url, destination: url).font(.caption2).lineLimit(1) }
                    }
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { assets[$0].id }
                store.db.media.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle("Media Library")
        .toolbar { Button { showAdd = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField(L("editor.title"), text: $newAsset.title)
                    Picker(L("media.kind"), selection: $newAsset.kind) {
                        ForEach(AMMediaKind.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    AMSinglePhotoPicker(title: L("common.addPhoto"), image: $newAsset.data)
                    TextField(L("media.url"), text: $newAsset.url).keyboardType(.URL).textInputAutocapitalization(.never)
                    TextField(L("media.tags"), text: $newAsset.tags)
                }
                .navigationTitle(L("media.add"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { showAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L("common.save")) {
                            store.db.media.insert(newAsset, at: 0)
                            newAsset = AMMediaAsset(title: "", kind: .photo)
                            showAdd = false
                        }
                        .disabled(newAsset.title.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Analytics

struct AMAnalyticsView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        let published = store.db.contentItems.filter { $0.status == .published }
        let totalViews = published.map(\.views).reduce(0, +)
        let totalSubs = published.map(\.newSubscribers).reduce(0, +)
        List {
            if let insight = store.analyticsInsight {
                Section {
                    Label(insight, systemImage: "lightbulb.max.fill").foregroundStyle(AMTheme.skyDeep)
                }
            }
            Section(L("analytics.media")) {
                HStack {
                    AMStatTile(value: "\(published.count)", title: L("analytics.videos"), icon: "play.rectangle")
                    AMStatTile(value: "\(totalViews)", title: L("analytics.views"), icon: "eye")
                    AMStatTile(value: "\(totalSubs)", title: L("analytics.subscribers"), icon: "person.badge.plus")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                let stats = store.seriesStats.filter { $0.averageViews > 0 }
                if !stats.isEmpty {
                    Chart(stats) { stat in
                        BarMark(x: .value(L("analytics.views"), stat.averageViews), y: .value("Series", stat.name))
                            .foregroundStyle(AMTheme.sky)
                    }
                    .frame(height: CGFloat(stats.count) * 36 + 30)
                    .accessibilityLabel(L("analytics.bySeries"))
                }
                let top = published.sorted { $0.views > $1.views }.prefix(5)
                ForEach(Array(top)) { item in
                    HStack {
                        Text(item.title).lineLimit(1)
                        Spacer()
                        Text("\(item.views)").monospacedDigit().foregroundStyle(.secondary)
                    }
                }
                if published.isEmpty { Text(L("analytics.noData")).font(.caption).foregroundStyle(.secondary) }
            }
            Section(L("analytics.platform")) {
                HStack {
                    AMStatTile(value: "\(store.db.users.count)", title: L("admin.stat.users"), icon: "person.3")
                    AMStatTile(value: "\(store.db.posts.filter { $0.status == .approved }.count)", title: L("admin.stat.posts"), icon: "text.bubble")
                    AMStatTile(value: "\(store.db.orders.filter { $0.status == .paid }.map(\.amount).reduce(0, +).tenge)", title: L("analytics.revenue"), icon: "creditcard")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                let byType = AMPostType.allCases.map { type in (type, store.db.posts.filter { $0.type == type }.count) }.filter { $0.1 > 0 }
                if !byType.isEmpty {
                    Chart(byType, id: \.0) { pair in
                        BarMark(x: .value(L("admin.stat.posts"), pair.1), y: .value("Type", pair.0.title))
                            .foregroundStyle(AMTheme.gold)
                    }
                    .frame(height: CGFloat(byType.count) * 32 + 30)
                }
                let byRegion = AMRegion.allCases.map { region in (region, store.db.posts.filter { $0.region == region }.count) }
                    .filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.prefix(6)
                ForEach(Array(byRegion), id: \.0) { pair in
                    HStack { Text(pair.0.title); Spacer(); Text("\(pair.1)").monospacedDigit() }
                }
            }
        }
        .navigationTitle("Analytics")
    }
}

// MARK: - Задачи

struct AMTasksView: View {
    @EnvironmentObject private var store: AMStore
    @State private var title = ""
    @State private var due = Date()
    @State private var assignee = ""

    var body: some View {
        List {
            Section {
                TextField(L("tasks.new"), text: $title)
                DatePicker(L("tasks.due"), selection: $due, displayedComponents: .date)
                TextField(L("studio.responsible"), text: $assignee)
                Button(L("common.add")) {
                    store.db.tasks.append(AMTask(title: title, due: due, assignee: assignee))
                    title = ""
                    assignee = ""
                }
                .disabled(title.isEmpty)
            }
            Section(L("tasks.open")) {
                ForEach(store.db.tasks.filter { !$0.done }.sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }) { task in
                    row(task)
                }
            }
            Section(L("tasks.done")) {
                ForEach(store.db.tasks.filter(\.done)) { task in row(task) }
            }
        }
        .navigationTitle(L("admin.tasks"))
    }

    private func row(_ task: AMTask) -> some View {
        HStack {
            Button {
                if let index = store.db.tasks.firstIndex(where: { $0.id == task.id }) { store.db.tasks[index].done.toggle() }
            } label: {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle").foregroundStyle(task.done ? AMTheme.success : .secondary)
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading) {
                Text(task.title).strikethrough(task.done)
                HStack {
                    if let due = task.due {
                        Text(due.amDate).foregroundStyle(due < Date() && !task.done && !Calendar.current.isDateInToday(due) ? AMTheme.danger : .secondary)
                    }
                    if !task.assignee.isEmpty { Text("· \(task.assignee)").foregroundStyle(.secondary) }
                }
                .font(.caption)
            }
            Spacer()
            Button(role: .destructive) {
                store.db.tasks.removeAll { $0.id == task.id }
            } label: { Image(systemName: "trash") }
            .buttonStyle(.borderless)
        }
    }
}
