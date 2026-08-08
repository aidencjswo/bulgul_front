import SwiftUI

struct DetailContentsView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen
    
    // 선택된 팁 데이터를 받아옵니다
    let selectedTip: TipsResponse?
    
    private let keychainTokenStore = KeychainTokenStore()
    
    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Button(action: {
                    currentScreen = .mainContent
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
                
                Text(selectedTip?.title ?? "상세 정보")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
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
            
            // 메인 컨텐츠 영역
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let tip = selectedTip {
                        // 1. 카테고리 정보
                        if let category = tip.category {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Text(category)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                if let subcategory = tip.subcategory {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(subcategory)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        
                        // 2. 태그
                        if !tip.tags.isEmpty, tip.tags.compactMap({ $0 }).count > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                    Text("태그")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                
                                FlowLayout(spacing: 6) {
                                    ForEach(tip.tags.compactMap { $0 }, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        
                        // 3. 단축키
                        if !tip.shortcuts.isEmpty, tip.shortcuts.compactMap({ $0 }).count > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "command")
                                        .font(.system(size: 12))
                                        .foregroundColor(.purple)
                                    Text("단축키")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                
                                VStack(spacing: 6) {
                                    ForEach(tip.shortcuts.compactMap { $0 }, id: \.self) { shortcut in
                                        HStack {
                                            Image(systemName: "keyboard")
                                                .font(.system(size: 10))
                                                .foregroundColor(.purple)
                                            Text(shortcut)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        
                        // 4. 설명
                        if let description = tip.description {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("설명")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 5. 단계별 설명
                        if !tip.steps.isEmpty, tip.steps.compactMap({ $0 }).count > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("단계")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(Array(tip.steps.compactMap { $0 }.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("\(index + 1).")
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        Text(step)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 6. SVG 이미지
                        if !tip.svgs.isEmpty, tip.svgs.compactMap({ $0 }).count > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("이미지")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(Array(tip.svgs.compactMap { $0 }.enumerated()), id: \.offset) { index, svg in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("이미지 \(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        SVGView(svgCode: svg)
                                            .frame(height: 200)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                    } else {
                        // 데이터가 없을 때
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("선택된 데이터가 없습니다")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 하단 버튼
            Button("뒤로가기") {
                currentScreen = .mainContent
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }
}

// FlowLayout - 태그를 자동으로 줄바꿈하는 레이아웃
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    DetailContentsView(
        token: .constant(nil),
        currentScreen: .constant(.mainContent),
        selectedTip: TipsResponse(
            id: 1,
            title: "테스트 팁",
            category: "디자인",
            subcategory: "레이아웃",
            shortcuts: ["Cmd+D", "Shift+A"],
            description: "이것은 테스트 설명입니다.",
            tags: ["SwiftUI", "디자인", "팁"],
            isFavorite: false,
            createdAt: "2026-08-09",
            steps: ["첫 번째 단계", "두 번째 단계"],
            svgs: [],
            pngs: []
        )
    )
}
