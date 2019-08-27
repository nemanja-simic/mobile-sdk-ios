//
//  StorageAPI.swift
//  CrowdinSDK
//
//  Created by Serhii Londar on 5/8/19.
//

import Foundation

class StorageAPI: CrowdinAPI {
    let login: String
    let accountKey: String
    
    init(login: String, accountKey: String, organizationName: String? = nil) {
        self.login = login
        self.accountKey = accountKey
        super.init(organizationName: organizationName)
    }
    
    enum ParameterKeys: String {
        case login
        case accountKey = "account-key"
    }
    
    override var apiPath: String {
        return "storages"
    }
    
    func uploadNewFile(data: Data, completion: @escaping (StorageUploadResponse?, Error?) -> Void) {
        let parameters = [ParameterKeys.login.rawValue: login, ParameterKeys.accountKey.rawValue: accountKey]
        let headers = [RequestHeaderFields.contentType.rawValue: "image/png"]
        self.cw_post(url: fullPath, parameters: parameters, headers: headers, body: data, completion: completion)
    }
}
