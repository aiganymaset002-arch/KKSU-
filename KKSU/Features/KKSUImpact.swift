//
//  KKSUImpact.swift
//  KKSU Online
//
//  Impact Dashboard (84), автоподсчёт показателей (85), образовательный прогресс (86),
//  проекты и изобретения (87), партнёрства (88), международная деятельность (89),
//  генератор KKSU Impact Report (90), экспорт в PDF (91), публичная страница Impact (92).
//  Также PDF-генератор сертификатов (42, 99).
//

import SwiftUI
import Charts

// MARK: - PDF

@MainActor
enum KKSUPDF {
    static let a4 = CGSize(width: 595, height: 842)
    static let a4Landscape = CGSize(width: 842, height: 595)

    /// Рендерит SwiftUI-страницы в многостраничный PDF (без UIKit — работает на iOS и macOS).
    static func render(pages: [AnyView], size: CGSize, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var box = CGRect(origin: .zero, size: size)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return nil }
        for page in pages {
            let renderer = ImageRenderer(content: page.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
            renderer.render { _, draw in
                context.beginPDFPage(nil)
                draw(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        return url
    }

    static func certificate(_ certificate: Certificate) -> URL? {
        render(pages: [AnyView(CertificatePDFPage(certificate: certificate))], size: a4Landscape,
               fileName: "KKSU-certificate-\(certificate.serial).pdf")
    }

    static func impactReport(_ report: ImpactReportData) -> URL? {
        let pages: [AnyView] = [
            AnyView(ImpactReportPage(report: report, page: 1) { ImpactReportCover(report: report) }),
            AnyView(ImpactReportPage(report: report, page: 2) { ImpactReportEducation(report: report) }),
            AnyView(ImpactReportPage(report: report, page: 3) { ImpactReportProjects(report: report) }),
            AnyView(ImpactReportPage(report: report, page: 4) { ImpactReportPartnerships(report: report) })
        ]
        return render(pages: pages, size: a4, fileName: "KKSU-Impact-Report-\(report.periodLabel.replacingOccurrences(of: " ", with: "_")).pdf")
    }
}

// MARK: - Impact Dashboard (задачи 84–89)

struct ImpactDashboardView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let m = ImpactMetrics(db: store.db)
        KPage("Impact Dashboard") {
            Text("Все показатели рассчитываются автоматически по данным платформы в реальном времени.")
                .font(.callout).foregroundStyle(.secondary)

            // 85 — ключевые показатели
            KSectionHeader(title: "Ключевые показатели", icon: "sum")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Учеников", value: "\(m.students)", icon: "graduationcap.fill")
                KStatTile(title: "Проведено занятий", value: "\(m.lessonsHeld)", icon: "video.fill", color: KKSUTheme.accent)
                KStatTile(title: "Проектов", value: "\(m.projects)", icon: "lightbulb.fill", color: KKSUTheme.success)
                KStatTile(title: "Результатов (итоги проектов и сертификаты)", value: "\(m.results)", icon: "flag.checkered", color: .purple)
            }

            // 86 — образовательный прогресс
            KSectionHeader(title: "Образовательный прогресс", icon: "chart.line.uptrend.xyaxis")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Средний балл работ", value: "\(Int(m.averageScore * 100))%", icon: "star.fill")
                KStatTile(title: "Выполнение заданий", value: "\(Int(m.completionRate * 100))%", icon: "checkmark.circle.fill", color: KKSUTheme.success)
                KStatTile(title: "Посещаемость", value: "\(Int(m.attendanceRate * 100))%", icon: "person.fill.checkmark", color: KKSUTheme.accent)
                KStatTile(title: "Сдано тестов", value: "\(m.testsPassed)", icon: "checklist", color: .purple)
                KStatTile(title: "Достижений", value: "\(m.achievements)", icon: "trophy.fill", color: KKSUTheme.accent)
                KStatTile(title: "Выпускников Teacher Academy", value: "\(m.academyGraduates)", icon: "building.columns.fill")
            }
            StudentProgressChart()

            // 87 — проекты и изобретения
            KSectionHeader(title: "Проекты и изобретения", icon: "lightbulb.max.fill")
            KCard {
                Text("Воронка стадий проектов").font(.headline)
                Chart(m.projectsByStage, id: \.0) { item in
                    BarMark(x: .value("Стадия", item.0.title), y: .value("Проектов", item.1))
                        .foregroundStyle(KKSUTheme.primary.opacity(0.4 + 0.12 * Double(item.0.index)))
                        .annotation(position: .top) { Text("\(item.1)").font(.caption2) }
                }
                .frame(height: 180)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Прототипов", value: "\(m.prototypes)", icon: "cube.transparent.fill")
                KStatTile(title: "Экспериментов", value: "\(m.experiments)", icon: "testtube.2", color: KKSUTheme.accent)
                KStatTile(title: "Заявок Young Inventors", value: "\(m.yiApplications)", icon: "sparkles", color: .purple)
                KStatTile(title: "Инклюзивных разработок", value: "\(m.inclusiveProjects)", icon: "figure.roll", color: KKSUTheme.success)
            }

            // 88 — партнёрства
            KSectionHeader(title: "Партнёрства", icon: "handshake.fill")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Партнёров", value: "\(m.partners)", icon: "building.2.fill")
                KStatTile(title: "Стажировок", value: "\(m.internships)", icon: "briefcase.fill", color: KKSUTheme.accent)
                KStatTile(title: "Заявок на стажировки", value: "\(m.internshipApplications)", icon: "person.crop.rectangle.stack", color: .purple)
                KStatTile(title: "Учеников на стажировках", value: "\(m.internshipAccepted)", icon: "checkmark.circle.fill", color: KKSUTheme.success)
            }
            if !m.partnersByKind.isEmpty {
                KCard {
                    Text("Партнёры по типам").font(.headline)
                    Chart(m.partnersByKind, id: \.0) { item in
                        SectorMark(angle: .value("Количество", item.1), innerRadius: .ratio(0.55))
                            .foregroundStyle(by: .value("Тип", item.0.title))
                    }
                    .frame(height: 200)
                }
            }

