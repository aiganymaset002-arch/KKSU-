import SwiftUI

struct StudentTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnswer: Int?
    @State private var showSuccess = false

    private let answers = [10, 11, 12, 13]
    private let correctAnswer = 12

    var body: some View {
        ZStack {
            Color(red: 0.969, green: 0.976, blue: 0.988)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.primaryBlue)
                            .frame(width: 44, height: 44)
                    }

                    Text("Задание 3 из 10")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color.primaryBlue)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // MARK: - Progress
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.18))

                            Capsule()
                                .fill(Color.primaryBlue)
                                .frame(width: geometry.size.width * 0.30)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                // MARK: - Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        Text("Решите задачу.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.secondaryText)

                        // MARK: Question
                        VStack {
                            Text("Сколько будет 5 + 7?")
                                .font(.system(
                                    size: 28,
                                    weight: .bold
                                ))
                                .foregroundStyle(Color.primaryBlue)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(
                            color: .black.opacity(0.06),
                            radius: 12,
                            y: 4
                        )

                        // MARK: Answers
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 16
                        ) {
                            ForEach(answers, id: \.self) { answer in
                                answerButton(answer)
                            }
                        }

                        // MARK: Answer button
                        Button {
                            checkAnswer()
                        } label: {
                            Text("Ответить")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    selectedAnswer == nil
                                    ? Color.primaryBlue.opacity(0.5)
                                    : Color.primaryBlue
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(selectedAnswer == nil)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }

            // MARK: - Success Overlay
            if showSuccess {
                successOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Answer Button

    @ViewBuilder
    private func answerButton(_ answer: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAnswer = answer
            }
        } label: {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .stroke(
                            selectedAnswer == answer
                            ? Color.primaryBlue
                            : Color.gray.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if selectedAnswer == answer {
                        Circle()
                            .fill(Color.primaryBlue)
                            .frame(width: 16, height: 16)
                    }
                }

                Text("\(answer)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        selectedAnswer == answer
                        ? Color.primaryBlue
                        : Color.gray.opacity(0.35),
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Check Answer

    private func checkAnswer() {
        guard let selectedAnswer else { return }

        if selectedAnswer == correctAnswer {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showSuccess = true
            }
        } else {
            // Неправильный ответ
            withAnimation(.default) {
                self.selectedAnswer = nil
            }
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                }

                Text("🎉 Отлично!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Вы правильно выполнили задание.")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)

                Button {
                    showSuccess = false
                    selectedAnswer = nil
                } label: {
                    Text("Следующее задание")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 500)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(20)
        }
        .transition(.opacity)
    }
}

// MARK: - Colors

extension Color {
    static let primaryBlue = Color(
        red: 0.0,
        green: 0.196,
        blue: 0.49
    )

    static let secondaryText = Color(
        red: 0.32,
        green: 0.38,
        blue: 0.41
    )
}

// MARK: - Preview

#Preview {
    StudentTaskView()
}
