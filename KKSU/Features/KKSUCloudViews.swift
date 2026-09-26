//
//  KKSUCloudViews.swift
//  KKSU Online
//
//  Экран «Сервер KKSU»: подключение к Supabase, статус синхронизации,
//  подтверждение сотрудников администратором, загрузка стартового контента.
//

import SwiftUI

struct CloudSettingsView: View {
    @EnvironmentObject private var store: KKSUStore
    @ObservedObject private var cloud = KKSUCloud.shared
    @State private var confirmLeave = false

    var body: some View {
        Form {
            Section {
                Label(cloud.status.title, systemImage: statusIcon)
                    .foregroundStyle(statusColor)
                if cloud.isSignedIn {
                    Button("Синхронизировать сейчас") { Task { await cloud.sync() } }
                }
            } header: {
                Text("Статус")
            } footer: {
                Text("С сервером аккаунты, задания, оценки, чат и оплаты доступны на всех устройствах. Без сервера приложение работает в демо-режиме на одном устройстве.")
            }

            Section {
                TextField("Project URL (https://xxxx.supabase.co)", text: $cloud.projectURL)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                SecureField("anon public key", text: $cloud.anonKey)
                TextField("Код школы", text: $cloud.schoolID)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("Подключение к Supabase")
            } footer: {
                Text("Данные проекта: Supabase → Settings → API. Чтобы не вводить их на каждом устройстве, впишите их в KKSUCloudDefaults (файл KKSU/Core/KKSUCloud.swift) перед сборкой. Пошаговая инструкция — backend/README.md.")
            }
            .disabled(cloud.isSignedIn)

            if cloud.isSignedIn && store.role == .admin {
                Section {
                    let pending = cloud.members.filter { !$0.approved && !$0.blocked }
                    if pending.isEmpty { Text("Новых заявок нет").foregroundStyle(.secondary) }
                    ForEach(pending) { member in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.full_name.isEmpty ? "Без имени" : member.full_name)
                                Text(member.kksuRole.title).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Подтвердить") { Task { try? await cloud.updateMember(member.user_id, approved: true) } }
                                .buttonStyle(.borderedProminent)
                            Button(role: .destructive) { Task { try? await cloud.updateMember(member.user_id, blocked: true) } } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("Сотрудники ожидают подтверждения")
                } footer: {
                    Text("Педагоги, психологи, эксперты, наставники и администраторы получают доступ к данным учеников только после подтверждения.")
                }
                Section {
                    Text("Всего участников: \(cloud.members.count)")
                    ForEach(KKSURole.allCases) { role in
                        let count = cloud.members.filter { $0.kksuRole == role && $0.approved }.count
                        if count > 0 { KInfoRow(label: role.title, value: "\(count)") }
                    }
                    Button("Обновить список") { Task { await cloud.loadMembers() } }
                } header: {
                    Text("Участники школы")
                }
                Section {
                    Button("Загрузить стартовый учебный контент") { Task { await cloud.uploadStarterContent() } }
                } footer: {
                    Text("Программы, библиотека, тесты, курсы Teacher Academy и Future Engineers, партнёры, мероприятия и цены из демо-набора — без демо-пользователей. Потом их можно отредактировать.")
                }
            }

            if cloud.isConfigured && store.cloudDataLoaded {
                Section {
                    Button("Отключиться и вернуться к демо-режиму", role: .destructive) { confirmLeave = true }
                } footer: {
                    Text("Данные на сервере не удаляются. На этом устройстве снова появятся демо-данные.")
                }
            }
        }
        .navigationTitle("Сервер KKSU")
        .task { await cloud.loadMembers() }
        .confirmationDialog("Выйти из аккаунта и вернуться к демо-данным?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Вернуться к демо-режиму", role: .destructive) {
                Task {
                    await cloud.signOut()
                    cloud.projectURL = ""
                    cloud.anonKey = ""
                    store.leaveCloudMode()
                }
            }
        }
    }

    private var statusIcon: String {
        switch cloud.status {
        case .localOnly: return "iphone"
        case .signedOut: return "person.crop.circle.badge.questionmark"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud.fill"
        case .failed: return "exclamationmark.icloud.fill"
        }
    }

    private var statusColor: Color {
        switch cloud.status {
        case .synced: return KKSUTheme.success
        case .failed: return KKSUTheme.danger
        case .syncing: return KKSUTheme.warning
        default: return .secondary
        }
    }
}

/// Небольшой индикатор синхронизации для шапок кабинетов.
struct CloudStatusBadge: View {
    @ObservedObject private var cloud = KKSUCloud.shared

    var body: some View {
        if cloud.isConfigured {
            switch cloud.status {
            case .syncing: Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(KKSUTheme.warning)
            case .failed: Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(KKSUTheme.danger)
            case .synced: Image(systemName: "checkmark.icloud").foregroundStyle(KKSUTheme.success)
            default: EmptyView()
            }
        }
    }
}
