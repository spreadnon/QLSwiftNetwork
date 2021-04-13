//
//  ViewController.swift
//  QLSwiftNetwork
//
//  Created by iOS123 on 2021/4/13.
//

import UIKit

struct BaseModel: Codable {
    let body: String
    let title: String
    let userId: Int
}

struct TestModel: Codable {
    let code: Int
    let message: String
    let result: [Item]
}
struct Item: Codable {
    let text: String
    let video: String
}

struct ResultModel: Codable {
    let city: String
    let citykey: String
    let parent: String
    let updateTime: String
}



class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NetworkTool.shared.canLogging = true
        
        /*
        NetworkTool.shared.requestWithConfig { (config) in
            config.networkType = .apps
            config.URLString = "https://timor.tech/api/holiday/year/2021/"
            config.requestMethod = .get
        } success: { (config) in

            let dic : [String: Any] = config.response?.value as! [String : Any]
            print("\(dic["holiday"])")

        } failure: { (_) in
            print("error getHoliday")
        }
        */
        
        
        
        NetworkToolRequest.get("https://jsonplaceholder.typicode.com/posts",netWorkType: .normal, modelType: [BaseModel].self) { (model) in
            print("\(String(describing: model))")
        }
        
        _ = NetworkToolRequest.get("http://t.weather.itboy.net/api/weather/city/101030100",netWorkType: .normal, modelType: ResultModel.self, modelKeyPath: "cityInfo") { (model) in
            print("22222\(String(describing: model))")
        }
		//a?.cancel()
        
        
    }


}
