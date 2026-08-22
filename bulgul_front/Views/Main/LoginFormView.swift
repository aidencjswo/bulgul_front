import SwiftUI

struct LoginFormView: View {
    @Binding var token : String?
    @Binding var currentScreen: MenuScreen
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let keychainTokenStore = KeychainTokenStore()
    
    var body: some View {
        VStack(spacing: 20) {
            // 헤더 섹션
            VStack(spacing: 8) {
                // SVG 아이콘 사용
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    .padding(.top)
                
                Text("불굴의 디자인")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("로그인하여 시작하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.horizontal)
            
            // 입력 필드 섹션
            VStack(spacing: 12) {
                TextField("아이디 입력", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                SecureField("비밀번호 입력", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .onSubmit {
                performLogin()
            }

            // 에러 메시지
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
            }
            
            // 로그인 버튼
            if isLoading {
                ProgressView()
                    .padding(.vertical, 8)
            } else {
                Button("로그인") {
                    performLogin()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty)
            }
            
            Divider()
                .padding(.horizontal)
            
            // 하단 버튼
            HStack(spacing: 12) {
                Button("취소") {
                    currentScreen = .menu
                }
                .buttonStyle(.bordered)
                
                Button("회원가입") {
                    currentScreen = .signup
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }
    
    private func performLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await AuthService.shared.login(email: email, password: password)
                
                // 📌 UI 변경 작업은 메인 스레드에서 안전하게 실행
                await MainActor.run {
                    isLoading = false
                    
                    if let token_f = response.token, !token_f.isEmpty {
                        currentScreen = .menu
                        keychainTokenStore.save(token_f)
                        token = token_f
                    } else {
                        errorMessage = "로그인 정보가 올바르지 않습니다."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "서버 통신 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}
