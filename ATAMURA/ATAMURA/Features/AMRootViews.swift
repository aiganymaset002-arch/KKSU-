//
//  AMRootViews.swift
//  ATA MURA
//
//  Корневой экран, приветствие, вход и регистрация, выбор языка и комфортного режима,
//  вкладки приложения.
//

import SwiftUI

struct AMRootView: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        Group {
            if store.currentUser != nil {
                AMMainTabs()
            } else {
                AMWelcomeView()
            }
        }
        // При смене языка интерфейс полностью перерисовывается.
        .id(store.language)
        .amInclusive(store.inclusiveMode)
        .task {
            AMCloud.shared.start(with: store)
        }
    }
}

// MARK: - Вкладки

struct AMMainTabs: View {
    @EnvironmentObject private var store: AMStore
    @State private var tab = 0
    @State private var showCreate = false

    var body: some View {
        TabView(selection: $tab) {
            AMHomeView()
                .tabItem { Label(L("tab.home"), systemImage: "house.fill") }
                .tag(0)
            AMMapView()
                .tabItem { Label(L("tab.map"), systemImage: "map.fill") }
                .tag(1)
            Color.clear
                .tabItem { Label(L("tab.create"), systemImage: "plus.circle.fill") }
                .tag(2)
            AMAssistantView()
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(3)
            AMMyProfileView()
                .tabItem { Label(L("tab.profile"), systemImage: "person.crop.circle") }
                .badge(store.unreadCount + store.myInvites.count)
                .tag(4)
        }
        .onChange(of: tab) { old, new in
            // Вкладка «Создать» открывает меню и возвращает на прежнюю вкладку.
            if new == 2 {
                tab = old
                showCreate = true
            }
        }
        .sheet(isPresented: $showCreate) {
            AMCreateMenu()
        }
    }
}

// MARK: - Приветствие

struct AMWelcomeView: View {
    @EnvironmentObject private var store: AMStore
    @State private var showLogin = false
    @State private var showRegister = false

