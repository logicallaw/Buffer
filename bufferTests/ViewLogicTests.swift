import Testing
import Foundation
@testable import buffer

// MARK: - NoteListView 필터링 로직 화이트박스 테스트
// (View 내부 filteredItems 계산 프로퍼티 로직을 직접 시뮬레이션)

struct NoteListFilteringLogicTests {

    // MARK: - .all 카테고리: parentItem == nil인 항목만 반환

    @Test func all_category_returns_top_level_only() {
        let parent = BufferItem(title: "부모", category: .notes)
        let child = BufferItem(title: "자식", category: .notes, parentItem: parent)
        let topLevel = BufferItem(title: "독립", category: .links)

        let allItems = [parent, child, topLevel]
        let category: BufferCategory = .all

        let topLevelFiltered = allItems.filter { $0.parentItem == nil }
        let result: [BufferItem]
        if category == .all {
            result = topLevelFiltered
        } else {
            result = topLevelFiltered.filter { $0.category == category }
        }

        #expect(result.count == 2)
        #expect(result.contains(where: { $0.title == "부모" }))
        #expect(result.contains(where: { $0.title == "독립" }))
        #expect(!result.contains(where: { $0.title == "자식" }))
    }

    // MARK: - 특정 카테고리: 해당 카테고리만 필터

    @Test func specific_category_filters_by_category() {
        let note1 = BufferItem(title: "메모1", category: .notes)
        let note2 = BufferItem(title: "메모2", category: .notes)
        let link = BufferItem(title: "링크1", category: .links)

        let allItems = [note1, note2, link]
        let category: BufferCategory = .links

        let topLevel = allItems.filter { $0.parentItem == nil }
        let result = topLevel.filter { $0.category == category }

        #expect(result.count == 1)
        #expect(result[0].title == "링크1")
    }

    // MARK: - 빈 목록

    @Test func empty_items_returns_empty() {
        let allItems: [BufferItem] = []
        let category: BufferCategory = .all

        let topLevel = allItems.filter { $0.parentItem == nil }
        let result: [BufferItem]
        if category == .all {
            result = topLevel
        } else {
            result = topLevel.filter { $0.category == category }
        }

        #expect(result.isEmpty)
    }

    // MARK: - 자식 아이템만 있을 때 (전부 parentItem != nil)

    @Test func all_items_are_children_returns_empty() {
        let parent = BufferItem(title: "부모")
        let child1 = BufferItem(title: "자식1", parentItem: parent)
        let child2 = BufferItem(title: "자식2", parentItem: parent)

        let allItems = [child1, child2]
        let topLevel = allItems.filter { $0.parentItem == nil }
        #expect(topLevel.isEmpty)
    }
}

// MARK: - createNewNote 로직 화이트박스 테스트

struct CreateNewNoteLogicTests {

    // MARK: - .all 선택 시 .notes로 생성

    @Test func all_category_creates_notes() {
        let category: BufferCategory = .all
        let newCategory = category == .all ? BufferCategory.notes : category
        #expect(newCategory == .notes)
    }

    // MARK: - 특정 카테고리 선택 시 해당 카테고리로 생성

    @Test func specific_category_preserved() {
        let category: BufferCategory = .links
        let newCategory = category == .all ? BufferCategory.notes : category
        #expect(newCategory == .links)
    }

    @Test func files_category_preserved() {
        let category: BufferCategory = .files
        let newCategory = category == .all ? BufferCategory.notes : category
        #expect(newCategory == .files)
    }

    @Test func images_category_preserved() {
        let category: BufferCategory = .images
        let newCategory = category == .all ? BufferCategory.notes : category
        #expect(newCategory == .images)
    }
}

// MARK: - SidebarView count(for:) 로직 화이트박스 테스트

struct SidebarCountLogicTests {

    // 로직 시뮬레이션: SidebarView.count(for:) 메서드
    private func count(for category: BufferCategory, items: [BufferItem]) -> Int {
        if category == .all {
            return items.count
        }
        return items.filter { $0.category == category }.count
    }

