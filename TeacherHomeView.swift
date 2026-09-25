//
//  TeacherHomeView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Задача 7: кабинет преподавателя.
//

import SwiftUI

struct TeacherHomeView: View {
    @EnvironmentObject private var store: KKSUStore

    var body: some View {
        let me = store.currentUser?.id
        let mySessions = store.db.sessions.filter { $0.teacherID == me || store.role == .admin }
        let today = mySessions.filter { Calendar.current.isDateInToday($0.start) }.sorted { $0.start < $1.start }
        let myAssignments = Set(store.db.assignments.filter { $0.teacherID == me || store.role == .admin }.map(\.id))
        let toGrade = store.db.submissions.filter { $0.status == .submitted && myAssignments.contains($0.assignmentID) }
        let pendingAI = store.db.assignments.filter { $0.isAIGenerated && !$0.approvedByTeacher }
        let analyses = store.students.map { ProgressAnalyzer.analyze($0.id, db: store.db, store: store) }
        let insights = TeacherInsightEngine.insights(for: analyses, store: store)

        KPage("Кабинет педагога") {
            CabinetHeader(subtitle: "Ваши занятия, работы и ученики")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                KStatTile(title: "Занятий сегодня", value: "\(today.count)", icon: "clock.fill")
                KStatTile(title: "Работ на проверку", value: "\(toGrade.count)", icon: "tray.full.fill", color: KKSUTheme.accent)
                KStatTile(title: "AI-заданий ждут проверки", value: "\(pendingAI.count)", icon: "sparkles", color: .purple)
                KStatTile(title: "Учеников в зоне риска", value: "\(analyses.filter { $0.risk == .high }.count)", icon: "exclamationmark.triangle.fill", color: KKSUTheme.danger)
            }
            KSectionHeader(title: "Сегодня", icon: "sun.max.fill")
            if today.isEmpty { KEmptyState(text: "Сегодня занятий нет", icon: "cup.and.saucer") }
            ForEach(today) { SessionCard(session: $0) }

            if !pendingAI.isEmpty {
                KSectionHeader(title: "Задания от AI — нужна ваша проверка", icon: "sparkles")
                ForEach(pendingAI) { assignment in
                    NavigationLink { AIAssignmentReviewView(assignmentID: assignment.id) } label: {
                        KCard {
                            Text(assignment.title).font(.headline)
                            Text("Для: \(assignment.assignedIDs.map { store.userName($0) }.joined(separator: ", "))").font(.caption)
                            KBadge(text: "Не видно ученику до утверждения", color: .purple)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            KSectionHeader(title: "Рекомендации на основе данных", icon: "lightbulb.fill")
            ForEach(insights.prefix(3)) { InsightCard(insight: $0) }
            RouteRow(route: .teacherRecommendations, subtitle: "Все рекомендации")

            KSectionHeader(title: "Инструменты", icon: "wrench.and.screwdriver.fill")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach([KKSURoute.grading, .homework, .testBuilder, .schedule, .aiTaskGenerator, .teacherAI, .progressAnalysis, .teacherAcademy], id: \.self) {
                    RouteTile(route: $0)
                }
            }
            RouteRow(route: .teacherMarketplace, subtitle: "Разместите собственный курс")
            NavigationLink { TeacherStudentsView() } label: {
                Label("Мои ученики", systemImage: "person.3.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct InsightCard: View {
    let insight: TeacherInsight

    var body: some View {
        KCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.icon)
                    .foregroundStyle(insight.priority.color)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title).font(.callout.weight(.semibold))
                    Text(insight.action).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { TeacherHomeView() }
        .environmentObject(KKSUStore(inMemory: true))
}