            // 89 — международная деятельность
            KSectionHeader(title: "Международная деятельность", icon: "globe")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Стран-участниц", value: "\(m.countries)", icon: "flag.fill")
                KStatTile(title: "Международных классов", value: "\(m.globalClasses)", icon: "video.bubble.fill", color: KKSUTheme.accent)
                KStatTile(title: "Совместных проектов", value: "\(m.internationalProjects)", icon: "globe", color: KKSUTheme.success)
                KStatTile(title: "Зарубежных экспертов", value: "\(m.internationalExperts)", icon: "person.crop.square.filled.and.at.rectangle", color: .purple)
                KStatTile(title: "Международных партнёров", value: "\(m.internationalPartners)", icon: "building.2.crop.circle")
                KStatTile(title: "Международных мероприятий", value: "\(m.internationalEvents)", icon: "calendar.badge.plus", color: KKSUTheme.accent)
            }
            if store.role == .admin {
                RouteRow(route: .impactReport, subtitle: "Сформировать отчёт в PDF")
            }
            RouteRow(route: .impactPublic, subtitle: "Как показатели видят посетители сайта")
        }
    }
}

struct StudentProgressChart: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let analyses = store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }
        let counts = [RiskLevel.low, .medium, .high].map { level in (level, analyses.filter { $0.risk == level }.count) }
        KCard {
            Text("Распределение учеников по статусу").font(.headline)
            Chart(counts, id: \.0) { item in
                BarMark(x: .value("Учеников", item.1), y: .value("Статус", item.0.title))
                    .foregroundStyle(item.0.color)
            }
            .frame(height: 120)
        }
    }
}

// MARK: - Генератор KKSU Impact Report (задачи 90, 91)

struct ImpactReportData {
    let periodLabel: String
    let from: Date
    let to: Date
    let metrics: ImpactMetrics
    let highlights: String
    let topProjects: [InventionProject]
    let partners: [Partner]
    let generatedAt = Date()
}

