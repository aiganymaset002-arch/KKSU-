//
//  RegistrationView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Задача 2: регистрация пользователей с выбором роли (задача 4).
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss

    var initialRole: KKSURole = .student

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var role: KKSURole = .student
    @State private var childEmail = ""
    @State private var acceptTerms = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Создайте аккаунт KKSU Online")
                    .font(.title2.bold())

                Text("Роль").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                    ForEach(KKSURole.selfRegistrable) { item in
                        RoleCard(role: item, selected: role == item) { role = item }
                    }
                }

                CustomTextField(title: "ФИО", text: $fullName, icon: "person")
                CustomTextField(title: "Email", text: $email, icon: "envelope", isEmail: true)
                CustomTextField(title: "Телефон", text: $phone, icon: "phone")
                CustomTextField(title: "Пароль (от 8 символов, с цифрой)", text: $password, icon: "lock", isSecure: true)
                CustomTextField(title: "Повторите пароль", text: $confirm, icon: "lock.rotation", isSecure: true)

                if role == .parent {
                    CustomTextField(title: "Email ребёнка в KKSU (необязательно)", text: $childEmail, icon: "figure.and.child.holdinghands", isEmail: true)
                }

                PasswordStrengthView(password: password)

                Toggle(isOn: $acceptTerms) {
                    Text("Я принимаю правила платформы и согласен на обработку персональных данных")
                        .font(.footnote)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(KKSUTheme.danger)
                }

                PrimaryButton(title: "Зарегистрироваться", icon: "person.badge.plus") { register() }
                    .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Регистрация")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
        }
        .onAppear { role = initialRole == .admin ? .student : initialRole }
    }

    private func register() {
        guard password == confirm else {
            errorMessage = "Пароли не совпадают."
            return
        }
        guard acceptTerms else {
            errorMessage = "Необходимо принять правила платформы."
            return
        }
        do {
            let user = try store.register(fullName: fullName, email: email, phone: phone, password: password, role: role)
            let childMail = childEmail.trimmingCharacters(in: .whitespaces).lowercased()
            if role == .parent, !childMail.isEmpty,
               let child = store.db.users.first(where: { $0.email == childMail && $0.role == .student }),
               let index = store.db.users.firstIndex(where: { $0.id == user.id }) {
                store.db.users[index].linkedStudentIDs.append(child.id)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PasswordStrengthView: View {
    let password: String

    private var score: Int {
        var value = 0
        if password.count >= 8 { value += 1 }
        if password.contains(where: \.isNumber) { value += 1 }
        if password.contains(where: \.isUppercase) { value += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { value += 1 }
        return value
    }

    var body: some View {
        if !password.isEmpty {
            let labels = ["Очень слабый", "Слабый", "Средний", "Хороший", "Надёжный"]
            let colors: [Color] = [KKSUTheme.danger, KKSUTheme.danger, KKSUTheme.warning, KKSUTheme.success, KKSUTheme.success]
            VStack(alignment: .leading, spacing: 4) {
                KProgressBar(value: Double(score) / 4, color: colors[score])
                Text("Надёжность пароля: \(labels[score])").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack { RegistrationView() }
        .environmentObject(KKSUStore(inMemory: true))
}
