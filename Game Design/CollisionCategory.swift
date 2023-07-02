//
//  CollisionCategory.swift
//  Starhaven
//
//  Created by JxR on 4/22/23.
//

import Foundation
import SwiftUI

struct CollisionCategory {
    static let ship: Int = 1 << 0
    static let enemyShip: Int = 1 << 1
    static let laser: Int = 1 << 2
    static let missile: Int = 1 << 3
    static let celestial: Int = 1 << 4
    static let OSNR: Int = 1 << 5
}
