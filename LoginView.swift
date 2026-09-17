import SwiftUI

struct LoginView: View {
    
    @State private var selectedRole: UserRole = .student
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    
    enum UserRole: String, CaseIterable {
        case student
        case teacher
        case parent
        case universityStudent
        
        var title: String {
            switch self {
            case .student:
                return "Ученик"
            case .teacher:
                return "Преподаватель"
            case .parent:
                return "Родитель"
            case .universityStudent:
                return "Студент"
            }
        }
        
        var icon: String {
            switch self {
            case .student:
                return "graduationcap.fill"
            case .teacher:
                return "person.fill"
            case .parent:
                return "person.2.fill"
            case .universityStudent:
                return "books.vertical.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            
            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: Заголовок
                    
                    VStack(spacing: 8) {
                        
                        Text("Корфоворт")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(
                                Color(red: 0.0, green: 0.20, blue: 0.49)
                            )
                        
                        Text("Образование без барьеров.")
                            .font(.system(size: 18))
                            .foregroundColor(
                                Color(red: 0.32, green: 0.38, blue: 0.41)
                            )
                    }
                    .padding(.top, 40)
                    
                    
                    // MARK: Иллюстрация
                    
                    VStack(spacing: 12) {
                        
                        Image(systemName: "book.and.wrench.fill")
                            .font(.system(size: 55))
                            .foregroundColor(
                                Color(red: 0.0, green: 0.20, blue: 0.49)
                            )
                        
                        Text("Учись в своём темпе")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Персональное образование\nдля каждого ученика")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.top, 30)
                    
                    
                    // MARK: Выбор роли
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Выберите вашу роль")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 10
                        ) {
                            
                            ForEach(UserRole.allCases, id: \.self) { role in
                                
                                RoleCard(
                                    role: role,
                                    selected: selectedRole == role
                                ) {
                                    selectedRole = role
                                }
                            }
                        }
                    }
                    .padding(.top, 30)
                    
                    
                    // MARK: Email
                    
                    TextField("Логин или Email", text: $email)
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .padding(.top, 28)
                    
                    
                    // MARK: Пароль
                    
                    HStack {
                        
                        if showPassword {
                            
                            TextField("Пароль", text: $password)
                            
                        } else {
                            
                            SecureField("Пароль", text: $password)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(
                                systemName: showPassword
                                ? "eye.slash"
                                : "eye"
                            )
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .padding(.top, 14)
                    
                    
                    // MARK: Кнопка входа
                    
                    Button {
                        login()
                    } label: {
                        
                        Text("Войти")
                            .font(.system(size: 17, weight: .semibold))
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
                            .cornerRadius(14)
                    }
                    .padding(.top, 20)
                    
                    
                    // MARK: Создать аккаунт
                    
                    Button {
                        createAccount()
                    } label: {
                        
                        Text("Создать аккаунт")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(
                                Color(
                                    red: 0.0,
                                    green: 0.20,
                                    blue: 0.49
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.clear)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color(
                                            red: 0.0,
                                            green: 0.20,
                                            blue: 0.49
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.top, 12)
                    
                    
                    // MARK: Забыли пароль
                    
                    Button {
                        forgotPassword()
                    } label: {
                        
                        Text("Забыли пароль?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    
    // MARK: Действия
    
    private func login() {
        print("Вход: \(email)")
        print("Роль: \(selectedRole.title)")
    }
    
    private func createAccount() {
        print("Создание аккаунта")
    }
    
    private func forgotPassword() {
        print("Восстановление пароля")
    }
}


// MARK: Карточка роли

struct RoleCard: View {
    
    let role: LoginView.UserRole
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            HStack(spacing: 10) {
                
                Image(systemName: role.icon)
                    .font(.system(size: 18))
                    .foregroundColor(
                        selected
                        ? Color(red: 0.0, green: 0.20, blue: 0.49)
                        : .secondary
                    )
                
                Text(role.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                ZStack {
                    
                    Circle()
                        .stroke(
                            selected
                            ? Color(red: 0.0, green: 0.20, blue: 0.49)
                            : Color.gray.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if selected {
                        
                        Circle()
                            .fill(
                                Color(
                                    red: 0.0,
                                    green: 0.20,
                                    blue: 0.49
                                )
                            )
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                selected
                ? Color(red: 0.97, green: 0.98, blue: 0.99)
                : Color.white
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        selected
                        ? Color(
                            red: 0.0,
                            green: 0.20,
                            blue: 0.49
                        )
                        : Color.gray.opacity(0.3),
                        lineWidth: selected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: Preview

struct LoginView_Previews: PreviewProvider {
    
    static var previews: some View {
        LoginView()
    }
}
