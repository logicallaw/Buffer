import Testing
import Foundation
@testable import buffer

// MARK: - BufferCategory 화이트박스 테스트

struct BufferCategoryTests {

    // MARK: - displayName 분기 커버리지 (5 case 전부)

    @Test func displayName_all_returns_전체() {
        #expect(BufferCategory.all.displayName == "전체")
    }

    @Test func displayName_notes_returns_메모() {
        #expect(BufferCategory.notes.displayName == "메모")
    }

    @Test func displayName_links_returns_링크() {
        #expect(BufferCategory.links.displayName == "링크")
    }

    @Test func displayName_files_returns_파일() {
        #expect(BufferCategory.files.displayName == "파일")
    }

    @Test func displayName_images_returns_이미지() {
        #expect(BufferCategory.images.displayName == "이미지")
    }

    // MARK: - icon 분기 커버리지 (5 case 전부)

    @Test func icon_all() {
        #expect(BufferCategory.all.icon == "tray.full")
    }

    @Test func icon_notes() {
        #expect(BufferCategory.notes.icon == "note.text")
    }

    @Test func icon_links() {
        #expect(BufferCategory.links.icon == "link")
    }

    @Test func icon_files() {
        #expect(BufferCategory.files.icon == "doc")
    }

    @Test func icon_images() {
        #expect(BufferCategory.images.icon == "photo")
    }

    // MARK: - Identifiable (id == rawValue)

    @Test func id_equals_rawValue() {
        for category in BufferCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - CaseIterable 카운트

    @Test func allCases_has_5_cases() {
        #expect(BufferCategory.allCases.count == 5)
    }

    // MARK: - Codable 라운드트립

    @Test func codable_roundtrip() throws {
        for category in BufferCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(BufferCategory.self, from: data)
            #expect(decoded == category)
        }
    }

    // MARK: - rawValue 검증

    @Test func rawValue_strings() {
        #expect(BufferCategory.all.rawValue == "all")
        #expect(BufferCategory.notes.rawValue == "notes")
        #expect(BufferCategory.links.rawValue == "links")
        #expect(BufferCategory.files.rawValue == "files")
        #expect(BufferCategory.images.rawValue == "images")
    }
}
