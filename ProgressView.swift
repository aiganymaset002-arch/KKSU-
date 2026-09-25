import SwiftUI

/// Переименовано из `ProgressView`, чтобы не перекрывать `SwiftUI.ProgressView` во всём модуле.
struct StudentProgressView: View {

    // MARK: - Colors

    private let backgroundColor = Color(red: 0.969, green: 0.976, blue: 0.988)
    private let primaryColor = Color(red: 0.0, green: 0.196, blue: 0.490)
    private let primaryFixedColor = Color(red: 0.855, green: 0.886, blue: 1.0)
    private let surfaceColor = Color.white
    private let surfaceHighColor = Color(red: 0.902, green: 0.910, blue: 0.922)
    private let secondaryColor = Color(red: 0.322, green: 0.376, blue: 0.412)
    private let secondaryContainerColor = Color(red: 0.827, green: 0.886, blue: 0.929)
    private let onSecondaryContainerColor = Color(red: 0.337, green: 0.396, blue: 0.431)

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Верхняя панель
                topBar

                // ОДИН общий ScrollView
                ScrollView(showsIndicators: false) {
                    mainContent
                }

                // Нижняя навигация остаётся закреплённой
                bottomNavigation
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {

                ZStack {
                    Circle()
                        .fill(surfaceHighColor)

                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(secondaryColor)
                }
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )

