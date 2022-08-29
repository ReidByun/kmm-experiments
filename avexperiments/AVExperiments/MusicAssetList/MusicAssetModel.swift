//
//  MusicAssetModel.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import Foundation


struct MusicAssetModel: Equatable, Identifiable {
  var id: Int = 0
  var path: String = ""
  var url: URL {
    URL(fileURLWithPath: self.path)
  }
  var titleMeta: String = ""
  var title: String {
    if self.titleMeta.isEmpty {
      return (self.path as NSString).lastPathComponent
    }
    else {
      return titleMeta
    }
  }
  var duration: Double = 0.0
  var formattedTime: String {
    PlayerTime(durationTime: self.duration).remainingText
  }
  var artist: String = ""
  var artworkData: NSData? = nil
}
