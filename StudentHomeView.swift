import SwiftUI

struct StudentHomeView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            
            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: Верхняя панель
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                
                                Text("Добрый день, Алия 👋")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(
                                        Color(
                                            red: 0.0,
                                            green: 0.20,
                                            blue: 0.49
                                        )
                                    )
                                
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                
                                Button {
                                    print("Уведомления")
                                } label: {
                                    Image(systemName: "bell")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, height: 40)
                                }
                                
                                Button {
                                    print("Профиль")
                                } label: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            Color(
                                                red: 0.0,
                                                green: 0.20,
                                                blue: 0.49
                                            )
                                        )
                                }
                            }
                        }
                        
                        
                        // MARK: Продолжим обучение
                        
                        VStack(alignment: .leading, spacing: 14) {
                            
                            Text("Продолжим обучение?")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    
                                    Text("Мой прогресс")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(
                                            Color(
                                                red: 0.0,
                                                green: 0.20,
                                                blue: 0.49
                                            )
                                        )
                                    
                                    Text("Вы продвинулись на 8% за эту неделю")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )
                                }
                                
                                Spacer()
                                
                                ProgressCircle(progress: 0.72)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(
                                color: Color.black.opacity(0.05),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                        }
                        
                        
                        // MARK: Сегодня
                        
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Text("Сегодня")
                                .font(.system(size: 22, weight: .semibold))
                            
                            VStack(spacing: 12) {
                                
                                LessonCard(
                                    icon: "plus.forwardslash.minus",
                                    title: "Математика",
                                    subtitle: "Задание 3 из 5",
                                    progress: 0.60
                                )
                                
                                LessonCard(
                                    icon: "book.fill",
                                    title: "Русский язык",
                                    subtitle: "Прочитать текст",
                                    progress: 0.10
                                )
                                
                                LessonCard(
                                    icon: "laptopcomputer",
                                    title: "Цифровая грамотность",
                                    subtitle: "Интерактивное задание",
                                    progress: nil
                                )
                            }
                        }
                        
                        
                        // MARK: Моя цель
                        
                        VStack(alignment: .leading, spacing: 16) {
                            
                            HStack(alignment: .top, spacing: 10) {
                                
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(
                                        Color(
                                            red: 0.0,
                                            green: 0.20,
                                            blue: 0.49
                                        )
                                    )
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    
                                    Text("Моя цель")
                                        .font(.system(size: 21, weight: .semibold))
                                        .foregroundColor(
                                            Color(
                                                red: 0.0,
                                                green: 0.20,
                                                blue: 0.49
                                            )
                                        )
                                    
                                    Text("Подготовиться к следующему уровню обучения")
                                        .font(.system(size: 15))
                                        .foregroundColor(
                                            Color(
                                                red: 0.0,
                                                green: 0.26,
                                                blue: 0.62
                                            )
                                        )
                                }
                            }
                            
//                            ProgressView(value: 0.45)
//                                .progressViewStyle(
//                                    LinearProgressViewStyle(
//                                        tint: Color(
//                                            red: 0.0,
//                                            green: 0.20,
//                                            blue: 0.49
//                                        )
//                                    )
//                                )
//                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                        .padding(20)
                        .background(
                            Color(
                                red: 0.85,
                                green: 0.89,
                                blue: 1.0
                            )
                        )
                        .cornerRadius(18)
                        
                        
                        // MARK: AI-помощник
                        
                        HStack(alignment: .top, spacing: 14) {
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 22))
                                .foregroundColor(
                                    Color(
                                        red: 0.0,
                                        green: 0.20,
                                        blue: 0.49
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .background(
                                    Color(
                                        red: 0.85,
                                        green: 0.91,
                                        blue: 0.96
                                    )
                                )
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 12) {
                                
                                Text("Попробуйте сегодня 10 минут практики чтения")
                                    .font(.system(size: 16))
                                
                                Button {
                                    print("Начать практику")
                                } label: {
                                    Text("Начать")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            Color(
                                                red: 0.0,
                                                green: 0.20,
                                                blue: 0.49
                                            )
                                        )
                                        .cornerRadius(22)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    Color(
                                        red: 0.0,
                                        green: 0.20,
                                        blue: 0.49
                                    ),
                                    lineWidth: 3
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                
                
                // MARK: Нижняя навигация
                
                HStack {
                    
                    TabButton(
                        icon: "house.fill",
                        title: "Главная",
                        selected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        icon: "book.fill",
                        title: "Обучение",
                        selected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    TabButton(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Прогресс",
                        selected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                    
                    TabButton(
                        icon: "person.fill",
                        title: "Профиль",
                        selected: selectedTab == 3
                    ) {
                        selectedTab = 3
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(Color.white)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 10,
                    x: 0,
                    y: -4
                )
            }
        }
    }
}


// MARK: Круг прогресса

struct ProgressCircle: View {
    
    let progress: Double
    
    var body: some View {
        
        ZStack {
            
            Circle()
                .stroke(
                    Color.gray.opacity(0.15),
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color(
                        red: 0.0,
                        green: 0.20,
                        blue: 0.49
                    ),
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(
                    Color(
                        red: 0.0,
                        green: 0.20,
                        blue: 0.49
                    )
                )
        }
        .frame(width: 80, height: 80)
    }
}


// MARK: Карточка урока

struct LessonCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    let progress: Double?
    
    var body: some View {
        
        Button {
            print("Открыт урок: \(title)")
        } label: {
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(spacing: 14) {
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(
                            Color(
                                red: 0.0,
                                green: 0.20,
                                blue: 0.49
                            )
                        )
                        .frame(width: 48, height: 48)
                        .background(
                            Color(
                                red: 0.88,
                                green: 0.91,
                                blue: 1.0
                            )
                        )
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text(title)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if let progress = progress {
                    
//                    ProgressView(value: progress)
//                        .progressViewStyle(
//                            LinearProgressViewStyle(
//                                tint: Color(
//                                    red: 0.0,
//                                    green: 0.20,
//                                    blue: 0.49
//                                )
//                            )
//                        )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.gray.opacity(0.18),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: Нижняя кнопка

struct TabButton: View {
    
    let icon: String
    let title: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            VStack(spacing: 4) {
                
                Image(systemName: icon)
                    .font(.system(size: 19))
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(
                selected
                ? Color(
                    red: 0.0,
                    green: 0.20,
                    blue: 0.49
                )
                : .secondary
            )
            .frame(maxWidth: .infinity)
        }
    }
}


// MARK: Preview

struct StudentHomeView_Previews: PreviewProvider {
    
    static var previews: some View {
        StudentHomeView()
    }
}
