//
//  RealtimeUpdateFeature.swift
//  CrowdinSDK
//
//  Created by Serhii Londar on 3/5/19.
//

import Foundation

protocol RealtimeUpdateFeatureProtocol {
    static var shared: RealtimeUpdateFeatureProtocol? { get set }
    
    var success: (() -> Void)? { get set }
    var error: ((Error) -> Void)? { set get }
    var enabled: Bool { get set }
    
    init(localization: String, strings: [String], plurals: [String], hash: String, sourceLanguage: String)
    
    func start(success: (() -> Void)?, error: ((Error) -> Void)?)
    func start(with csrfToken: String, userAgent: String, cookies: [HTTPCookie], success: (() -> Void)?, error: ((Error) -> Void)?)
    func stop()
    func subscribe(control: Refreshable)
    func unsubscribe(control: Refreshable)
    func refreshAllControls()
}

class RealtimeUpdateFeature: RealtimeUpdateFeatureProtocol {
    static var shared: RealtimeUpdateFeatureProtocol?
    
    var success: (() -> Void)?
    var error: ((Error) -> Void)?
    var localization: String
    var hashString: String
    
    var active: Bool { return socketManger?.active ?? false }
    var enabled: Bool {
        set {
            newValue ? start() : stop()
        }
        get {
            return active
        }
    }
    
    private var controls = NSHashTable<AnyObject>.weakObjects()
    private var socketManger: CrowdinSocketManagerProtocol?
    private var mappingManager: CrowdinMappingManagerProtocol
    
    required init(localization: String, strings: [String], plurals: [String], hash: String, sourceLanguage: String) {
        self.localization = localization
        self.hashString = hash
        self.mappingManager = CrowdinMappingManager(strings: strings, plurals: plurals, hash: hash, sourceLanguage: sourceLanguage)
    }
    
    func subscribe(control: Refreshable) {
        guard let localizationKey = control.key else { return }
        guard let id = self.mappingManager.id(for: localizationKey) else { return }
        socketManger?.subscribeOnUpdateDraft(localization: localization, stringId: id)
        socketManger?.subscribeOnUpdateTopSuggestion(localization: localization, stringId: id)
        controls.add(control)
    }
    
    func unsubscribe(control: Refreshable) {
        controls.remove(control)
    }
    
    func start(success: (() -> Void)? = nil, error: ((Error) -> Void)? = nil) {
        LoginFeature.login(completion: { (csrfToken, userAgent, cookies) in
            self.start(with: csrfToken, userAgent: userAgent, cookies: cookies, success: success, error: error)
        }) { err in
            error?(err)
        }
    }
    
    func start(with csrfToken: String, userAgent: String, cookies: [HTTPCookie], success: (() -> Void)? = nil, error: ((Error) -> Void)? = nil) {
        self.success = success
        self.error = error
        self.socketManger = CrowdinSocketManager(hashString: hashString, csrfToken: csrfToken, userAgent: userAgent, cookies: cookies)
        self.socketManger?.didChangeString = { id, newValue in
            self.didChangeString(with: id, to: newValue)
        }
        
        self.socketManger?.didChangePlural = { id, newValue in
            self.didChangePlural(with: id, to: newValue)
        }
        
        self.socketManger?.error = error
        self.socketManger?.connect = {
            self.success?()
            self.subscribeAllVisibleConrols()
        }
        
        self.socketManger?.start()
    }
    
    func stop() {
        self.socketManger?.stop()
        self.socketManger?.didChangeString = nil
        self.socketManger?.didChangePlural = nil
        self.socketManger = nil
    }
    
    func refreshAllControls() {
        self.controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                refreshable.refresh()
            }
        }
    }
}

extension RealtimeUpdateFeature {
    func refreshControl(with localizationKey: String, newText: String) {
        self.controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                if let key = refreshable.key, key == localizationKey {
                    refreshable.refresh(text: newText)
                }
            }
        }
    }
    
    func subscribeAllVisibleConrols() {
        guard let window = UIApplication.shared.keyWindow else { return }
        subscribeAllControls(from: window)
    }
    
    func subscribeAllControls(from view: UIView) {
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.subscribe(control: refreshable)
            }
            subscribeAllControls(from: subview)
        }
    }
    
    func didChangeString(with id: Int, to newValue: String) {
        guard let key = mappingManager.stringLocalizationKey(for: id) else { return }
        self.refreshControl(with: key, newText: newValue)
    }
    
    func didChangePlural(with id: Int, to newValue: String) {
        guard let key = mappingManager.stringLocalizationKey(for: id) else { return }
        self.refreshControl(with: key, newText: newValue)
    }
}
