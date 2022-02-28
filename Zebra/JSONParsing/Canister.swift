//
//  Canister.swift
//  Zebra
//
//  Created by Amy While on 26/12/2021.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

import Foundation
import Evander

@objc(ZBCanister)
class Canister: NSObject {
    
    @objc public static let shared = Canister()
    @objc public var repos: [ZBDummySource] {
        safeRepos.raw
    }
    
    static let canisterQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "xyz.willy.Zebra.canister-queue", qos: .utility)
        queue.setSpecific(key: queueKey, value: queueContext)
        return queue
    }()
    public static let queueKey = DispatchSpecificKey<Int>()
    public static var queueContext = 2245
    private(set) public var safeRepos = SafeArray<ZBDummySource>(queue: canisterQueue, key: queueKey, context: queueContext)
    
    @objc public func fetchRepos(_ completion: @escaping () -> Void) {
        EvanderNetworking.request(url: "https://api.canister.me/v1/community/repositories/search?query=", type: [String: Any].self) { _, _, _, dict in
            guard let dict = dict,
                  let data = dict["data"] as? [[String: Any]] else { return }
            let repos = data.compactMap { ZBDummySource($0) }.sorted { $0.origin.localizedCaseInsensitiveCompare($1.origin) == .orderedAscending }
            if repos != self.safeRepos.raw {
                self.safeRepos.setTo(repos)
                completion()
            }
        }
    }
    
}

extension ZBDummySource {
    
    convenience init?(_ dict: [String: Any]) {
        guard let name = dict["name"] as? String,
              let _uri = dict["uri"] as? String,
              let uri  = URL(string: _uri) else { return nil }
        self.init(url: uri)
        origin = name
        verificationStatus = .exists
        if let dist = dict["dist"] as? String {
            distribution = dist
        }
        if let suite = dict["suite"] as? String {
            components = [suite]
        }
    }
    
}
