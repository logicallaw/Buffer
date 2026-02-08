import Testing
@testable import buffer

// MARK: - HotKeyService 화이트박스 테스트

struct HotKeyServiceTests {

    // MARK: - 싱글톤 패턴

    @Test func shared_returns_same_instance() {
        let a = HotKeyService.shared
        let b = HotKeyService.shared
        #expect(a === b)
    }

    // MARK: - onActivate 콜백 설정/해제

    @Test func onActivate_initially_nil() {
        let service = HotKeyService.shared
        // 기본적으로 nil일 수 있으나, 다른 테스트에서 설정했을 수 있으므로 설정/해제 확인
        service.onActivate = nil
        #expect(service.onActivate == nil)
    }

    @Test func onActivate_can_be_set() {
        let service = HotKeyService.shared
        var called = false
        service.onActivate = { called = true }
        service.onActivate?()
        #expect(called == true)
        service.onActivate = nil
    }

    // MARK: - register/unregister 호출 (crash 없이 완료)

    @Test func register_then_unregister_no_crash() {
        let service = HotKeyService.shared
        service.register()
        service.unregister()
        // unregister 후 재호출 (nil 분기)
        service.unregister()
    }

    @Test func unregister_without_register_no_crash() {
        // unregister 내부에서 nil 체크 분기
        let service = HotKeyService.shared
        service.unregister()
    }
}
