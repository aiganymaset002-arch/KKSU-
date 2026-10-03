//
//  AMAcademy.swift
//  ATA MURA
//
//  ATA MURA ACADEMY (курсы, цены, промокоды, My Courses), ATA MURA MAGAZINE (чтение PDF),
//  новости, мероприятия, MARKETPLACE и заказы пользователя.
//
//  Оплата: заказ создаётся со статусом «ожидает оплаты», администратор подтверждает оплату
//  в админке (Kaspi, карта, перевод) — после этого открывается доступ.
//  Перед публикацией в App Store цифровые курсы и журналы нужно перевести на встроенные
//  покупки Apple (StoreKit), как это сделано в KKSU, — см. ATAMURA/README.md.
//

import SwiftUI
import PDFKit

// MARK: - Академия

struct AMAcademyView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink { AMMyCoursesView() } label: {
                    Label("My Courses", systemImage: "person.crop.rectangle.stack").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                if store.publishedCourses.isEmpty { AMEmptyState(icon: "graduationcap", text: L("academy.empty")) }
                ForEach(store.publishedCourses) { course in
                    NavigationLink { AMCourseDetailView(courseId: course.id) } label: { AMCourseCard(course: course) }
                        .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ATA MURA Academy")
    }
}

struct AMCourseCard: View {
    @EnvironmentObject private var store: AMStore
    let course: AMCourse

