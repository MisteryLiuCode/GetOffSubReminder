//
//  Res.swift
//  GetOffSubReminder
//
//  Created by 刘帅彪 on 2023/4/25.
//

import Foundation
//定义通用返回对象
struct Res<T: Decodable>: Decodable{
    let retCode: String
    let retMsg: String
    let busBody: T
}
