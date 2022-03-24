//// ViewController.swift
// ffmpegDemo
//
// Created by ffmpegDemo on 14/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit

class ViewController: BaseViewController, StoryboardSceneBased {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnListAction(_ sender: UIButton) {
        let vc = ListVC.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnRecordingWithAudio(_ sender: UIButton) {
        let vc = RecordingWithSound.instantiate()
        vc.isCameraAudioUse = false
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
    @IBAction func btnWithLyrics(_ sender: UIButton) {
        let vc = RecordingWithSoundLyrics.instantiate()
        vc.isCameraAudioUse = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
 
    @IBAction func btnHVideoRecording(_ sender: UIButton) {
        let vc = RecordingHVVC.instantiate()
        vc.isCameraAudioUse = false
        vc.isHorizontalStack = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnVVideoRecording(_ sender: UIButton) {
        let vc = RecordingHVVC.instantiate()
        vc.isCameraAudioUse = false
        vc.isHorizontalStack = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnVideoRecordingWithText(_ sender: UIButton) {
        let vc = RecordingTextImageVideoVC.instantiate()
        vc.isCameraAudioUse = true
        vc.isText = true
        vc.isVideo = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func btnVideoRecordingWithImage(_ sender: UIButton) {
        let vc = RecordingTextImageVideoVC.instantiate()
        vc.isCameraAudioUse = true
        vc.isText = false
        vc.isVideo = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnVideoRecordingWithVideo(_ sender: UIButton) {
        let vc = RecordingTextImageVideoVC.instantiate()
        vc.isCameraAudioUse = true
        vc.isText = false
        vc.isVideo = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