    var body: some View {
        AMCard {
            if let cover = course.cover { AMImageView(data: cover, height: 140) }
            HStack {
                AMTag(text: course.access.title, icon: "tag")
                if store.enrollment(course.id) != nil { AMTag(text: L("academy.enrolled"), icon: "checkmark", color: AMTheme.success) }
                Spacer()
                VStack(alignment: .trailing) {
                    if course.discountPercent > 0 && course.access != .free {
                        Text(course.price.tenge).font(.caption).strikethrough().foregroundStyle(.secondary)
                    }
                    Text(course.finalPrice.tenge).font(.headline)
                }
            }
            Text(course.title.value).font(.headline)
            Text(course.summary.value).font(.callout).foregroundStyle(.secondary).lineLimit(3)
            HStack {
                Label(course.teacher, systemImage: "person").font(.caption)
                Spacer()
                Label(L("academy.lessons", course.lessons.count), systemImage: "list.number").font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct AMCourseDetailView: View {
    @EnvironmentObject private var store: AMStore
    let courseId: UUID
    @State private var promo = ""
    @State private var method: AMPaymentMethod = .kaspi
    @State private var orderMessage: String?

    var body: some View {
        if let course = store.db.courses.first(where: { $0.id == courseId }) {
            let enrollment = store.enrollment(course.id)
            let pending = store.pendingOrder(itemId: course.id)
            List {
                Section {
                    if let cover = course.cover { AMImageView(data: cover, height: 180) }
                    Text(course.title.value).font(.title2.bold())
                    AMBodyText(text: course.summary.value)
                    Label(course.teacher, systemImage: "person")
                    if course.hasCertificate { Label(L("academy.certificate"), systemImage: "rosette") }
                    if let seats = store.seatsLeft(course) { Label(L("academy.seats", seats), systemImage: "person.3") }
                    if course.salesStart > Date() { Label(L("academy.salesStart", course.salesStart.amDate), systemImage: "calendar") }
                }
                if let enrollment {
                    Section {
                        let done = enrollment.completedLessons.count
                        ProgressView(value: Double(done), total: Double(max(course.lessons.count, 1))) {
                            Text(L("academy.progress", done, course.lessons.count)).font(.caption)
                        }
                        if done == course.lessons.count && course.hasCertificate && !course.lessons.isEmpty {
                            Label(L("academy.certificateReady"), systemImage: "rosette").foregroundStyle(AMTheme.gold)
                        }
                    }
                } else if let pending {
                    Section {
                        Label(L("academy.pending", pending.amount.tenge), systemImage: "hourglass")
                        Text(L("academy.pendingHint")).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Section(L("academy.join")) {
                        if course.access != .free {
                            TextField(L("academy.promo"), text: $promo).textInputAutocapitalization(.characters)
                            Picker(L("payment.method"), selection: $method) {
                                ForEach(AMPaymentMethod.allCases, id: \.self) { Text($0.title).tag($0) }
                            }
                        }
                        Text(L("academy.total", store.price(of: course, promo: promo).tenge)).font(.headline)
                        Button {
                            if let order = store.enroll(course, promo: promo, method: method) {
                                orderMessage = L("academy.orderCreated", order.amount.tenge)
                            }
                        } label: {
                            Label(course.access == .free ? L("academy.startFree") : L("academy.buy"), systemImage: "cart.fill").bold()
                        }
                        .disabled(course.salesStart > Date() || store.seatsLeft(course) == 0)
                    }
                }
                Section(L("academy.program")) {
                    ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                        if enrollment != nil || store.isStaff {
                            NavigationLink { AMLessonView(course: course, lesson: lesson) } label: {
                                HStack {
                                    Text("\(index + 1). \(lesson.title)")
                                    Spacer()
                                    if enrollment?.completedLessons.contains(lesson.id) == true {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(AMTheme.success)
                                    }
                                }
                            }
                        } else {
                            Label("\(index + 1). \(lesson.title)", systemImage: "lock")
                        }
                    }
                }
            }
            .navigationTitle(L("academy.course"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(orderMessage ?? "", isPresented: Binding(get: { orderMessage != nil }, set: { if !$0 { orderMessage = nil } })) {
                Button("OK") { orderMessage = nil }
            }
        } else {
            AMEmptyState(icon: "questionmark", text: L("common.notFound"))
        }
    }
}

struct AMLessonView: View {
    @EnvironmentObject private var store: AMStore
    let course: AMCourse
    let lesson: AMLesson
    @State private var answers: [UUID: Int] = [:]

    var body: some View {
        let done = store.enrollment(course.id)?.completedLessons.contains(lesson.id) == true
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(lesson.title).font(.title2.bold())
                AMLinkButton(title: L("common.watchVideo"), url: lesson.videoURL, icon: "play.rectangle.fill")
                AMLinkButton(title: "PDF", url: lesson.pdfURL, icon: "doc.richtext")
                if !lesson.text.isEmpty {
                    AMBodyText(text: lesson.text)
                    AMSpeakButton(text: lesson.text, id: lesson.id)
                }
                if !lesson.quiz.isEmpty {
                    AMSectionHeader(title: L("academy.quiz"), icon: "checklist")
                    ForEach(lesson.quiz) { question in
                        AMCard {
                            Text(question.question).font(.headline)
                            ForEach(question.options.indices, id: \.self) { index in
                                Button {
                                    answers[question.id] = index
                                } label: {
                                    HStack {
                                        Image(systemName: icon(question, index))
                                        Text(question.options[index]).foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                if !lesson.homework.isEmpty {
                    AMCard {
                        Label(L("academy.homework"), systemImage: "pencil.and.list.clipboard").font(.headline)
                        Text(lesson.homework)
                    }
                }
                if store.enrollment(course.id) != nil {
                    Button {
                        store.toggleLesson(lesson.id, courseId: course.id)
                    } label: {
                        Label(done ? L("academy.completed") : L("academy.markDone"), systemImage: done ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle(course.title.value)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(_ question: AMQuizQuestion, _ index: Int) -> String {
        guard let chosen = answers[question.id] else { return "circle" }
        if index == question.correctIndex { return "checkmark.circle.fill" }
        return chosen == index ? "xmark.circle.fill" : "circle"
    }
}

struct AMMyCoursesView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        let mine = store.db.courses.filter { store.enrollment($0.id) != nil }
        List {
            if mine.isEmpty { AMEmptyState(icon: "graduationcap", text: L("academy.mineEmpty")) }
            ForEach(mine) { course in
                NavigationLink { AMCourseDetailView(courseId: course.id) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.title.value).font(.headline)
                        let done = store.enrollment(course.id)?.completedLessons.count ?? 0
                        ProgressView(value: Double(done), total: Double(max(course.lessons.count, 1)))
                        Text(L("academy.progress", done, course.lessons.count)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("My Courses")
    }
}

struct AMOrdersView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        let orders = store.db.orders.filter { $0.userId == store.currentUser?.id }.sorted { $0.date > $1.date }
        List {
            if orders.isEmpty { AMEmptyState(icon: "creditcard", text: L("orders.empty")) }
            ForEach(orders) { order in
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.title).font(.headline)
                    HStack {
                        Text(order.amount.tenge)
                        Text("· \(order.method.title)")
                        Spacer()
                        AMTag(text: order.status.title, color: order.status == .paid ? AMTheme.success : .orange)
                    }
                    .font(.caption)
                    Text(order.date.amDateTime).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L("orders.title"))
    }
}

// MARK: - Журнал

struct AMMagazineListView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(store.publishedMagazines) { issue in
                    NavigationLink { AMMagazineDetailView(issue: issue) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            AMMagazineCover(issue: issue)
                            Text("№\(issue.number) · \(issue.title.value)").font(.headline).lineLimit(2)
                            Text(issue.price == 0 ? L("price.free") : issue.price.tenge).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            if store.publishedMagazines.isEmpty { AMEmptyState(icon: "magazine", text: L("magazine.empty")) }
        }
        .navigationTitle("ATA MURA Magazine")
    }
}

struct AMMagazineCover: View {
    let issue: AMMagazineIssue

    var body: some View {
        Group {
            if let cover = issue.cover, let image = UIImage(data: cover) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    AMTheme.heroGradient
                    VStack(spacing: 6) {
                        Text("ATA MURA").font(.headline.weight(.heavy))
                        Text("MAGAZINE").font(.caption.bold()).tracking(3)
                        Text("№\(issue.number)").font(.largeTitle.bold()).foregroundStyle(AMTheme.gold)
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AMMagazineDetailView: View {
    @EnvironmentObject private var store: AMStore
    let issue: AMMagazineIssue
    @State private var method: AMPaymentMethod = .kaspi
    @State private var reading = false

    var body: some View {
        let canRead = issue.price == 0 || store.hasPaid(itemId: issue.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                AMMagazineCover(issue: issue).frame(maxWidth: 260)
                Text("ATA MURA Magazine №\(issue.number)").font(.caption.bold()).foregroundStyle(AMTheme.skyDeep)
                Text(issue.title.value).font(.title2.bold())
                Text(issue.releaseDate.amDate).font(.caption).foregroundStyle(.secondary)
                AMBodyText(text: issue.summary.value)
                if !issue.authors.isEmpty { Text(L("magazine.authors") + ": " + issue.authors).font(.callout) }
                if !issue.editorialBoard.isEmpty { Text(L("magazine.board") + ": " + issue.editorialBoard).font(.callout) }
                if canRead {
                    if issue.pdf != nil {
                        Button { reading = true } label: { Label(L("magazine.read"), systemImage: "book.pages") }
                            .buttonStyle(.borderedProminent)
                    }
                    AMLinkButton(title: L("magazine.readOnline"), url: issue.pdfURL, icon: "safari")
                    if issue.pdf == nil && issue.pdfURL.isEmpty {
                        Text(L("magazine.noPdf")).font(.caption).foregroundStyle(.secondary)
                    }
                } else if let pending = store.pendingOrder(itemId: issue.id) {
                    Label(L("academy.pending", pending.amount.tenge), systemImage: "hourglass")
                } else {
                    Picker(L("payment.method"), selection: $method) {
                        ForEach(AMPaymentMethod.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Button {
                        store.buy(kind: .magazine, itemId: issue.id, title: "ATA MURA Magazine №\(issue.number)", amount: issue.price, method: method)
                    } label: {
                        Label(L("magazine.buy", issue.price.tenge), systemImage: "cart")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Magazine")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $reading) {
            NavigationStack {
                if let pdf = issue.pdf {
                    AMPDFView(data: pdf)
                        .navigationTitle("№\(issue.number)")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { Button(L("common.close")) { reading = false } }
                }
            }
        }
    }
}

struct AMPDFView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}

// MARK: - Новости и мероприятия

struct AMNewsListView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        List {
            ForEach(store.publishedNews) { news in
                NavigationLink { AMNewsDetailView(news: news) } label: {
                    HStack(alignment: .top) {
                        if news.pinned { Image(systemName: "pin.fill").foregroundStyle(AMTheme.gold) }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(news.title.value).font(.headline)
                            Text(news.publishAt.amDate).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            let events = store.db.events.filter { $0.published && $0.date > Date() }.sorted { $0.date < $1.date }
            if !events.isEmpty {
                Section(L("events.title")) {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title).font(.headline)
                            Label("\(event.date.amDateTime) · \(event.place)", systemImage: "calendar").font(.caption)
                            if !event.summary.isEmpty { Text(event.summary).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
        }
        .navigationTitle(L("home.news"))
    }
}

struct AMNewsDetailView: View {
    let news: AMNews

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let image = news.image { AMImageView(data: image, height: 220) }
                Text(news.title.value).font(.title2.bold())
                Text("\(news.authorName) · \(news.publishAt.amDate)").font(.caption).foregroundStyle(.secondary)
                AMBodyText(text: news.body.value)
                AMSpeakButton(text: news.title.value + ". " + news.body.value, id: news.id)
                AMLinkButton(title: L("common.watchVideo"), url: news.videoURL, icon: "play.rectangle.fill")
                AMLinkButton(title: news.linkTitle.isEmpty ? L("news.more") : news.linkTitle, url: news.linkURL, icon: "arrow.up.right.square")
            }
            .padding()
        }
        .navigationTitle(L("feed.news"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Marketplace

struct AMMarketplaceView: View {
    @EnvironmentObject private var store: AMStore
    @State private var method: AMPaymentMethod = .kaspi
    @State private var message: String?

    var body: some View {
        List {
            Section {
                Picker(L("payment.method"), selection: $method) {
                    ForEach(AMPaymentMethod.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            }
            ForEach(AMProductKind.allCases, id: \.self) { kind in
                let products = store.db.products.filter { $0.kind == kind && $0.published }
                if !products.isEmpty {
                    Section(kind.title) {
                        ForEach(products) { product in
                            VStack(alignment: .leading, spacing: 6) {
                                if let image = product.image { AMImageView(data: image, height: 140) }
                                Label(product.title, systemImage: kind.icon).font(.headline)
                                Text(product.summary).font(.callout).foregroundStyle(.secondary)
                                HStack {
                                    Text(product.price.tenge).font(.headline)
                                    if let stock = product.stock { Text(L("market.stock", stock)).font(.caption).foregroundStyle(.secondary) }
                                    Spacer()
                                    if store.hasPaid(itemId: product.id) {
                                        AMTag(text: L("order.paid"), icon: "checkmark", color: AMTheme.success)
                                    } else if store.pendingOrder(itemId: product.id) != nil {
                                        AMTag(text: L("order.pending"), icon: "hourglass", color: .orange)
                                    } else {
                                        Button(L("market.buy")) {
                                            store.buy(kind: .product, itemId: product.id, title: product.title, amount: product.price, method: method)
                                            message = L("academy.orderCreated", product.price.tenge)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(product.stock == 0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Marketplace")
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        }
    }
}
