import SwiftUI

struct LearningView: View {
    
    @State private var selectedCategory = "📚 Все предметы"
    
    let categories = [
        "📚 Все предметы",
        "🧠 Навыки",
        "💻 Цифровые навыки",
        "🤝 Социальные навыки",
        "🎯 Профориентация"
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: - Верхняя панель
                    
                    HStack {
                        HStack(spacing: 12) {
                            
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.93, blue: 0.98))
                                
                                Image(systemName: "person.fill")
                                    .foregroundColor(
                                        Color(red: 0.0, green: 0.20, blue: 0.49)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            
                            Text("Добрый день, Алия 👋")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(
                                    Color(red: 0.0, green: 0.20, blue: 0.49)
                                )
                        }
                        
                        Spacer()
                        
                        Button {
                            print("Уведомления")
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(
                                        Color(red: 0.0, green: 0.20, blue: 0.49)
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 9, height: 9)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color(red: 0.97, green: 0.98, blue: 0.99),
                                                lineWidth: 2
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    
                    // MARK: - Заголовок
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Моё обучение")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    
                    
                    // MARK: - Категории
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(
                                            selectedCategory == category
                                            ? .white
                                            : Color(red: 0.26, green: 0.29, blue: 0.33)
                                        )
                                        .padding(.horizontal, 18)
                                        .frame(height: 44)
                                        .background(
                                            selectedCategory == category
                                            ? Color(red: 0.0, green: 0.20, blue: 0.49)
                                            : Color(red: 0.92, green: 0.93, blue: 0.95)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    
                    // MARK: - Курсы
                    
                    VStack(spacing: 16) {
                        
                        CourseCard(
                            icon: "function",
                            title: "Математика",
                            subtitle: "12 из 15 заданий",
                            progress: 78,
                            iconBackground: Color(red: 0.85, green: 0.89, blue: 1.0),
                            iconColor: Color(red: 0.0, green: 0.20, blue: 0.49),
                            progressColor: Color(red: 0.0, green: 0.20, blue: 0.49)
                        )
                        
                        CourseCard(
                            icon: "book.fill",
                            title: "Русский язык",
                            subtitle: "В процессе изучения",
                            progress: 65,
                            iconBackground: Color(red: 0.84, green: 0.90, blue: 0.94),
                            iconColor: Color(red: 0.32, green: 0.38, blue: 0.41),
                            progressColor: Color(red: 0.32, green: 0.38, blue: 0.41)
                        )
                        
                        CourseCard(
                            icon: "desktopcomputer",
                            title: "Цифровая грамотность",
                            subtitle: "Почти завершено",
                            progress: 91,
                            iconBackground: Color(red: 0.64, green: 0.96, blue: 0.61),
                            iconColor: Color(red: 0.0, green: 0.35, blue: 0.08),
                            progressColor: Color(red: 0.0, green: 0.35, blue: 0.08)
                        )
                        
                        CourseCard(
                            icon: "person.3.fill",
                            title: "Социальные навыки",
                            subtitle: "Требует внимания",
                            progress: 54,
                            iconBackground: Color(red: 1.0, green: 0.86, blue: 0.84),
                            iconColor: Color(red: 0.65, green: 0.05, blue: 0.05),
                            progressColor: Color(red: 0.73, green: 0.10, blue: 0.10)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 110)
                }
            }
            
            // MARK: - Нижняя навигация
            
            BottomNavigation(selectedTab: .learning)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}


// MARK: - Карточка курса

struct CourseCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    let progress: Int
    let iconBackground: Color
    let iconColor: Color
    let progressColor: Color
    
    var body: some View {
        Button {
            print("Открыт курс: \(title)")
        } label: {
            VStack(spacing: 16) {
                
                HStack {
                    
                    HStack(spacing: 14) {
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(iconBackground)
                            
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(iconColor)
                        }
                        .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(progress)%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(progressColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            progressColor.opacity(0.12)
                        )
                        .clipShape(Capsule())
                }
                
                // Progress bar
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                        
                        Capsule()
                            .fill(progressColor)
                            .frame(
                                width: geometry.size.width * CGFloat(progress) / 100
                            )
                    }
                }
                .frame(height: 10)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.gray.opacity(0.18),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Нижняя навигация

enum AppTab {
    case home
    case learning
    case progress
    case support
    case profile
}


struct BottomNavigation: View {
    
    let selectedTab: AppTab
    
    var body: some View {
        HStack {
            
            NavigationItem(
                icon: "house.fill",
                title: "Главная",
                selected: selectedTab == .home
            )
            
            NavigationItem(
                icon: "graduationcap.fill",
                title: "Обучение",
                selected: selectedTab == .learning
            )
            
            NavigationItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Прогресс",
                selected: selectedTab == .progress
            )
            
            NavigationItem(
                icon: "headphones",
                title: "Поддержка",
                selected: selectedTab == .support
            )
            
            NavigationItem(
                icon: "person.fill",
                title: "Профиль",
                selected: selectedTab == .profile
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


struct NavigationItem: View {
    
    let icon: String
    let title: String
    let selected: Bool
    
    var body: some View {
        Button {
            print(title)
        } label: {
            VStack(spacing: 4) {
                
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(
                selected
                ? Color(red: 0.0, green: 0.20, blue: 0.49)
                : Color.gray
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selected
                ? Color(red: 0.84, green: 0.90, blue: 0.94)
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Preview

#Preview {
    LearningView()
}
