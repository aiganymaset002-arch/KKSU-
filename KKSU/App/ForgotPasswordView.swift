//
//  ForgotPasswordView.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//
//  Задача 3: восстановление пароля по одноразовому коду.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var store: KKSUStore
    @Environment(\.dismiss) private var dismiss

    @State var email: String = ""
    @State private var step = 0
    @State private var code = ""
    @State private var newPassword = ""
    @State private var sentCode: String?
    @State private var errorMessage: String?
    @State private var done = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: done ? "checkmark.shield.fill" : "key.horizontal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity)

                if done {
                    Text("Пароль изменён").font(.title2.bold())
                    Text("Теперь войдите с новым паролем.").foregroundStyle(.secondary)
                    PrimaryButton(title: "Вернуться ко входу") { dismiss() }
                } else if step == 0 {
                    Text("Восстановление пароля").font(.title2.bold())
                    Text("Введите email — мы отправим одноразовый код (действует 15 минут).")
                        .foregroundStyle(.secondary)
                    CustomTextField(title: "Email", text: $email, icon: "envelope", isEmail: true)
                    PrimaryButton(title: "Получить код", icon: "paperplane.fill") { requestCode() }
                } else {
                    Text("Введите код и новый пароль").font(.title2.bold())
                    if let sentCode {
                        Label("Демо-режим: код отправлен во входящие уведомления аккаунта — \(sentCode)", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    CustomTextField(title: "Код из письма", text: $code, icon: "number")
                    CustomTextField(title: "Новый пароль", text: $newPassword, icon: "lock", isSecure: true)
                    PasswordStrengthView(password: newPassword)
                    PrimaryButton(title: "Сменить пароль", icon: "checkmark") { reset() }
                    Button("Отправить код повторно") { requestCode() }
                        .font(.footnote)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(KKSUTheme.danger)
                }
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Забыли пароль?")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } }
        }
    }

    private func requestCode() {
        do {
            sentCode = try store.requestPasswordReset(email: email)
            errorMessage = nil
            step = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reset() {
        do {
            try store.resetPassword(email: email, code: code, newPassword: newPassword)
            errorMessage = nil
            done = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { ForgotPasswordView() }
        .environmentObject(KKSUStore(inMemory: true))
}
