//
//  ParentProgressView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Сводка успеваемости ребёнка для родителя: оценки, посещаемость, дедлайны.
//

import SwiftUI

struct ParentProgressView: View {
    @EnvironmentObject private var store: KKSUStore
    let studentID: UUID

    var body: some View {
        let analysis = ProgressAnalyzer.analyze(studentID, db: store.db, store: store)
        VStack(alignment: .leading, spacing: 14) {
            KCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.userName(studentID)).font(.headline)
                        KBadge(text: analysis.risk.title, color: analysis.risk.color)
                        Text("Выполнение заданий: \(Int(analysis.completionRate * 100))%").font(.caption)
                        if let attendance = analysis.attendanceRate {
                            Text("Посещаемость: \(Int(attendance * 100))%").font(.caption)
                        }
                    }
                    Spacer()
                    KProgressRing(progress: analysis.overall)
                }
            }
            KSectionHeader(title: "Оценки по предметам", icon: "star.fill")
            if analysis.subjects.isEmpty { KEmptyState(text: "Оценок пока нет") }
            ForEach(analysis.subjects) { subject in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(subject.subject)
                        Spacer()
                        Text("\(Int(subject.average * 100))%").bold()
                        Image(systemName: subject.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(subject.trend >= 0 ? KKSUTheme.success : KKSUTheme.danger)
                    }
                    KProgressBar(value: subject.average)
                }
            }
            KSectionHeader(title: "Последние оценки и отзывы", icon: "text.bubble.fill")
            ForEach(store.db.submissions.filter { $0.studentID == studentID && $0.score != nil }.sorted { $0.submittedAt > $1.submittedAt }.prefix(5)) { sub in
                SubmissionSummaryRow(submission: sub)
            }
            if !analysis.overdue.isEmpty {
                KSectionHeader(title: "Просроченные задания", icon: "exclamationmark.triangle.fill")
                ForEach(analysis.overdue) { DeadlineRow(assignment: $0) }
            }
            KSectionHeader(title: "Достижения", icon: "trophy.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(store.db.achievements.filter { $0.userID == studentID }) { achievement in
                        VStack {
                            Image(systemName: achievement.icon).font(.title).foregroundStyle(KKSUTheme.accent)
                            Text(achievement.title).font(.caption).multilineTextAlignment(.center)
                        }
                        .frame(width: 110, height: 90)
                        .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}
