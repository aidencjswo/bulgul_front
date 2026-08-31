import SwiftUI

struct AddTipResponse: Codable {
    let title: String
    let category: String
    let subcategory: String
    let shortcuts: [String]
    let description: String
    let steps: [String]
    let tags: [String]
}

struct SvgResponse: Codable {
    let svgs: [String]
}

struct AddTipFormView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen
    
    private let keychainTokenStore = KeychainTokenStore()
    
    // 화면 상태
    @State private var showFullForm = false
    
    // 폼 상태 변수
    @State private var title = ""
    @State private var category = "Ai"
    @State private var subcategory = ""
    @State private var shortcutsString = ""
    @State private var description = ""
    @State private var tagsString = ""
    
    @State private var step1 = ""
    @State private var step2 = ""
    @State private var step3 = ""
    
    @State private var svg1 = ""
    @State private var svg2 = ""
    @State private var svg3 = ""
    
    // AI 연동 상태 변수
    @State private var aiInputPrompt = ""
    @State private var isAiSuggesting = false
    @State private var isAiGeneratingSvgs = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Button(action: {
                    currentScreen = .menu
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("새 단축키 등록")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 오른쪽 여백 (대칭을 위해)
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
                .padding(.horizontal)
            
            if !showFullForm {
                // 초기 화면: AI 입력만
                initialInputView
            } else {
                // 전체 폼
                fullFormView
            }
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 300, maxHeight: 500)
    }
    
    private var initialInputView: some View {
        VStack(spacing: 14) {
            Spacer()

            VStack(spacing: 12) {
                Text("🪄 AI로 단축키 카드 만들기")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("단축키나 기능을 설명해주세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("예: 포토샵 인물 누끼 따기, 피그마 컴포넌트 복제...", text: $aiInputPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal, 40)
                
                Button(action: runAiSuggest) {
                    HStack {
                        if isAiSuggesting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        }
                        Text(isAiSuggesting ? "AI가 생성 중..." : "AI 자동완성")
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(aiInputPrompt.isEmpty ? Color.gray : Color.indigo)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isAiSuggesting || aiInputPrompt.isEmpty)
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(statusMessage.contains("⚠️") ? .red : .indigo)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
    
    // 전체 폼 화면
    private var fullFormView: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 14) {
                        // AI 자동완성 결과 안내
                        VStack(alignment: .leading, spacing: 6) {
                            Text("✓ AI 자동완성 완료!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            Text("아래 내용을 확인하고 수정한 후 저장하세요.")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .frame(width: geometry.size.width - 32)
                        .background(Color.green.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green.opacity(0.15), lineWidth: 1)
                        )
                        
                        // 주 입력 폼들
                        VStack(alignment: .leading, spacing: 9) {
                            // 제목 입력
                            HStack {
                                Text("단축키 제목:")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                TextField("행동명 입력 (예: 오브젝트 복제)", text: $title)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // 카테고리 콤보박스 선택
                            HStack {
                                Text("도구분류:")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                Picker("", selection: $category) {
                                    Text("Illustrator").tag("Ai")
                                    Text("Photoshop").tag("Ps")
                                    Text("Figma").tag("Figma")
                                    Text("기타").tag("기타")
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // 소그룹 카테고리 입력
                            HStack {
                                Text("소분류명:")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                TextField("예: 드로잉, 컴포넌트, 레이아웃", text: $subcategory)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // 단축키 입력
                            HStack {
                                Text("단축키 키:")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                TextField("쉼표로 구분 (예: Ctrl, Alt, C)", text: $shortcutsString)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // 설명
                            VStack(alignment: .leading, spacing: 4) {
                                Text("단축키 용도 및 설명:")
                                    .font(.caption)
                                TextEditor(text: $description)
                                    .frame(height: 38)
                                    .border(Color.gray.opacity(0.2), width: 1)
                                    .cornerRadius(4)
                            }
                            
                            // 태그
                            HStack {
                                Text("검색 태그:")
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                TextField("쉼표로 구분 (예: 펜툴, 누끼)", text: $tagsString)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .frame(width: geometry.size.width - 32)
                        
                        Divider()
                            .frame(width: geometry.size.width - 32)
                        
                        // 단계별 설명 및 SVG 코드 입력 폼
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("🛠 실행 가이드 단계 설정")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                // AI SVG 생성 버튼
                                Button(action: runAiGenerateSvgs) {
                                    HStack(spacing: 4) {
                                        if isAiGeneratingSvgs {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                                .tint(.white)
                                        }
                                        Text("AI 그림 생성")
                                    }
                                    .font(.system(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.purple)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .disabled(isAiGeneratingSvgs || title.isEmpty || step1.isEmpty)
                            }
                            
                            // 1단계
                            VStack(alignment: .leading, spacing: 5) {
                                Text("1단계 지침 설명:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("텍스트 입력", text: $step1)
                                    .textFieldStyle(.roundedBorder)
                                Text("1단계 SVG 코드:")
                                    .font(.system(size: 9))
                                TextEditor(text: $svg1)
                                    .frame(height: 38)
                                    .font(.system(.caption, design: .monospaced))
                                    .border(Color.gray.opacity(0.2), width: 1)
                            }
                            
                            // 2단계
                            VStack(alignment: .leading, spacing: 5) {
                                Text("2단계 지침 설명:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("텍스트 입력", text: $step2)
                                    .textFieldStyle(.roundedBorder)
                                Text("2단계 SVG 코드:")
                                    .font(.system(size: 9))
                                TextEditor(text: $svg2)
                                    .frame(height: 38)
                                    .font(.system(.caption, design: .monospaced))
                                    .border(Color.gray.opacity(0.2), width: 1)
                            }
                            
                            // 3단계
                            VStack(alignment: .leading, spacing: 5) {
                                Text("3단계 지침 설명:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("텍스트 입력", text: $step3)
                                    .textFieldStyle(.roundedBorder)
                                Text("3단계 SVG 코드:")
                                    .font(.system(size: 9))
                                TextEditor(text: $svg3)
                                    .frame(height: 38)
                                    .font(.system(.caption, design: .monospaced))
                                    .border(Color.gray.opacity(0.2), width: 1)
                            }
                        }
                        .frame(width: geometry.size.width - 32)
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Divider()
                .padding(.horizontal)
            
            // 저장 액션 바
            HStack {
                Spacer()
                
                Button("저장하기") {
                    saveTip()
                }
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.indigo)
                .cornerRadius(8)
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // AI 카드 생성 실행
    private func runAiSuggest() {
        guard token != nil else {
            statusMessage = "⚠️ 로그인이 필요합니다."
            return
        }

        isAiSuggesting = true
        statusMessage = "Gemini AI가 카드를 생성하고 있습니다..."

        Task {
            do {
                let decoded: AddTipResponse = try await NetworkClient.shared.request(
                    path: "/api/api_v1/gemini/suggest-tip",
                    method: "POST",
                    body: SuggestTipRequest(rawDescription: aiInputPrompt, currentCategories: [])
                )

                await MainActor.run {
                    isAiSuggesting = false
                    title = decoded.title
                    category = decoded.category
                    subcategory = decoded.subcategory
                    shortcutsString = decoded.shortcuts.joined(separator: ", ")
                    description = decoded.description
                    tagsString = decoded.tags.joined(separator: ", ")

                    if decoded.steps.count > 0 { step1 = decoded.steps[0] }
                    if decoded.steps.count > 1 { step2 = decoded.steps[1] }
                    if decoded.steps.count > 2 { step3 = decoded.steps[2] }

                    statusMessage = ""
                    showFullForm = true
                }
            } catch {
                await MainActor.run {
                    isAiSuggesting = false
                    statusMessage = "⚠️ 서버 연결 실패"
                }
            }
        }
    }

    // AI 실행 가이드 일러스트 생성
    private func runAiGenerateSvgs() {
        guard token != nil else {
            statusMessage = "⚠️ 로그인이 필요합니다."
            return
        }

        isAiGeneratingSvgs = true
        statusMessage = "Gemini AI가 단계별 고화질 SVG 도해를 그리고 있습니다..."

        let steps = [step1, step2, step3].filter { !$0.isEmpty }

        Task {
            do {
                let decoded: SvgResponse = try await NetworkClient.shared.request(
                    path: "/api/api_v1/gemini/generate-svgs",
                    method: "POST",
                    body: GenerateSvgsRequest(title: title, category: category, steps: steps)
                )

                await MainActor.run {
                    isAiGeneratingSvgs = false
                    if decoded.svgs.count > 0 { svg1 = decoded.svgs[0] }
                    if decoded.svgs.count > 1 { svg2 = decoded.svgs[1] }
                    if decoded.svgs.count > 2 { svg3 = decoded.svgs[2] }
                    statusMessage = "✓ AI 가이드 일러스트 생성이 완료되었습니다!"
                }
            } catch {
                await MainActor.run {
                    isAiGeneratingSvgs = false
                    statusMessage = "SVG 생성 실패 (네트워크 오류)"
                }
            }
        }
    }

    // 최종 디자인 팁 저장
    private func saveTip() {
        guard token != nil else {
            statusMessage = "⚠️ 로그인이 필요합니다."
            return
        }

        let shortcuts = shortcutsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let steps = [step1, step2, step3].filter { !$0.isEmpty }
        let svgs = [svg1, svg2, svg3]

        let requestBody = SaveTipRequest(
            title: title,
            category: category,
            subcategory: subcategory,
            shortcuts: shortcuts,
            description: description,
            tags: tags,
            steps: steps,
            svgs: svgs,
            isFavorite: false
        )

        Task {
            do {
                try await NetworkClient.shared.requestWithoutDecoding(
                    path: "/api/api_v1/design/tips",
                    method: "POST",
                    body: requestBody
                )

                await MainActor.run {
                    statusMessage = "✓ 저장 완료!"
                    // 저장 성공 후 메인 화면으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentScreen = .mainContent
                    }
                }
            } catch {
                await MainActor.run {
                    statusMessage = "저장 처리 중 에러가 발생했습니다."
                }
            }
        }
    }
}

private struct SuggestTipRequest: Encodable {
    let rawDescription: String
    let currentCategories: [String]
}

private struct GenerateSvgsRequest: Encodable {
    let title: String
    let category: String
    let steps: [String]
}

private struct SaveTipRequest: Encodable {
    let title: String
    let category: String
    let subcategory: String
    let shortcuts: [String]
    let description: String
    let tags: [String]
    let steps: [String]
    let svgs: [String]
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case title, category, subcategory, shortcuts, description, tags, steps, svgs
        case isFavorite = "is_favorite"
    }
}

#Preview {
    AddTipFormView(token: .constant("test_token"), currentScreen: .constant(.createTip))
}
