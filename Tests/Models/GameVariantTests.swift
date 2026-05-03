import Testing
import Foundation
@testable import LayoverKit

/// Tests for GameVariant model
@Suite("Game Variant Model Tests")
struct GameVariantTests {
    
    @Test("GameVariant initialization")
    func testGameVariantInitialization() {
        let variant = GameVariant(
            gameType: .chess,
            name: "Standard Chess",
            region: "International",
            description: "Classic chess",
            rules: ["boardSize": "8x8"]
        )
        
        #expect(variant.gameType == .chess)
        #expect(variant.name == "Standard Chess")
        #expect(variant.region == "International")
        #expect(variant.description == "Classic chess")
        #expect(variant.rules["boardSize"] == "8x8")
    }
    
    @Test("Chess variants exist")
    func testChessVariantsExist() {
        let variants = GameVariants.allChessVariants
        
        #expect(variants.count >= 4)
        #expect(variants.contains { $0.name.contains("Standard") })
        #expect(variants.contains { $0.name.contains("Xiangqi") })
        #expect(variants.contains { $0.name.contains("Shogi") })
        #expect(variants.contains { $0.name.contains("960") })
    }
    
    @Test("Checkers variants exist")
    func testCheckersVariantsExist() {
        let variants = GameVariants.allCheckersVariants
        
        #expect(variants.count >= 4)
        #expect(variants.contains { $0.name.contains("American") })
        #expect(variants.contains { $0.name.contains("International") })
        #expect(variants.contains { $0.name.contains("Brazilian") })
        #expect(variants.contains { $0.name.contains("Russian") })
    }
    
    @Test("Connect Four variants exist")
    func testConnectFourVariantsExist() {
        let variants = GameVariants.allConnectFourVariants
        
        #expect(variants.count >= 3)
        #expect(variants.contains { $0.name.contains("Standard") })
        #expect(variants.contains { $0.name.contains("Pop Out") })
        #expect(variants.contains { $0.name.contains("Power Up") })
    }
    
    @Test("Get variants for game type")
    func testGetVariantsForGameType() {
        let chessVariants = GameVariants.variants(for: .chess)
        #expect(chessVariants.allSatisfy { $0.gameType == .chess })
        
        let checkersVariants = GameVariants.variants(for: .checkers)
        #expect(checkersVariants.allSatisfy { $0.gameType == .checkers })
        
        let connectFourVariants = GameVariants.variants(for: .connectFour)
        #expect(connectFourVariants.allSatisfy { $0.gameType == .connectFour })
    }
    
    @Test("Get variants for region")
    func testGetVariantsForRegion() {
        let chineseVariants = GameVariants.variants(forRegion: "China")
        #expect(chineseVariants.contains { $0.name.contains("Xiangqi") })
        
        let japaneseVariants = GameVariants.variants(forRegion: "Japan")
        #expect(japaneseVariants.contains { $0.name.contains("Shogi") })
        
        let russianVariants = GameVariants.variants(forRegion: "Russia")
        #expect(russianVariants.contains { $0.name.contains("Russian") })
    }
    
    @Test("All variants have unique IDs")
    func testAllVariantsHaveUniqueIds() {
        let allIds = GameVariants.allVariants.map { $0.id }
        let uniqueIds = Set(allIds)
        
        #expect(allIds.count == uniqueIds.count)
    }
    
    @Test("All variants have non-empty names")
    func testAllVariantsHaveNames() {
        for variant in GameVariants.allVariants {
            #expect(!variant.name.isEmpty)
            #expect(!variant.region.isEmpty)
            #expect(!variant.description.isEmpty)
        }
    }
    
    @Test("All variants have rules")
    func testAllVariantsHaveRules() {
        for variant in GameVariants.allVariants {
            #expect(!variant.rules.isEmpty)
        }
    }
    
    @Test("Xiangqi has Chinese-specific rules")
    func testXiangqiHasChineseRules() {
        let xiangqi = GameVariants.xiangqi
        
        #expect(xiangqi.name.contains("Xiangqi"))
        #expect(xiangqi.region == "China")
        #expect(xiangqi.rules["river"] == "enabled")
        #expect(xiangqi.rules["palace"] == "enabled")
    }
    
    @Test("Shogi has Japanese-specific rules")
    func testShogiHasJapaneseRules() {
        let shogi = GameVariants.shogi
        
        #expect(shogi.name.contains("Shogi"))
        #expect(shogi.region == "Japan")
        #expect(shogi.rules["drops"] == "enabled")
    }
    
    @Test("International Draughts is larger board")
    func testInternationalDraughtsLargerBoard() {
        let draughts = GameVariants.internationalDraughts
        
        #expect(draughts.rules["boardSize"] == "10x10")
        #expect(draughts.rules["flyingKings"] == "true")
    }
    
    @Test("Game type enum has all cases")
    func testGameTypeEnumCases() {
        let types: [GameVariant.GameType] = [.chess, .checkers, .connectFour]
        
        for type in types {
            #expect(!type.rawValue.isEmpty)
        }
    }
}
