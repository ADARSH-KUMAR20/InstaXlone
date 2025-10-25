//
//  PostModel.swift
//  Multiplier
//
//  Created by HT-Mac-08 on 10/10/25.
//

import Foundation
struct PostModel: Codable {
    let name: String
    let profileImage: String
    let description: String
    let mainImage: String
    let videoURL: String?
    let likeCount: Int
}