struct ImpactReportView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var from = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var to = Date()
    @State private var highlights = "KKSU Online объединяет инклюзивное обучение, изобретательство и международное сотрудничество. За отчётный период ученики создали прототипы для людей с особыми потребностями, а педагоги прошли курсы Teacher Academy."
    @State private var pdfURL: URL?
    @State private var preview = false

    private var report: ImpactReportData {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let range = from...max(from, to)
        return ImpactReportData(
            periodLabel: "\(formatter.string(from: from)) – \(formatter.string(from: to))",
            from: from, to: to,
            metrics: ImpactMetrics(db: store.db, from: from, to: Calendar.current.date(byAdding: .day, value: 1, to: to) ?? to),
            highlights: highlights,
            topProjects: Array(store.db.projects.filter { range.contains($0.createdAt) }.sorted { $0.likes > $1.likes }.prefix(4)),
            partners: store.db.partners
        )
    }

    var body: some View {
        Form {
            Section("Период отчёта") {
                DatePicker("С", selection: $from, displayedComponents: .date)
                DatePicker("По", selection: $to, displayedComponents: .date)
                HStack {
                    Button("Квартал") { from = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(); to = Date() }
                    Button("Полгода") { from = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(); to = Date() }
                    Button("Год") { from = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(); to = Date() }
                }
                .buttonStyle(.bordered)
            }
            Section("Ключевые события периода") {
                TextField("Текст для раздела «Главное»", text: $highlights, axis: .vertical)
            }
            Section("Показатели будут рассчитаны автоматически") {
                let m = report.metrics
                KInfoRow(label: "Ученики / занятия", value: "\(m.students) / \(m.lessonsHeld)")
                KInfoRow(label: "Проекты / прототипы", value: "\(m.projects) / \(m.prototypes)")
                KInfoRow(label: "Партнёры / стажировки", value: "\(m.partners) / \(m.internships)")
                KInfoRow(label: "Страны / международные проекты", value: "\(m.countries) / \(m.internationalProjects)")
            }
            Section {
                Button("Предпросмотр отчёта") { preview = true }
                Button {
                    pdfURL = KKSUPDF.impactReport(report)
                } label: {
                    Label("Сформировать PDF", systemImage: "doc.richtext.fill")
                }
                .fontWeight(.semibold)
                if let pdfURL {
                    ShareLink(item: pdfURL) { Label("Скачать / отправить KKSU Impact Report.pdf", systemImage: "square.and.arrow.up") }
                }
            }
        }
        .navigationTitle("KKSU Impact Report")
        .sheet(isPresented: $preview) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ImpactReportPage(report: report, page: 1) { ImpactReportCover(report: report) }
                        ImpactReportPage(report: report, page: 2) { ImpactReportEducation(report: report) }
                        ImpactReportPage(report: report, page: 3) { ImpactReportProjects(report: report) }
                        ImpactReportPage(report: report, page: 4) { ImpactReportPartnerships(report: report) }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.2))
                .navigationTitle("Предпросмотр")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Закрыть") { preview = false } } }
            }
        }
    }
}

// MARK: - Страницы отчёта (A4)

struct ImpactReportPage<Content: View>: View {
    let report: ImpactReportData
    let page: Int
    let content: Content

    init(report: ImpactReportData, page: Int, @ViewBuilder content: () -> Content) {
        self.report = report
        self.page = page
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("KKSU IMPACT REPORT").font(.system(size: 10, weight: .heavy)).tracking(3)
                Spacer()
                Text(report.periodLabel).font(.system(size: 10))
            }
            .foregroundColor(KKSUTheme.primary)
            .padding(.bottom, 8)
            Rectangle().fill(KKSUTheme.primary).frame(height: 2)
            content
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                Text("KKSU Online · Comfort School-University").font(.system(size: 9))
                Spacer()
                Text("Стр. \(page)").font(.system(size: 9))
            }
            .foregroundColor(.gray)
        }
        .padding(40)
        .frame(width: KKSUPDF.a4.width, height: KKSUPDF.a4.height)
        .background(Color.white)
        .foregroundColor(.black)
    }
}

