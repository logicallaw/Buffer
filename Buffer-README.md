# Buffer

> Your macOS inbox for thoughts, links, files, and screenshots.

**Buffer**는 생각의 흐름을 방해하지 않으면서, 모든 것을 빠르게 저장할 수 있는 macOS 네이티브 메모 앱입니다.

---

## 🎯 Core Concept

```
빠른 접근 → 즉시 기록 → 자동 분류 → 나중에 정리
```

Buffer는 당신의 **디지털 임시 저장소**입니다. 
- 생각은 **메모**로
- 나중에 읽을 것은 **링크**로
- 참고 자료는 **파일**로
- 영감은 **스크린샷**으로

모두 한 곳에 모으되, 명확하게 분류됩니다.

---

## ✨ Key Features

### 1. **Lightning-fast Note Taking**
- `Option + P`: 어디서든 즉시 메모 시작
- 인라인 마크다운 렌더링 (타이핑 즉시 적용)
- 자동 iCloud 백업

### 2. **Drag & Drop Everything**
| 드롭하는 것 | 자동 처리 |
|-----------|---------|
| Safari URL | 링크 카드 생성 (제목, 썸네일) |
| PDF 파일 | 파일 카드 생성 (메타데이터 추출) |
| 이미지 | 메모에 바로 삽입 |

### 3. **Automatic Categorization**
AI가 아닌, **명확한 규칙 기반** 자동 분류:
```markdown
📝 Notes     - 직접 작성한 메모
🔗 Links     - 저장한 URL들
📄 Files     - PDF, 문서들
📸 Images    - 스크린샷, 이미지
```

### 4. **Zero Configuration**
- 복잡한 설정 없음
- 설치하자마자 바로 사용
- Notion, Obsidian 같은 러닝커브 없음

---

## 🎨 Design Philosophy

### Minimalism
- 불필요한 UI 요소 제거
- 커서에 집중할 수 있는 인터페이스
- 생각을 방해하지 않는 디자인

### Speed
- macOS 네이티브 앱 (SwiftUI)
- 즉각적인 반응 속도
- 0.5초 이내 앱 실행

### No AI Interference
- AI 자동 요약 없음
- 사용자의 생각을 있는 그대로 보존
- 필요한 것만 자동화 (카테고리 분류)

---

## 🚀 Roadmap

### Phase 1: MVP (2 weeks)
**목표**: 기본 메모 + 드래그 앤 드롭 동작

- [x] 프로젝트 세팅
- [x] 마크다운 인라인 렌더링
- [ ] URL 드래그 앤 드롭 → 링크 카드
- [ ] 이미지 드래그 앤 드롭 → 삽입
- [ ] 글로벌 단축키 (Option + P)
- [ ] iCloud 동기화
- [ ] 기본 검색 기능

### Phase 2: Smart Features (2 weeks)
**목표**: PDF 지원 + 카테고리 시스템

- [ ] PDF 드래그 앤 드롭
- [ ] PDF 메타데이터 자동 추출 (제목, 저자, 연도)
- [ ] 자동 카테고리 분류 (Notes/Links/Files/Images)
- [ ] 수동 태그 시스템
- [ ] 향상된 검색 (태그, 날짜 필터)

### Phase 3: Advanced (Optional)
**목표**: 프로 사용자 기능

- [ ] 스크린샷 병합 기능
- [ ] PDF 내부 전문 검색
- [ ] 타임라인 뷰 (날짜별 보기)
- [ ] 메뉴바 Quick Capture
- [ ] 다크모드 테마

### Phase 4: Distribution
- [ ] 코드 서명
- [ ] App Store 제출
- [ ] 랜딩 페이지 제작

---

## 🏗 Technical Stack

### Platform
- **macOS 14.0+** (Sonoma 이상)
- **SwiftUI** - 네이티브 UI
- **SwiftData** - 데이터 영속성
- **CloudKit** - iCloud 동기화

### Key Technologies
- **Swift 5.9+**
- **SwiftData** - 로컬 데이터 저장 (통합 BufferItem 모델)
- **NSTextView + NSViewRepresentable** - 인라인 마크다운 렌더링
- **NSRegularExpression** - 실시간 마크다운 파싱/스타일링
- **Carbon Events API** - 글로벌 단축키 (Option+P)
- **PDFKit** - PDF 메타데이터 추출 (예정)

### File Structure
```
buffer/
├── bufferApp.swift               # @main 앱 진입점 (SwiftData ModelContainer)
├── ContentView.swift             # 3단 NavigationSplitView
├── Models/
│   └── BufferItem.swift          # 통합 데이터 모델 + BufferCategory enum
├── Views/
│   ├── SidebarView.swift         # 카테고리 사이드바
│   ├── NoteListView.swift        # 필터링된 아이템 목록
│   ├── NoteRowView.swift         # 목록 내 개별 행
│   ├── EditorView.swift          # 제목 + 마크다운 에디터
│   └── MarkdownTextView.swift    # NSTextView 래퍼 (인라인 렌더링)
├── Services/
│   ├── HotKeyService.swift       # Option+P 글로벌 단축키
│   └── MarkdownRenderer.swift    # 실시간 마크다운 스타일 엔진
├── Assets.xcassets/
└── buffer.entitlements           # Sandbox + CloudKit
```

