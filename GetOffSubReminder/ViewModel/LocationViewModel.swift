import UIKit
import CoreLocation
import Alamofire

class LocationViewModel: NSObject {
    //    struct DesChinese: Decodable {
    //        let des: String
    //    }
    
    
    
    private var locationManager: CLLocationManager?
    var myCurrentLocation: CLLocationCoordinate2D?
    var updatingLocationValue : CLLocationCoordinate2D?
    weak var delegate: UpdateLocationProtocol?
    
    convenience init(delegateValue: UpdateLocationProtocol) {
        self.init()
        self.delegate = delegateValue
        //获取目的地信息
        getDes()
        //获取用户位置
        getUserLocation()
        //更新位置
        getTimedLocation()
        //获取回家位置信息
        getWorkAndHomeLocation(flag: 0)
        //获取上班位置信息
        getWorkAndHomeLocation(flag: 1)
    }
    //10秒获取一下位置
    func getTimedLocation(){
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: { [weak self] in
            guard let unwrappedLocation = self?.updatingLocationValue else { return }
            self?.updateDatabase(value: unwrappedLocation)
            self?.getTimedLocation()
        })
    }
    //获取目的地信息
    func getDes(){
        // 定义入参参数
        let userId=getUserId();
        let userReq: Parameters = [
            "userId": userId,
        ]
        // 发送POST请求
        AF.request("http://\(kHost):\(kPort)/getDestination", method: .post, parameters: userReq)
            .responseJSON { response in
                if case .success(let value) = response.result {
                    if let json = value as? [String: Any],
                       let responseData = try? JSONDecoder().decode(Res<String>.self, from: JSONSerialization.data(withJSONObject: json)) {
                        // 获取response data
                        if responseData.retCode=="0000"{
                            let desChinese = responseData.busBody
                            print("目的地中文：\(desChinese)")
                            self.delegate?.updateDesChinese("目的地:\(desChinese)")
                        }
                    }
                }
            }
    }
    //        更新位置
    func updateDatabase(value: CLLocationCoordinate2D) {
        var latitude=value.latitude
        var longitude=value.longitude
        // 定义入参参数
        let userId=getUserId();
        let distanceReq: Parameters = [
            "userId": userId,
            "oriLong": longitude,
            "oriLat": latitude,
        ]
        AF.request("http://\(kHost):\(kPort)/getDistance", method: .post, parameters: distanceReq)
            .responseJSON { response in
                if case .success(let value) = response.result {
                    if let json = value as? [String: Any],
                       let responseData = try? JSONDecoder().decode(Res<Double>.self, from: JSONSerialization.data(withJSONObject: json)) {
                        // 获取response data
                        if responseData.retCode=="0000"{
                            let distance = responseData.busBody
                            print("距离：\(distance)")
                            if(distance==0){
                                self.delegate?.updateDestination("距离目的地:请先采集位置信息")
                            }else{
                                self.delegate?.updateDestination("距离目的地:\(distance as! Double/1000)千米")
                            }
                        }
                    }
                }
            }
    }
    
    //获取上下班地铁位置
    func updateLocation(flag: Int){
        //0:更新家方向地铁下车位置 1:获取上班方向地铁下车位置
        guard let unwrappedLocation = self.updatingLocationValue else { return }
        let latitude=unwrappedLocation.latitude
        let longitude=unwrappedLocation.longitude
        let userId=getUserId();
        if(flag==0){
            //更新位置
            self.delegate?.updateHomeLocation(longitude,latitude)
            // 定义入参参数
            let userId=getUserId();
            let saveHomeReq: Parameters = [
                "userId": userId,
                "oriLong": longitude,
                "oriLat": latitude,
                "locationType":"home"
            ]
            AF.request("http://\(kHost):\(kPort)/saveLocation", method: .post, parameters: saveHomeReq)
                .responseJSON { response in
                    if case .success(let value) = response.result {
                        if let json = value as? [String: Any],
                           let responseData = try? JSONDecoder().decode(Res<Int>.self, from: JSONSerialization.data(withJSONObject: json)) {
                            // 获取response data
                            if responseData.retCode=="0000"{
                                let saveHomeStatus = responseData.busBody
                                print("保存家位置信息状态：\(saveHomeStatus)")
                            }
                        }
                    }
                }
        }else if(flag==1){
            self.delegate?.updateWorkLocation(longitude,latitude)
            // 定义入参参数
            let userId=getUserId();
            let saveWorkReq: Parameters = [
                "userId": userId,
                "oriLong": longitude,
                "oriLat": latitude,
                "locationType":"work"
            ]
            AF.request("http://\(kHost):\(kPort)/saveLocation", method: .post, parameters: saveWorkReq)
                .responseJSON { response in
                    if case .success(let value) = response.result {
                        if let json = value as? [String: Any],
                           let responseData = try? JSONDecoder().decode(Res<Int>.self, from: JSONSerialization.data(withJSONObject: json)) {
                            // 获取response data
                            if responseData.retCode=="0000"{
                                let saveHomeStatus = responseData.busBody
                                print("保存上班位置信息状态：\(saveHomeStatus)")
                            }
                        }
                    }
                }
        }
    }
    
    //获取回家位置和上班位置已经更新的位置信息
    func getWorkAndHomeLocation(flag: Int){
        let userId=getUserId();
        if(flag==0){
            // 定义入参参数
            let homeReq: Parameters = [
                "userId": userId,
                "locationType":"home"
            ]
            //获取回家的经纬度
            AF.request("http://\(kHost):\(kPort)/getWorkAndHomeLocation", method: .post, parameters: homeReq)
                .responseJSON { response in
                        if let data=response.data{
                            let homeInfo = String(data: data, encoding: .utf8)
                            print("回家位置经纬度\(homeInfo)")
                            //更新视图
                            self.delegate?.updateHomeLocationTxt(homeInfo!)
                        }
                }
        }else if(flag==1){
            // 定义入参参数
            let workReq: Parameters = [
                "userId": userId,
                "locationType":"work"
            ]
            
            //获取上班的经纬度
            AF.request("http://\(kHost):\(kPort)/getWorkAndHomeLocation", method: .post, parameters: workReq)
                .responseJSON { response in
                        if let data=response.data{
                            let workInfo = String(data: data, encoding: .utf8)
                            print("上班位置经纬度\(workInfo)")
                            //更新视图
                            self.delegate?.updateWorkLocationTxt(workInfo!)
                        }
                }
        }
    }
    
    //获取位置权限
    func getUserLocation() {
        locationManager = CLLocationManager()
        
        switch locationManager?.authorizationStatus {
        case .denied , .restricted:
            delegate?.presentError("Oh no!", subHeading: "请允许我获取位置信息")
            break
        case .notDetermined:
            // Ask for Authorisation from the User.
            self.locationManager?.requestAlwaysAuthorization()
            // For use in foreground
            self.locationManager?.requestWhenInUseAuthorization()
            break
        default:
            break
        }
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.startUpdatingLocation()
            locationManager?.allowsBackgroundLocationUpdates = true
        }
    }
    //    获取时间
    func getTime() -> String{
        let now = Date()
        let format = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let dateFormatter = DateFormatter.init()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: now)
    }
    
    //    获取时间，不同格式
    func getDateString() -> String {
        let now = Date()
        let format = "dd MMM yyyy"
        let dateFormatter = DateFormatter.init()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: now)
    }
    //获取用户id
    func getUserId() -> String{
        guard let myId = UserDefaults.standard.string(forKey: "myId") else { return "" };
        return myId
    }
    
}


extension LocationViewModel: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.updatingLocationValue = locValue
        guard let unwrappedLocation = myCurrentLocation else {
            myCurrentLocation = locValue
            return
        }
        //get distance between locValue and myCurrentLocation
        let currentCoordinates = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        let previousCoordinates = CLLocation(latitude: unwrappedLocation.latitude, longitude: unwrappedLocation.longitude)
        let distance = currentCoordinates.distance(from: previousCoordinates)
    }
}