private struct ReportMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundColor(KKSUTheme.primary)
            Text(title).font(.system(size: 10)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(KKSUTheme.softBlue.opacity(0.5))
        .cornerRadius(8)
    }
}

private struct ReportGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.0) { ReportMetric(title: $0.0, value: $0.1) }
        }
    }
}

struct ImpactReportCover: View {
    let report: ImpactReportData

    var body: some View {
        let m = report.metrics
        VStack(alignment: .leading, spacing: 16) {
            Text("Отчёт о влиянии").font(.system(size: 34, weight: .bold)).foregroundColor(KKSUTheme.primary)
            Text("Период: \(report.periodLabel)").font(.system(size: 14))
            Text("Главное").font(.system(size: 16, weight: .semibold))
            Text(report.highlights).font(.system(size: 12))
            ReportGrid(items: [
                ("Учеников", "\(m.students)"), ("Педагогов", "\(m.teachers)"), ("Занятий проведено", "\(m.lessonsHeld)"),
                ("Проектов", "\(m.projects)"), ("Результатов", "\(m.results)"), ("Сертификатов", "\(m.certificates)"),
                ("Партнёров", "\(m.partners)"), ("Стран", "\(m.countries)"), ("Мероприятий", "\(m.events)")
            ])
            Text("Отчёт сформирован автоматически платформой KKSU Online \(report.generatedAt.kksuDateTime).")
                .font(.system(size: 9)).foregroundColor(.gray)
        }
    }
}

struct ImpactReportEducation: View {
    let report: ImpactReportData

    var body: some View {
        let m = report.metrics
        VStack(alignment: .leading, spacing: 16) {
            Text("1. Образовательный прогресс").font(.system(size: 20, weight: .bold)).foregroundColor(KKSUTheme.primary)
            ReportGrid(items: [
                ("Средний балл работ", "\(Int(m.averageScore * 100))%"), ("Выполнение заданий", "\(Int(m.completionRate * 100))%"), ("Посещаемость", "\(Int(m.attendanceRate * 100))%"),
                ("Сдано тестов", "\(m.testsPassed)"), ("Достижений", "\(m.achievements)"), ("Выпускников Academy", "\(m.academyGraduates)")
            ])
            Chart {
                BarMark(x: .value("Показатель", "Средний балл"), y: .value("%", m.averageScore * 100))
                BarMark(x: .value("Показатель", "Выполнение"), y: .value("%", m.completionRate * 100))
                BarMark(x: .value("Показатель", "Посещаемость"), y: .value("%", m.attendanceRate * 100))
            }
            .foregroundStyle(KKSUTheme.primary)
            .chartYScale(domain: 0...100)
            .frame(height: 220)
            Text("Инклюзивность: все видеоуроки сопровождаются субтитрами и текстовыми альтернативами, ученики получают индивидуальные траектории и учебные планы.")
                .font(.system(size: 11))
        }
    }
}

struct ImpactReportProjects: View {
    let report: ImpactReportData

    var body: some View {
        let m = report.metrics
        VStack(alignment: .leading, spacing: 16) {
            Text("2. Проекты и изобретения").font(.system(size: 20, weight: .bold)).foregroundColor(KKSUTheme.primary)
            ReportGrid(items: [
                ("Проектов", "\(m.projects)"), ("Прототипов", "\(m.prototypes)"), ("Экспериментов", "\(m.experiments)"),
                ("Заявок Young Inventors", "\(m.yiApplications)"), ("Финалистов", "\(m.yiFinalists)"), ("Инклюзивных разработок", "\(m.inclusiveProjects)")
            ])
            Chart(m.projectsByStage, id: \.0) { item in
                BarMark(x: .value("Стадия", item.0.title), y: .value("Проектов", item.1))
                    .foregroundStyle(KKSUTheme.accent)
            }
            .frame(height: 160)
            Text("Лучшие проекты периода").font(.system(size: 14, weight: .semibold))
            ForEach(report.topProjects) { project in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(project.title) — \(project.track.title), стадия \(project.stage.title)").font(.system(size: 11, weight: .semibold))
                    Text(project.summary).font(.system(size: 10))
                }
            }
        }
    }
}

