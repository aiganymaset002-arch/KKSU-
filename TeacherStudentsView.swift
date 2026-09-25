//
//  TeacherStudentsView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Список учеников педагога с уровнем риска и переходом к обзору ученика.
//

import SwiftUI

struct TeacherStudentsView: View {
    @EnvironmentObject private var store: KKSUStore
    @State private var query = ""

    var body: some View {
        List {
            ForEach(store.students.filter { query.isEmpty || $0.fullName.localizedCaseInsensitiveContains(query) }) { student in
                NavigationLink { StudentOverviewView(studentID: student.id) } label: {
                    StudentRow(studentID: student.id)
                }
            }
        }
        .searchable(text: $query, prompt: "Поиск ученика")
        .navigationTitle("Мои ученики")
    }
}
