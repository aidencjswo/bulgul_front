import SwiftUI

struct MainContentsView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen
    
    @State private var tips: [TipsResponse] = []
    @State private var searchText: String = ""
    @State private var pendingDeleteTip: TipsResponse? = nil
    @State private var showDeleteConfirm = false
    @State private var statusMessage = ""
    
    private let keychainTokenStore = KeychainTokenStore()
    
    // 검색 필터링된 팁 목록
    private var filteredTips: [TipsResponse] {
        if searchText.isEmpty {
            return tips
        } else {
            return tips.filter { tip in
                // 제목, 카테고리, 태그에서 검색
                let titleMatch = tip.title?.localizedCaseInsensitiveContains(searchText) ?? false
                let categoryMatch = tip.category?.localizedCaseInsensitiveContains(searchText) ?? false
                let tagsMatch = tip.tags.compactMap { $0 }.contains { $0.localizedCaseInsensitiveContains(searchText) }
                
                return titleMatch || categoryMatch || tagsMatch
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더 섹션
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
                
                Text("불굴의 디자인")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 오른쪽 여백 (대칭을 위해)
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 검색 바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("검색...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // 메인 컨텐츠 영역
            ScrollView {
                VStack(spacing: 12) {
                    if tips.isEmpty {
                        VStack(spacing: 8) {
                            ProgressView()
                                .padding(.top, 40)
                            
                            Text("데이터를 불러오는 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    } else if filteredTips.isEmpty {
                        // 검색 결과 없음
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                            
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("'\(searchText)'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(filteredTips, id: \.id) { tip in
                            Button(action: {
                                currentScreen = .detailConents(tip)
                            }) {
                                HStack(spacing: 12) {
                                    // 카테고리 아이콘
                                    if let category = tip.category {
                                        Image(systemName: getCategoryIcon(category))
                                            .font(.system(size: 16))
                                            .foregroundColor(getCategoryColor(category))
                                            .frame(width: 32, height: 32)
                                            .background(getCategoryColor(category).opacity(0.1))
                                            .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tip.title ?? "제목 없음")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        HStack(spacing: 4) {
                                            if let category = tip.category {
                                                Text(category)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }

                                            if let subcategory = tip.subcategory {
                                                Text("·")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                                Text(subcategory)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if tip.id != nil {
                                    Button("삭제", role: .destructive) {
                                        pendingDeleteTip = tip
                                        showDeleteConfirm = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
            
            // 하단 정보
            HStack(spacing: 12) {
                Text("\(filteredTips.count)개")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
        .task {
            do {
                tips = try await ContentService.shared.getTips()
            } catch {
                print("에러: \(error)")
            }
        }
        .alert("팁을 삭제하시겠습니까?", isPresented: $showDeleteConfirm, presenting: pendingDeleteTip) { tip in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                deleteTip(tip)
            }
        } message: { tip in
            Text("\"\(tip.title ?? "제목 없음")\"을(를) 삭제하면 복구할 수 없습니다.")
        }
    }

    private func deleteTip(_ tip: TipsResponse) {
        guard let id = tip.id else { return }
        Task {
            do {
                try await ContentService.shared.deleteTip(id: id)
                await MainActor.run {
                    tips.removeAll { $0.id == id }
                }
            } catch {
                await MainActor.run {
                    statusMessage = "⚠️ 삭제 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    // 카테고리별 아이콘 반환
    private func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "ai", "illustrator":
            return "pencil.and.outline"
        case "ps", "photoshop":
            return "photo"
        case "figma":
            return "rectangle.on.rectangle"
        case "windows":
            return "menubar.rectangle"
        case "macos":
            return "apple.logo"
        default:
            return "doc.text"
        }
    }
    
    // 카테고리별 색상 반환
    private func getCategoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "ai", "illustrator":
            return .orange
        case "ps", "photoshop":
            return .blue
        case "figma":
            return .purple
        case "windows":
            return .cyan
        case "macos":
            return .gray
        default:
            return .green
        }
    }
}

#Preview {
    MainContentsView(token: .constant(nil), currentScreen: .constant(.menu))
}