---

## 🎯 Target Users

### Primary
- **대학원생 / 연구자**
  - 논문 여러 개 읽으면서 메모
  - 링크, PDF 자주 저장
  
- **개발자**
  - GitHub 링크, 기술 문서 수집
  - 코드 스니펫 메모

### Secondary
- 프리랜서, 디자이너, 작가
- "나중에 읽기" 습관이 있는 사람
- Notion은 무겁고, Apple Notes는 부족한 사람

---

## 💰 Monetization Strategy

### Free Tier
- 기본 메모 기능
- 월 50개 항목 제한 (메모, 링크, 파일 합산)
- iCloud 동기화

### Pro Tier ($4.99/month or $49/year)
- 무제한 항목
- PDF 전문 검색
- 우선 지원
- 얼리 액세스 신규 기능

**출시 전략:**
1. 첫 3개월 무료 (얼리어답터 확보)
2. Product Hunt 런칭
3. 학생 할인 50%

---

## 🔥 Competitive Advantage

| 기능 | Buffer | Notion | Obsidian | Apple Notes |
|-----|--------|--------|----------|-------------|
| 설정 시간 | **0분** | 30분 | 1시간+ | 0분 |
| 마크다운 | ✅ 인라인 | ✅ | ✅ | ❌ |
| URL 드롭 | ✅ 자동 카드 | ✅ | ❌ | ❌ |
| PDF 관리 | ✅ 메타데이터 | ❌ | 플러그인 | ❌ |
| 속도 | ⚡ 네이티브 | 🐌 웹 | ⚡ | ⚡ |
| 가격 | $4.99/월 | $10/월 | 무료 | 무료 |

**핵심 차별점:**
> "Notion의 유연성 + Apple Notes의 속도 + Obsidian의 마크다운 - 복잡성"

---

## 📐 UI/UX Mockup Ideas

### Main Window
```
┌─────────────────────────────────────────────────┐
│ Buffer                                    ⚙️ 🔍 │
├──────────┬──────────────────────────────────────┤
│          │                                      │
│ 📝 Notes │  # Meeting Notes 2026-02-06         │
│ 🔗 Links │                                      │
│ 📄 Files │  Discussed new feature ideas...     │
│ 📸 Images│                                      │
│          │  🔗 [arXiv Paper on Quantum]        │
│ ────────│  📄 [research_paper.pdf]             │
│ #research│                                      │
│ #project │  ![screenshot.png]                   │
│          │                                      │
└──────────┴──────────────────────────────────────┘
```

### Quick Capture (Option + P)
```
┌─────────────────────────────────┐
│  Quick Note                  ✕  │
├─────────────────────────────────┤
│                                 │
│  [타이핑 시작...]               │
│                                 │
│                                 │
│                        [Save]   │
└─────────────────────────────────┘
```

---

## 🧪 Success Metrics

### Launch (Month 1)
- 100 downloads
- 10 유료 전환

### Growth (Month 3)
- 1,000 downloads
- 50 유료 사용자
- App Store 평점 4.5+

### Sustainability (Month 6)
- 5,000 downloads
- 200 유료 사용자 ($1,000 MRR)
- Product Hunt 상위 10

---

## 📝 Marketing Strategy

### Pre-Launch
1. **Developer Log** - Twitter에 개발 과정 공유
2. **Beta Testing** - 50명 얼리어답터 모집
3. **Landing Page** - waitlist 수집

### Launch
1. **Product Hunt** - 화요일/수요일 런칭
2. **Reddit** - r/macapps, r/productivity
3. **Hacker News** - Show HN

### Post-Launch
1. **유튜브 리뷰어** 컨택
2. **학생 커뮤니티** (대학 포럼, Discord)
3. **블로그 포스팅** - "Notion 대신 Buffer 쓰는 이유"

---

## 🤝 Contributing (Future)

Buffer는 현재 개인 프로젝트지만, 향후 오픈소스 전환을 고려 중입니다.

---

## 📄 License

Proprietary (상업용 라이선스)

---

## 👤 Author

**[Your Name]**
- Flutter Developer
- Swift Learner
- Apple Developer Program Member

---

## 🙏 Acknowledgments

**Inspiration:**
- Obsidian - 마크다운 철학
- Notion - 드래그 앤 드롭 UX
- Bear - macOS 네이티브 디자인
- Apple Notes - 단순함

**Philosophy:**
> "The best app is the one that gets out of your way."

---

**Built with ❤️ for macOS**

---

## 📞 Contact

- Website: [buffernotes.app](https://buffernotes.app) (TBD)
- Email: hello@buffernotes.app (TBD)
- Twitter: [@BufferNotesApp](https://twitter.com/BufferNotesApp) (TBD)

---

*Last Updated: 2026-02-06*