struct ImpactReportPartnerships: View {
    let report: ImpactReportData

    var body: some View {
        let m = report.metrics
        VStack(alignment: .leading, spacing: 16) {
            Text("3. Партнёрства").font(.system(size: 20, weight: .bold)).foregroundColor(KKSUTheme.primary)
            ReportGrid(items: [
                ("Партнёров", "\(m.partners)"), ("Стажировок", "\(m.internships)"), ("Учеников на стажировках", "\(m.internshipAccepted)")
            ])
            Text(report.partners.map(\.name).joined(separator: " · ")).font(.system(size: 11))
            Text("4. Международная деятельность").font(.system(size: 20, weight: .bold)).foregroundColor(KKSUTheme.primary)
            ReportGrid(items: [
                ("Стран", "\(m.countries)"), ("Международных классов", "\(m.globalClasses)"), ("Совместных проектов", "\(m.internationalProjects)"),
                ("Зарубежных экспертов", "\(m.internationalExperts)"), ("Международных партнёров", "\(m.internationalPartners)"), ("Международных мероприятий", "\(m.internationalEvents)")
            ])
            Text("5. Мероприятия").font(.system(size: 20, weight: .bold)).foregroundColor(KKSUTheme.primary)
            ReportGrid(items: [("Мероприятий", "\(m.events)"), ("Участников", "\(m.eventParticipants)"), ("Сертификатов", "\(m.certificates)")])
        }
    }
}

// MARK: - Публичная страница Impact (задача 92)

struct ImpactPublicView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let m = ImpactMetrics(db: store.db)
        KPage("Наш Impact") {
            VStack(alignment: .leading, spacing: 8) {
                Text("KKSU в цифрах").font(.largeTitle.bold()).foregroundStyle(.tint)
                Text("Мы делаем образование доступным для каждого ребёнка и превращаем идеи учеников в реальные изобретения.")
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "учеников учатся в KKSU", value: "\(m.students)", icon: "graduationcap.fill")
                KStatTile(title: "занятий проведено", value: "\(m.lessonsHeld)", icon: "video.fill", color: KKSUTheme.accent)
                KStatTile(title: "проектов и изобретений", value: "\(m.projects)", icon: "lightbulb.fill", color: KKSUTheme.success)
                KStatTile(title: "прототипов создано", value: "\(m.prototypes)", icon: "cube.transparent.fill", color: .purple)
                KStatTile(title: "партнёров", value: "\(m.partners)", icon: "handshake.fill")
                KStatTile(title: "стран-участниц", value: "\(m.countries)", icon: "globe", color: KKSUTheme.accent)
                KStatTile(title: "выдано сертификатов", value: "\(m.certificates)", icon: "rosette", color: KKSUTheme.success)
                KStatTile(title: "инклюзивных разработок", value: "\(m.inclusiveProjects)", icon: "figure.roll", color: .purple)
            }
            KSectionHeader(title: "Истории изобретений", icon: "sparkles")
            ForEach(store.db.projects.filter(\.showInExhibition).sorted { $0.likes > $1.likes }.prefix(3)) { project in
                KCard {
                    Label(project.title, systemImage: project.track.icon).font(.headline)
                    Text(project.summary).font(.callout)
                    if !project.inclusiveTarget.isEmpty { KBadge(text: "Для: \(project.inclusiveTarget)", color: .purple) }
                }
            }
            KSectionHeader(title: "Партнёры", icon: "handshake.fill")
            FlowTags(tags: store.db.partners.map(\.name))
            if store.currentUser == nil {
                NavigationLink { EnrollmentApplicationView() } label: {
                    Label("Стать учеником KKSU", systemImage: "person.badge.plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Text("Данные обновляются автоматически и не содержат персональной информации.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