    private let path = ["tarih", "person", "idea", "research", "invention", "future"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AMLanguagePicker()
                    VStack(spacing: 10) {
                        AMLogo(size: 96)
                        Text("ATA MURA").font(.system(size: 40, weight: .heavy, design: .serif))
                        Text("Digital Heritage & Innovation Platform").font(.subheadline).foregroundStyle(.secondary)
                        Text("Heritage creates innovation.").font(.headline).foregroundStyle(AMTheme.skyDeep)
                    }
                    AMCard {
                        Text(L("welcome.slogan.1")).font(.headline)
                        Text(L("welcome.slogan.2")).font(.headline)
                        Text(L("welcome.slogan.3")).font(.headline)
                    }
                    AMFlowLayout(spacing: 6) {
                        ForEach(path.indices, id: \.self) { index in
                            HStack(spacing: 6) {
                                AMTag(text: L("path.\(path[index])"))
                                if index < path.count - 1 {
                                    Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Text(L("welcome.about")).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    VStack(spacing: 12) {
                        Button {
                            showRegister = true
                        } label: {
                            Text(L("auth.register")).frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            showLogin = true
                        } label: {
                            Text(L("auth.login")).frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.large)
                }
                .padding(20)
            }
            .sheet(isPresented: $showLogin) { AMLoginView() }
            .sheet(isPresented: $showRegister) { AMRegisterView() }
        }
    }
}

/// Знак ATA MURA: солнце над степью (рисуется кодом, без картинок).
struct AMLogo: View {
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle().fill(AMTheme.heroGradient)
            ForEach(0..<16, id: \.self) { index in
                Capsule()
                    .fill(AMTheme.gold)
                    .frame(width: size * 0.04, height: size * 0.12)
                    .offset(y: -size * 0.33)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }
            Circle().fill(AMTheme.gold).frame(width: size * 0.36, height: size * 0.36)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct AMLanguagePicker: View {
    @EnvironmentObject private var store: AMStore

    var body: some View {
        Picker(L("settings.language"), selection: $store.language) {
            ForEach(AMLanguage.allCases) { language in
                Text(language.nativeName).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(L("settings.language"))
    }
}

// MARK: - Вход

struct AMLoginView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloud = AMCloud.shared
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var busy = false
    @State private var resetSent = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("auth.email"), text: $email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    SecureField(L("auth.password"), text: $password).textContentType(.password)
                }
                if let error {
                    Section { Text(error).foregroundStyle(AMTheme.danger) }
                }
                Section {
                    Button {
                        Task { await login() }
                    } label: {
                        if busy { ProgressView() } else { Text(L("auth.login")).bold() }
                    }
                    .disabled(email.isEmpty || password.isEmpty || busy)
                    if cloud.isConfigured {
                        Button(L("auth.forgot")) {
                            Task {
                                do {
                                    try await cloud.requestPasswordReset(email: email)
                                    resetSent = true
                                } catch {
                                    self.error = error.localizedDescription
                                }
                            }
                        }
                        .disabled(email.isEmpty)
                    }
                }
                if resetSent {
                    Section { Text(L("auth.resetSent")).foregroundStyle(.secondary) }
                }
                Section {
                    Label(cloud.status.title, systemImage: cloud.isConfigured ? "icloud" : "iphone")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L("auth.login"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            }
        }
    }

    private func login() async {
        busy = true
        defer { busy = false }
        do {
            if cloud.isConfigured {
                try await cloud.signIn(email: email, password: password)
            } else {
                try store.login(email: email, password: password)
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Регистрация

struct AMRegisterView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cloud = AMCloud.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var city = ""
    @State private var region: AMRegion?
    @State private var birthYear = ""
    @State private var mode: AMInclusiveMode = .standard
    @State private var acceptTerms = false
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L("auth.section.account")) {
                    TextField(L("auth.name"), text: $name).textContentType(.name)
                    TextField(L("auth.email"), text: $email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    SecureField(L("auth.password"), text: $password).textContentType(.newPassword)
                    Text(L("auth.passwordHint")).font(.caption).foregroundStyle(.secondary)
                }
                Section(L("auth.section.about")) {
                    TextField(L("profile.city"), text: $city)
                    Picker(L("common.region"), selection: $region) {
                        Text(L("common.notSelected")).tag(AMRegion?.none)
                        ForEach(AMRegion.allCases) { Text($0.title).tag(AMRegion?.some($0)) }
                    }
                    TextField(L("auth.birthYear"), text: $birthYear).keyboardType(.numberPad)
                }
                Section {
                    AMInclusiveModePicker(mode: $mode)
                } header: {
                    Text(L("inclusive.title"))
                } footer: {
                    Text(L("inclusive.footer"))
                }
                Section {
                    Toggle(L("auth.terms"), isOn: $acceptTerms)
                }
                if let error {
                    Section { Text(error).foregroundStyle(AMTheme.danger) }
                }
                Section {
                    Button {
                        Task { await register() }
                    } label: {
                        if busy { ProgressView() } else { Text(L("auth.register")).bold() }
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || !acceptTerms || busy)
                }
            }
            .navigationTitle(L("auth.register"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("common.cancel")) { dismiss() } }
            }
        }
    }

    private func register() async {
        busy = true
        defer { busy = false }
        do {
            if cloud.isConfigured {
                try await cloud.signUp(fullName: name, email: email, password: password)
                store.updateCurrentUser { user in
                    user.city = city
                    user.region = region
                    user.birthYear = Int(birthYear)
                }
            } else {
                try store.register(fullName: name, email: email, password: password, city: city, region: region, birthYear: Int(birthYear))
            }
            store.inclusiveMode = mode
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Выбор комфортного режима (INCLUSIVE MODE).
struct AMInclusiveModePicker: View {
    @Binding var mode: AMInclusiveMode

    var body: some View {
        ForEach(AMInclusiveMode.allCases) { option in
            Button {
                mode = option
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: option.icon).frame(width: 28).foregroundStyle(AMTheme.skyDeep)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title).foregroundStyle(.primary)
                        Text(option.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if mode == option { Image(systemName: "checkmark.circle.fill").foregroundStyle(AMTheme.success) }
                }
            }
            .accessibilityAddTraits(mode == option ? .isSelected : [])
        }
    }
}
