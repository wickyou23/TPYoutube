/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Wraps the command status.
*/

import UIKit
import WatchConnectivity

// Constants to identify the Watch Connectivity methods, also for user-visible strings in UI.
//
enum Command: String {
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferComplicationUserInfo"
    
    case getSearchingVideo = "getSearchingVideo"
    case playVideo = "playVideo"
    case pauseVideo = "pauseVideo"
    case nextVideo = "nextVideo"
    case backVideo = "backVideo"
    case undefined
}

// Constants to identify the phrases of Watch Connectivity communication.
//
enum Phrase: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
    case undefined
}

// Wrap a timed color payload dictionary with a stronger type.
//
//struct TimedColor {
//    var timeStamp: String
//    var colorData: Data
//
//    var color: UIColor {
//        let optional = ((try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)) as Any??)
//        guard let color = optional as? UIColor else {
//            fatalError("Failed to unarchive a UIClor object!")
//        }
//        return color
//    }
//    var timedColor: [String: Any] {
//        return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
//    }
//
//    init(_ timedColor: [String: Any]) {
//        guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
//            let colorData = timedColor[PayloadKey.colorData] as? Data else {
//                fatalError("Timed color dictionary doesn't have right keys!")
//        }
//        self.timeStamp = timeStamp
//        self.colorData = colorData
//    }
//
//    init(_ timedColor: Data) {
//        let data = ((try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(timedColor)) as Any??)
//        guard let dictionary = data as? [String: Any] else {
//            fatalError("Failed to unarchive a timedColor dictionary!")
//        }
//        self.init(dictionary)
//    }
//}

// Wrap the command's status to bridge the commands status and UI.
//
struct CommandStatus {
    var command: Command
    var phrase: Phrase
//    var timedColor: TimedColor?
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var userInfoTranser: WCSessionUserInfoTransfer?
    var errorMessage: String?
    
    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}

struct TPCommandStatus {
    var command: TPCommand
    var phrase: Phrase
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var userInfoTranser: WCSessionUserInfoTransfer?
    var errorMessage: String?
    
    init(command: TPCommand, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}

struct TPCommand: Codable {
    var command: Command
    var phrase: Phrase
    var metadata: Data?
    
    var jsonMetadata: [String: Any]? {
        guard let data = metadata,
           let metadataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return metadataDict
    }
    
    enum CodingKeys: CodingKey {
        case command
        case metadata
        case phrase
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commandString = try container.decode(String.self, forKey: .command)
        let phraseString = try container.decode(String.self, forKey: .phrase)
        command = Command(rawValue: commandString) ?? .undefined
        phrase = Phrase(rawValue: phraseString) ?? .undefined
        metadata = try? container.decode(Data.self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command.rawValue, forKey: .command)
        try container.encode(phrase.rawValue, forKey: .phrase)
        
        if let metadata = metadata {
            try container.encode(metadata, forKey: .metadata)
        }
    }
    
    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
    
    init(command: Command, phrase: Phrase, metadata: [String: Any]) {
        self.command = command
        self.phrase = phrase
        
        if let data = try? JSONSerialization.data(withJSONObject: metadata) {
            self.metadata = data
        }
    }
    
    init(command: Command, phrase: Phrase, metadata: Data) {
        self.command = command
        self.phrase = phrase
        self.metadata = metadata
    }
    
    func toJson() -> [String: Any]? {
        let encode = JSONEncoder()
        if let data = try? encode.encode(self),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        
        return nil
    }
    
    static func initWithJson(json: [String: Any]) -> TPCommand? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        return try? decoder.decode(TPCommand.self, from: jsonData)
    }
}
