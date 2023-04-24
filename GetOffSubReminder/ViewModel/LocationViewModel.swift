import UIKit
import CoreLocation
import Alamofire

class LocationViewModel: NSObject {
    // 定义User对象
    struct Res<T: Decodable>: Decodable{
        let retCode: String
        let retMsg: String
        let busBody: T
    }
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
                        let errorCode = responseData.retCode
                        let message = responseData.retMsg
                        let desChinese = responseData.busBody
                        print("目的地中文：\(desChinese)")
                        self.delegate?.updateDesChinese("目的地:\(desChinese)")
                    }
                }
            }
    }
    //        更新位置
    func updateDatabase(value: CLLocationCoordinate2D) {
        var modelValue = [String: Any]()
        var latitude=value.latitude
        var longitude=value.longitude
        modelValue["latitude"] = latitude
        modelValue["longitude"] = longitude
        modelValue["time"] = getTime()
        let userId=getUserId();
        //发送请求，获取距离
        AF.request("http://\(kHost):\(kPort)/getDistance/\(longitude)/\(latitude)/\(userId)").responseJSON { response in
            if let data=response.value{
                print("距离：\(data)")
                if(data as! Int==0){
                    self.delegate?.updateDestination("距离目的地:请先采集位置信息")
                }else{
                    self.delegate?.updateDestination("距离目的地:\(data as! Double/1000)千米")
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
            //发送请求存储位置
            AF.request("http://\(kHost):\(kPort)/saveLocation/\(longitude)/\(latitude)/home/\(userId)").responseJSON { response in
                if let data=response.value{
                    print("保存家位置信息状态：\(data)")
                }
            }
        }else if(flag==1){
            self.delegate?.updateWorkLocation(longitude,latitude)
            //发送请求存储位置
            AF.request("http://\(kHost):\(kPort)/saveLocation/\(longitude)/\(latitude)/work/\(userId)").responseJSON { response in
                if let data=response.value{
                    print("保存上班位置信息状态：\(data)")
                }
            }
        }
    }
    
    //获取回家位置和上班位置已经更新的位置信息
    func getWorkAndHomeLocation(flag: Int){
        let userId=getUserId();
        if(flag==0){
            //获取回家的经纬度
            AF.request("http://\(kHost):\(kPort)/getWorkAndHomeLocation/home/\(userId)").responseJSON { response in
                if let data=response.data{
                    let string = String(data: data, encoding: .utf8)
                    print("回家位置经纬度\(string)")
                    //更新视图
                    self.delegate?.updateHomeLocationTxt(string!)
                }
            }
        }else if(flag==1){
            //获取上班位置
            AF.request("http://\(kHost):\(kPort)/getWorkAndHomeLocation/work/\(userId)").responseJSON { response in
                if let data=response.data{
                    let string = String(data: data, encoding: .utf8)
                    print("上班位置经纬度\(string)")
                    //更新视图
                    self.delegate?.updateWorkLocationTxt(string!)
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




