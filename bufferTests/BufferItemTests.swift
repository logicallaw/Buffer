import Testing
import Foundation
@testable import buffer

// MARK: - BufferItem 화이트박스 테스트

struct BufferItemTests {

    // MARK: - init 기본값 테스트

    @Test func init_defaults() {
        let item = BufferItem()
        #expect(item.title == "")
        #expect(item.content == "")
        #expect(item.category == .notes)
        #expect(item.isPinned == false)
        #expect(item.parentItem == nil)
    }

    // MARK: - init 커스텀 값 테스트

    @Test func init_custom_values() {
        let item = BufferItem(
            title: "테스트 제목",
            content: "테스트 내용",
            category: .links,
            isPinned: true
        )
        #expect(item.title == "테스트 제목")
        #expect(item.content == "테스트 내용")
        #expect(item.category == .links)
        #expect(item.isPinned == true)
    }

    // MARK: - 날짜 자동 설정 검증

    @Test func init_sets_dates() {
        let before = Date()
        let item = BufferItem()
        let after = Date()

        #expect(item.createdAt >= before)
        #expect(item.createdAt <= after)
        #expect(item.updatedAt >= before)
        #expect(item.updatedAt <= after)
    }

    // MARK: - 카테고리별 init 분기

    @Test func init_with_each_category() {
        for category in BufferCategory.allCases where category != .all {
            let item = BufferItem(category: category)
            #expect(item.category == category)
        }
    }

    // MARK: - parentItem 연결

    @Test func init_with_parentItem() {
        let parent = BufferItem(title: "부모")
        let child = BufferItem(title: "자식", parentItem: parent)
        #expect(child.parentItem === parent)
    }

    // MARK: - 옵셔널 프로퍼티 nil 기본값

    @Test func optional_properties_default_to_nil() {
        let item = BufferItem()
        #expect(item.url == nil)
        #expect(item.linkTitle == nil)
        #expect(item.linkDescription == nil)
        #expect(item.fileName == nil)
        #expect(item.fileSize == nil)
        #expect(item.fileBookmark == nil)
        #expect(item.imageData == nil)
        #expect(item.childItems == nil)
    }

    // MARK: - 프로퍼티 변경 가능 테스트

    @Test func mutable_properties() {
        let item = BufferItem()
        item.title = "변경된 제목"
        item.content = "변경된 내용"
        item.isPinned = true
        item.url = "https://example.com"
        item.fileName = "test.txt"
        item.fileSize = 1024
        item.fileBookmark = Data([0x01, 0x02])
        item.imageData = Data([0xFF])
        item.linkTitle = "링크 제목"
        item.linkDescription = "링크 설명"

        #expect(item.title == "변경된 제목")
        #expect(item.content == "변경된 내용")
        #expect(item.isPinned == true)
        #expect(item.url == "https://example.com")
        #expect(item.fileName == "test.txt")
        #expect(item.fileSize == 1024)
        #expect(item.fileBookmark == Data([0x01, 0x02]))
        #expect(item.imageData == Data([0xFF]))
        #expect(item.linkTitle == "링크 제목")
        #expect(item.linkDescription == "링크 설명")
    }

    // MARK: - updatedAt 수동 업데이트

    @Test func updatedAt_can_be_changed() {
        let item = BufferItem()
        let original = item.updatedAt
        let future = Date(timeIntervalSinceNow: 100)
        item.updatedAt = future
        #expect(item.updatedAt == future)
        #expect(item.updatedAt != original)
    }
}
