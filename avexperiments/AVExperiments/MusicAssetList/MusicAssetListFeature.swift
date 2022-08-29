//
//  MusicAssetListFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import Foundation
import Combine
import ComposableArchitecture
import AVFoundation

struct MusicAssetListState: Equatable {
  var musicAssets: [MusicAssetModel] = []
  
}

enum MusicAssetListAction: Equatable {
  case load
  case selecet(id: Int)
}

struct MusicAssetListEnvironment {
  var bundleAudioLoader: () throws -> [MusicAssetModel]
}

extension MusicAssetListEnvironment {
  static func live(scheduler: AnySchedulerOf<DispatchQueue>)-> Self {
    .init(bundleAudioLoader: {
      do {
        var assetModels: [MusicAssetModel] = []
        let files = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
        
        files.enumerated().forEach { (index, file) in
          guard let path = Bundle.main.path(forResource: file, ofType: nil) else {
            return
          }
          var assetModel = MusicAssetModel(id: index, path: path)
          let asset = AVURLAsset(url: assetModel.url)
          if asset.isPlayable {
            assetModel.duration = asset.duration.seconds
            //using the asset property to get the metadata of file
            for metaDataItems in asset.commonMetadata {
              guard let key = metaDataItems.commonKey else {
                continue
              }
              
              switch key.rawValue {
                case "title":
                  guard let titleData = metaDataItems.value as? NSString else {
                    continue
                  }
                  assetModel.titleMeta = titleData as String
                  
                case "artist":
                  guard let artistData = metaDataItems.value as? NSString else {
                    continue
                  }
                  print("artist -> \(artistData)")
                  
                case "artwork":
                  guard let imageData = metaDataItems.value as? NSData else {
                    continue
                  }
                  print("image data exists")
                  assetModel.artworkData = imageData
                  
                default:
                  continue
              }
            }
            assetModels.append(assetModel)
          } // isPlayable
        } // forEach
        
        return assetModels
      }
      catch {
        throw error
      }
      
    })
  }
}


let musicAssetListReducer = Reducer<
  MusicAssetListState,
  MusicAssetListAction,
  MusicAssetListEnvironment> { state, action, environment in
    switch action {
      case .load:
        do {
          state.musicAssets = try environment.bundleAudioLoader()
        }
        catch {
          print("failed to load bundle audio assets.")
        }
      
        return .none
        
      case .selecet(let id):
        print("select action from the sheet \(id)")
        return .none
    }
}

