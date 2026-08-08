import SwiftUI

struct SignUpFormView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let keychainTokenStore = KeychainTokenStore()

    var body: some View {
        VStack(spacing: 20) {
            // 헤더 섹션
            VStack(spacing: 8) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    .padding(.top)

                Text("불굴의 디자인")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("회원가입하고 시작하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .padding(.horizontal)

            // 입력 필드 섹션
            VStack(spacing: 12) {
                TextField("아이디(이메일) 입력", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                SecureField("비밀번호 입력", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                SecureField("비밀번호 확인", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }

            // 에러 메시지
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
            }

            // 가입 버튼
            if isLoading {
                ProgressView()
                    .padding(.vertical, 8)
            } else {
                Button("가입하기") {
                    performSignUp()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            }

            Divider()
                .padding(.horizontal)

            // 하단 버튼
            Button("로그인 화면으로") {
                currentScreen = .login
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }

    private func performSignUp() {
        guard isValidEmail(email) else {
            errorMessage = "올바른 이메일 형식이 아닙니다."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "비밀번호가 일치하지 않습니다."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await AuthService.shared.register(email: email, password: password)

                await MainActor.run {
                    isLoading = false

                    if let newToken = response.token, !newToken.isEmpty {
                        keychainTokenStore.save(newToken)
                        token = newToken
                        currentScreen = .mainContent
                    } else {
                        errorMessage = "회원가입에 실패했습니다."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    SignUpFormView(token: .constant(nil), currentScreen: .constant(.signup))
}
