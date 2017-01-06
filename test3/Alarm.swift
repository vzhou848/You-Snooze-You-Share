//
//  Alarm.swift
//  test3
//
//  Created by Vivian Zhou on 11/30/16.
//  Copyright © 2016 viv. All rights reserved.
//

import UIKit

class Alarm: NSObject, NSCoding {
    
    // MARK: Properties
    var time: String
    var onoff: Bool
    var id: Int
    
    //MARK: Archiving Paths
    static let DocumentsDirectory =
        FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("alarms")
    
    //MARK: Types
    struct PropertyKey {
        static let timeKey = "time"
        static let onoffKey = "onoff"
        static let idKey = "id"
    }
    
    
    // MARK: Initializer
    
    init?(time: String, onoff: Bool, id: Int) {
        
        // Initialize properties of Alarm
        self.time = time
        self.onoff = onoff
        self.id = id
        
        super.init()
        
        // If time is empty, return nil
        if time.isEmpty {
            return nil
        }
        
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: PropertyKey.timeKey)
        aCoder.encode(onoff, forKey: PropertyKey.onoffKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let time = aDecoder.decodeObject(forKey: "time") as! String
        let onoff = aDecoder.decodeBool(forKey: "onoff")
        let id = aDecoder.decodeInteger(forKey: "id")
        
        self.init(time: time, onoff: onoff, id: id)
    }
}
