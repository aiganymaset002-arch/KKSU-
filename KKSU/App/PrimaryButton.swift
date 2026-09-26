//
//  PrimaryButton.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 21.08.2026.
//

import SwiftUI

/// Основная кнопка платформы. Учитывает настройку «Крупные кнопки».
struct PrimaryButton: View {
    @Environment(\.kksuAccessibility) private var a11y

    let title: String
    var icon: String?
    var isLoading = false
    var style: Style = .filled
    let action: () -> Void

    enum Style { case filled, outlined }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    SwiftUI.ProgressView().tint(style == .filled ? .white : KKSUTheme.primary)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: a11y.largeButtons ? 64 : 52)
            .foregroundStyle(style == .filled ? Color.white : a11y.tint)
            .background {
                if style == .filled {
                    RoundedRectangle(cornerRadius: 14).fill(a11y.tint)
                } else {
                    RoundedRectangle(cornerRadius: 14).stroke(a11y.tint, lineWidth: a11y.highContrast ? 3 : 1.5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack {
        PrimaryButton(title: "Войти", icon: "arrow.right") {}
        PrimaryButton(title: "Создать аккаунт", style: .outlined) {}
    }
    .padding()
}
