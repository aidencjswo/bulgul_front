//
//  bulgul_frontTests.swift
//  bulgul_frontTests
//
//  Created by 안상영 on 8/4/26.
//

import Testing
@testable import bulgul_front

struct bulgul_frontTests {

    @Test func getTipsTest() async throws {
        var tips : [TipsResponse] = []
        
        do{
            
            print("test start : getTipsTest")
            
            tips = try await ContentService.shared.getTips()
            
            print(tips)
            
        }
        catch{
            print("에러 발생: \(error)")
        }
    }

}
