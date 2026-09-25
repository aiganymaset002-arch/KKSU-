import SwiftUI

struct LoginView: View {
    
    @State private var selectedRole: UserRole = .student
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    
    @EnvironmentObject private var store: KKSUStore
    @State private var errorMessage: String?
    @State private var showRegistration = false
    @State private var showRecovery = false

    /// Роли KKSU Online: ученик, родитель, педагог, психолог, эксперт, наставник, партнёр, администратор.
    typealias UserRole = KKSURole
    
    var body: some View {
        ZStack {
            
            Color(red: 0.97, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: Заголовок
                    
                    VStack(spacing: 8) {
                        
                        Text("KKSU Online")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(
                                Color(red: 0.0, green: 0.20, blue: 0.49)
                            )
                        
                        Text("Comfort School-University · Образование без барьеров.")
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
                    
                    TextField("Email", text: $email)
                        .autocorrectionDisabled()
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
#endif
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
                    
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                    }
                    
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
                    
                    // MARK: Демо-доступ
                    
                    if !KKSUCloud.shared.isConfigured {
                    Button {
                        fillDemo()
                    } label: {
                        Text("Демо-вход для роли «\(selectedRole.title)» (пароль \(KKSUSeed.demoPassword))")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.0, green: 0.20, blue: 0.49))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showRegistration) {
            NavigationStack { RegistrationView(initialRole: selectedRole) }
        }
        .sheet(isPresented: $showRecovery) {
            NavigationStack { ForgotPasswordView(email: email) }
        }
    }
    
    
    // MARK: Действия
    
    private func login() {
        if KKSUCloud.shared.isConfigured {
            Task {
                do {
                    try await KKSUCloud.shared.signIn(email: email, password: password, expectedRole: selectedRole)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }
        do {
            try store.login(email: email, password: password, expectedRole: selectedRole)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func createAccount() {
        showRegistration = true
    }
    
    private func forgotPassword() {
        showRecovery = true
    }
    
    private func fillDemo() {
        if let account = KKSUSeed.demoAccounts.first(where: { $0.role == selectedRole }) {
            email = account.email
            password = KKSUSeed.demoPassword
        }
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
            .environmentObject(KKSUStore(inMemory: true))
    }
}
