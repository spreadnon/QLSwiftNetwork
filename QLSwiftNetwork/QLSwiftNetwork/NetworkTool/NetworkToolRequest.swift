//
//  NetworkToolRequest.swift
//  IKSwiftCoreModule
//
//  Created by iOS123 on 2021/2/20.
//

import UIKit
import Alamofire

class NetworkToolRequest: NSObject {
    public typealias requestCallBack<T: Codable> = (_ data : T?) -> Void
    
    @discardableResult
    public class func get<T : Codable>(_ url: String,
                                       netWorkType: NetworkType = .apps,
                                       parameters: [String:Any] = [:],
                                       modelType: T.Type,
                                       modelKeyPath: String? = nil,
                                       callBack: requestCallBack<T>?) -> DataRequest?{
        return request(url,
                       netWorkType: netWorkType,
                       requestMethod: .get,
                       parameters: parameters,
                       modelType: modelType,
                       modelKeyPath: modelKeyPath,
                       callBack: callBack)
    }
    
    @discardableResult
    public class func post<T : Codable>(_ url: String,
                                    	netWorkType: NetworkType = .apps,
                                       parameters: [String:Any] = [:],
                                       modelType: T.Type,
                                       modelKeyPath: String? = nil,
                                       callBack: requestCallBack<T>?) -> DataRequest?{
        return request(url,
                       netWorkType: netWorkType,
                       requestMethod: .post,
                       parameters: parameters,
                       modelType: modelType,
                       modelKeyPath: modelKeyPath,
                       callBack: callBack)
    }
    
    class func request<T: Codable>(_ url : String, netWorkType: NetworkType = .apps, requestMethod: HTTPMethod = .get , parameters: [String:Any] = [:] , modelType: T.Type , modelKeyPath: String? = nil , callBack: requestCallBack<T>?) -> DataRequest? {
        return NetworkTool.shared.requestWithConfig { (config) in
            config.networkType = netWorkType
            config.requestMethod = requestMethod
            config.URLString = url
            config.parameters = parameters
        } success: { (config) in
            
            if let keypath = modelKeyPath, keypath.count > 0 {
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let data = config.response?.data, let model = try? decoder.decode(modelType.self, from: data, keyPath: keypath) else {
                    callBack?(nil)
                    return
                }
                
                callBack?(model)
                
            }else{
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let data = config.response?.data, let model = try? decoder.decode(modelType.self, from: data) else {
                    callBack?(nil)
                    return
                }
                
                callBack?(model)
            }
        } failure: { (config) in
            callBack?(nil)
        }

    }
}




public extension JSONDecoder {
    
    func decode<T>(_ type: T.Type,
                   from data: Data,
                   keyPath: String,
                   keyPathSeparator separator: String = ".") throws -> T where T : Decodable {
        userInfo[keyPathUserInfoKey] = keyPath.components(separatedBy: separator)
        return try decode(KeyPathWrapper<T>.self, from: data).object
    }
}

private let keyPathUserInfoKey = CodingUserInfoKey(rawValue: "keyPathUserInfoKey")!

private final class KeyPathWrapper<T: Decodable>: Decodable {
    
    enum KeyPathError: Error {
        case `internal`
    }
    
    struct Key: CodingKey {
        init?(intValue: Int) {
            self.intValue = intValue
            stringValue = String(intValue)
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }
        
        let intValue: Int?
        let stringValue: String
    }
    
    typealias KeyedContainer = KeyedDecodingContainer<KeyPathWrapper<T>.Key>
    
    init(from decoder: Decoder) throws {
        guard let keyPath = decoder.userInfo[keyPathUserInfoKey] as? [String],
            !keyPath.isEmpty
            else { throw KeyPathError.internal }
        
        func getKey(from keyPath: [String]) throws -> Key {
            guard let first = keyPath.first,
                let key = Key(stringValue: first)
                else { throw KeyPathError.internal }
            return key
        }
        
        func objectContainer(for keyPath: [String],
                             in currentContainer: KeyedContainer,
                             key currentKey: Key) throws -> (KeyedContainer, Key) {
            guard !keyPath.isEmpty else { return (currentContainer, currentKey) }
            let container = try currentContainer.nestedContainer(keyedBy: Key.self, forKey: currentKey)
            let key = try getKey(from: keyPath)
            return try objectContainer(for: Array(keyPath.dropFirst()), in: container, key: key)
        }
        
        let rootKey = try getKey(from: keyPath)
        let rooTContainer = try decoder.container(keyedBy: Key.self)
        let (keyedContainer, key) = try objectContainer(for: Array(keyPath.dropFirst()), in: rooTContainer, key: rootKey)
        object = try keyedContainer.decode(T.self, forKey: key)
    }
    
    let object: T
}
/// Codable 默认值
@propertyWrapper
struct Default<T: DefaultValue> {
    var wrappedValue: T.defalut
}

extension Default: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.defalut.self)) ?? T.defaultValue
    }

}
extension KeyedDecodingContainer {
    func decode<T>(
        _ type: Default<T>.Type,
        forKey key: Key
    ) throws -> Default<T> where T: DefaultValue {
        try decodeIfPresent(type, forKey: key) ?? Default(wrappedValue: T.defaultValue)
    }
}

extension KeyedEncodingContainer{
    func encode<T>(
        _ type: Default<T>.Type,
        forKey key: Key
    ) throws -> Default<T> where T: DefaultValue {
        
        try encode(type, forKey: key)
    }
}

protocol DefaultValue {
    associatedtype defalut: Codable
    static var defaultValue: defalut { get }
}

// MARK:基础数据类型 遵守DefaultValue
extension Bool: DefaultValue {
    static let defaultValue = false
}
extension String: DefaultValue {
    static let defaultValue = ""
}
extension Double: DefaultValue {
    static let defaultValue = -1
}
extension Int: DefaultValue {
    static let defaultValue = -1
}
extension Float: DefaultValue {
    static let defaultValue = -1
}
