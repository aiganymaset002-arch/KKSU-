import SwiftUI

struct MathCourseView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {

            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Mobile Header

                    HStack(spacing: 10) {

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(
                                    Color(red: 0.0, green: 0.20, blue: 0.49)
                                )
                                .frame(width: 40, height: 40)
                        }

                        Text("Математика")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(
                                Color(red: 0.0, green: 0.20, blue: 0.49)
                            )

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // MARK: - Progress

                    VStack(spacing: 16) {

                        HStack(alignment: .bottom) {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("Ваш прогресс")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Вы отлично справляетесь!")
                                    .font(.system(size: 17))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("78%")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(
                                    Color(red: 0.0, green: 0.20, blue: 0.49)
                                )
                        }

                        // ИСПРАВЛЕНО:
                        // Было: ProgressView(value: " 0.78")
                        // Стало: ProgressView(value: 0.78)
//                        ProgressView(value: 0.78)
//                            .tint(
//                                Color(red: 0.0, green: 0.20, blue: 0.49)
//                            )
//                            .scaleEffect(
//                                x: 1,
//                                y: 2,
//                                anchor: .center
//                            )
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // MARK: - Разделы курса

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Разделы курса")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.primary)

                        CourseModule(
                            title: "Числа",
                            subtitle: "Завершено",
                            icon: "checkmark.circle.fill",
                            state: .completed
                        )

                        CourseModule(
                            title: "Сложение и вычитание",
                            subtitle: "Завершено",
                            icon: "checkmark.circle.fill",
                            state: .completed
                        )

                        CourseModule(
                            title: "Умножение",
                            subtitle: "В процессе (Текущий урок)",
                            icon: "play.circle.fill",
                            state: .current
                        )

                        CourseModule(
                            title: "Деление",
                            subtitle: "Заблокировано",
                            icon: "lock.fill",
                            state: .locked
                        )

                        CourseModule(
                            title: "Практические задачи",
                            subtitle: "Заблокировано",
                            icon: "lock.fill",
                            state: .locked
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                    // MARK: - Кнопка

                    VStack {

                        Divider()
                            .padding(.bottom, 24)

                        Button {
                            print("Продолжить обучение")
                        } label: {

                            HStack(spacing: 10) {

                                Text("Продолжить обучение")
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .semibold
                                        )
                                    )

                                Image(systemName: "arrow.right")
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .semibold
                                        )
                                    )
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Color(
                                    red: 0.0,
                                    green: 0.20,
                                    blue: 0.49
                                )
                            )
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 120)
                }
            }

            // MARK: - Нижняя навигация

            CourseBottomNavigation()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Состояния модуля

enum CourseModuleState {
    case completed
    case current
    case locked
}

// MARK: - Модуль курса

struct CourseModule: View {

    let title: String
    let subtitle: String
    let icon: String
    let state: CourseModuleState

    var body: some View {

        Button {

            if state != .locked {
                print("Открыт раздел: \(title)")
            }

        } label: {

            HStack(spacing: 14) {

                ZStack {

                    Circle()
                        .fill(backgroundColor)

                    Image(systemName: icon)
                        .font(
                            .system(
                                size: 22,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(iconColor)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {

                    Text(title)
                        .font(
                            .system(
                                size: 15,
                                weight: state == .current
                                    ? .bold
                                    : .semibold
                            )
                        )
                        .foregroundColor(titleColor)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(subtitleColor)
                }

                Spacer()

                if state == .current {

                    VStack(spacing: 4) {

                        Text("45%")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(
                                Color(
                                    red: 0.0,
                                    green: 0.20,
                                    blue: 0.49
                                )
                            )

//                        ProgressView(value: 0.45)
//                            .tint(
//                                Color(
//                                    red: 0.0,
//                                    green: 0.20,
//                                    blue: 0.49
//                                )
//                            )
//                            .frame(width: 70)
                    }
                }

                if state != .locked {

                    Image(systemName: "chevron.right")
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(
                            state == .current
                            ? Color(
                                red: 0.0,
                                green: 0.20,
                                blue: 0.49
                            )
                            : .gray
                        )
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        borderColor,
                        lineWidth: state == .current ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(state == .locked)
    }

    private var backgroundColor: Color {

        switch state {

        case .completed:
            return Color(
                red: 0.88,
                green: 0.95,
                blue: 0.89
            )

        case .current:
            return Color(
                red: 0.88,
                green: 0.92,
                blue: 1.0
            )

        case .locked:
            return Color.gray.opacity(0.12)
        }
    }

    private var iconColor: Color {

        switch state {

        case .completed:
            return Color(
                red: 0.0,
                green: 0.35,
                blue: 0.08
            )

        case .current:
            return Color(
                red: 0.0,
                green: 0.20,
                blue: 0.49
            )

        case .locked:
            return .secondary
        }
    }

    private var titleColor: Color {

        switch state {

        case .completed:
            return .primary

        case .current:
            return Color(
                red: 0.0,
                green: 0.20,
                blue: 0.49
            )

        case .locked:
            return .secondary
        }
    }

    private var subtitleColor: Color {

        switch state {

        case .completed:
            return .secondary

        case .current:
            return Color(
                red: 0.0,
                green: 0.20,
                blue: 0.49
            )
            .opacity(0.8)

        case .locked:
            return .gray
        }
    }

    private var cardBackground: Color {

        switch state {

        case .completed:
            return .white

        case .current:
            return .white

        case .locked:
            return Color.gray.opacity(0.07)
        }
    }

    private var borderColor: Color {

        switch state {

        case .completed:
            return Color.gray.opacity(0.15)

        case .current:
            return Color(
                red: 0.0,
                green: 0.20,
                blue: 0.49
            )

        case .locked:
            return .clear
        }
    }
}

// MARK: - Нижняя навигация

struct CourseBottomNavigation: View {

    var body: some View {

        HStack {

            CourseNavItem(
                icon: "house.fill",
                title: "Главная",
                active: false
            )

            CourseNavItem(
                icon: "graduationcap.fill",
                title: "Обучение",
                active: true
            )

            CourseNavItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Прогресс",
                active: false
            )

            CourseNavItem(
                icon: "headphones",
                title: "Поддержка",
                active: false
            )

            CourseNavItem(
                icon: "person.fill",
                title: "Профиль",
                active: false
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 15,
            x: 0,
            y: -4
        )
    }
}

// MARK: - Navigation Item

struct CourseNavItem: View {

    let icon: String
    let title: String
    let active: Bool

    var body: some View {

        Button {

            print(title)

        } label: {

            VStack(spacing: 4) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 19,
                            weight: .semibold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
            }
            .foregroundColor(
                active
                ? Color(
                    red: 0.0,
                    green: 0.20,
                    blue: 0.49
                )
                : .gray
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                active
                ? Color(
                    red: 0.84,
                    green: 0.90,
                    blue: 0.94
                )
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MathCourseView()
}
