//// Utility.swift
// ffmpegDemo
//
// Created by ffmpegDemo on 16/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/// General object of Application Delegate
let APP_DELEGATE: AppDelegate                   =   UIApplication.shared.delegate as! AppDelegate

/// General object of FileManager
let FILE_MANAGER                                =   FileManager.default

/// General object of Main Bundle
let MAIN_BUNDLE                                 =   Bundle.main

/// General object of Main Screen
let MAIN_SCREEN                                 =   UIScreen.main

/// General object of UIApplication
let APPLICATION                                 =   UIApplication.shared

/// General object of Current Device
let CURRENT_DEVICE                              =   UIDevice.current

/// General object of NotificationCenter
let NOTIFICATION_CENTER                         =   NotificationCenter.default

class Utility: NSObject {
    
    static let sharedUtility = Utility()
    
    /// Get time in hours , minuts, secronds
    /// - Parameter seconds: Time ins seconds
    /// - Returns: tuples
    func secondsToHoursMinutesSeconds (seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func getFileLenght(fileName: String, exten: String) -> Double? {
        var length = 0.0
        if let path = MAIN_BUNDLE.path(forResource: fileName, ofType: exten) {
            let asset = AVURLAsset(url: URL(fileURLWithPath: path))
            let audioDuration = asset.duration
            length = CMTimeGetSeconds(audioDuration)
        }
        return length
    }

    func getThumbnail(urlPath: String, isWebPath: Bool = false, block:@escaping (UIImage?)->()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset: AVAsset!
            if isWebPath {
                asset = AVAsset(url: URL(string: urlPath)!)

            } else {
                asset = AVAsset(url: URL(fileURLWithPath: urlPath))
            }

            let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            assetImgGenerate.maximumSize = CGSize(width: 1160, height: 1160)
            assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero
            assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero

            let time = CMTimeMakeWithSeconds(Float64(1), preferredTimescale: 100)
            assetImgGenerate.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)], completionHandler: { (requestedTime, thumbnail, actualTime, result, error) in
                if error == nil {
                    let frameImg  = UIImage(cgImage: thumbnail!)
                    block(frameImg)
                }
            })
        }
    }
}
