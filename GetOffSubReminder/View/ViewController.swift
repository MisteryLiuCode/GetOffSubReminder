//
//  ViewController.swift
//  Telyport_Assignment
//
//  Created by Girira Stephy on 13/02/21.
//

import UIKit
import CoreLocation
import Alamofire


//*******If the app is not getting launched in the device.Please go to Settings->General->DeviceManagement->Trust The Apple Development*******This is because of
//inadequate entitlements or its profile has not been explicitly trusted by the user.


class ViewController: UIViewController {
    
    var viewModel: LocationViewModel!
    
    //家方向地铁的位置
    @IBOutlet weak var homeLocationLabel: UILabel!
    
    //上班地铁位置
    @IBOutlet weak var workLocationLabel: UILabel!
    
    //目的地中文
    @IBOutlet weak var DesChineseLabel: UILabel!
    
    //目的地距离
    @IBOutlet weak var destinationLabel: UILabel!
    
    //获取回家家下车位置按钮
    @IBAction func homeLocationBt(_ sender: UIButton){
        print("点了第一个按钮")
        if(!(homeLocationLabel.text == "右边按钮获取回家地铁下车位置")){
            // create the alert
            let alert = UIAlertController(title: "位置更新", message: "你确定要更新位置信息吗", preferredStyle: UIAlertController.Style.alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default, handler: { action in
                
                // do something like...
                self.viewModel.updateLocation(flag: 0)
                
            }))
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            viewModel.updateLocation(flag: 0)
        }
    }
    
    //获取上班地铁下车按钮
    @IBAction func workLocationBt(_ sender: UIButton){
        if(!(workLocationLabel.text == "右边按钮获取上班地铁下车位置")){
            // create the alert
            let alert = UIAlertController(title: "位置更新", message: "你确定要更新位置信息吗", preferredStyle: UIAlertController.Style.alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default, handler: { action in
                
                // do something like...
                self.viewModel.updateLocation(flag: 1)
                
            }))
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            viewModel.updateLocation(flag: 1)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //生成唯一id
        SaveUserId()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel = LocationViewModel(delegateValue: self)
    }
    
    func SaveUserId(){
        if let myId = UserDefaults.standard.string(forKey: "myId") {
            print("本机设备id: \(myId)")
            // 定义入参参数
            let userReq: Parameters = [
                "userId": myId,
            ]
            
            //发送请求保存用户
            AF.request("http://\(kHost):\(kPort)/saveUserInfo", method: .post, parameters: userReq)
                .responseJSON { response in
                    if case .success(let value) = response.result {
                        if let json = value as? [String: Any],
                           let responseData = try? JSONDecoder().decode(Res<Bool>.self, from: JSONSerialization.data(withJSONObject: json)) {
                            // 获取response data
                            if responseData.retCode=="0000"{
                                let saveUser = responseData.busBody
                                print("保存用户id状态：\(saveUser)")
                            }
                        }
                    }
                }
        }else{
            let uniqueId = UUID().uuidString
            UserDefaults.standard.set(uniqueId, forKey: "myId")
            SaveUserId()
        }
    }
}

extension ViewController: UpdateLocationProtocol{
    
    func updateHomeLocation(_ long: Double,_ lat: Double) {
        homeLocationLabel!.text = "\(long),\(lat)"
    }
    func updateWorkLocation(_ long: Double,_ lat: Double) {
        workLocationLabel!.text = "\(long),\(lat)"
    }
    func updateDestination(_ value: String) {
        destinationLabel!.text = value
    }
    
    func updateDesChinese(_ value: String) {
        DesChineseLabel!.text = value
    }
    
    func updateHomeLocationTxt(_ value: String) {
        homeLocationLabel!.text = value
    }
    
    func updateWorkLocationTxt(_ value: String) {
        workLocationLabel!.text = value
    }
    
    func presentError(_ title: String,subHeading: String) {
        let alert = UIAlertController.init(title: title, message: subHeading, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Go to Settings", style: .default, handler: { [weak self] (_) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    
                })
            }
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (_) in
            //show error view
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}


