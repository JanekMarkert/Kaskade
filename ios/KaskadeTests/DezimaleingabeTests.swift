import Testing
@testable import Kaskade

@Test func wandeltKommaAlsDezimaltrennzeichenUm() {
    #expect("0,5".alsDezimalzahl == 0.5)
    #expect("2.0".alsDezimalzahl == 2.0)
    #expect("20".alsDezimalzahl == 20.0)
    #expect("keine zahl".alsDezimalzahl == nil)
}
