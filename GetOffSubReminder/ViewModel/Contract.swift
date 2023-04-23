//
//  Contract.swift
//  Telyport_Assignment
//
//  Created by Girira Stephy on 14/02/21.
//

import Foundation



protocol UpdateLocationProtocol: AnyObject {
    
    //距离目的地
    func updateDestination(_ value: String)
    //获取家方向地铁位置
    func updateHomeLocation(_ long: Double,_ lat: Double)
    //获取上班地铁位置
    func updateWorkLocation(_ long: Double,_ lat: Double)
    //获取目的地，中文
    func updateDesChinese(_ value: String)
    func presentError(_ title: String,subHeading: String)
    
    func updateHomeLocationTxt(_ value: String)
    
    func updateWorkLocationTxt(_ value: String)
}
