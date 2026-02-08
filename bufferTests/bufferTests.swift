import Testing
@testable import buffer

// MARK: - bufferApp 기본 검증

struct bufferTests {

    @Test func bufferCategory_is_importable() {
        // @testable import buffer가 정상 작동하는지 확인
        let category = BufferCategory.notes
        #expect(category.rawValue == "notes")
    }
}
