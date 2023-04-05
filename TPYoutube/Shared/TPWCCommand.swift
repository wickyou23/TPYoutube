import UIKit
import WatchConnectivity

enum TPCommandType: String {
    case getSearchingVideo = "getSearchingVideo"
    case loadVideo = "loadVideo"
    case averageColorOfCurrentVideo = "averageColorOfCurrentVideo"
    
    case playControl = "playControl"
    case pauseControl = "pauseControl"
    case nextControl = "nextControl"
    case backControl = "backControl"
    case undefined
}

enum TPPhraseType: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
    case notify = "notify"
    case undefined
}

struct TPCommand: Codable {
    var command: TPCommandType
    var phrase: TPPhraseType
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
        command = TPCommandType(rawValue: commandString) ?? .undefined
        phrase = TPPhraseType(rawValue: phraseString) ?? .undefined
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
    
    init(command: TPCommandType, phrase: TPPhraseType) {
        self.command = command
        self.phrase = phrase
    }
    
    init(command: TPCommandType, phrase: TPPhraseType, metadata: [String: Any]) {
        self.command = command
        self.phrase = phrase
        
        if let data = try? JSONSerialization.data(withJSONObject: metadata) {
            self.metadata = data
        }
    }
    
    init(command: TPCommandType, phrase: TPPhraseType, metadata: Data) {
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