                Text("Добрый день, Алия 👋")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                // Уведомления
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(primaryColor)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(backgroundColor)
    }

    // MARK: - Main Content

    private var mainContent: some View {

        VStack(alignment: .leading, spacing: 24) {

            // =====================================================
            // ОБРАЗОВАТЕЛЬНАЯ ТРАЕКТОРИЯ
            // =====================================================

            VStack(alignment: .leading, spacing: 8) {

                Text("Моя образовательная траектория")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.098, green: 0.110, blue: 0.118))

                Text("Твой прогресс и следующие шаги к успеху.")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.263, green: 0.275, blue: 0.325))
            }

            // Текущий уровень

            trajectoryCard(
                icon: "star.fill",
                title: "Текущий уровень",
                description: "Ты уверенно двигаешься вперед! Твои базовые знания прочны, и ты готов к новым вызовам.",
                badge: "Уровень: Базовый +"
            )

            // Математика

            progressGoalCard(
                icon: "function",
                title: "Следующая цель",
                subject: "Математика",
                progress: 65,
                target: 80,
                description: "Осталось совсем немного до перехода на продвинутый уровень решения задач."
            )

            // Коммуникация

            progressGoalCard(
                icon: "bubble.left.and.bubble.right",
                title: "Следующий навык",
                subject: "Коммуникация",
                progress: 54,
                target: 70,
                description: nil
            )

            // Цифровые навыки

            progressGoalCard(
                icon: "laptopcomputer",
                title: "Следующий этап",
                subject: "Цифровые навыки",
                progress: 82,
                target: 90,
                description: nil
            )

            // =====================================================
            // МОЙ ПРОГРЕСС
            // =====================================================

            Text("Мой прогресс")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryColor)
                .padding(.top, 12)

            // Общий прогресс

            overallProgressCard

            // Прогресс по предметам

            subjectsProgressCard

            // Активность

            weeklyActivityCard

            // Достижения

            achievementsSection

            // Кнопка

            Button {
                // Открыть подробности
            } label: {

                HStack(spacing: 8) {
                    Text("Подробнее")

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(primaryColor)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 120)
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trajectory Card

    private func trajectoryCard(
        icon: String,
        title: String,
        description: String,
        badge: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(primaryFixedColor)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
                .frame(width: 64, height: 64)

                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(red: 0.098, green: 0.110, blue: 0.118))
            }

            Text(description)
                .font(.system(size: 17))
                .foregroundColor(Color(red: 0.263, green: 0.275, blue: 0.325))

            Text(badge)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(onSecondaryContainerColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(secondaryContainerColor)
                .clipShape(Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 10
        )
    }

    // MARK: - Goal Card

    private func progressGoalCard(
        icon: String,
        title: String,
        subject: String,
        progress: Int,
        target: Int,
        description: String?
    ) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {

                Image(systemName: icon)
                    .foregroundColor(primaryColor)
                    .font(.system(size: 20))

                Text(title)
                    .font(.system(size: 22, weight: .semibold))

                Spacer()

                Text(subject)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {

                Text("Текущий результат")
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 5) {

                    Text("\(progress)%")
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(primaryColor)

                    Text("\(target)%")
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                }
            }

            GeometryReader { geometry in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(surfaceHighColor)
                        .frame(height: 10)

                    Capsule()
                        .fill(primaryColor)
                        .frame(
                            width: geometry.size.width * CGFloat(progress) / 100,
                            height: 10
                        )
                }
            }
            .frame(height: 10)

            if let description = description {

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 10
        )
    }

    // MARK: - Overall Progress

    private var overallProgressCard: some View {

        VStack(spacing: 12) {

            Text("Общий прогресс обучения")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {

                Text("72")
                    .font(.system(size: 64, weight: .bold))

                Text("%")
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundColor(primaryColor)

            GeometryReader { geometry in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(surfaceHighColor)
                        .frame(height: 12)

                    Capsule()
                        .fill(primaryColor)
                        .frame(
                            width: geometry.size.width * 0.72,
                            height: 12
                        )
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 25)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 10
        )
    }

    // MARK: - Subjects Progress

    private var subjectsProgressCard: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Прогресс по предметам")
                .font(.system(size: 22, weight: .semibold))

            HStack(alignment: .bottom, spacing: 20) {

                subjectBar(
                    title: "Матем",
                    height: 130,
                    opacity: 1.0
                )

                subjectBar(
                    title: "Чтение",
                    height: 75,
                    opacity: 0.35
                )

                subjectBar(
                    title: "Логика",
                    height: 100,
                    opacity: 0.55
                )

                subjectBar(
                    title: "Письмо",
                    height: 145,
                    opacity: 0.8
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
        }
        .padding(16)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 10
        )
    }

    private func subjectBar(
        title: String,
        height: CGFloat,
        opacity: Double
    ) -> some View {

        VStack {

            Spacer()

            RoundedRectangle(cornerRadius: 7)
                .fill(primaryColor.opacity(opacity))
                .frame(height: height)

            Text(title)
                .font(.caption)
        }
    }

    // MARK: - Weekly Activity

    private var weeklyActivityCard: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Активность за неделю")
                .font(.system(size: 22, weight: .semibold))

            HStack(alignment: .bottom, spacing: 10) {

                ForEach(
                    [40, 70, 50, 90, 60, 80, 100],
                    id: \.self
                ) { height in

                    RoundedRectangle(cornerRadius: 5)
                        .fill(primaryColor.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: CGFloat(height))
                }
            }
            .frame(height: 150)
        }
        .padding(16)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 10
        )
    }

    // MARK: - Achievements

    private var achievementsSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Мои достижения")
                .font(.system(size: 22, weight: .semibold))

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {

                achievementCard(
                    emoji: "🏆",
                    title: "Первые 10 заданий"
                )

                achievementCard(
                    emoji: "📚",
                    title: "7 дней обучения"
                )

                achievementCard(
                    emoji: "🧠",
                    title: "Новый навык"
                )

                achievementCard(
                    emoji: "🎯",
                    title: "Достигнута цель"
                )
            }
        }
    }

    private func achievementCard(
        emoji: String,
        title: String
    ) -> some View {

        VStack(spacing: 8) {

            Text(emoji)
                .font(.system(size: 32))

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 5
        )
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {

        HStack {

            bottomItem(
                icon: "house",
                title: "Главная",
                active: false
            )

            bottomItem(
                icon: "graduationcap",
                title: "Обучение",
                active: false
            )

            bottomItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Прогресс",
                active: true
            )

            bottomItem(
                icon: "person.2",
                title: "Поддержка",
                active: false
            )

            bottomItem(
                icon: "person",
                title: "Профиль",
                active: false
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(surfaceColor)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                topTrailingRadius: 16
            )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 10,
            x: 0,
            y: -4
        )
    }

    private func bottomItem(
        icon: String,
        title: String,
        active: Bool
    ) -> some View {

        Button {
            // Навигация
        } label: {

            VStack(spacing: 4) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 20,
                            weight: active ? .bold : .regular
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
            }
            .foregroundColor(
                active
                ? primaryColor
                : secondaryColor
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                active
                ? secondaryContainerColor
                : Color.clear
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    StudentProgressView()
}
