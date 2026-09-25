//
//  ParentHomeView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Задача 6: кабинет родителя.
//

import SwiftUI

struct ParentHomeView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var selectedChildID: UUID?

    var body: some View {
        let children = store.visibleStudents
        let childID = selectedChildID ?? children.first?.id
        KPage("Кабинет родителя") {
            CabinetHeader(subtitle: "Прогресс и безопасность вашего ребёнка")
            if children.isEmpty {
                KEmptyState(text: "К аккаунту не привязан ни один ребёнок. Подайте заявку на обучение или попросите администратора привязать аккаунт ребёнка.", icon: "person.crop.circle.badge.plus")
                RouteRow(route: .application)
            } else {
                if children.count > 1 {
                    Picker("Ребёнок", selection: Binding(get: { childID }, set: { selectedChildID = $0 })) {
                        ForEach(children) { Text($0.fullName).tag(UUID?.some($0.id)) }
                    }
                    .pickerStyle(.segmented)
                }
                if let childID {
                    ParentProgressView(studentID: childID)
                    KSectionHeader(title: "Для родителя", icon: "person.2.fill")
                    KCard {
                        RouteRow(route: .consents, subtitle: "Подписать или отозвать согласия")
                        Divider()
                        RouteRow(route: .intake, subtitle: "Анкета первичного поступления")
                        Divider()
                        RouteRow(route: .schedule, subtitle: "Расписание занятий")
                        Divider()
                        RouteRow(route: .progressAnalysis, subtitle: "Подробный анализ прогресса")
                        Divider()
                        if let teacher = store.users(with: .teacher).first {
                            NavigationLink { ChatThreadView(otherID: teacher.id) } label: {
                                Label("Написать педагогу — \(teacher.fullName)", systemImage: "bubble.left.and.bubble.right.fill")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ParentHomeView() }
        .environmentObject(KKSUStore(inMemory: true))
}
