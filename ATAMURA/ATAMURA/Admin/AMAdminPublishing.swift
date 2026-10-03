//
//  AMAdminPublishing.swift
//  ATA MURA
//
//  Публикации редакции: новости (RU / EN / KZ, отложенная публикация, закрепление),
//  ATA MURA Magazine (обложка, PDF, цена), курсы Academy (уроки, цена, скидка, промокоды,
//  места), заказы и оплаты, товары Marketplace, мероприятия, партнёры и спонсоры.
//

import SwiftUI
import UniformTypeIdentifiers

/// Поле на трёх языках с переключателем RU / EN / KZ.
struct AMLocalizedField: View {
    let title: String
    @Binding var text: LocalizedText
    var multiline = false
    @State private var language: AMLanguage = AMLanguage.current

    private var binding: Binding<String> {
        Binding(get: { text[language] }, set: { text[language] = $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Picker(title, selection: $language) {
                    ForEach(AMLanguage.allCases) { lang in
                        Text(lang.flag + (text[lang].isEmpty ? "" : " ✓")).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
            if multiline {
                TextEditor(text: binding)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("\(title) \(language.nativeName)")
            } else {
                TextField("\(title) (\(language.flag))", text: binding, axis: .vertical)
            }
        }
    }
}

// MARK: - Новости

struct AMNewsAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var editing: AMNews?

    var body: some View {
        List {
            Section {
                Button { editing = AMNews() } label: { Label(L("create.news"), systemImage: "square.and.pencil") }
            }
            ForEach(store.db.news.sorted { $0.publishAt > $1.publishAt }) { news in
                Button { editing = news } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if news.pinned { Image(systemName: "pin.fill").foregroundStyle(AMTheme.gold) }
                            Text(news.title.value.isEmpty ? L("studio.untitled") : news.title.value).font(.headline).foregroundStyle(.primary)
                        }
                        HStack {
                            AMTag(text: news.isDraft ? L("news.draft") : (news.isScheduled ? L("news.scheduled") : L("news.published")),
                                  color: news.isDraft ? .gray : (news.isScheduled ? .orange : AMTheme.success))
                            Text(news.publishAt.amDateTime).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                let sorted = store.db.news.sorted { $0.publishAt > $1.publishAt }
                let ids = offsets.map { sorted[$0].id }
                store.db.news.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle(L("admin.news"))
        .sheet(item: $editing) { news in NavigationStack { AMNewsEditorView(news: news) } }
    }
}

struct AMNewsEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var news: AMNews
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                AMLocalizedField(title: L("news.headline"), text: $news.title)
                AMLocalizedField(title: L("news.text"), text: $news.body, multiline: true)
            } footer: {
                Text(L("news.languagesHint"))
            }
            Section {
                AMSinglePhotoPicker(title: L("news.photo"), image: $news.image)
                TextField(L("editor.video"), text: $news.videoURL).keyboardType(.URL).textInputAutocapitalization(.never)
                TextField(L("news.buttonTitle"), text: $news.linkTitle)
                TextField(L("news.buttonURL"), text: $news.linkURL).keyboardType(.URL).textInputAutocapitalization(.never)
            }
            Section {
                Toggle(L("news.pin"), isOn: $news.pinned)
                Toggle(L("news.draft"), isOn: $news.isDraft)
                DatePicker(L("news.publishAt"), selection: $news.publishAt)
            } footer: {
                Text(L("news.scheduleHint"))
            }
            Section {
                Button {
                    if news.authorName.isEmpty { news.authorName = store.currentUser?.fullName ?? "ATA MURA" }
                    store.publishNews(news)
                    if !news.isDraft && news.publishAt <= Date() {
                        for user in store.db.users where user.id != store.currentUser?.id {
                            store.notify(user.id, title: L("feed.news"), body: news.title.value)
                        }
                    }
                    saved = true
                } label: {
                    Label(news.isDraft ? L("news.saveDraft") : (news.publishAt > Date() ? L("news.schedule") : L("news.publishNow")),
                          systemImage: "paperplane.fill").bold()
                }
                .disabled(news.title.isEmpty || news.body.isEmpty)
            }
            if !news.title.isEmpty {
                Section(L("news.preview")) {
                    if let image = news.image { AMImageView(data: image, height: 160) }
                    Text(news.title.value).font(.headline)
                    Text(news.body.value).font(.callout).lineLimit(6)
                }
            }
        }
        .navigationTitle(L("admin.news"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("common.close")) { dismiss() } } }
        .alert(L("project.saved"), isPresented: $saved) { Button("OK") { dismiss() } }
    }
}