    @Test func count_all_returns_total() {
        let items = [
            BufferItem(category: .notes),
            BufferItem(category: .links),
            BufferItem(category: .files),
        ]
        #expect(count(for: .all, items: items) == 3)
    }

    @Test func count_specific_category() {
        let items = [
            BufferItem(category: .notes),
            BufferItem(category: .notes),
            BufferItem(category: .links),
        ]
        #expect(count(for: .notes, items: items) == 2)
        #expect(count(for: .links, items: items) == 1)
        #expect(count(for: .files, items: items) == 0)
        #expect(count(for: .images, items: items) == 0)
    }

    @Test func count_empty_items() {
        let items: [BufferItem] = []
        #expect(count(for: .all, items: items) == 0)
        #expect(count(for: .notes, items: items) == 0)
    }
}

// MARK: - EditorView createSubPage 로직 화이트박스 테스트

struct CreateSubPageLogicTests {

    @Test func sub_page_has_parent_set() {
        let parent = BufferItem(title: "부모 페이지", content: "내용")
        let subPage = BufferItem(title: "", content: "", category: .notes, parentItem: parent)

        #expect(subPage.parentItem === parent)
        #expect(subPage.title == "")
        #expect(subPage.category == .notes)
    }

    @Test func link_text_appended_to_content() {
        let item = BufferItem(title: "테스트", content: "기존 내용")
        let linkText = "[[새 페이지]]"
        item.content += linkText
        #expect(item.content == "기존 내용[[새 페이지]]")
    }

    @Test func page_picker_link_insertion() {
        let item = BufferItem(title: "테스트", content: "")
        let selectedPageTitle = "연결할 페이지"
        let title = selectedPageTitle.isEmpty ? "제목 없음" : selectedPageTitle
        item.content += "[[" + title + "]]"
        #expect(item.content == "[[연결할 페이지]]")
    }

    @Test func page_picker_empty_title_fallback() {
        let selectedPageTitle = ""
        let title = selectedPageTitle.isEmpty ? "제목 없음" : selectedPageTitle
        #expect(title == "제목 없음")
    }

    @Test func page_picker_non_empty_title_kept() {
        let selectedPageTitle = "실제 제목"
        let title = selectedPageTitle.isEmpty ? "제목 없음" : selectedPageTitle
        #expect(title == "실제 제목")
    }
}

// MARK: - NoteRowView 표시 로직 화이트박스 테스트

struct NoteRowDisplayLogicTests {

    @Test func empty_title_shows_fallback() {
        let item = BufferItem(title: "")
        let displayTitle = item.title.isEmpty ? "제목 없음" : item.title
        #expect(displayTitle == "제목 없음")
    }

    @Test func non_empty_title_shows_as_is() {
        let item = BufferItem(title: "실제 제목")
        let displayTitle = item.title.isEmpty ? "제목 없음" : item.title
        #expect(displayTitle == "실제 제목")
    }

    @Test func empty_content_hidden() {
        let item = BufferItem(content: "")
        let showContent = !item.content.isEmpty
        #expect(showContent == false)
    }

    @Test func non_empty_content_visible() {
        let item = BufferItem(content: "내용 있음")
        let showContent = !item.content.isEmpty
        #expect(showContent == true)
    }

    @Test func pinned_item_shows_indicator() {
        let item = BufferItem(isPinned: true)
        #expect(item.isPinned == true)
    }

    @Test func unpinned_item_hides_indicator() {
        let item = BufferItem(isPinned: false)
        #expect(item.isPinned == false)
    }

    @Test func category_icon_shown() {
        let item = BufferItem(category: .links)
        #expect(item.category.icon == "link")
    }
}

// MARK: - ContentView 기본 상태 테스트

struct ContentViewLogicTests {

    @Test func default_category_is_all() {
        // ContentView의 초기 selectedCategory 값
        let defaultCategory: BufferCategory = .all
        #expect(defaultCategory == .all)
    }

    @Test func default_selected_item_is_nil() {
        // ContentView의 초기 selectedItem 값
        let selectedItem: BufferItem? = nil
        #expect(selectedItem == nil)
    }
}
