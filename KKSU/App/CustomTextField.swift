//
//  CustomTextField.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//

import SwiftUI

/// Поле ввода в стиле платформы с иконкой и режимом пароля.
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var icon: String?
    var isSecure = false
    var isEmail = false

    @State private var reveal = false

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 22)
            }
            Group {
                if isSecure && !reveal {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textFieldStyle(.plain)
            #if os(iOS)
            .keyboardType(isEmail ? .emailAddress : .default)
            .textInputAutocapitalization(isSecure || isEmail ? .never : .sentences)
            #endif
            .autocorrectionDisabled(isSecure || isEmail)
            if isSecure {
                Button { reveal.toggle() } label: {
                    Image(systemName: reveal ? "eye.slash" : "eye").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(reveal ? "Скрыть пароль" : "Показать пароль")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
}