// MARK: - Журнал

struct AMMagazineAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var editing: AMMagazineIssue?

    var body: some View {
        List {
            Section {
                Button {
                    editing = AMMagazineIssue(number: (store.db.magazines.map(\.number).max() ?? 0) + 1)
                } label: { Label(L("magazine.create"), systemImage: "plus") }
            }
            ForEach(store.db.magazines.sorted { $0.number > $1.number }) { issue in
                Button { editing = issue } label: {
                    HStack {
                        AMMagazineCover(issue: issue).frame(width: 60, height: 80)
                        VStack(alignment: .leading) {
                            Text("№\(issue.number) · \(issue.title.value)").font(.headline).foregroundStyle(.primary)
                            Text(issue.published ? L("news.published") : L("news.draft")).font(.caption).foregroundStyle(.secondary)
                            Text(issue.price.tenge).font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("ATA MURA Magazine")
        .sheet(item: $editing) { issue in NavigationStack { AMMagazineEditorView(issue: issue) } }
    }
}

struct AMMagazineEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var issue: AMMagazineIssue
    @State private var importPDF = false

    var body: some View {
        Form {
            Section {
                Stepper(L("magazine.number", issue.number), value: $issue.number, in: 1...999)
                AMLocalizedField(title: L("magazine.titleField"), text: $issue.title)
                AMLocalizedField(title: L("magazine.description"), text: $issue.summary, multiline: true)
                DatePicker(L("magazine.release"), selection: $issue.releaseDate, displayedComponents: .date)
            }
            Section {
                AMSinglePhotoPicker(title: L("magazine.cover"), image: $issue.cover)
                Button { importPDF = true } label: {
                    Label(issue.pdf == nil ? L("magazine.uploadPdf") : L("magazine.pdfReady", ByteCountFormatter.string(fromByteCount: Int64(issue.pdf?.count ?? 0), countStyle: .file)),
                          systemImage: "doc.richtext")
                }
                TextField(L("magazine.pdfURL"), text: $issue.pdfURL).keyboardType(.URL).textInputAutocapitalization(.never)
            } footer: {
                Text(L("magazine.pdfHint"))
            }
            Section {
                TextField(L("magazine.authors"), text: $issue.authors, axis: .vertical)
                TextField(L("magazine.board"), text: $issue.editorialBoard, axis: .vertical)
                LabeledContent(L("magazine.price")) {
                    TextField("0", value: $issue.price, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                Toggle(L("magazine.publish"), isOn: $issue.published)
            } footer: {
                Text(L("magazine.publishHint"))
            }
        }
        .navigationTitle("№\(issue.number)")
        .fileImporter(isPresented: $importPDF, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                issue.pdf = try? Data(contentsOf: url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    let wasPublished = store.db.magazines.first { $0.id == issue.id }?.published ?? false
                    if let index = store.db.magazines.firstIndex(where: { $0.id == issue.id }) {
                        store.db.magazines[index] = issue
                    } else {
                        store.db.magazines.append(issue)
                    }
                    if issue.published && !wasPublished {
                        for user in store.db.users where user.id != store.currentUser?.id {
                            store.notify(user.id, title: L("magazine.newIssue"), body: "ATA MURA Magazine №\(issue.number) — \(issue.title.value)")
                        }
                    }
                    dismiss()
                }
                .disabled(issue.title.isEmpty)
            }
        }
    }
}

// MARK: - Курсы

struct AMCoursesAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var editing: AMCourse?

    var body: some View {
        List {
            Section {
                Button { editing = AMCourse() } label: { Label(L("course.create"), systemImage: "plus") }
            }
            ForEach(store.db.courses) { course in
                Button { editing = course } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title.value.isEmpty ? L("studio.untitled") : course.title.value).font(.headline).foregroundStyle(.primary)
                        HStack {
                            AMTag(text: course.access.title)
                            Text(course.finalPrice.tenge).font(.caption)
                            Text(L("academy.lessons", course.lessons.count)).font(.caption).foregroundStyle(.secondary)
                            Text(L("course.students", store.db.enrollments.filter { $0.courseId == course.id }.count)).font(.caption).foregroundStyle(.secondary)
                        }
                        if !course.published { Text(L("news.draft")).font(.caption2).foregroundStyle(.orange) }
                    }
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { store.db.courses[$0].id }
                store.db.courses.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle(L("admin.courses"))
        .sheet(item: $editing) { course in NavigationStack { AMCourseEditorView(course: course) } }
    }
}

struct AMCourseEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var course: AMCourse
    @State private var newPromo = ""
    @State private var newPromoPercent = 10
    @State private var limitSeats = false

    var body: some View {
        Form {
            Section {
                AMLocalizedField(title: L("course.titleField"), text: $course.title)
                AMLocalizedField(title: L("course.description"), text: $course.summary, multiline: true)
                TextField(L("course.teacher"), text: $course.teacher)
                AMSinglePhotoPicker(title: L("magazine.cover"), image: $course.cover)
            }
            Section {
                Picker(L("course.access"), selection: $course.access) {
                    ForEach(AMCourseAccess.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                if course.access != .free {
                    LabeledContent(L("course.price")) {
                        TextField("0", value: $course.price, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Stepper(L("course.discount", course.discountPercent), value: $course.discountPercent, in: 0...100, step: 5)
                    Text(L("academy.total", course.finalPrice.tenge)).font(.headline)
                }
                DatePicker(L("course.salesStart"), selection: $course.salesStart, displayedComponents: .date)
                Toggle(L("course.limitSeats"), isOn: $limitSeats)
                if limitSeats {
                    Stepper(L("course.seats", course.seats ?? 20), value: Binding(get: { course.seats ?? 20 }, set: { course.seats = $0 }), in: 1...10_000)
                }
                Toggle(L("academy.certificate"), isOn: $course.hasCertificate)
            } header: {
                Text(L("course.pricing"))
            } footer: {
                Text(L("course.pricingHint"))
            }
            if course.access != .free {
                Section(L("course.promo")) {
                    ForEach(course.promoCodes) { promo in
                        Text("\(promo.code) — \(promo.percent)%")
                    }
                    .onDelete { course.promoCodes.remove(atOffsets: $0) }
                    TextField(L("course.promoCode"), text: $newPromo).textInputAutocapitalization(.characters)
                    Stepper("\(newPromoPercent)%", value: $newPromoPercent, in: 5...100, step: 5)
                    Button(L("common.add")) {
                        course.promoCodes.append(AMPromoCode(code: newPromo.uppercased(), percent: newPromoPercent))
                        newPromo = ""
                    }
                    .disabled(newPromo.isEmpty)
                }
            }
            Section(L("academy.program")) {
                ForEach($course.lessons) { $lesson in
                    NavigationLink {
                        AMLessonEditorView(lesson: $lesson)
                    } label: {
                        Text(lesson.title.isEmpty ? L("studio.untitled") : lesson.title)
                    }
                }
                .onDelete { course.lessons.remove(atOffsets: $0) }
                .onMove { course.lessons.move(fromOffsets: $0, toOffset: $1) }
                Button { course.lessons.append(AMLesson(title: L("course.lesson", course.lessons.count + 1))) } label: {
                    Label(L("course.addLesson"), systemImage: "plus")
                }
            }
            Section {
                Toggle(L("course.publish"), isOn: $course.published)
            }
        }
        .navigationTitle(L("academy.course"))
        .onAppear { limitSeats = course.seats != nil }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    if !limitSeats { course.seats = nil }
                    if let index = store.db.courses.firstIndex(where: { $0.id == course.id }) {
                        store.db.courses[index] = course
                    } else {
                        store.db.courses.append(course)
                    }
                    dismiss()
                }
                .disabled(course.title.isEmpty)
            }
        }
    }
}

struct AMLessonEditorView: View {
    @Binding var lesson: AMLesson
    @State private var question = ""
    @State private var options = ""
    @State private var correct = 0

    var body: some View {
        Form {
            Section {
                TextField(L("editor.title"), text: $lesson.title)
                TextField(L("lesson.video"), text: $lesson.videoURL).keyboardType(.URL).textInputAutocapitalization(.never)
                TextField(L("lesson.pdf"), text: $lesson.pdfURL).keyboardType(.URL).textInputAutocapitalization(.never)
                AMTextArea(title: L("lesson.text"), text: $lesson.text, minHeight: 160)
                AMTextArea(title: L("academy.homework"), text: $lesson.homework, minHeight: 60)
            }
            Section(L("academy.quiz")) {
                ForEach(lesson.quiz) { item in
                    VStack(alignment: .leading) {
                        Text(item.question).font(.headline)
                        Text(item.options.enumerated().map { ($0.offset == item.correctIndex ? "✓ " : "• ") + $0.element }.joined(separator: "\n"))
                            .font(.caption)
                    }
                }
                .onDelete { lesson.quiz.remove(atOffsets: $0) }
                TextField(L("lesson.question"), text: $question)
                TextField(L("lesson.options"), text: $options)
                Stepper(L("lesson.correct", correct + 1), value: $correct, in: 0...5)
                Button(L("common.add")) {
                    let list = options.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    lesson.quiz.append(AMQuizQuestion(question: question, options: list, correctIndex: min(correct, max(list.count - 1, 0))))
                    question = ""
                    options = ""
                    correct = 0
                }
                .disabled(question.isEmpty || options.split(separator: ";").count < 2)
            }
        }
        .navigationTitle(lesson.title)
    }
}

// MARK: - Заказы и оплаты

struct AMOrdersAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var status: AMOrderStatus? = .pending

    var body: some View {
        let orders = store.db.orders.filter { status == nil || $0.status == status }.sorted { $0.date > $1.date }
        let revenue = store.db.orders.filter { $0.status == .paid }.map(\.amount).reduce(0, +)
        List {
            Section {
                LabeledContent(L("analytics.revenue"), value: revenue.tenge)
                Picker(L("studio.status"), selection: $status) {
                    Text(L("common.all")).tag(AMOrderStatus?.none)
                    ForEach(AMOrderStatus.allCases, id: \.self) { Text($0.title).tag(AMOrderStatus?.some($0)) }
                }
            }
            if orders.isEmpty { AMEmptyState(icon: "creditcard", text: L("orders.empty")) }
            ForEach(orders) { order in
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.title).font(.headline)
                    Text("\(order.userName) · \(order.amount.tenge) · \(order.method.title)").font(.caption)
                    if !order.promoCode.isEmpty { Text(L("academy.promo") + ": " + order.promoCode).font(.caption2) }
                    Text(order.date.amDateTime).font(.caption2).foregroundStyle(.secondary)
                    HStack {
                        AMTag(text: order.status.title, color: order.status == .paid ? AMTheme.success : .orange)
                        Spacer()
                        if order.status == .pending {
                            Button(L("orders.confirm")) { store.setOrderStatus(order.id, .paid) }.buttonStyle(.borderedProminent)
                            Button(L("orders.cancel")) { store.setOrderStatus(order.id, .cancelled) }.buttonStyle(.bordered)
                        } else if order.status == .paid {
                            Button(L("orders.refund")) { store.setOrderStatus(order.id, .refunded) }.buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .navigationTitle(L("admin.orders"))
    }
}

// MARK: - Marketplace

struct AMProductsAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var editing: AMProduct?

    var body: some View {
        List {
            Button { editing = AMProduct(kind: .ebook, title: "", summary: "", price: 0) } label: { Label(L("market.add"), systemImage: "plus") }
            ForEach(store.db.products) { product in
                Button { editing = product } label: {
                    HStack {
                        Label(product.title, systemImage: product.kind.icon).foregroundStyle(.primary)
                        Spacer()
                        Text(product.price.tenge).font(.caption)
                    }
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { store.db.products[$0].id }
                store.db.products.removeAll { ids.contains($0.id) }
            }
        }
        .navigationTitle("Marketplace")
        .sheet(item: $editing) { product in
            NavigationStack { AMProductEditor(product: product) }
        }
    }
}

struct AMProductEditor: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State var product: AMProduct
    @State private var limited = false

    var body: some View {
        Form {
            Picker(L("market.kind"), selection: $product.kind) {
                ForEach(AMProductKind.allCases, id: \.self) { Label($0.title, systemImage: $0.icon).tag($0) }
            }
            TextField(L("editor.title"), text: $product.title)
            AMTextArea(title: L("course.description"), text: $product.summary, minHeight: 80)
            LabeledContent(L("course.price")) {
                TextField("0", value: $product.price, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
            }
            Toggle(L("market.limited"), isOn: $limited)
            if limited {
                Stepper(L("market.stock", product.stock ?? 10), value: Binding(get: { product.stock ?? 10 }, set: { product.stock = $0 }), in: 0...100_000)
            }
            AMSinglePhotoPicker(title: L("common.addPhoto"), image: $product.image)
            Toggle(L("course.publish"), isOn: $product.published)
        }
        .navigationTitle(L("market.product"))
        .onAppear { limited = product.stock != nil }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L("common.save")) {
                    if !limited { product.stock = nil }
                    if let index = store.db.products.firstIndex(where: { $0.id == product.id }) {
                        store.db.products[index] = product
                    } else {
                        store.db.products.append(product)
                    }
                    dismiss()
                }
                .disabled(product.title.isEmpty)
            }
        }
    }
}

// MARK: - Мероприятия

struct AMEventsAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var event = AMEvent(title: "", date: Date().addingTimeInterval(86_400 * 7))

    var body: some View {
        List {
            Section(L("events.new")) {
                TextField(L("editor.title"), text: $event.title)
                DatePicker(L("events.date"), selection: $event.date)
                TextField(L("events.place"), text: $event.place)
                TextField(L("course.description"), text: $event.summary, axis: .vertical)
                Button(L("common.add")) {
                    store.db.events.append(event)
                    event = AMEvent(title: "", date: Date().addingTimeInterval(86_400 * 7))
                }
                .disabled(event.title.isEmpty)
            }
            Section(L("events.title")) {
                ForEach(store.db.events.sorted { $0.date > $1.date }) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text("\(item.date.amDateTime) · \(item.place)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    let sorted = store.db.events.sorted { $0.date > $1.date }
                    let ids = offsets.map { sorted[$0].id }
                    store.db.events.removeAll { ids.contains($0.id) }
                }
            }
        }
        .navigationTitle(L("admin.events"))
    }
}

// MARK: - Партнёры и спонсоры

struct AMPartnersAdminView: View {
    @EnvironmentObject private var store: AMStore
    @State private var partner = AMPartner(name: "")

    var body: some View {
        List {
            Section(L("partners.new")) {
                TextField(L("partners.name"), text: $partner.name)
                Picker(L("partners.kind"), selection: $partner.kind) {
                    ForEach(AMPartnerKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                TextField(L("guests.contacts"), text: $partner.contact)
                TextField(L("partners.agreement"), text: $partner.agreement)
                if partner.kind == .sponsor {
                    LabeledContent(L("partners.amount")) {
                        TextField("0", value: $partner.amount, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                TextField(L("guests.notes"), text: $partner.notes, axis: .vertical)
                Button(L("common.add")) {
                    store.db.partners.append(partner)
                    partner = AMPartner(name: "")
                }
                .disabled(partner.name.isEmpty)
            }
            ForEach(AMPartnerKind.allCases, id: \.self) { kind in
                let list = store.db.partners.filter { $0.kind == kind }
                if !list.isEmpty {
                    Section(kind.title) {
                        ForEach(list) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.headline)
                                if !item.agreement.isEmpty { Text(item.agreement).font(.caption) }
                                if item.amount > 0 { Text(item.amount.tenge).font(.caption).foregroundStyle(.secondary) }
                                if !item.contact.isEmpty { Text(item.contact).font(.caption2).foregroundStyle(.secondary) }
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { list[$0].id }
                            store.db.partners.removeAll { ids.contains($0.id) }
                        }
                    }
                }
            }
        }
        .navigationTitle(L("admin.partners"))
    }
}
